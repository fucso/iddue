#!/bin/bash
# check-completion.sh - オーケストレーション完了チェック
#
# Usage: bash check-completion.sh <parent-issue-number>
#
# 終了コード:
#   0: 全タスク正常完了（status=completed, pending_tasks=[], failed_task=null）
#   1: 未完了タスクあり（pending/failed が残っている）
#
# stdout（exit 0 の場合）:
#   完了タスクの report.md パスを1行ずつ出力（ファイルが存在するもののみ）

set -euo pipefail

PARENT="${1:?Usage: $0 <parent-issue-number>}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT=$(git -C "$SCRIPTS" rev-parse --show-toplevel)
cd "$REPO_ROOT"

STATUS_YAML=".orchestrate/status.yaml"

if [ ! -f "$STATUS_YAML" ]; then
  echo "Error: $STATUS_YAML が見つかりません" >&2
  exit 1
fi

STATUS=$(grep "^status:" "$STATUS_YAML" | awk '{print $2}')
PENDING_COUNT=$(awk '/^pending_tasks:/{f=1;next} f && /^  - /{c++} f && !/^  - /{exit} END{print c+0}' "$STATUS_YAML")
FAILED=$(grep "^failed_task:" "$STATUS_YAML" | awk '{print $2}')

if [ "$STATUS" != "completed" ] || [ "$PENDING_COUNT" -gt 0 ] || [ "$FAILED" != "null" ]; then
  echo "未完了: status=${STATUS}, pending=${PENDING_COUNT}, failed=${FAILED}" >&2
  exit 1
fi

# 完了タスクの report.md パスを出力（存在するもののみ）
find ".orchestrate/reports" -name "implement.md" -type f 2>/dev/null | sort || true
