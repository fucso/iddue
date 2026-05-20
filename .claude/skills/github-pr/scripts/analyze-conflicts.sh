#!/bin/bash
# PR のコンフリクトを分析する
#
# Usage: ./analyze-conflicts.sh <base_ref> <head_ref>
#   base_ref: ベースブランチ名（例: main）
#   head_ref: PR ヘッドブランチ名（例: idd/5）
#
# Output: JSON 配列。各要素は以下を含む:
#   { "file": "...", "base_diff": "...", "head_diff": "..." }
#
# 両側で変更されているファイル（コンフリクト候補）のみ出力する。
# コンフリクト候補がない場合は空配列 [] を出力する。

set -euo pipefail

BASE_REF="${1:?Usage: $0 <base_ref> <head_ref>}"
HEAD_REF="${2:?Usage: $0 <base_ref> <head_ref>}"

git fetch origin "${BASE_REF}" 2>/dev/null
git fetch origin "${HEAD_REF}" 2>/dev/null

MERGE_BASE=$(git merge-base "origin/${BASE_REF}" "origin/${HEAD_REF}")

BASE_FILES=$(git diff "${MERGE_BASE}" "origin/${BASE_REF}" --name-only | sort)
HEAD_FILES=$(git diff "${MERGE_BASE}" "origin/${HEAD_REF}" --name-only | sort)

CONFLICT_FILES=$(comm -12 <(echo "$BASE_FILES") <(echo "$HEAD_FILES") || true)

if [ -z "$CONFLICT_FILES" ]; then
  echo "[]"
  exit 0
fi

RESULTS="[]"
while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue
  BASE_DIFF=$(git diff "${MERGE_BASE}" "origin/${BASE_REF}" -- "${FILE}" 2>/dev/null || true)
  HEAD_DIFF=$(git diff "${MERGE_BASE}" "origin/${HEAD_REF}" -- "${FILE}" 2>/dev/null || true)
  ENTRY=$(jq -n \
    --arg file "$FILE" \
    --arg base_diff "$BASE_DIFF" \
    --arg head_diff "$HEAD_DIFF" \
    '{file: $file, base_diff: $base_diff, head_diff: $head_diff}')
  RESULTS=$(echo "$RESULTS" | jq --argjson e "$ENTRY" '. + [$e]')
done <<< "$CONFLICT_FILES"

echo "$RESULTS"
