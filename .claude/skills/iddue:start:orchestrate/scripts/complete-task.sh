#!/bin/bash
# complete-task.sh - サブ Issue のマージと状態更新を行う
#
# Usage: bash complete-task.sh <sub-issue-number> <parent-issue-number>
#
# 終了コード:
#   0: 成功
#   1: 引数エラー
#   2: フック中断
#   3: マージ失敗
#   5: コンフリクト解消失敗

set -euo pipefail

SUB="${1:?Usage: $0 <sub-issue-number> <parent-issue-number>}"
PARENT="${2:?Usage: $0 <sub-issue-number> <parent-issue-number>}"
MAIN_ISSUE_BRANCH="iddue/${PARENT}"

REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$REPO_ROOT"

SUB_BRANCH="iddue/${SUB}"
SCRIPTS_DIR="$(dirname "$0")"
STATUS_FILE=".orchestrate/status.yaml"
BEFORE_MERGE_HOOK="${REPO_ROOT}/.claude/orchestration-hooks/before-merge.sh"

# Step 1: before-merge フック（存在する場合のみ実行）
if [ -f "${BEFORE_MERGE_HOOK}" ]; then
  bash "${BEFORE_MERGE_HOOK}" "${SUB}" "${SUB_BRANCH}" "${MAIN_ISSUE_BRANCH}" || {
    echo "Error: before-merge hook aborted merge for sub-issue #${SUB}" >&2
    exit 2
  }
fi

# Step 2: メイン Issue ブランチに切り替え
git checkout "${MAIN_ISSUE_BRANCH}"

# Step 3: マージ（ローカルブランチを直接マージ）
if ! git merge --no-ff "${SUB_BRANCH}" -m "Merge sub-issue #${SUB} into ${MAIN_ISSUE_BRANCH}"; then
  # コンフリクト検知
  if git diff --name-only --diff-filter=U | grep -q .; then
    git merge --abort 2>/dev/null || true
    echo "Merge conflict in sub-issue #${SUB}. Launching conflict resolver..." >&2

    CONFLICT_REPORT=".orchestrate/reports/${SUB}/conflict.md"
    mkdir -p "$(dirname "${CONFLICT_REPORT}")"

    # フォアグラウンドで起動（完了を待つ）
    if env -u CLAUDECODE claude -p \
         "/iddue:orchestration-development:resolve-conflict ${SUB} ${PARENT}" \
         > "${CONFLICT_REPORT}" 2>&1; then
      # 解消成功: iddue/<SUB> が parent の変更を含んだ状態に更新されているため再マージはクリーン
      git checkout "${MAIN_ISSUE_BRANCH}"
      if ! git merge --no-ff "${SUB_BRANCH}" \
           -m "Merge sub-issue #${SUB} into ${MAIN_ISSUE_BRANCH}"; then
        echo "Error: Re-merge failed after conflict resolution for sub-issue #${SUB}" >&2
        node "${SCRIPTS_DIR}/tasks.js" fail "${SUB}" "re-merge-failed"
        exit 3
      fi
    else
      echo "Error: Conflict resolution failed for sub-issue #${SUB}" >&2
      node "${SCRIPTS_DIR}/tasks.js" fail "${SUB}" "conflict-resolution-failed"
      exit 5
    fi
  else
    echo "Error: Merge failed for sub-issue #${SUB}" >&2
    exit 3
  fi
fi

# Step 4: tasks.js で状態を complete に更新
node "${SCRIPTS_DIR}/tasks.js" complete "${SUB}"

# Step 5: status.yaml をコミット
git add "${STATUS_FILE}"
git commit -m "orchestration: complete sub-issue #${SUB}"

echo "Sub-issue #${SUB} merged and marked complete"
