# iddue

## 概要

- IDD (Issue-Driven Development) ワークフローを Claude Code で実行するためのスキルコレクション
- GitHub Issues による開発管理と、Claude Code スキル（`/idd:*`）による自律実装を組み合わせたワークフローを提供する
- 複数のプロジェクトリポジトリにコピーして共通利用できる設計

## セットアップ

- **gh CLI**: GitHub との通信に使用。[インストール](https://cli.github.com/)後、`gh auth login` で認証する
- **Claude Code CLI**: スキルの実行環境。[インストール](https://claude.ai/code)後、`.claude/` を配置したリポジトリで利用する

## ユーザーが直接呼び出すスキル

| スキル | 用途 |
|--------|------|
| `/idd:open` | Issue を対話形式で起票する（concrete / bug / problem / idea の 4 種別） |
| `/idd:start {Issue番号}` | Issue を指定して worktree で実装を開始し PR を作成する |
| `/idd:pr:review` | Issue に紐づいた PR を複数観点でレビューし、PR にコメントする |
| `/idd:pr:address-review-feedback` | PR の未解決レビューコメントを実装して解消する |
