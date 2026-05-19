---
name: github-fetcher
description: |
  GitHub から必要な情報を一括取得する機能を提供する。
  PR 情報取得（diff, status, branch, sha）、レビューコメント取得、ファイルコンテンツ取得、CI ステータス確認などに使用する。
---

# GitHub Fetcher

GitHub から情報を収集するための機能を提供する。

**重要**: このスキルは読み取り専用。変更操作は絶対に行わない。

## 提供機能

### 1. PR 情報の取得

**使用ツール:**
```
mcp__github__pull_request_read
```

**method パラメータ:**

| method | 説明 |
|--------|------|
| `get` | PR 基本情報（branch, sha, state, author など） |
| `get_diff` | PR の差分 |
| `get_files` | 変更ファイル一覧 |
| `get_status` | CI ステータス（success/failure/pending） |
| `get_review_comments` | レビューコメント |
| `get_reviews` | レビュー一覧 |
| `get_comments` | PR コメント |

**基本パラメータ:**

| パラメータ | 説明 | 例 |
|------------|------|-----|
| `owner` | リポジトリオーナー | `enechange` |
| `repo` | リポジトリ名 | `emap-api` |
| `pullNumber` | PR 番号 | `1827` |

**実行例:**
```
mcp__github__pull_request_read を以下のパラメータで呼び出す：
- method: get
- owner: enechange
- repo: emap-api
- pullNumber: 1827
```

### 2. レビューコメントのフィルタリング

特定の review_id のコメントのみを取得する場合：

1. `mcp__github__pull_request_read` (method: get_review_comments) で全コメントを取得
2. 各コメントの `pull_request_review_id` フィールドを確認
3. 指定された review_id と一致するコメントのみを抽出

### 3. ファイルコンテンツの取得

**使用ツール:**
```
mcp__github__get_file_contents
```

**パラメータ:**

| パラメータ | 説明 | 例 |
|------------|------|-----|
| `owner` | リポジトリオーナー | `enechange` |
| `repo` | リポジトリ名 | `emap-api` |
| `path` | ファイルパス | `.agents/developments/in-progress.yaml` |
| `ref` | ブランチ/コミット参照 | `refs/heads/feature/xxx` |

### 4. PR 検索

**使用ツール:**
```
mcp__github__list_pull_requests
mcp__github__search_pull_requests
```

## URL 解析

GitHub URL から情報を抽出する際のパターン：

**PR URL:**
```
https://github.com/{owner}/{repo}/pull/{pullNumber}
```

**レビュー URL:**
```
https://github.com/{owner}/{repo}/pull/{pullNumber}#pullrequestreview-{reviewId}
```

例: `https://github.com/enechange/emap-api/pull/1785#pullrequestreview-3517327223`
→ owner: `enechange`, repo: `emap-api`, pullNumber: `1785`, reviewId: `3517327223`

## 注意事項

- 変更操作は絶対に行わない（読み取りのみ）
- 呼び出し元のプロンプトで指定された出力形式に従う
- 不要な情報は省略してコンパクトに返す

## 関連スキル

| スキル | 説明 |
|--------|------|
| `.claude/skills/github-pr-create/SKILL.md` | PR 作成 |
