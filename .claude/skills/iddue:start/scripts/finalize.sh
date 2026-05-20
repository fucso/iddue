#!/bin/bash
# コミット・プッシュ・クリーンアップを一括実行する
# 引数: ENV_NAME COMMIT_MESSAGE TASK_BRANCH
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

ENV_NAME="$1"
COMMIT_MESSAGE="$2"
TASK_BRANCH="$3"

bash .claude/skills/worktree-development/scripts/commit.sh "$ENV_NAME" "$COMMIT_MESSAGE" "$TASK_BRANCH"
bash .claude/skills/worktree-development/scripts/push.sh "$ENV_NAME" "$TASK_BRANCH"
bash .claude/skills/worktree-development/scripts/cleanup.sh "$ENV_NAME"
