---
name: idd:issue:revise
description: |
  起票済みの Issue の内容を修正・補完するスキル。
  実装中の発見・要件変更・レビュー指摘など、起票後に判明した情報を反映する。
  親 Issue を指定した場合はサブ Issue も含めて変更対象を検討する。
argument-hint: "{issue_number} [{brief_context}]"
---

# `/idd:issue:revise` — Issue 内容の修正・補完

起票済みの Issue に、実装中の発見・要件変更・レビュー指摘などを反映する。

## 使い方

```
/idd:issue:revise {issue_number}
/idd:issue:revise {issue_number} {brief_context}
```

| 引数 | 必須 | 説明 |
|------|------|------|
| `issue_number` | ✅ | 更新対象の Issue 番号。親 Issue を指定するとサブ Issue も検討対象になる |
| `brief_context` | 任意 | 変更の概要（省略時は Phase 2 で対話収集） |

---

## Phase 1: コンテキスト収集

### 1.1 指定 Issue の内容を取得する

```bash
bash .claude/skills/idd:fetch-issue/scripts/get-issue.sh {issue_number}
```

取得した内容から以下を把握する：

- タイトル・本文（実装方針・完了条件・各セクション）
- 現在のラベル（`ready to implementation` の有無）
- Issue の種別（親 Issue か単一 Issue か）

### 1.2 親 Issue の場合: サブ Issue 一覧を取得する

指定 Issue がサブ Issue を持つ場合（本文に `## サブ Issue` セクションがある、または以下のスクリプトで取得できる場合）、サブ Issue の一覧を取得する。

```bash
bash .claude/skills/idd:fetch-issue/scripts/get-sub-issues.sh {issue_number}
```

この段階ではサブ Issue のタイトル・番号・状態のみ把握すればよい。本文の詳細取得は Phase 3 で行う。

---

## Phase 2: 変更内容検討

### 2.1 変更の概要を把握する

`brief_context` が指定されている場合はそれをベースに質問を始める。
指定されていない場合は以下を質問する：

> 何をどう変更したいですか？変更の背景・理由もあわせて教えてください。

### 2.2 対話を通じて変更内容を具体化する

ユーザーの説明をもとに、必要に応じてコードベースのファイルを `Read` して確認しながら以下を明確にする：

| 確認項目 | 説明 |
|----------|------|
| **何が変わるか** | 実装方針・完了条件・設計・要件など、Issue のどのセクションに影響するか |
| **なぜ変わるか** | 発見・指摘・要件変更など変更の根拠 |
| **変更の確定度** | 確定 / 検討中 / 暫定のいずれか |

詳細が必要な場合は追加の質問を行う。曖昧なまま進めない。

### 2.3 変更内容の合意を得る

収集した変更内容を整理してユーザーに提示し、合意を得る。

```
変更内容の確認:
- 変更理由: {理由}
- 変更対象セクション: {実装方針 / 完了条件 / etc.}
- 変更内容: {具体的な変更点}

この内容で進めますか？
```

---

## Phase 3: 変更対象 Issue の特定（親 Issue 指定時のみ）

単一 Issue を指定した場合はこの Phase をスキップして Phase 4 へ進む。

### 3.1 各サブ Issue の内容を確認する

Phase 2 で確定した変更内容を踏まえて、影響を受ける可能性のあるサブ Issue の本文を取得する。

```bash
bash .claude/skills/idd:fetch-issue/scripts/get-issue.sh {sub_issue_number}
```

詳細が必要なサブ Issue のみ取得する（全件取得は不要）。

### 3.2 変更対象 Issue をリストアップする

各 Issue（親 + 各サブ）について、Phase 2 の変更内容が影響するかを判断する。

変更対象候補と判断した理由を整理する。詳細は [`references/issue-sections.md`](references/issue-sections.md) を参照。

### 3.3 ユーザーに計画を提示して合意を得る

```
変更対象 Issue の確認:

変更対象:
  - #{parent}: {タイトル} — {変更理由の一言}
  - #{sub1}: {タイトル} — {変更理由の一言}

変更対象外:
  - #{sub2}: {タイトル} — {変更不要と判断した理由}

この対象で進めますか？
```

ユーザーが対象を追加・除外した場合はリストを更新して再確認する。

---

## Phase 4: ドラフト作成・ユーザー合意・Issue 更新

各変更対象 Issue について以下を繰り返す。複数 Issue がある場合は1件ずつ順番に処理する。

### 4.1 更新後本文のドラフトを作成する

Phase 2 の変更内容を現在の Issue 本文に適用した更新後本文を生成する。

変更箇所のマッピング指針は [`references/issue-sections.md`](references/issue-sections.md) を参照。

- 変更に関係しないセクションは現在の内容を保持する
- 情報が薄くならないよう、収集したすべての情報を反映する

### 4.2 Issue コメントのドラフトを作成する

変更理由・変更前後の差分を記述したコメント文案を生成する。

```
## Issue 内容の更新

### 変更理由
{Phase 2 で確認した変更の背景・理由}

### 変更内容
{主な変更点を before/after 形式で記述}
```

### 4.3 ユーザーに提示して合意を得る

```
#{NNN} の更新ドラフト:

【本文 変更箇所】
- {セクション名}: {変更概要}

【コメント文案（抜粋）】
{コメントの冒頭部分}

このドラフトで Issue を更新しますか？（修正があれば指示してください）
```

修正がある場合はドラフトを更新して再提示する。

### 4.4 オーダーシート YAML を作成する

`.idd/orders/{YYYYMMDD-HHMMSS}-revise-{issue_number}.yaml` に保存する。

`labels.remove` には `ready to implementation` を常に含める（ラベルが付いていない場合も指定してよい。スクリプトが存在確認を行う）。

### 4.5 `idd:update-issue` を実行する

```
/idd:update-issue .idd/orders/{YYYYMMDD-HHMMSS}-revise-{issue_number}.yaml
```

---

## Phase 5: 完了報告

すべての更新が完了したら報告する。

```
✅ Issue 更新完了

更新した Issue:
  - #{NNN}: {タイトル} — {変更概要の一言}
  （複数ある場合は列挙）

`ready to implementation` ラベルを削除しました。
実装内容が確定したら /idd:judging-ready-to-implementation で再判定してください。
```
