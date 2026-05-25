#!/bin/bash
# wait-for-completion.sh - active ワーカーのいずれか1つの完了/クラッシュを検知して終了
#
# Usage: bash wait-for-completion.sh <parent-issue-number>
#
# 監視対象は起動時に tasks.js active から1回だけ取得する。
# 最初のイベントを stdout に出力して即終了する。
#
# Output (stdout):
#   COMPLETED:{sub}  完了時（終了コード 0）
#   CRASHED:{sub}    クラッシュ時（終了コード 1）
#
# 終了コード:
#   0: 完了検知
#   1: クラッシュ検知
#   2: 監視対象なし

set -euo pipefail

PARENT="${1:?Usage: $0 <parent-issue-number>}"

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT=$(git -C "$SCRIPTS" rev-parse --show-toplevel)
cd "$REPO_ROOT"

POLL_INTERVAL=15
POLL_MAX=120

# 監視対象を取得
ACTIVE=$(node "$SCRIPTS/tasks.js" active)

if [ -z "$ACTIVE" ]; then
  echo "No active workers."
  exit 2
fi

while true; do
  while IFS=: read -r SUB PID; do
    [ -z "$SUB" ] && continue
    REPORT=".orchestrate/reports/${SUB}/implement.md"

    if git log --oneline "iddue/${SUB}" -- "${REPORT}" 2>/dev/null | grep -q .; then
      echo "COMPLETED:${SUB}"
      exit 0
    elif ! kill -0 "${PID}" 2>/dev/null; then
      echo "CRASHED:${SUB}"
      exit 1
    fi
  done <<< "$ACTIVE"

  sleep "$POLL_INTERVAL"
  POLL_INTERVAL=$(( POLL_INTERVAL * 2 ))
  [ "$POLL_INTERVAL" -gt "$POLL_MAX" ] && POLL_INTERVAL=$POLL_MAX
done
