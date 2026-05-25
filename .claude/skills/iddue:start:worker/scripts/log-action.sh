#!/bin/bash
# log-action.sh - worker アクションをリアルタイムに actions.log へ記録する
#
# PostToolUse フックから呼び出される。
# 環境変数 IDD_WORKER_SUB（start-worker.sh が設定）でタスク番号を受け取り、
# .orchestrate/tasks/{sub}/actions.log に1行追記する。
#
# stdin: Claude Code が渡す PostToolUse の JSON
# 出力例: [12:01:05] Edit: app/models/user.rb

set -euo pipefail

SUB="${IDD_WORKER_SUB:-unknown}"
LOG_DIR="${CLAUDE_PROJECT_DIR}/.orchestrate/tasks/${SUB}"
ACTIONS_LOG="${LOG_DIR}/actions.log"

[ -d "$LOG_DIR" ] || exit 0

DATA=$(cat)

TOOL=$(echo "$DATA" | jq -r '.tool_name // "unknown"')

KEY=$(echo "$DATA" | jq -r '
  .tool_input |
  if .file_path then .file_path
  elif .command then (.command | .[0:70])
  elif .description then .description
  elif .pattern then .pattern
  elif .glob then .glob
  elif .query then .query
  else (to_entries | if length > 0 then (.[0].value | tostring | .[0:70]) else "" end)
  end
' 2>/dev/null || echo "")

echo "[$(date +%H:%M:%S)] ${TOOL}: ${KEY}" >> "$ACTIONS_LOG"
