# Sub-Issue #17 実装レポート

## 実装概要

GitHub Actions を使った iddue PR レビュー・レビュー対応ワークフローを新規作成した。
`iddue/**` ブランチへの push をトリガーに自動レビューを実行し、レビュー投稿をトリガーに自動レビュー対応を実行する構成。

## 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `.github/workflows/iddue-review.yml` | 新規作成。`iddue/**` への push 後に CI 待機し `/iddue:pr:review` を実行 |
| `.github/workflows/iddue-address.yml` | 新規作成。`<!-- iddue:pr:review -->` マーカー付きレビュー投稿で `/iddue:pr:address-review-feedback` を実行 |

## 品質チェック結果

=== 品質チェック ===
環境名: iddue/17
パス: .worktree/iddue/17

品質チェックフックが未設定のため、スキップします

## コミット情報

- Branch: iddue/17
- Commit: 221ed6e358998298d47b906b903bf615af3f19bd
- Message: [Issue#17] GitHub Actions レビュー・対応ワークフローを追加する

## 引き継ぎ事項

- `iddue-review.yml` の prompt 引数は `${{ github.ref_name }}` (ブランチ名) を渡している。`iddue:pr:review` スキルの argument-hint は `{Issue 番号}` だが、ブランチ名 `iddue/{number}` からスキルが番号を抽出できるよう、スキル側での対応が必要な場合は親 Issue #14 の実装時に確認すること。
- `iddue-address.yml` は同様に `${{ github.event.pull_request.head.ref }}` (ブランチ名) を渡している。

## ステータス

completed
