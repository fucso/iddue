# iddue

GitHub Issues を起点とした開発ワークフローを Claude Code 上で実行するためのスキルコレクションです。Issue の起票から実装・PR 作成・レビュー対応まで、一連の開発フローをスキルとして提供します。

## セットアップ

以下の CLI ツールが必要です。

- [gh CLI](https://cli.github.com/) — GitHub との通信に使用します。インストール後、`gh auth login` で認証してください
- [Claude Code CLI](https://claude.ai/code) — スキルの実行環境です。`.claude/` を利用したいリポジトリにコピーして使用します

## GitHub Actions による自動化

`.github/workflows/` に含まれるワークフローを使うと、Issue へのラベル付与だけで実装から PR レビュー対応までを自動実行できます。

### 必要な Secrets

リポジトリの **Settings → Secrets and variables → Actions** に以下を登録してください。

| Secret 名 | 内容 |
|-----------|------|
| `ANTHROPIC_API_KEY` | Anthropic API キー |
| `IDDUE_TOKEN` | GitHub PAT（`repo` / `issues` / `pull_requests` スコープ付き）|

`IDDUE_TOKEN` に通常の `GITHUB_TOKEN` ではなく PAT を使う理由は、判定ワークフローが付与したラベルで実装ワークフローを連鎖トリガーするためです（`GITHUB_TOKEN` によるイベントは別ワークフローをトリガーしません）。

### 自動化フロー

```
Issue に iddue ラベル付与
  → 実装可否判定（iddue-judge.yml）
    → 判定 OK → ready to implementation ラベルを付与
      → 実装・PR 作成（iddue-implement.yml）
        → PR レビュー（iddue-review.yml / push ごとに自動実行）
          → フィードバック対応（iddue-address.yml / レビュー投稿を検知）
```

### ラベルの作成

GitHub リポジトリに以下のラベルを作成してください。

- `iddue` — 自動化の起点となるラベル
- `ready to implementation` — 実装ワークフローのトリガー
- `iddue: review ok` — このラベルが付いた PR はレビュー・対応ワークフローをスキップ

## スキル

### Issue を起票する

対話形式で Issue を起票します。問題・アイデア・バグ・具体的な改修など、どのような内容でも受け付けます。

```
/iddue:open
/iddue:open 認証エラーが発生している
```

### 実装を開始する

Issue 番号を指定して実装を開始します。独立した git worktree 環境でコードを実装し、PR を作成するまでを自動で行います。

```
/iddue:start {Issue番号}
/iddue:start 42
```

### PR をレビューする

Issue 番号を指定して、紐づいた PR を複数の観点（要件充足・設計・コード品質など）でレビューし、PR にコメントを投稿します。

```
/iddue:pr:review {Issue番号}
/iddue:pr:review 42
```

### レビューフィードバックに対応する

Issue 番号を指定して、PR の未解決レビューコメントをタスクに整理し、修正を実装してプッシュします。

```
/iddue:pr:address-review-feedback {Issue番号}
/iddue:pr:address-review-feedback 42
```
