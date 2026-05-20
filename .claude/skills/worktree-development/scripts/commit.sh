#!/bin/bash
# 作業環境での変更をコミットする
#
# Usage: ./commit.sh <environment_name> <commit_message> [branch_name]
#   environment_name: 作業環境の識別名（例: iddue/103）
#   commit_message: コミットメッセージ
#   branch_name: （オプション）新しいブランチ名。指定すると新しいブランチを作成してからコミット
#
# Examples:
#   ./commit.sh iddue/103 "[Issue#103] 機能実装"
#   ./commit.sh iddue/103 "[Issue#103] 機能実装" feature/new-branch

set -e
cd "$(git rev-parse --show-toplevel)"

ENVIRONMENT_NAME="${1:?環境名を指定してください}"
COMMIT_MESSAGE="${2:?コミットメッセージを指定してください}"
BRANCH_NAME="${3:-}"  # オプション: 新しいブランチ名
WORKTREE_PATH=".worktree/${ENVIRONMENT_NAME}"

echo "=== コミット処理 ==="
echo "環境名: ${ENVIRONMENT_NAME}"
echo "パス: ${WORKTREE_PATH}"
if [ -n "${BRANCH_NAME}" ]; then
    echo "新しいブランチ: ${BRANCH_NAME}"
fi
echo ""

# 作業環境の存在確認
if [ ! -d "${WORKTREE_PATH}" ]; then
    echo "エラー: 作業環境が存在しません: ${WORKTREE_PATH}"
    exit 1
fi

# 新しいブランチの作成（指定された場合）
if [ -n "${BRANCH_NAME}" ]; then
    echo "--- 新しいブランチを作成 ---"
    git -C "${WORKTREE_PATH}" checkout -b "${BRANCH_NAME}"
    echo "ブランチ '${BRANCH_NAME}' を作成しました"
    echo ""
fi

# ステージング
echo "--- 変更をステージング ---"
git -C "${WORKTREE_PATH}" add .
echo "完了"
echo ""

# 変更の確認
echo "--- 変更内容 ---"
git -C "${WORKTREE_PATH}" status --short
echo ""

# コミット
echo "--- コミット ---"
git -C "${WORKTREE_PATH}" commit -m "${COMMIT_MESSAGE}"
echo ""

# コミット情報の表示
echo "=== コミット完了 ==="
COMMIT_SHA=$(git -C "${WORKTREE_PATH}" rev-parse HEAD)
echo "コミット SHA: ${COMMIT_SHA}"
echo "ブランチ: $(git -C "${WORKTREE_PATH}" branch --show-current)"
