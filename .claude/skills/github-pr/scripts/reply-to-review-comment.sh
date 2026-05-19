#!/bin/bash
# PR レビューコメントへの返信を投稿する
#
# Usage: echo "<body>" | ./reply-to-review-comment.sh <pr_number> <comment_id>
#   comment_id: 返信先コメントの databaseId
# stdin: 返信本文

set -e

PR_NUMBER="${1:?Usage: echo '<body>' | $0 <pr_number> <comment_id>}"
COMMENT_ID="${2:?}"
BODY=$(cat)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=$(bash "${SCRIPT_DIR}/get-repo.sh")

gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
  --method POST \
  --field body="${BODY}"
