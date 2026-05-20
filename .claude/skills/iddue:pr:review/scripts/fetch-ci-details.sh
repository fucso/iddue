#!/bin/bash
# 失敗した CI チェックの詳細を収集して stdout に出力する
#
# Usage: ./fetch-ci-details.sh <pr_number>
#
# 処理内容:
#   1. 全 checks を取得して failure のみ絞り込み
#   2. 各 failure の check_run_id を取得してアノテーションを付与
#   3. .claude/iddue-hooks/get-ci-failure-details.sh が存在すれば呼び出し
#
# フックへの引数: <pr_number> <head_sha> <failed_checks_json_file>
#   failed_checks_json_file: [{name, conclusion, link, annotations}] の JSON ファイルパス
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PR_NUMBER="${1:?PR番号を指定してください}"

HEAD_SHA=$(gh pr view "${PR_NUMBER}" --json headRefOid --jq '.headRefOid')
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

FAILED_CHECKS_FILE=$(mktemp /tmp/iddue-failed-checks.XXXXXX.json)
ENRICHED_FILE=$(mktemp /tmp/iddue-enriched-checks.XXXXXX.json)
trap "rm -f ${FAILED_CHECKS_FILE} ${ENRICHED_FILE}" EXIT

gh pr checks "${PR_NUMBER}" \
  --json name,state,link \
  --jq '[.[] | select(.state == "FAILURE")]' \
  > "${FAILED_CHECKS_FILE}"

FAILURE_COUNT=$(jq 'length' "${FAILED_CHECKS_FILE}")

if [ "${FAILURE_COUNT}" -eq 0 ]; then
  echo "CI に失敗はありません。"
  exit 0
fi

echo "## 失敗した CI チェック（${FAILURE_COUNT} 件）"
echo ""

ENRICHED_ARRAY="[]"
while read -r CHECK; do
  CHECK_NAME=$(echo "${CHECK}" | jq -r '.name')

  CHECK_RUN_ID=$(gh api "repos/${REPO}/commits/${HEAD_SHA}/check-runs" \
    --jq ".check_runs[] | select(.name == \"${CHECK_NAME}\") | .id" \
    2>/dev/null | head -1)

  ANNOTATIONS="[]"
  if [ -n "${CHECK_RUN_ID:-}" ]; then
    ANNOTATIONS=$(gh api "repos/${REPO}/check-runs/${CHECK_RUN_ID}/annotations" 2>/dev/null || echo "[]")
  fi

  ENRICHED_ITEM=$(echo "${CHECK}" | jq --argjson annotations "${ANNOTATIONS}" '. + {annotations: $annotations}')
  ENRICHED_ARRAY=$(echo "${ENRICHED_ARRAY}" | jq --argjson item "${ENRICHED_ITEM}" '. + [$item]')
done < <(jq -c '.[]' "${FAILED_CHECKS_FILE}")

echo "${ENRICHED_ARRAY}" > "${ENRICHED_FILE}"

jq -r '.[] |
  "### \(.name)\n" +
  if (.annotations | length) > 0 then
    (.annotations[] | "- \(.path):\(.start_line) [\(.annotation_level)] \(.message)")
  else
    "アノテーション: なし"
  end
' "${ENRICHED_FILE}"

HOOK=".claude/iddue-hooks/get-ci-failure-details.sh"
if [ -f "${HOOK}" ]; then
  echo ""
  echo "---"
  bash "${HOOK}" "${PR_NUMBER}" "${HEAD_SHA}" "${ENRICHED_FILE}"
fi
