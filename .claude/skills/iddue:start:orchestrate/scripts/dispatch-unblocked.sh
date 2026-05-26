#!/bin/bash
# dispatch-unblocked.sh - ブロックなしタスクの readiness チェック + ワーカー起動
#
# Usage: bash dispatch-unblocked.sh <parent-issue-number>
#
# Output (stdout): 起動/スキップの結果サマリー
#
# 終了コード:
#   0: 正常終了（ワーカー 0 件でも正常）
#   1: 引数エラー

set -euo pipefail

PARENT_ISSUE_NUMBER="${1:?Usage: $0 <parent-issue-number>}"
MAIN_ISSUE_BRANCH="iddue/${PARENT_ISSUE_NUMBER}"

REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$REPO_ROOT"

TASKS_JS=".claude/skills/iddue:start:orchestrate/scripts/tasks.js"
START_WORKER=".claude/skills/iddue:start:orchestrate/scripts/start-worker.sh"

UNBLOCKED=$(node "$TASKS_JS" unblocked)

if [ -z "$UNBLOCKED" ]; then
  echo "No unblocked tasks."
  exit 0
fi

DISPATCHED=0
STATUS_CHANGED=false

# サマリー用の配列（bash 3 互換のため文字列で管理）
STARTED_LINES=""
NG_LINES=""

issue_title() {
  local sub="$1"
  local yaml=".iddue/issue/${sub}.yaml"
  if [ -f "$yaml" ]; then
    grep "  title:" "$yaml" | head -1 | sed 's/.*title: //' | tr -d '"' | tr -d "'"
  else
    echo "#${sub}"
  fi
}

while IFS= read -r SUB; do
  [ -z "$SUB" ] && continue

  LOG_DIR=".orchestrate/tasks/${SUB}"
  mkdir -p "$LOG_DIR"
  JUDGING_LOG="${LOG_DIR}/judging.log"

  echo "Checking readiness for #${SUB}..."

  env -u CLAUDECODE claude --no-session-persistence -p "/iddue:judging-ready-to-implementation ${SUB}" > "$JUDGING_LOG" 2>&1 || true

  TITLE=$(issue_title "$SUB")

  if grep -q "✅" "$JUDGING_LOG"; then
    PID=$(bash "$START_WORKER" "$SUB" "$MAIN_ISSUE_BRANCH")
    node "$TASKS_JS" start "$SUB" "$PID"
    echo "  → Worker started (PID: ${PID})"
    DISPATCHED=$((DISPATCHED + 1))
    STATUS_CHANGED=true
    STARTED_LINES="${STARTED_LINES}  #${SUB} ${TITLE} iddue/${SUB}\n"
  else
    echo "  → Not ready (#${SUB}). Leaving in pending."
    NG_LINES="${NG_LINES}  #${SUB} ${TITLE}\n$(cat "$JUDGING_LOG")\n"
  fi
done <<< "$UNBLOCKED"

if [ "$STATUS_CHANGED" = "true" ]; then
  git add .orchestrate/status.yaml
  git commit -m "orchestration: dispatch unblocked tasks for #${PARENT_ISSUE_NUMBER} (workers: ${DISPATCHED})"
fi

echo ""
echo "=== dispatch-unblocked 完了 ==="
echo ""

if [ -n "$STARTED_LINES" ]; then
  echo "起動したワーカー:"
  printf "%b" "$STARTED_LINES"
else
  echo "起動したワーカー: なし"
fi

echo ""

if [ -n "$NG_LINES" ]; then
  echo "readiness NG（pending に残します）:"
  printf "%b" "$NG_LINES"
fi
