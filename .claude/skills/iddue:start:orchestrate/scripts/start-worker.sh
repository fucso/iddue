#!/bin/bash
# start-worker.sh - IDDUE ワーカープロセスを起動する
#
# Usage: bash start-worker.sh <sub-issue-number> <setup-branch>
#
# Output (stdout): ワーカーの PID
#
# 終了コード:
#   0: 起動成功
#   1: 引数エラー
#   2: ログディレクトリ作成失敗
#   3: ワーカー起動失敗

set -euo pipefail

SUB="${1:?Usage: $0 <sub-issue-number> <setup-branch>}"
SETUP_BRANCH="${2:?Usage: $0 <sub-issue-number> <setup-branch>}"

REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$REPO_ROOT"

LOG_DIR=".orchestrate/tasks/${SUB}"
mkdir -p "$LOG_DIR" || {
  echo "Error: Failed to create log directory: ${LOG_DIR}" >&2
  exit 2
}

LOG_FILE="${LOG_DIR}/worker.log"

WORKER_PROMPT="/iddue:start:worker ${SUB} ${SETUP_BRANCH}"

IDD_WORKER_SUB="${SUB}" env -u CLAUDECODE claude -p "${WORKER_PROMPT}" > "${LOG_FILE}" 2>&1 &
WORKER_PID=$!

if [ $? -ne 0 ] || [ -z "$WORKER_PID" ]; then
  echo "Error: Failed to launch worker for sub-issue #${SUB}" >&2
  exit 3
fi

echo "${WORKER_PID}"
