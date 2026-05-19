#!/bin/bash
# PR にレビューを投稿する
#
# Usage: echo "<body>" | ./post-review.sh <pr_number> <sha> <event> [comments_json_file]
#   event: REQUEST_CHANGES | COMMENT
#   comments_json_file: インラインコメントの JSON ファイル（省略時はインラインなし）
#     形式: [{"path": "...", "line": N, "body": "..."}]
# stdin: レビュー本文

set -e

PR_NUMBER="${1:?Usage: echo '<body>' | $0 <pr_number> <sha> <event> [comments_json_file]}"
SHA="${2:?}"
EVENT="${3:?}"
COMMENTS_FILE="${4:-}"
BODY=$(cat)

if [ -n "${COMMENTS_FILE}" ] && [ -f "${COMMENTS_FILE}" ]; then
  COMMENTS=$(cat "${COMMENTS_FILE}")
else
  COMMENTS="[]"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=$(bash "${SCRIPT_DIR}/get-repo.sh")

jq -n \
  --arg commit_id "${SHA}" \
  --arg body "${BODY}" \
  --arg event "${EVENT}" \
  --argjson comments "${COMMENTS}" \
  '{commit_id: $commit_id, body: $body, event: $event, comments: $comments}' \
| gh api "repos/${REPO}/pulls/${PR_NUMBER}/reviews" \
  --method POST \
  --input -
