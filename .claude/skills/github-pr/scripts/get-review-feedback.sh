#!/bin/bash
# PR のレビュースレッドを取得する
#
# Usage: ./get-review-feedback.sh <pr_number> [--resolved <true|false>] [--outdated <true|false>]
# Defaults: --resolved false --outdated false

set -e

PR_NUMBER="${1:?Usage: $0 <pr_number> [--resolved <true|false>] [--outdated <true|false>]}"
shift

RESOLVED="false"
OUTDATED="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resolved) RESOLVED="${2:?--resolved requires a value}"; shift 2 ;;
    --outdated) OUTDATED="${2:?--outdated requires a value}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FULL=$(bash "${SCRIPT_DIR}/get-repo.sh")
OWNER=$(echo "$REPO_FULL" | cut -d'/' -f1)
REPO=$(echo "$REPO_FULL" | cut -d'/' -f2)

gh api graphql \
  -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $number) {
          reviewThreads(first: 100) {
            nodes {
              id
              isResolved
              isOutdated
              comments(first: 10) {
                nodes {
                  databaseId
                  url
                  body
                  path
                  diffHunk
                  originalCommit { oid }
                  author { login }
                  createdAt
                }
              }
            }
          }
        }
      }
    }
  ' \
  -f owner="$OWNER" \
  -f repo="$REPO" \
  -F number="${PR_NUMBER}" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes' \
| jq --argjson resolved "${RESOLVED}" --argjson outdated "${OUTDATED}" \
  'map(select(.isResolved == $resolved and .isOutdated == $outdated))'
