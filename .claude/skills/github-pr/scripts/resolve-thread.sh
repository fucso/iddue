#!/bin/bash
# レビュースレッドを resolve する
#
# Usage: ./resolve-thread.sh <thread_id>
# Output: "true" (resolve 成功時)

set -e

THREAD_ID="${1:?Usage: $0 <thread_id>}"

gh api graphql \
  -f query='
    mutation($threadId: ID!) {
      resolveReviewThread(input: {threadId: $threadId}) {
        thread { isResolved }
      }
    }
  ' \
  -f threadId="${THREAD_ID}" \
  --jq '.data.resolveReviewThread.thread.isResolved'
