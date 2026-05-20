#!/bin/bash
# iddue:start/scripts/create-pr.sh
# 既存 PR の確認と PR 作成を一括で行う
#
# Usage:
#   bash create-pr.sh <task_branch> <title> <base_branch> <body_file>
#
# Arguments:
#   task_branch  実装ブランチ名
#   title        PR タイトル
#   base_branch  マージ先ブランチ
#   body_file    PR 本文を記述した一時ファイルのパス
#
# Output (stdout):
#   exists:{pr_number}:{pr_url}   - 既存の open PR が見つかった場合
#   created:{pr_number}:{pr_url}  - PR を新規作成した場合

set -euo pipefail

TASK_BRANCH="${1:?Usage: $0 <task_branch> <title> <base_branch> <body_file>}"
TITLE="${2:?Usage: $0 <task_branch> <title> <base_branch> <body_file>}"
BASE_BRANCH="${3:?Usage: $0 <task_branch> <title> <base_branch> <body_file>}"
BODY_FILE="${4:?Usage: $0 <task_branch> <title> <base_branch> <body_file>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")
OWNER=$(echo "$REPO" | cut -d'/' -f1)

if [ ! -f "$BODY_FILE" ]; then
  echo "Error: body_file not found: $BODY_FILE" >&2
  exit 1
fi

# 既存の open PR を確認
EXISTING=$(gh pr list \
  --repo "$REPO" \
  --head "${OWNER}:${TASK_BRANCH}" \
  --state open \
  --json number,url \
  --jq '.[0] | "\(.number):\(.url)"' 2>/dev/null || echo "")

if [ -n "$EXISTING" ] && [ "$EXISTING" != "null:null" ]; then
  echo "exists:${EXISTING}"
  exit 0
fi

# PR を新規作成
PR_URL=$(gh pr create \
  --repo "$REPO" \
  --title "$TITLE" \
  --body-file "$BODY_FILE" \
  --head "$TASK_BRANCH" \
  --base "$BASE_BRANCH")

PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')

echo "created:${PR_NUMBER}:${PR_URL}"
