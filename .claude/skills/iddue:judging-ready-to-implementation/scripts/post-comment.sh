#!/bin/bash
# 指定した Issue に判定結果をコメントとして投稿する
# Usage: bash post-comment.sh <issue_number> <comment_body>

set -euo pipefail

ISSUE_NUMBER="${1:?Usage: $0 <issue_number> <comment_body>}"
COMMENT_BODY="${2:?Usage: $0 <issue_number> <comment_body>}"

gh issue comment "$ISSUE_NUMBER" --body "$COMMENT_BODY"
