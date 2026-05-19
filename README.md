# iddue

GitHub Issues を起点とした開発ワークフローを Claude Code 上で実行するためのスキルコレクションです。Issue の起票から実装・PR 作成・レビュー対応まで、一連の開発フローをスキルとして提供します。

## セットアップ

以下の CLI ツールが必要です。

- [gh CLI](https://cli.github.com/) — GitHub との通信に使用します。インストール後、`gh auth login` で認証してください
- [Claude Code CLI](https://claude.ai/code) — スキルの実行環境です。`.claude/` を利用したいリポジトリにコピーして使用します

## スキル

### Issue を起票する

対話形式で Issue を起票します。問題・アイデア・バグ・具体的な改修など、どのような内容でも受け付けます。

```
/idd:open
/idd:open 認証エラーが発生している
```

### 実装を開始する

Issue 番号を指定して実装を開始します。独立した git worktree 環境でコードを実装し、PR を作成するまでを自動で行います。

```
/idd:start {Issue番号}
/idd:start 42
```

### PR をレビューする

Issue 番号を指定して、紐づいた PR を複数の観点（要件充足・設計・コード品質など）でレビューし、PR にコメントを投稿します。

```
/idd:pr:review {Issue番号}
/idd:pr:review 42
```

### レビューフィードバックに対応する

Issue 番号を指定して、PR の未解決レビューコメントをタスクに整理し、修正を実装してプッシュします。

```
/idd:pr:address-review-feedback {Issue番号}
/idd:pr:address-review-feedback 42
```
