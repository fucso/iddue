#!/bin/bash
# コメントを minimize する
#
# Usage: ./minimize-comment.sh <node_id> [--classifier <RESOLVED|OUTDATED|SPAM|ABUSE|OFF_TOPIC|DUPLICATE>]
# Default classifier: RESOLVED
#
# 対象: PR review body (PRR_...), issue comment (IC_...) など Minimizable な node
# ※ inline review thread (PRRT_...) は resolve-thread.sh を使うこと

set -e

NODE_ID="${1:?Usage: $0 <node_id> [--classifier <RESOLVED|OUTDATED|...>]}"
shift

CLASSIFIER="RESOLVED"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --classifier) CLASSIFIER="${2:?--classifier requires a value}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

gh api graphql \
  -f query='
    mutation($subjectId: ID!, $classifier: ReportedContentClassifiers!) {
      minimizeComment(input: {subjectId: $subjectId, classifier: $classifier}) {
        minimizedComment {
          isMinimized
          minimizedReason
        }
      }
    }
  ' \
  -f subjectId="${NODE_ID}" \
  -f classifier="${CLASSIFIER}" \
  --jq '.data.minimizeComment.minimizedComment.isMinimized'
