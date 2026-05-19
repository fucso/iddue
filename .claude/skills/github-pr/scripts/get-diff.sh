#!/bin/bash
# PR の差分またはコミット間の差分を取得する
#
# Usage:
#   ./get-diff.sh <pr_number> [--name-only]
#   ./get-diff.sh <pr_number> <start_oid> <end_oid> [path] [--name-only]
#
# start_oid/end_oid 省略時: PR 全体の差分（gh pr diff）
# start_oid/end_oid 指定時: 指定コミット間の差分（git diff）

set -e

PR_NUMBER="${1:?Usage: $0 <pr_number> [<start_oid> <end_oid> [path]] [--name-only]}"
shift

NAME_ONLY=false
START_OID=""
END_OID=""
FILE_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name-only) NAME_ONLY=true; shift ;;
    *)
      if [ -z "${START_OID}" ]; then
        START_OID="$1"
      elif [ -z "${END_OID}" ]; then
        END_OID="$1"
      else
        FILE_PATH="$1"
      fi
      shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=$(bash "${SCRIPT_DIR}/get-repo.sh")

if [ -z "${START_OID}" ]; then
  if ${NAME_ONLY}; then
    gh pr diff "${PR_NUMBER}" --repo "$REPO" --name-only
  else
    gh pr diff "${PR_NUMBER}" --repo "$REPO"
  fi
else
  if [ -z "${END_OID}" ]; then
    echo "Error: end_oid is required when start_oid is specified" >&2
    exit 1
  fi
  RANGE="${START_OID}..${END_OID}"
  if [ -n "${FILE_PATH}" ]; then
    if ${NAME_ONLY}; then
      git diff --name-only "${RANGE}" -- "${FILE_PATH}"
    else
      git diff "${RANGE}" -- "${FILE_PATH}"
    fi
  else
    if ${NAME_ONLY}; then
      git diff --name-only "${RANGE}"
    else
      git diff "${RANGE}"
    fi
  fi
fi
