#!/bin/bash
# IDD 共通ラベル付与スクリプト
# ラベルを Issue に付与する。
# 付与に失敗した場合（ラベル未登録）は labels.yaml を参照してラベルを作成してから再試行する。
#
# Usage: bash add-label.sh <issue_number> <label>
#
# Example:
#   bash .claude/skills/iddue/scripts/add-label.sh 101 "iddue"
#   bash .claude/skills/iddue/scripts/add-label.sh 101 "ready to implementation"

set -euo pipefail

ISSUE_NUMBER="${1:?Usage: $0 <issue_number> <label>}"
LABEL="${2:?Usage: $0 <issue_number> <label>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FULL=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")
OWNER=$(echo "$REPO_FULL" | cut -d'/' -f1)
REPO=$(echo "$REPO_FULL" | cut -d'/' -f2)
LABELS_YAML="${SCRIPT_DIR}/../config/labels.yaml"
GET_ATTR="${SCRIPT_DIR}/get-label-attr.py"

# ラベルを Issue に付与する（ラベル未登録の場合は非ゼロで終了）
add_label() {
  gh issue edit "$ISSUE_NUMBER" \
    --repo "${OWNER}/${REPO}" \
    --add-label "$LABEL" 2>/dev/null
}

# labels.yaml を参照してラベルをリポジトリに登録する
create_label() {
  local color description
  color=$(python3 "$GET_ATTR" "$LABEL" "color" "$LABELS_YAML")
  description=$(python3 "$GET_ATTR" "$LABEL" "description" "$LABELS_YAML")

  echo "ラベル \"${LABEL}\" が存在しないため作成します..." >&2
  gh label create "$LABEL" \
    --repo "${OWNER}/${REPO}" \
    --color "${color:-ededed}" \
    --description "${description:-}"
}

# 付与 → 失敗ならラベル登録 → 再付与
if ! add_label; then
  create_label
  add_label
fi

echo "ラベル \"${LABEL}\" を Issue #${ISSUE_NUMBER} に付与しました" >&2
