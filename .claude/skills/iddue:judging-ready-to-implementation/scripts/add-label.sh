#!/bin/bash
# 指定した Issue に "ready to implementation" ラベルを付与する
# iddue 共通スクリプトに委譲する
#
# Usage: bash add-label.sh <issue_number>
#
# Example: bash .claude/skills/iddue:judging-ready-to-implementation/scripts/add-label.sh 101

set -euo pipefail

ISSUE_NUMBER="${1:?Usage: $0 <issue_number>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${SCRIPT_DIR}/../../iddue/scripts/add-label.sh" "$ISSUE_NUMBER" "ready to implementation"
