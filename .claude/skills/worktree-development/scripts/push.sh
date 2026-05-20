#!/bin/bash
# 作業環境のコミットをリモートにプッシュする
#
# Usage: ./push.sh <environment_name> <branch>
#   environment_name: 作業環境の識別名（例: iddue/103）
#   branch: プッシュ先のブランチ名（origin/ プレフィックスは自動除去されます）
#
# Example: ./push.sh iddue/103 feature/my-feature
#
# 注意: detached HEAD でコミットした場合、worktree を削除するとコミットが
#       到達不能になるため、必ずクリーンアップ前にこのスクリプトを実行してください。

set -e
cd "$(git rev-parse --show-toplevel)"

ENVIRONMENT_NAME="${1:?環境名を指定してください}"
BRANCH_INPUT="${2:?ブランチ名を指定してください}"
WORKTREE_PATH=".worktree/${ENVIRONMENT_NAME}"

# origin/ プレフィックスを除去（二重指定防止）
BRANCH="${BRANCH_INPUT#origin/}"

echo "=== プッシュ処理 ==="
echo "環境名: ${ENVIRONMENT_NAME}"
echo "パス: ${WORKTREE_PATH}"
echo "ブランチ: ${BRANCH}"
echo ""

# 作業環境の存在確認
if [ ! -d "${WORKTREE_PATH}" ]; then
    echo "エラー: 作業環境が存在しません: ${WORKTREE_PATH}"
    exit 1
fi

# 現在のコミットSHAを取得
COMMIT_SHA=$(git -C "${WORKTREE_PATH}" rev-parse HEAD)
echo "--- コミット情報 ---"
echo "コミット SHA: ${COMMIT_SHA}"
echo ""

# プッシュ（detached HEAD からでもコミットSHAを使ってプッシュ可能）
echo "--- プッシュ ---"
git push origin "${COMMIT_SHA}:refs/heads/${BRANCH}"
echo ""

echo "=== プッシュ完了 ==="
echo "ブランチ: ${BRANCH}"
echo "コミット: ${COMMIT_SHA}"
