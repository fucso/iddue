---
name: iddue:judging-ready-to-implementation
description: |
  IDDUE Issue がエージェントによる実装に十分な具体性を持つかを判定する。
  実装可否と理由を返す。
argument-hint: "{Issue 番号} [refresh:true]"
---

# `iddue:judging-ready-to-implementation` — 実装可能性の判定

> **⚠️ スコープ制約: 引数で指定した Issue 番号 1件のみを判定する。**
> 他の Issue YAML ファイルの読み込み・評価は禁止。`.iddue/issue/` 配下の他ファイル、config.yaml、status.yaml にアクセスしてはならない。

単一の GitHub Issue がエージェントによる自律実装に適した具体性・粒度を持つかを判定する。

## 概要

エージェントが自律的に実装できるのは、実装内容が十分に具体化された Issue のみ。
本スキルはその判定基準と手順を定義する。

判定基準は `iddue/references/workflow.md` の「実装可能な Issue の目安」を具体化・ケース化したもの。

## スクリプト

- [`scripts/check-label.sh`](scripts/check-label.sh) — `ready to implementation` ラベルの有無を確認（exit 0: あり / exit 1: なし）
- [`scripts/add-label.sh`](scripts/add-label.sh) — `ready to implementation` ラベルを付与（存在しない場合は自動作成）

## 利用方法

```
/iddue:judging-ready-to-implementation {Issue 番号}
例: /iddue:judging-ready-to-implementation 101

# Issue 更新後に最新の内容で判定する場合
/iddue:judging-ready-to-implementation 101 refresh:true
```

---

## 判定手順

### Step 1: ラベルチェック（スキップ判定）

Issue に `ready to implementation` ラベルが付与済みかを確認する。

```bash
bash .claude/skills/iddue:judging-ready-to-implementation/scripts/check-label.sh {Issue 番号}
```

- exit 0（ラベルあり）の場合 → **内容チェックをスキップし、以下の出力を行って終了**

  ```
  ✅ 実装可能と判定しました（`ready to implementation` ラベル確認済み）

  実装を開始します。
  ```

- exit 1（ラベルなし）の場合 → Step 2 へ進む

### Step 2: Issue コンテキストの確認

`iddue:fetch-issue` スキルを実行して Issue コンテキストを取得する。

```
/iddue:fetch-issue {Issue 番号}
```

`refresh:true` が指定された場合は `force:true` を付けて実行する：

```
/iddue:fetch-issue {Issue 番号} force:true
```

返された YAML 内容を参照する。

**重要: 評価対象は引数で渡された Issue 番号 1件のみ。他の Issue YAML（親・サブ・兄弟 Issue）を取得・参照してはならない。**

### Step 3: 各基準を評価する

[criteria.md](./references/criteria.md) に記載の判定基準について、**指定された Issue 1件のみ**を評価する。

### Step 4: 判定結果を出力する

#### 実装可能な場合

`ready to implementation` ラベルを Issue に付与する。ラベルが存在しない場合は事前に作成する。

```bash
bash .claude/skills/iddue:judging-ready-to-implementation/scripts/add-label.sh {Issue 番号}
```

出力:

```
✅ 実装可能と判定しました

## 判定結果

| 基準 | 結果 |
|------|------|
| 変更対象ファイルの特定 | ✅ {ファイル名などの根拠} |
| 実装内容の明確さ | ✅ {実装内容の概要} |
| 完了条件の定義 | ✅ {完了条件の内容} |
| 実装範囲の適切さ | ✅ 変更ファイル概算: {N}ファイル |

実装を開始します。
```

#### 実装不可の場合

```
❌ 実装不可と判定しました

## 判定結果

| 基準 | 結果 |
|------|------|
| 変更対象ファイルの特定 | {✅/❌} {理由} |
| 実装内容の明確さ | {✅/❌} {理由} |
| 完了条件の定義 | {✅/❌} {理由} |
| 実装範囲の適切さ | {✅/❌} {理由} |

## 不足している内容

{満たせていない基準について、何が不足しているかを具体的に説明}

## 推奨アクション

{不足を解消するために何をすべきか具体的に提案}
```
