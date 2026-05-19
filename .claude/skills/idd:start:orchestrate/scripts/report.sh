#!/bin/bash
# report.sh - オーケストレーション完了レポートを定型出力する
#
# Usage: bash report.sh <parent-issue-number>

set -euo pipefail

PARENT="${1:?Usage: $0 <parent-issue-number>}"

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT=$(git -C "$SCRIPTS" rev-parse --show-toplevel)
cd "$REPO_ROOT"

ISSUE_YAML=".idd/issue/${PARENT}.yaml"
CONFIG_YAML=".idd/orchestration/config.yaml"
STATUS_YAML=".idd/orchestration/status.yaml"

# config.yaml からタイトルを取得
task_title() {
  local sub="$1"
  grep -A 2 "issue: ${sub}$" "$CONFIG_YAML" 2>/dev/null \
    | grep "title:" | head -1 \
    | sed 's/.*title: //' | tr -d '"' || echo "#${sub}"
}

# PR URL
PR_URL=""
if [ -f "$ISSUE_YAML" ]; then
  PR_URL=$(grep "url:" "$ISSUE_YAML" | grep "pull" | head -1 | awk '{print $2}' | tr -d '"' || true)
fi

STATUS_OUT=$(cat "$STATUS_YAML")

COMPLETED=$(echo "$STATUS_OUT" | awk '/^completed_tasks:/{f=1;next} f && /^  - /{print $2} f && !/^  - /{exit}' || true)
SKIPPED=$(echo "$STATUS_OUT"   | awk '/^skipped_tasks:/{f=1;next}   f && /^  - /{print $2} f && !/^  - /{exit}' || true)
PENDING=$(echo "$STATUS_OUT"   | awk '/^pending_tasks:/{f=1;next}   f && /^  - /{print $2} f && !/^  - /{exit}' || true)
FAILED=$(echo "$STATUS_OUT"    | grep "^failed_task:" | grep -v "null" | awk '{print $2}' || true)

echo ""
echo "✅ /idd:start:orchestrate 完了"
echo ""
echo "親 Issue: #${PARENT}"
echo "ブランチ: idd/${PARENT}"
[ -n "$PR_URL" ] && echo "PR: ${PR_URL}"
echo ""

if [ -n "$COMPLETED" ]; then
  echo "完了したサブ Issue:"
  while IFS= read -r sub; do
    [ -z "$sub" ] && continue
    echo "  - #${sub}: $(task_title "$sub")"
  done <<< "$COMPLETED"
  echo ""
fi

if [ -n "$SKIPPED" ]; then
  echo "スキップしたサブ Issue:"
  while IFS= read -r sub; do
    [ -z "$sub" ] && continue
    echo "  - #${sub}: $(task_title "$sub")"
  done <<< "$SKIPPED"
  echo ""
fi

if [ -n "$FAILED" ]; then
  echo "失敗したサブ Issue:"
  echo "  - #${FAILED}"
  echo ""
fi

if [ -n "$PENDING" ]; then
  echo "未処理のサブ Issue:"
  while IFS= read -r sub; do
    [ -z "$sub" ] && continue
    echo "  - #${sub}: $(task_title "$sub")"
  done <<< "$PENDING"
fi

# pending タスクの judging ログが存在すれば常に出力
JUDGING_NG_FOUND=false
if [ -n "$PENDING" ]; then
  while IFS= read -r sub; do
    [ -z "$sub" ] && continue
    JUDGING_LOG=".idd/orchestration/tasks/${sub}/judging.log"
    if [ -f "$JUDGING_LOG" ]; then
      $JUDGING_NG_FOUND || { echo ""; echo "⚠️  judging NG のサブ Issue（対応が必要）:"; }
      JUDGING_NG_FOUND=true
      echo ""
      echo "--- #${sub}: $(task_title "$sub") ---"
      cat "$JUDGING_LOG"
    fi
  done <<< "$PENDING"
fi
