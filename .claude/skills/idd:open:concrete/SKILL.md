---
name: idd:open:concrete
description: |
  具体的な改修ポイントの Issue を GitHub に起票する。
  変更対象・実装内容・完了条件が明確な改修を GitHub Issue として記録する。
argument-hint: "[説明文（任意）]"
---

# `/idd:open:concrete` — 具体的な改修ポイント起票

実装内容が明確な改修を GitHub Issue として記録する。

## 使い方

```
/idd:open:concrete
/idd:open:concrete UserForm の email バリデーションを修正したい
```

---

## 共通フェーズ

### Phase 1: 情報収集（対話形式）

以下の情報を収集する。`idd:open` から委譲された場合は引き継いだ説明文をベースに確認しながら進める。

| 項目 | 説明 | 必須 |
|------|------|------|
| タイトル | Issue タイトルの核となる1行の概要 | ✅ |
| 変更対象ファイル・箇所 | 変更するファイルパスとgit対象のクラス・メソッド等 | ✅ |
| 変更内容と実装のポイント | 何をどう変えるか・設計意図 | ✅ |
| 変更の背景・理由 | なぜこの改修が必要か | ✅ |
| 完了条件 | 実装完了の判断基準 | ✅ |
| 依存 Issue・前提条件 | 先に完了している必要がある Issue があれば | 任意 |
| 親 Issue 番号 | 親となる Issue の番号 | 任意 |

収集が完了したら内容をユーザーに確認してもらう。

### Phase 2: 分割判断

起票する内容を複数の Sub Issue に分割すべきか判断する。

以下の場合は分割を検討する：
- 独立して実装・レビューできる複数の作業が含まれている
- 並行実装が可能な作業がある

判断結果：
- **分割する** → [Sub Issue パス](#sub-issue-パス)へ進む
- **分割しない** → [単一 Issue パス](#単一-issue-パス)へ進む

---

## 単一 Issue パス

### Step 1: 全体計画の合意

収集した変更対象ファイルと変更内容を表形式で提示し、ユーザーの合意を得る。

```
以下の内容で Issue を起票します。

| ファイル / 対象 | 変更内容 |
|----------------|--------|
| {ファイルパス}  | {変更内容} |
| ...            | ...    |

この内容で進めてよいですか？
```

ユーザーの確認が取れてから Step 2 へ進む。

### Step 2: オーダーシート作成・Issue 起票

オーダーシートを作成する（テンプレート: [`templates/create-order.yaml`](templates/create-order.yaml)）。

ファイル名: `.idd/orders/{YYYYMMDD-HHMMSS}-create.yaml`

各フィールドにはできるだけ詳細に情報を記載する。情報を省略・要約せず、収集したすべての情報を記録すること。

作成したオーダーシートの内容をユーザーに確認する。
確認後、`idd:create-issue` スキルで Issue を作成する。

```
/idd:create-issue .idd/orders/{ファイル名}
```

### Step 3: 実装可能性の判定・補完ループ

[`references/readiness-loop.md`](references/readiness-loop.md) の手順に従い、作成した Issue に対して判定・補完ループを実行する。

判定 OK → 完了報告へ進む。
判定 NG のまま中断 → 完了報告へ進む（NG のまま完了）。

### 完了報告（単一 Issue）

判定 OK で完了した場合：

```
✅ /idd:open:concrete 完了

- Issue: [#{NNN}] {タイトル}
  URL: {URL}

## 次のステップ
実装を開始する: /idd:start {NNN}
```

判定 NG のまま中断した場合：

```
⚠️ /idd:open:concrete 中断

- Issue: [#{NNN}] {タイトル}
  URL: {URL}

実装可能性の判定が NG のまま終了しました。
Issue に不足内容を追記してから /idd:start {NNN} で実装を開始してください。
```

---

## Sub Issue パス

### Step 1: Sub Issue 計画の確認

分割案を整理し、ユーザーに確認する。各 Sub Issue について以下を収集する：

| 項目 | 説明 |
|------|------|
| タイトル | Sub Issue の1行概要 |
| 実装内容 | 何をどう実装するか |
| 依存 Sub Issue | 先に完了が必要な Sub Issue（番号または仮ID） |

依存グラフをユーザーに提示して確認を得る：

```
以下のサブ Issue 分割案を確認してください。

| # | タイトル | 依存 |
|---|---------|------|
| A | {title} | なし |
| B | {title} | A |
| C | {title} | A, B |

この内容で進めてよいですか？
```

### Step 2: 親 Issue 起票

親 Issue のオーダーシートを作成する（テンプレート: [`templates/create-order.yaml`](templates/create-order.yaml)）。

ファイル名: `.idd/orders/{YYYYMMDD-HHMMSS}-create.yaml`

各フィールドにはできるだけ詳細に情報を記載する。情報を省略・要約せず、収集したすべての情報を記録すること。

作成したオーダーシートの内容をユーザーに確認する。
確認後、`idd:create-issue` スキルで親 Issue を作成する。

```
/idd:create-issue .idd/orders/{ファイル名}
```

### Step 3: Sub Issue 起票

各 Sub Issue について create オーダーシートを作成し `idd:create-issue` で登録する（`parent_issue` に親 Issue 番号を指定）。

ファイル名: `.idd/orders/{YYYYMMDD-HHMMSS}-create-sub{n}.yaml`

各 Sub Issue の実装内容・完了条件を詳細に記載すること。

```
/idd:create-issue .idd/orders/{ファイル名}
```

全 Sub Issue の登録が完了したら Step 4 へ進む。

### Step 4: 実装可能性の判定・補完ループ

各 Sub Issue に対して [`references/readiness-loop.md`](references/readiness-loop.md) の手順を実行する。

Sub Issue ごとに順番に判定・補完ループを行う。
全 Sub Issue が OK（または中断）になったら Step 5 へ進む。

### Step 5: オーケストレーション準備

`idd:setup-orchestration` スキルでメイン Issue ブランチ・config.yaml・メイン Issue PR の作成と
各 Sub Issue YAML への `parent.linked_pr.branch` 設定を行う。

```
/idd:setup-orchestration {親 Issue 番号}
```

### 完了報告（Sub Issue あり）

```
✅ /idd:open:concrete 完了

- 親 Issue: [#{NNN}] {タイトル}
  URL: {URL}
- メイン Issue PR: {PR URL}（idd:setup-orchestration 完了時に表示）

## 次のステップ
オーケストレーター実装を開始する: /idd:start {NNN}
```

---

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| Issue 作成失敗 | エラーメッセージを表示して終了 |
| Sub Issue 登録失敗 | 警告を表示してフローを継続（手動での登録方法を案内） |
