---
name: idd:open:idea
description: |
  将来の機能追加・改修アイデアの Issue を GitHub に起票する。
  問題・解決策ともに漠然としているアイデアを GitHub Issue として記録する。
  問題は特定できているが対応方法が未定の場合は idd:open:problem を使用する。
argument-hint: "[説明文（任意）]"
---

# `/idd:open:idea` — アイデアベース起票

方向性はあるが詳細が未定の改善アイデアを GitHub Issue として記録する。
`idd:open` からの委譲でも、直接呼び出しでも動作する。

## 使い方

```
/idd:open:idea
/idd:open:idea シミュレーション結果のキャッシュ戦略を見直したい
```

---

## 実行内容

### Phase 1: 情報収集（対話形式）

以下の情報を収集する。`idd:open` から委譲された場合は引き継いだ説明文をベースに確認しながら進める。

| 項目 | 説明 | 必須 |
|------|------|------|
| タイトル | Issue タイトルの核となる1行の概要 | ✅ |
| 解決したい課題・動機 | 何が問題か、なぜ改善したいか | ✅ |
| 想定するアプローチ | 大まかな方向性（ラフで可） | ✅ |
| 期待される効果 | 改善後に得られるもの | ✅ |
| 未決定事項・検討が必要な点 | 今後議論・調査が必要な点 | 任意 |
| 親 Issue 番号 | 親となる Issue の番号 | 任意 |

収集が完了したら内容をユーザーに確認してもらう。

### Phase 2: オーダーシート作成・Issue 起票

収集した情報から create オーダーシートを作成する。
各フィールドにはできるだけ詳細に情報を記載する。情報を省略・要約せず、収集したすべての情報を記録すること。

ファイル名: `.idd/orders/{YYYYMMDD-HHMMSS}-create.yaml`

```yaml
type: create
parent_issue: {親 Issue 番号または null}
labels:
  - "idd"
  - "level:idea"

objective:
  what: "{実現したいこと・改善の概要}"
  why: "{課題・動機・期待される効果}"
  how: "{大まかなアプローチ（ラフで可）}"
  detail:
    - type: spec
      content: "{実現したい内容・要件1}"
    - type: spec
      content: "{実現したい内容・要件2}"
    # 未決定事項がある場合も spec として記載可
```

作成したオーダーシートの内容をユーザーに確認する。
確認後、`idd:create-issue` スキルで Issue を作成する。

```
/idd:create-issue .idd/orders/{ファイル名}
```

### Phase 3: 完了報告

```
✅ /idd:open:idea 完了

- Issue: [#{NNN}] {タイトル}
  URL: {URL}

## 次のステップ
具体化が進んだら: /idd:open:problem または /idd:open:concrete
```

---

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| Issue 作成失敗 | エラーメッセージを表示して終了 |
