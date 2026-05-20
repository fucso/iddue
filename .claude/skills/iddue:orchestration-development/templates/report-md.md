# implement.md — ワーカー完了シグナル

`iddue:start:worker` がサブ Issue の実装完了時に書き出すファイル。
オーケストレーターが `git log` で検知し、完了として処理する。

## ファイルパス

```
.iddue/orchestration/reports/{sub-issue-number}/implement.md
```

## 役割

- **完了シグナル**: このファイルがサブ Issue ブランチ（`iddue/{sub}`）にコミットされた時点で
  `wait-for-completion.sh` が `COMPLETED:{sub}` を出力する
- **引き継ぎ情報**: マージ後にオーケストレーターが参照できる実装サマリー

## フォーマット

```markdown
# Sub-Issue #{sub} 実装レポート

## 実装概要

{実装した内容の概要}

## 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| {path} | {説明} |

## 品質チェック結果

{quality-check.sh の stdout をそのまま転記する}

## コミット情報

- Branch: iddue/{sub}
- Commit: {sha}
- Message: {commit_message}

## 引き継ぎ事項

{後続サブ Issue や親 Issue のマージ時に注意すべき点}

## ステータス

completed
```

## コミットポリシー

`iddue:start:worker` は実装完了後に `worktree-development/scripts/commit.sh` を実行し、
`implement.md` をサブ Issue ブランチにコミット・プッシュする。

**このコミットがオーケストレーターの唯一の完了シグナルである。**
