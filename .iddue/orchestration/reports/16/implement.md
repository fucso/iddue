# Sub-Issue #16 実装レポート

## 実装概要

GitHub Actions ワークフロー 2 本（iddue-judge.yml・iddue-implement.yml）を新規作成した。
`iddue` ラベルを付与するだけで実装可否判定・実装・PR 作成が自動実行される仕組みを構築した。

- `iddue-judge.yml`: Issue に `iddue` ラベルが付与された際に `iddue:judging-ready-to-implementation` スキルを自動実行する
- `iddue-implement.yml`: Issue に `ready to implementation` ラベルが付与された際に `iddue:start` スキルを自動実行する

判定ワークフローは PAT（`IDDUE_TOKEN`）を使用するため、ラベル追加時に実装ワークフローが連鎖トリガーされる。
実装ワークフローは同一 Issue の同時実行を `concurrency` で防止している。

また、CI 環境で Claude Code が操作権限プロンプトなしに動作できるよう `.claude/settings.json` を追加した。

## 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| .github/workflows/iddue-judge.yml | 新規作成: iddue ラベル → 判定ワークフロー |
| .github/workflows/iddue-implement.yml | 新規作成: ready to implementation ラベル → 実装ワークフロー |
| .claude/settings.json | 新規作成: CI 用 Claude Code 権限設定 |
| .gitignore | 修正: tmp/ を追加 |

## 品質チェック結果

```
=== 品質チェック ===
環境名: iddue/16
パス: .worktree/iddue/16

品質チェックフックが未設定のため、スキップします
```

## コミット情報

- Branch: iddue/16
- Commit: 4c1b905b1d8fa42dc3698f48d39ddcee351e8320
- Message: [Issue#16] GitHub Actions 判定・実装ワークフローを追加する（iddue-judge.yml + iddue-implement.yml）

## 引き継ぎ事項

- `IDDUE_TOKEN` シークレット（PAT）のリポジトリへの登録が必要
- `ANTHROPIC_API_KEY` シークレットのリポジトリへの登録が必要
- Issue #17（iddue-review.yml + iddue-address.yml）は本ブランチをベースにしないが、同じ secrets 設定が必要
- iddue:judging-ready-to-implementation スキルへのコメント投稿機能（Issue #15）が実装されると判定結果が Issue に可視化される

## ステータス

completed
