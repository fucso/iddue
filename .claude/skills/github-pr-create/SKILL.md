---
name: github-pr-create
description: |
  GitHub Pull Request を作成する機能を提供する。
  MCP GitHub ツール（mcp__github__create_pull_request）を使用して PR を作成する。
  PR 作成が必要な場合に使用する。
---

# GitHub PR Create

GitHub に Pull Request を作成するための機能を提供する。

**重要**: このスキルは PR 作成機能のみを提供する。プッシュは別途（`background-development` SKILL 等）で完了していることが前提。

## 提供機能

### Pull Request の作成

MCP GitHub ツールを使用して PR を作成する。

**使用ツール:**
```
mcp__github__create_pull_request
```

**必須パラメータ:**

| パラメータ | 説明 | 例 |
|------------|------|-----|
| `owner` | リポジトリオーナー | `enechange` |
| `repo` | リポジトリ名 | `emap-api` |
| `title` | PR タイトル | `Add user authentication` |
| `head` | マージ元ブランチ | `feature/auth` |
| `base` | マージ先ブランチ | `develop` |

**オプションパラメータ:**

| パラメータ | 説明 | デフォルト |
|------------|------|------------|
| `body` | PR 説明文 | なし |
| `draft` | ドラフト PR として作成 | `false` |
| `maintainer_can_modify` | メンテナーによる編集を許可 | `true` |

**実行例:**
```
mcp__github__create_pull_request を以下のパラメータで呼び出す：
- owner: enechange
- repo: emap-api
- title: "Add user authentication"
- head: feature/auth
- base: develop
- body: "## Summary\n\nAdd user authentication feature..."
- draft: false
```

**戻り値:**
```yaml
number: number      # PR 番号
url: string         # PR の API URL
html_url: string    # PR の Web URL
state: string       # PR 状態（open）
```

## 前提条件

PR を作成する前に以下が完了していること：

1. **ブランチが存在する**: `head` で指定するブランチがリモートに存在
2. **コミットがプッシュ済み**: 変更がリモートブランチにプッシュ済み
3. **ベースブランチが存在**: `base` で指定するブランチがリモートに存在

## エラーハンドリング

| エラー | 原因 | 対応 |
|--------|------|------|
| `Validation Failed` | ブランチが存在しない、または既に PR が存在 | ブランチ名を確認、既存 PR を検索 |
| `Reference does not exist` | head または base ブランチが見つからない | プッシュが完了しているか確認 |
| `A pull request already exists` | 同じ head/base で PR が既に存在 | 既存 PR の URL を返す |

## 関連スキル

| スキル | 説明 |
|--------|------|
| `background-development` | バックグラウンド実装（プッシュ機能を含む） |
