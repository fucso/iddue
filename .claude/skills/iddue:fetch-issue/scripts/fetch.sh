#!/bin/bash
# iddue:fetch-issue スキルで必要な Issue コンテキストを一括取得する
#
# Usage: ./fetch.sh <issue_number>
#   issue_number: 取得する Issue 番号
#
# Output: JSON
#   issue:      対象 Issue（number, title, body, state, url, comments, linked_pr）
#   parent:     親 Issue（number, title, state, url, linked_pr）| null
#   sub_issues: 子 Issue 一覧 [{ number, title, state, url, linked_pr }, ...]
#   depends_on: Depends on Issue 一覧 [{ number, title, state, url, linked_pr }, ...]
#
# Example: bash .claude/skills/iddue:fetch-issue/scripts/fetch.sh 103

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISSUE_NUMBER="${1:?Usage: $0 <issue_number>}"

echo "=== Issue #${ISSUE_NUMBER} のコンテキスト取得 ===" >&2

# 対象 Issue の取得（body + comments を含む）
echo "[1/4] Issue #${ISSUE_NUMBER} を取得中..." >&2
issue=$(bash "$SCRIPT_DIR/get-issue.sh" "$ISSUE_NUMBER")
issue_pr=$(bash "$SCRIPT_DIR/get-linked-pr.sh" "$ISSUE_NUMBER")
issue=$(echo "$issue" | jq --argjson pr "$issue_pr" '. + {linked_pr: $pr}')

# 親 Issue の取得（body なし・linked_pr 含む）
echo "[2/4] 親 Issue を取得中..." >&2
parent=$(bash "$SCRIPT_DIR/get-parent-issue.sh" "$ISSUE_NUMBER")

# 子 Issue の取得（body なし・linked_pr 含む）
echo "[3/4] 子 Issue を取得中..." >&2
sub_issues=$(bash "$SCRIPT_DIR/get-sub-issues.sh" "$ISSUE_NUMBER")

# Depends on Issue の取得
# 本文から "Depends on: #NNN" パターンを抽出し、各 Issue の情報（body/comments なし）を取得する
echo "[4/4] Depends on Issue を取得中..." >&2
depends_on='[]'
depends_on_numbers=$(echo "$issue" | jq -r '.body // ""' | grep -o 'Depends on: #[0-9]*' | grep -o '[0-9]*' || true)

if [ -n "$depends_on_numbers" ]; then
  for dep_num in $depends_on_numbers; do
    echo "  - #${dep_num} を取得中..." >&2
    dep_issue=$(bash "$SCRIPT_DIR/get-issue.sh" "$dep_num" | jq '{number, title, state, url}')
    dep_pr=$(bash "$SCRIPT_DIR/get-linked-pr.sh" "$dep_num")
    dep_with_pr=$(echo "$dep_issue" | jq --argjson pr "$dep_pr" '. + {linked_pr: $pr}')
    depends_on=$(echo "$depends_on" | jq --argjson dep "$dep_with_pr" '. + [$dep]')
  done
fi

echo "" >&2
echo "=== 取得完了 ===" >&2

# 結果を JSON として stdout に出力（AI が解析する）
jq -n \
  --argjson issue "$issue" \
  --argjson parent "$parent" \
  --argjson sub_issues "$sub_issues" \
  --argjson depends_on "$depends_on" \
  '{
    issue: $issue,
    parent: $parent,
    sub_issues: $sub_issues,
    depends_on: $depends_on
  }'
