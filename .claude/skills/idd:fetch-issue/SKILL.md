---
name: idd:fetch-issue
description: |
  IDD ワークフローで必要な Issue コンテキストを収集し、
  .idd/issue/{number}.yaml に書き出してその YAML 内容を返す。
argument-hint: "{Issue 番号} [force:true|false]"
---

# `idd:fetch-issue` — Issue コンテキスト収集

GitHub Issue を読み取り、実装開始・実装可否判定に必要なコンテキストを `.idd/issue/{number}.yaml` に書き出して YAML 内容を返す。
対象 Issue・依存 Issue・コメントを読み取り、実装開始・実装可否判定に必要な情報をYAMLとして呼び出し元に提供する。

## 使い方

```
/idd:fetch-issue {Issue 番号}
例: /idd:fetch-issue 103

# キャッシュを無視して強制再取得する場合
/idd:fetch-issue 103 force:true
```

---

## 実行内容

### Step 1: キャッシュチェック

`.idd/issue/{Issue 番号}.yaml` が存在するかチェックする。

- `force:true` が指定された場合：このステップをスキップして Step 2 へ進む
- `force:true` が指定されていない場合：
  - ファイルが存在する → **`Read` ツールでファイル内容を読み込み、その YAML 内容をレスポンスとして返す**
  - ファイルが存在しない → Step 2 へ進む

---

### Step 2: 生データの一括取得（スクリプト）

以下のスクリプトを実行して、対象 Issue と全依存 Issue の生データを取得する。

```bash
bash .claude/skills/idd:fetch-issue/scripts/fetch.sh {Issue 番号}
```

このスクリプトが行うこと（AI による分析不要の定型処理）:
- 対象 Issue の取得（タイトル・本文・状態・コメント・紐づく PR）
- 親 Issue の取得（GraphQL Sub-issues API）
- Sub Issue 一覧の取得（GraphQL Sub-issues API）
- 本文中の `Depends on: #NNN` を抽出し各 Issue を取得
- 全 Issue に紐づく PR の番号・ブランチ・URL・状態を取得（GraphQL）

出力 JSON の構造:
```json
{
  "issue":      { "number", "title", "body", "state", "url", "comments", "linked_pr" },
  "parent":     { "number", "title", "state", "url", "linked_pr" } | null,
  "sub_issues": [ { "number", "title", "state", "url", "linked_pr" }, ... ],
  "depends_on": [ { "number", "title", "state", "url", "linked_pr" }, ... ]
}
```

`linked_pr`: `{ "number", "branch", "url", "state" }` または `null`（紐づく PR がない場合）

**エラー:**
- Issue が存在しない場合はエラーメッセージを表示して終了

---

### Step 3: 開発内容のまとめ（AI + スクリプト）

`issue.title` と `issue.body` から実装内容・システムへの影響・完了条件を推論してまとめる。

`issue.linked_pr` が存在する場合は以下のスクリプトで docs の変更差分を取得し、
内容を読み取って開発内容の理解に活用する。

```bash
bash .claude/skills/idd:fetch-issue/scripts/get-pr-docs-diff.sh {linked_pr.number}
```

出力がない場合（docs への変更なし）はスキップする。

---

### Step 4: 意思決定の議論のまとめ（AI）

`issue.comments` から、実装方針の選択理由・却下された案・設計上の議論を要約する。
コメントがない場合は「コメントなし」とする。

---

### Step 5: YAML ファイルへの書き出し（AI）

`idd:issue-yaml` のスキーマ・記述原則に従い、Step 2〜4 の結果を `.idd/issue/{Issue 番号}.yaml` に書き出す。

GitHub から取得した最新データをもとに書き出すため、以下の点に注意する：
- コメント・ディスカッションがある場合は `decision_rationale` に要約する
- コメントがない場合は `"コメントなし"` と記載する

**書き出し手順:**
1. `.idd/issue/` ディレクトリが存在しない場合は作成する（`mkdir -p .idd/issue`）
2. YAML ファイルを書き出す
3. `Read` ツールで書き出したファイルを読み込む
4. **読み込んだ YAML 内容をレスポンスとして返す**

---

## スクリプト一覧

| スクリプト | 役割 |
|-----------|------|
| `scripts/fetch.sh` | 全データ一括取得（通常はこれだけ呼べばよい） |
| `scripts/get-issue.sh` | 単一 Issue の詳細取得（body・comments 含む） |
| `scripts/get-parent-issue.sh` | 親 Issue 取得・linked_pr 付き（GraphQL） |
| `scripts/get-sub-issues.sh` | Sub Issue 一覧取得・linked_pr 付き（GraphQL） |
| `scripts/get-linked-pr.sh` | 単一 Issue に紐づく PR の番号・ブランチ取得（GraphQL） |
| `scripts/get-pr-docs-diff.sh` | PR の docs/ 配下の変更ファイル一覧と diff を取得 |

---

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| Issue が存在しない | エラーメッセージを表示して終了 |
