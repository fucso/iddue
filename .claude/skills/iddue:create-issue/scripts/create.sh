#!/bin/bash
# iddue:create-issue/scripts/create.sh
# GitHub Issue を作成し、指定があれば親 Issue の Sub-issue として登録する
#
# Usage:
#   bash create.sh <title> <labels> [parent_issue_number] << 'EOF'
#   {Issue 本文}
#   EOF
#
# Arguments:
#   title               Issue タイトル
#   labels              ラベルのカンマ区切り文字列（例: "iddue,level:concrete"）
#   parent_issue_number 親 Issue 番号（省略可）
#
# Stdin:
#   Issue 本文（マークダウン）

set -e

TITLE="$1"
LABELS="$2"
PARENT_ISSUE_NUMBER="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")

if [ -z "$TITLE" ] || [ -z "$LABELS" ]; then
  echo "Error: title and labels are required" >&2
  echo "Usage: $0 <title> <labels> [parent_issue_number] < body_content" >&2
  exit 1
fi

# Issue 本文を stdin から一時ファイルへ
BODY_FILE=$(mktemp /tmp/iddue-issue-body.XXXXXX.md)
trap "rm -f '$BODY_FILE'" EXIT
cat > "$BODY_FILE"

# ラベルをカンマで分割して配列化
LABEL_LIST=()
IFS=',' read -ra RAW_LABELS <<< "$LABELS"
for label in "${RAW_LABELS[@]}"; do
  label=$(echo "$label" | xargs)  # trim whitespace
  [ -n "$label" ] && LABEL_LIST+=("$label")
done

# Issue を作成（ラベルなし。ラベル未登録エラーを避けるため後から付与する）
ISSUE_URL=$(gh issue create \
  --title "$TITLE" \
  --body-file "$BODY_FILE" \
  --repo "$REPO")

ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -o '[0-9]*$')

echo "Created: #${ISSUE_NUMBER} ${ISSUE_URL}"

# ラベルを付与（未登録の場合は labels.yaml を参照して自動作成）
for label in "${LABEL_LIST[@]}"; do
  bash "${SCRIPT_DIR}/../../iddue/scripts/add-label.sh" "$ISSUE_NUMBER" "$label"
done

# 親 Issue が指定されている場合は Sub-issue として登録
if [ -n "$PARENT_ISSUE_NUMBER" ]; then
  PARENT_NODE_ID=$(gh api "repos/${REPO}/issues/${PARENT_ISSUE_NUMBER}" --jq '.node_id')
  CHILD_NODE_ID=$(gh api "repos/${REPO}/issues/${ISSUE_NUMBER}" --jq '.node_id')

  gh api graphql -f query='
    mutation($parentId: ID!, $childId: ID!) {
      addSubIssue(input: {issueId: $parentId, subIssueId: $childId}) {
        issue { number }
      }
    }
  ' -f parentId="$PARENT_NODE_ID" -f childId="$CHILD_NODE_ID" > /dev/null

  echo "Registered as sub-issue of #${PARENT_ISSUE_NUMBER}"
fi
