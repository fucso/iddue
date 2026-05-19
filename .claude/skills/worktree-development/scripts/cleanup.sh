#!/bin/bash
# 作業環境をクリーンアップする
#
# Usage: ./cleanup.sh <environment_name>
#   environment_name: 作業環境の識別名（例: idd/103）
#
# Example: ./cleanup.sh idd/103

set -e
cd "$(git rev-parse --show-toplevel)"

ENVIRONMENT_NAME="${1:?環境名を指定してください}"
WORKTREE_PATH=".worktree/${ENVIRONMENT_NAME}"

echo "=== クリーンアップ処理 ==="
echo "環境名: ${ENVIRONMENT_NAME}"
echo "パス: ${WORKTREE_PATH}"
echo ""

# worktree の削除
echo "--- worktree の削除 ---"
if git worktree list | grep -q "${WORKTREE_PATH}"; then
    git worktree remove "${WORKTREE_PATH}" --force
    echo "worktree を削除しました"
else
    echo "worktree は既に存在しません"
fi
echo ""

# ディレクトリの削除（残っている場合）
echo "--- ディレクトリの削除 ---"
if [ -d "${WORKTREE_PATH}" ]; then
    rm -rf "${WORKTREE_PATH}"
    echo "ディレクトリを削除しました"
else
    echo "ディレクトリは既に存在しません"
fi
echo ""

echo "=== クリーンアップ完了 ==="
