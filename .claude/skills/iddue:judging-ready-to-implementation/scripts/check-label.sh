#!/bin/bash
# 指定した Issue に "ready to implementation" ラベルが付与されているか確認する
#
# Usage: ./check-label.sh <issue_number>
#   issue_number: 確認する Issue 番号
#
# Output:
#   ラベルあり → exit 0
#   ラベルなし → exit 1
#
# Example: bash .claude/skills/iddue:judging-ready-to-implementation/scripts/check-label.sh 101

set -euo pipefail

ISSUE_NUMBER="${1:?Usage: $0 <issue_number>}"
LABEL="ready to implementation"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_FULL=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")
OWNER=$(echo "$REPO_FULL" | cut -d'/' -f1)
REPO=$(echo "$REPO_FULL" | cut -d'/' -f2)

has_label=$(gh api "repos/${OWNER}/${REPO}/issues/${ISSUE_NUMBER}" \
  --jq "[.labels[].name] | contains([\"${LABEL}\"])")

if [ "$has_label" = "true" ]; then
  exit 0
else
  exit 1
fi
