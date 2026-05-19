#!/bin/bash
# 指定した PR の docs/ 配下の変更差分を取得する
#
# Usage: ./get-pr-docs-diff.sh <pr_number>
#   pr_number: 対象 PR 番号
#
# Output:
#   - docs/ 配下に変更がある場合: 変更ファイル一覧（JSON）と diff を出力
#   - 変更がない場合: 何も出力しない（exit 0）
#
# Example: bash .claude/skills/idd:fetch-issue/scripts/get-pr-docs-diff.sh 456

set -euo pipefail

PR_NUMBER="${1:?Usage: $0 <pr_number>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FULL=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")
OWNER=$(echo "$REPO_FULL" | cut -d'/' -f1)
REPO=$(echo "$REPO_FULL" | cut -d'/' -f2)

# docs/ 配下の変更ファイル一覧を取得
changed_docs=$(gh pr view "$PR_NUMBER" \
  --repo "${OWNER}/${REPO}" \
  --json files \
  --jq '[.files[] | select(.path | startswith("docs/")) | .path]')

# 変更がなければ終了
if [ "$changed_docs" = "[]" ]; then
  exit 0
fi

echo "=== 変更された docs ファイル ==="
echo "$changed_docs"
echo ""
echo "=== diff ==="
gh pr diff "$PR_NUMBER" \
  --repo "${OWNER}/${REPO}" \
  -- docs/
