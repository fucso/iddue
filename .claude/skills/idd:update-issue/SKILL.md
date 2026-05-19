---
name: idd:update-issue
description: |
  オーダーシート YAML を受け取り GitHub Issue を更新する。
  現在の Issue 内容に変更を適用して本文を再構築し、変更経緯・概要をコメントとして投稿する。
  idd:open:* スキルから呼び出される。直接呼び出しも可能。
argument-hint: "{order_sheet_path}"
---

# `idd:update-issue` — Issue 更新

オーダーシート（`.idd/orders/*.yaml`）を受け取り、GitHub Issue の本文を更新する。
現在の Issue 内容に objectives の変更を適用して更新後本文を組み立て、変更経緯・概要をコメントとして投稿する。
ユーザーとの対話は行わない完全スタンドアローンワークフロー。

## スクリプト

- [`scripts/update.sh`](scripts/update.sh) — Issue 本文の更新・`ready to implementation` ラベル削除
- [`scripts/comment.sh`](scripts/comment.sh) — Issue コメントの追加
- [`scripts/label.sh`](scripts/label.sh) — ラベルの追加・削除

## テンプレート

- [`templates/order.yaml`](templates/order.yaml) — オーダーシートのスキーマ定義

## 使い方

```
/idd:update-issue {order_sheet_path}
```

| 引数 | 必須 | 説明 |
|------|------|------|
| `order_sheet_path` | ✅ | オーダーシート YAML のパス（`.idd/orders/*.yaml`） |

---

## 実行内容

### Step 1: オーダーシートを読み込む

指定されたパスの YAML ファイルを読み込む。
`type: update` であることを確認する。

### Step 2: 現在の Issue 内容を取得する

```bash
REPO=$(bash .claude/skills/github-pr/scripts/get-repo.sh)
gh issue view {issue_number} \
  --repo "${REPO}" \
  --json title,body,labels
```

### Step 3: 更新後の本文を組み立てる

オーダーシートのすべての内容を把握した上で、現在の Issue 本文に `objectives` の変更内容を適用して更新後本文を組み立てる。
下表はフィールドと本文セクションの対応の目安であり、必ずしも1対1のマッピングではない。
情報を全体的に把握し、Issue テンプレートに合うよう適切に組み直すこと。

| オーダーシートフィールド | 参考となる本文セクション（目安） |
|------------------------|-------------------------------|
| `objectives[].what` + `objectives[].why` | `## 概要・目的` |
| `objectives[].how` | `## 実装方針` |
| `objectives[].detail[type=design]` | `## 実装方針` 内にファイル別で記載 |
| `objectives[].detail[type=spec]` | `## 詳細` |
| `objectives[].completion_criteria` | `## 完了条件` |
| `parent_issue` | `## 親 Issue` |

変更に関係しないセクションは現在の内容を保持する。
オーダーシートに記載されたすべての情報を本文に反映する。要約・整理してテンプレートに当てはめるが、内容が薄くならないようにする。

### Step 4: Issue コメントを作成・投稿する

`objectives[].why` と変更内容をもとにコメントを作成し、`comment.sh` で投稿する。
変更経緯が不明な場合でも必ずコメントを投稿する。コメントには以下を含める：

- **変更経緯・理由** — `objectives[].why` の内容を中心に推測し記述する
- **変更概要** — 変更前後の主要な差分を before/after 形式で記述する

```bash
bash .claude/skills/idd:update-issue/scripts/comment.sh "{issue_number}" << 'EOF'
{作成したコメント}
EOF
```

### Step 5: スクリプトを実行する（本文更新）

```bash
bash .claude/skills/idd:update-issue/scripts/update.sh "{issue_number}" << 'EOF'
{更新後の本文}
EOF
```

スクリプトの出力から更新された Issue の URL を取得する。

### Step 6: ラベルを操作する

`labels.add` / `labels.remove` が指定されている場合に `label.sh` を実行する。

```bash
bash .claude/skills/idd:update-issue/scripts/label.sh \
  "{issue_number}" \
  "{labels.add をカンマ区切りで結合（なければ空文字列）}" \
  "{labels.remove をカンマ区切りで結合（なければ空文字列）}"
```

`labels` キー自体が存在しない場合はスキップする。

### Step 7: Issue YAML を更新する

`idd:issue-yaml` のスキーマ・記述原則に従い `.idd/issue/{issue_number}.yaml` を更新する。

ファイルが存在しない場合はスキップする（警告不要）。

存在する場合は以下のフィールドを更新する：

| フィールド | 取り扱い |
|-----------|---------|
| `fetched_at` | 現在の日時（ISO 8601） |
| `summary.implementation_content` | 更新後の本文の内容を解釈して更新 |
| `summary.completion_conditions` | 更新後の本文の内容を解釈して更新 |
| `summary.decision_rationale` | Step 4 で投稿したコメントの内容（変更経緯・理由）を反映 |

`issue.state` や `sub_issues` など、更新操作に関係しないフィールドは変更しない。

### Step 8: オーダーシートファイルを削除する

```bash
rm -f "{order_sheet_path}"
```

失敗してもフローを継続する（警告不要）。

### Step 9: 結果を返す

```
Updated: #{NNN}
URL: {URL}
YAML: .idd/issue/{NNN}.yaml（更新した場合）/ スキップ（ファイルが存在しない場合）
```

---

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| `gh` コマンドが失敗した | エラーメッセージを表示して終了（オーダーシートは残す） |
| コメント追加が失敗した | 警告を表示してフローを継続（本文更新は完了済み） |
| ラベル操作が失敗した | 警告を表示してフローを継続 |
| YAML 更新が失敗した | 警告を表示してフローを継続（GitHub 側は更新済み） |
| オーダーシート削除が失敗した | 警告なしでフローを継続 |
