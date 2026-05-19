#!/bin/bash
# 指定した Issue の子 Issue 一覧と各子 Issue に紐づいた PR を取得する
#
# Usage: ./get-sub-issues.sh <issue_number>
#   issue_number: 対象 Issue 番号
#
# Output: JSON 配列 [{ number, title, state, url, linked_pr }, ...]
#   linked_pr: { number, branch, url, state } or null
#   子がない場合は []
#
# Example: bash .claude/skills/idd:fetch-issue/scripts/get-sub-issues.sh 103

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
      subIssues(first: 50) {
        nodes {
          number
          title
          state
          url
          timelineItems(first: 25, itemTypes: [CONNECTED_EVENT]) {
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
    .data.repository.issue.subIssues.nodes
    | map({
        number: .number,
        title: .title,
        state: .state,
        url: .url,
        linked_pr: (
          .timelineItems.nodes
          | map(select(.subject != null) | .subject)
          | first
          // null
          | if . then {number: .number, branch: .headRefName, url: .url, state: .state}
            else null end
        )
      })
  '
