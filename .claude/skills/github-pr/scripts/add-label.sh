#!/bin/bash
# PR ラベル付与スクリプト
# ラベルを PR に付与する。
# 付与に失敗した場合（ラベル未登録）はデフォルト値でラベルを作成してから再試行する。
#
# Usage: bash add-label.sh [-h] <pr_number> <label>
#
# Options:
#   -h  ラベルが未登録の場合にデフォルト値で作成してから付与する
#
# Example:
#   bash .claude/skills/github-pr/scripts/add-label.sh 101 "your label"
#   bash .claude/skills/github-pr/scripts/add-label.sh -h 101 "your label"

set -euo pipefail

CREATE_IF_MISSING=false
if [[ "${1:-}" == "-h" ]]; then
  CREATE_IF_MISSING=true
  shift
fi

PR_NUMBER="${1:?Usage: $0 [-h] <pr_number> <label>}"
LABEL="${2:?Usage: $0 [-h] <pr_number> <label>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FULL=$(bash "${SCRIPT_DIR}/get-repo.sh")
OWNER=$(echo "$REPO_FULL" | cut -d'/' -f1)
REPO=$(echo "$REPO_FULL" | cut -d'/' -f2)

# ラベルを PR に付与する（ラベル未登録の場合は非ゼロで終了）
add_label() {
  gh pr edit "$PR_NUMBER" \
    --repo "${OWNER}/${REPO}" \
    --add-label "$LABEL" 2>/dev/null
}

# デフォルト値でラベルをリポジトリに登録する
create_label() {
  echo "ラベル \"${LABEL}\" が存在しないため作成します..." >&2
  gh label create "$LABEL" \
    --repo "${OWNER}/${REPO}" \
    --color "ededed" \
    --description ""
}

if $CREATE_IF_MISSING; then
  # 付与 → 失敗ならラベル登録 → 再付与
  if ! add_label; then
    create_label
    add_label
  fi
else
  add_label
fi

echo "ラベル \"${LABEL}\" を PR #${PR_NUMBER} に付与しました" >&2
