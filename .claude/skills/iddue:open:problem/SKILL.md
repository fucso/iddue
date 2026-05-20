---
name: iddue:open:problem
description: |
  明確な問題の Issue を GitHub に起票する。
  リファクタリングの必要性・設計上の問題など「何が問題かは明確だが対応方法・対象ファイルは未定」な内容を GitHub Issue として記録する。
argument-hint: "[説明文（任意）]"
---

# `/iddue:open:problem` — 明確な問題起票

問題は明確だが対応方法が未確定な課題を GitHub Issue として記録する。
リファクタリング・設計改善・技術的負債の解消などが典型例。
`iddue:open` からの委譲でも、直接呼び出しでも動作する。

## 使い方

```
/iddue:open:problem
/iddue:open:problem ElecPlanService が肥大化していて責務が分散できていない
```

---

## 実行内容

### Phase 1: 情報収集（対話形式）

以下の情報を収集する。`iddue:open` から委譲された場合は引き継いだ説明文をベースに確認しながら進める。

| 項目 | 説明 | 必須 |
|------|------|------|
| タイトル | Issue タイトルの核となる1行の概要 | ✅ |
| 問題の内容 | 何が問題か（コードの状態・設計上の課題など） | ✅ |
| 問題が発生している箇所 | どのモジュール・機能・フローで起きているか | ✅ |
| 問題の影響 | 放置するとどうなるか（保守性・拡張性・パフォーマンスへの影響など） | ✅ |
| 解決の方向性 | アプローチの大まかなイメージ（「責務を分割したい」程度で可） | 任意 |
| 親 Issue 番号 | 親となる Issue の番号 | 任意 |

収集が完了したら内容をユーザーに確認してもらう。

### Phase 2: オーダーシート作成・Issue 起票

収集した情報から create オーダーシートを作成する。
各フィールドにはできるだけ詳細に情報を記載する。情報を省略・要約せず、収集したすべての情報を記録すること。

ファイル名: `.iddue/orders/{YYYYMMDD-HHMMSS}-create.yaml`

```yaml
type: create
parent_issue: {親 Issue 番号または null}
labels:
  - "iddue"
  - "level:problem"

objective:
  what: "{問題の概要・解決すべきこと}"
  why: |
    {問題の内容・発生箇所・影響の詳細}
  how: "{解決の方向性（任意）}"  # 未確定の場合は省略
  detail:
    - type: spec
      content: "{影響を受けるモジュール・機能・フロー}"
    - type: spec
      content: "{解決後の望ましい状態}"
    # detail は任意。省略しても構わない
```

作成したオーダーシートの内容をユーザーに確認する。
確認後、`iddue:create-issue` スキルで Issue を作成する。

```
/iddue:create-issue .iddue/orders/{ファイル名}
```

### Phase 3: 完了報告

```
✅ /iddue:open:problem 完了

- Issue: [#{NNN}] {タイトル}
  URL: {URL}

## 次のステップ
対応方針が固まったら: /iddue:open:concrete または /iddue:start {NNN}
```

---

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| Issue 作成失敗 | エラーメッセージを表示して終了 |
