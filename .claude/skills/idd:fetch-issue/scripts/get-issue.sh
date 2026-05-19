#!/bin/bash
# 指定した Issue の詳細情報を取得する
#
# Usage: ./get-issue.sh <issue_number>
#   issue_number: 取得する Issue 番号
#
# Output: JSON（number, title, body, state, url, comments）
#
# Example: bash .claude/skills/idd:fetch-issue/scripts/get-issue.sh 103

set -euo pipefail

ISSUE_NUMBER="${1:?Usage: $0 <issue_number>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FULL=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")
OWNER=$(echo "$REPO_FULL" | cut -d'/' -f1)
REPO=$(echo "$REPO_FULL" | cut -d'/' -f2)

gh issue view "$ISSUE_NUMBER" \
  --repo "${OWNER}/${REPO}" \
  --json number,title,body,state,url,comments
