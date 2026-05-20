# config.yaml — オーケストレーション依存グラフ

`iddue:setup-orchestration` が生成する read-only ファイル。依存グラフを定義する。

## ファイルパス

```
.iddue/orchestration/config.yaml
```

## スキーマ

```yaml
parent_issue: 123                    # 親 Issue 番号（整数）
main_issue_branch: "iddue/123"         # メイン Issue ブランチ名
created_at: "2026-04-30T12:00:00Z"   # ISO 8601

tasks:
  - issue: 124                       # サブ Issue 番号（整数）
    title: "API エンドポイント実装"    # Issue タイトル
    dependencies: []                  # 依存サブ Issue 番号のリスト
  - issue: 125
    title: "フロントエンド実装"
    dependencies:
      - 124                          # Issue 124 が完了してから実行
  - issue: 126
    title: "テスト追加"
    dependencies:
      - 124
      - 125
```

## 設計方針

- `iddue:start:orchestrate` は config.yaml を **読み取り専用** で扱う
- 実行状態は `status.yaml` が担当する
- `dependencies` が空のタスクはすぐにディスパッチ可能（ブロックなし）
- 依存は完了（completed）または スキップ（skipped）で満たされる

## 生成タイミング

`iddue:setup-orchestration` の Phase 2 でエージェントが直接書き出し、
メイン Issue ブランチ（`iddue/{parent}`）にコミットされる。
