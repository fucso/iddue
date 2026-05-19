#!/bin/bash
# 変更ファイルの取得と品質チェックを一括実行する
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

ENV_NAME="$1"

CHANGED_FILES=$(bash .claude/skills/worktree-development/scripts/exec.sh "$ENV_NAME" "git diff --cached --name-only")

bash .claude/skills/worktree-development/scripts/quality-check.sh "$ENV_NAME" "$CHANGED_FILES"
