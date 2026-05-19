#!/bin/bash
# PR の情報と CI ステータスを取得する
#
# Usage: ./get-pr-info.sh <pr_number>
# Output: {"number": N, "headRefOid": "...", "url": "...", "checks": [...]}

set -e

PR_NUMBER="${1:?Usage: $0 <pr_number>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO=$(bash "${SCRIPT_DIR}/get-repo.sh")

PR=$(gh pr view "${PR_NUMBER}" \
  --repo "$REPO" \
  --json number,headRefOid,url)

if [ -z "${PR}" ] || [ "${PR}" = "null" ]; then
  echo "Error: PR #${PR_NUMBER} not found" >&2
  exit 1
fi

CHECKS=$(gh pr checks "${PR_NUMBER}" \
  --repo "$REPO" \
  --json name,state,conclusion,link 2>/dev/null || echo '[]')

echo "${PR}" | jq --argjson checks "${CHECKS}" '. + {checks: $checks}'
