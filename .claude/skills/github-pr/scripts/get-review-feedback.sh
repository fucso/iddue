#!/bin/bash
# PR のレビュースレッドとレビュー本体を取得する
#
# Usage: ./get-review-feedback.sh <pr_number> [--resolved <true|false>] [--outdated <true|false>]
# Defaults: フラグ未指定時はフィルターなし（両方取得）
#
# 返却オブジェクトの type フィールド:
#   "thread" - コード行に紐づくインラインスレッド (PullRequest.reviewThreads)
#   "review" - PR Review 本体 (PullRequest.reviews, 非空 body のみ)
#
# --resolved / --outdated フィルターは "thread" にのみ適用される。
# "review" は body が空でないもののうち最新の 1 件のみを返す。

set -e

PR_NUMBER="${1:?Usage: $0 <pr_number> [--resolved <true|false>] [--outdated <true|false>]}"
shift

RESOLVED=""
OUTDATED=""

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
          reviews(first: 100) {
            nodes {
              databaseId
              url
              state
              body
              author { login }
              submittedAt
              commit { oid }
            }
          }
        }
      }
    }
  ' \
  -f owner="$OWNER" \
  -f repo="$REPO" \
  -F number="${PR_NUMBER}" \
  --jq '{threads: .data.repository.pullRequest.reviewThreads.nodes, reviews: .data.repository.pullRequest.reviews.nodes}' \
| jq --arg resolved "${RESOLVED}" --arg outdated "${OUTDATED}" \
  '
    (
      .threads
      | map(select(
          ($resolved == "" or .isResolved == ($resolved == "true"))
          and ($outdated == "" or .isOutdated == ($outdated == "true"))
        ))
      | map(. + {type: "thread"})
    )
    +
    (
      .reviews
      | map(select(.body != null and .body != ""))
      | sort_by(.submittedAt)
      | last
      | if . then [. + {type: "review"}] else [] end
    )
  '
