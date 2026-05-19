#!/bin/bash
# 作業環境内で任意のコマンドを実行する
#
# Usage: ./exec.sh <environment_name> <command> [options...]
#   environment_name: 作業環境の識別名（例: idd/103）
#   command: 実行するコマンド
#   options: 任意のオプション（フックに透過される。例: --docker）
#
# Examples:
#   ./exec.sh idd/103 "bundle exec rails runner 'puts User.count'" --docker
#   ./exec.sh idd/103 "git diff --cached --name-only"
#
# .claude/worktree-hooks/exec.sh が存在すればそれを使用する。
# フックの引数: <worktree_path> <command> [options...]
# フックが存在しない場合は worktree ディレクトリ内で直接実行する。

set -e
cd "$(git rev-parse --show-toplevel)"

ENVIRONMENT_NAME="${1:?環境名を指定してください}"
COMMAND="${2:?コマンドを指定してください}"
WORKTREE_PATH=".worktree/${ENVIRONMENT_NAME}"
shift 2

if [ ! -d "${WORKTREE_PATH}" ]; then
    echo "エラー: 作業環境が存在しません: ${WORKTREE_PATH}" >&2
    exit 1
fi

EXEC_HOOK=".claude/worktree-hooks/exec.sh"
if [ -f "${EXEC_HOOK}" ]; then
    bash "${EXEC_HOOK}" "${WORKTREE_PATH}" "${COMMAND}" "$@"
else
    bash -c "cd ${WORKTREE_PATH} && ${COMMAND}"
fi
