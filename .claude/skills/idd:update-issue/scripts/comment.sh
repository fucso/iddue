#!/bin/bash
# idd:update-issue/scripts/comment.sh
# GitHub Issue にコメントを追加する。
#
# Usage:
#   bash comment.sh <issue_number> < comment_content
#
# Arguments:
#   issue_number  コメント対象の Issue 番号
#
# Stdin:
#   コメント本文（マークダウン）

set -e

ISSUE_NUMBER="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")

if [ -z "$ISSUE_NUMBER" ]; then
  echo "Error: issue_number is required" >&2
  echo "Usage: $0 <issue_number> < comment_content" >&2
  exit 1
fi

# コメント本文を stdin から一時ファイルへ
COMMENT_FILE=$(mktemp /tmp/idd-issue-comment.XXXXXX.md)
trap "rm -f '$COMMENT_FILE'" EXIT
cat > "$COMMENT_FILE"

gh issue comment "$ISSUE_NUMBER" \
  --body-file "$COMMENT_FILE" \
  --repo "$REPO"

echo "Commented on: #${ISSUE_NUMBER}"
