#!/bin/bash
# 作業環境での品質チェックを実行する
#
# Usage: ./quality-check.sh <environment_name> [changed_files]
#   environment_name: 作業環境の識別名（例: iddue/103）
#   changed_files: worktree で変更したファイルのリスト（スペース区切り、省略可）
#                  どのファイルをテスト対象とするかはリポジトリ固有フックが決定する
#
# Examples:
#   ./quality-check.sh iddue/103 "app/models/user.rb lib/foo.rb"
#
# .claude/worktree-hooks/quality-check.sh が存在すればそれを使用する。
# フックの引数: <worktree_path> <changed_files>
# フックが存在しない場合は何もせずに終了する（exit 0）。

cd "$(git rev-parse --show-toplevel)"

ENVIRONMENT_NAME="${1:?環境名を指定してください}"
CHANGED_FILES="${2:-}"
WORKTREE_PATH=".worktree/${ENVIRONMENT_NAME}"

echo "=== 品質チェック ==="
echo "環境名: ${ENVIRONMENT_NAME}"
echo "パス: ${WORKTREE_PATH}"
if [ -n "${CHANGED_FILES}" ]; then
    echo "変更ファイル: ${CHANGED_FILES}"
fi
echo ""

if [ ! -d "${WORKTREE_PATH}" ]; then
    echo "エラー: 作業環境が存在しません: ${WORKTREE_PATH}"
    exit 1
fi

QUALITY_CHECK_HOOK=".claude/worktree-hooks/quality-check.sh"
if [ -f "${QUALITY_CHECK_HOOK}" ]; then
    bash "${QUALITY_CHECK_HOOK}" "${WORKTREE_PATH}" "${CHANGED_FILES}"
else
    echo "品質チェックフックが未設定のため、スキップします"
fi
