#!/bin/bash
# worktree 作業環境をセットアップする
#
# Usage: ./setup.sh <environment_name> <branch>
#   environment_name: 作業環境の識別名（例: idd/103）、ブランチ名としても使用される
#   branch: ベースとなるブランチ名（origin/ プレフィックスは自動除去されます）
#
# ブランチの扱い:
#   - environment_name と同名のブランチが存在しない場合: branch をベースに新規作成
#   - environment_name と同名のブランチが既存の場合: そのブランチの最新コミットから開始
#
# Example: ./setup.sh idd/103 feature/my-feature
# Example: ./setup.sh idd/103 origin/feature/my-feature  # origin/ は自動除去
#
# セットアップ後に .claude/worktree-hooks/post-setup.sh が存在すれば実行する。
# フックの引数: <worktree_path>

set -e
cd "$(git rev-parse --show-toplevel)"

ENVIRONMENT_NAME="${1:?環境名を指定してください}"
BRANCH_INPUT="${2:?ブランチ名を指定してください}"
WORKTREE_PATH=".worktree/${ENVIRONMENT_NAME}"

# origin/ プレフィックスを除去（二重指定防止）
BRANCH="${BRANCH_INPUT#origin/}"

echo "=== worktree 作業環境のセットアップ ==="
echo "環境名: ${ENVIRONMENT_NAME}"
echo "ブランチ: ${BRANCH}"
echo "パス: ${WORKTREE_PATH}"
echo ""

# 1. 既存環境のクリーンアップ
echo "--- 1. 既存環境のクリーンアップ ---"
if git worktree list | grep -q "${WORKTREE_PATH}"; then
    echo "既存の worktree を削除中..."
    git worktree remove "${WORKTREE_PATH}" --force || true
fi
if [ -d "${WORKTREE_PATH}" ]; then
    echo "既存のディレクトリを削除中..."
    rm -rf "${WORKTREE_PATH}"
fi
mkdir -p .worktree
echo "完了"
echo ""

# 2. ブランチの fetch と worktree 作成
echo "--- 2. ブランチの fetch と worktree 作成 ---"
echo "ブランチを fetch 中..."
git fetch origin "${BRANCH}"
echo "worktree を作成中..."
if git show-ref --verify --quiet "refs/heads/${ENVIRONMENT_NAME}"; then
    echo "既存ブランチ '${ENVIRONMENT_NAME}' を使用します"
    git worktree add "${WORKTREE_PATH}" "${ENVIRONMENT_NAME}"
else
    echo "新規ブランチ '${ENVIRONMENT_NAME}' を作成します"
    git worktree add -b "${ENVIRONMENT_NAME}" "${WORKTREE_PATH}" FETCH_HEAD
fi
echo "完了"
echo ""

# 3. Submodule 初期化
echo "--- 3. Submodule 初期化 ---"
git -C "${WORKTREE_PATH}" submodule update --init
echo "完了"
echo ""

# 4. post-setup フック
echo "--- 4. post-setup フック ---"
POST_SETUP_HOOK=".claude/worktree-hooks/post-setup.sh"
if [ -f "${POST_SETUP_HOOK}" ]; then
    bash "${POST_SETUP_HOOK}" "${WORKTREE_PATH}"
else
    echo "フックなし（スキップ）"
fi
echo "完了"
echo ""

echo "=== セットアップ完了 ==="
echo "作業環境パス: ${WORKTREE_PATH}"
