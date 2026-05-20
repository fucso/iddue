#!/bin/bash
# 指定した Issue に紐づいた PR の番号・ブランチ・URL・状態を取得する
#
# Usage: ./get-linked-pr.sh <issue_number>
#   issue_number: 対象 Issue 番号
#
# Output: JSON { number, branch, url, state } or null（紐づいた PR がない場合）
#
# Example: bash .claude/skills/idd:fetch-issue/scripts/get-linked-pr.sh 103

set -euo pipefail

ISSUE_NUMBER="${1:?Usage: $0 <issue_number>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FULL=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")
OWNER=$(echo "$REPO_FULL" | cut -d'/' -f1)
REPO=$(echo "$REPO_FULL" | cut -d'/' -f2)

gh api graphql -f query='
query($name: String!, $owner: String!, $issue_number: Int!) {
  repository(name: $name, owner: $owner) {
    issue(number: $issue_number) {
      timelineItems(first: 25, itemTypes: [CONNECTED_EVENT, CROSS_REFERENCED_EVENT]) {
        nodes {
          ... on ConnectedEvent {
            subject {
              ... on PullRequest {
                number
                headRefName
                url
                state
              }
            }
          }
          ... on CrossReferencedEvent {
            willCloseTarget
            source {
              ... on PullRequest {
                number
                headRefName
                url
                state
              }
            }
          }
        }
      }
    }
  }
}' \
  -f owner="$OWNER" \
  -f name="$REPO" \
  -F issue_number="$ISSUE_NUMBER" \
  | jq '
    .data.repository.issue.timelineItems.nodes
    | map(
        if .subject then .subject
        elif (.willCloseTarget == true) and .source then .source
        else null end
      )
    | map(select(. != null and .number != null))
    | first
    // null
    | if . then {number: .number, branch: .headRefName, url: .url, state: .state}
      else null end
  '
