#!/bin/bash
# GitHub リポジトリのデフォルトブランチ名を取得する
#
# 環境変数 GITHUB_DEFAULT_BRANCH が設定されている場合はそちらを優先する
# 未設定の場合は gh コマンドで現在のリポジトリ情報を取得する
#
# Output: デフォルトブランチ名（例: develop, main, master）

set -euo pipefail
echo "${GITHUB_DEFAULT_BRANCH:-$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')}"
