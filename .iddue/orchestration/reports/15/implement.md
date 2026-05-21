# Sub-Issue #15 実装レポート

## 実装概要

`iddue:judging-ready-to-implementation` スキルの Step 4 に、判定結果を GitHub Issue にコメントとして投稿するステップを追加した。
実装可能・実装不可の両ケースで `gh issue comment` を呼び出す `post-comment.sh` スクリプトを新規作成し、SKILL.md に呼び出し手順を記載した。

## 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `.claude/skills/iddue:judging-ready-to-implementation/SKILL.md` | Step 4 に判定結果の Issue コメント投稿ステップを追加、スクリプト一覧に post-comment.sh を追記 |
| `.claude/skills/iddue:judging-ready-to-implementation/scripts/post-comment.sh` | 新規作成: gh issue comment のラッパースクリプト |

## 品質チェック結果

=== 品質チェック ===
環境名: iddue/15
パス: .worktree/iddue/15

品質チェックフックが未設定のため、スキップします

## コミット情報

- Branch: iddue/15
- Commit: a7c86b35a80cd2d1135457bd0e56b43460cf4dd7
- Message: [Issue#15] iddue:judging-ready-to-implementation に Issue コメント投稿ステップを追加する

## 引き継ぎ事項

- `post-comment.sh` は `gh issue comment <number> --body "<body>"` を直接呼び出す。コメント本文に改行を含む場合は呼び出し側がクォートを適切に処理する必要がある。
- SKILL.md の Step 4 における `{上記の出力内容}` は、実装可能・不可それぞれの出力テキスト全体を指す。
- 親 Issue #14 のブランチ `iddue/14` をベースとして作成しており、マージ時に他のサブ Issue との競合がないか確認すること。

## ステータス

completed
