#!/bin/bash
# GitHub リポジトリの "owner/repo" 形式の名前を取得する
#
# 環境変数 GITHUB_REPOSITORY が設定されている場合はそちらを優先する（CI 環境用）
# 未設定の場合は gh コマンドで現在のリポジトリ情報を取得する
#
# Output: "owner/repo" 形式（例: enechange/emap-api）

set -euo pipefail
echo "${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"
