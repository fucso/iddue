#!/bin/bash
# iddue:update-issue/scripts/update.sh
# GitHub Issue の本文を更新し、"ready to implementation" ラベルが付いていれば削除する。
#
# Usage:
#   bash update.sh <issue_number> < body_content
#
# Arguments:
#   issue_number  更新対象の Issue 番号
#
# Stdin:
#   新しい Issue 本文（マークダウン）

set -e

ISSUE_NUMBER="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")
READY_LABEL="ready to implementation"

if [ -z "$ISSUE_NUMBER" ]; then
  echo "Error: issue_number is required" >&2
  echo "Usage: $0 <issue_number> < body_content" >&2
  exit 1
fi

# Issue 本文を stdin から一時ファイルへ
BODY_FILE=$(mktemp /tmp/iddue-issue-body.XXXXXX.md)
trap "rm -f '$BODY_FILE'" EXIT
cat > "$BODY_FILE"

# Issue 本文を更新
gh issue edit "$ISSUE_NUMBER" \
  --body-file "$BODY_FILE" \
  --repo "$REPO"

# "ready to implementation" ラベルが付いていれば削除
has_label=$(gh api "repos/${REPO}/issues/${ISSUE_NUMBER}" \
  --jq --arg label "$READY_LABEL" '[.labels[].name] | contains([$label])')
if [ "$has_label" = "true" ]; then
  gh issue edit "$ISSUE_NUMBER" \
    --remove-label "$READY_LABEL" \
    --repo "$REPO"
  echo "Removed label: ${READY_LABEL}"
fi

ISSUE_URL=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --json url --jq '.url')
echo "Updated: #${ISSUE_NUMBER} ${ISSUE_URL}"
