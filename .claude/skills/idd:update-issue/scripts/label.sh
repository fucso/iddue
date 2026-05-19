#!/bin/bash
# idd:update-issue/scripts/label.sh
# GitHub Issue のラベルを追加・削除する
#
# Usage:
#   bash label.sh <issue_number> <add_labels_csv> <remove_labels_csv>
#
# Arguments:
#   issue_number      操作対象の Issue 番号
#   add_labels_csv    追加するラベルのカンマ区切り文字列（なければ空文字列）
#   remove_labels_csv 削除するラベルのカンマ区切り文字列（なければ空文字列）

set -e

ISSUE_NUMBER="$1"
ADD_LABELS="$2"
REMOVE_LABELS="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=$(bash "${SCRIPT_DIR}/../../github-pr/scripts/get-repo.sh")

if [ -z "$ISSUE_NUMBER" ]; then
  echo "Error: issue_number is required" >&2
  echo "Usage: $0 <issue_number> <add_labels_csv> <remove_labels_csv>" >&2
  exit 1
fi

# ラベル追加
if [ -n "$ADD_LABELS" ]; then
  ADD_ARGS=()
  IFS=',' read -ra ADD_LIST <<< "$ADD_LABELS"
  for label in "${ADD_LIST[@]}"; do
    label=$(echo "$label" | xargs)
    [ -n "$label" ] && ADD_ARGS+=(--add-label "$label")
  done
  if [ ${#ADD_ARGS[@]} -gt 0 ]; then
    gh issue edit "$ISSUE_NUMBER" "${ADD_ARGS[@]}" --repo "$REPO"
    echo "Added labels: $ADD_LABELS"
  fi
fi

# ラベル削除
if [ -n "$REMOVE_LABELS" ]; then
  REMOVE_ARGS=()
  IFS=',' read -ra REMOVE_LIST <<< "$REMOVE_LABELS"
  for label in "${REMOVE_LIST[@]}"; do
    label=$(echo "$label" | xargs)
    [ -n "$label" ] && REMOVE_ARGS+=(--remove-label "$label")
  done
  if [ ${#REMOVE_ARGS[@]} -gt 0 ]; then
    gh issue edit "$ISSUE_NUMBER" "${REMOVE_ARGS[@]}" --repo "$REPO"
    echo "Removed labels: $REMOVE_LABELS"
  fi
fi
