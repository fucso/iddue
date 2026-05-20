---
name: iddue:create-issue
description: |
  オーダーシート YAML を受け取り GitHub Issue を作成する。
  タイトル・本文の組み立てから gh コマンドによる作成、YAML 管理まで一貫して行う。
argument-hint: "{order_sheet_path}"
---

# `iddue:create-issue` — Issue 作成

オーダーシート（`.iddue/orders/*.yaml`）を受け取り、Issue タイトル・本文を組み立てて GitHub Issue を作成する。

## スクリプト

- [`scripts/create.sh`](scripts/create.sh) — Issue 作成 + Sub Issue 登録

## テンプレート

- [`templates/order.yaml`](templates/order.yaml) — オーダーシートのスキーマ定義

## 使い方

```
/iddue:create-issue {order_sheet_path}
```

| 引数 | 必須 | 説明 |
|------|------|------|
| `order_sheet_path` | ✅ | オーダーシート YAML のパス（`.iddue/orders/*.yaml`） |

---

## 実行内容

### Step 1: オーダーシートを読み込む

指定されたパスの YAML ファイルを読み込む。
`type: create` であることを確認する。

### Step 2: タイトルを生成する

`objective.what` / `objective.why` / `objective.how` の内容から主目的を凝縮し、
簡潔で明確な Issue タイトルを1行で生成する。

### Step 3: Issue 本文を組み立てる

オーダーシートのすべての内容を把握した上で、`iddue/templates/issue.md` の構造に従い本文を組み立てる。
下表はフィールドと本文セクションの対応の目安であり、必ずしも1対1のマッピングではない。
情報を全体的に把握し、Issue テンプレートに合うよう適切に組み直すこと。

| オーダーシートフィールド | 参考となる本文セクション（目安） |
|------------------------|----------------------|
| `objective.what` + `objective.why` | `## 概要・目的` |
| `objective.how` | `## 実装方針` |
| `objective.detail[type=design]` | `## 実装方針` 内にファイル別で記載 |
| `objective.detail[type=spec]` | `## 詳細` |
| `objective.completion_criteria` | `## 完了条件` |
| `objective.prerequisites` | `## 依存関係` |
| `parent_issue` | `## 親 Issue` |

オーダーシートに記載されたすべての情報を本文に反映する。要約・整理してテンプレートに当てはめるが、内容が薄くならないようにする。
存在しないフィールドに対応するセクションは省略も可能。

### Step 4: スクリプトを実行する

`labels` をカンマ区切り文字列に変換してスクリプトを実行する。

```bash
bash .claude/skills/iddue:create-issue/scripts/create.sh \
  "{title}" \
  "{labels をカンマ区切りで結合: 例 "iddue,level:concrete"}" \
  "{parent_issue_number（省略可）}" << 'EOF'
{組み立てた本文}
EOF
```

スクリプトの出力から作成された Issue の番号と URL を取得する。

### Step 5: Issue YAML の書き出し

`iddue:issue-yaml` のスキーマ・記述原則に従い `.iddue/issue/{issue_number}.yaml` を書き出す。

GitHub への Issue 作成直後であるため、以下のルールを適用する：

| フィールド | 取り扱い |
|-----------|---------|
| `fetched_at` | 現在の日時（ISO 8601） |
| `issue.state` | `"open"` 固定 |
| `issue.linked_pr` | 省略（PR 未作成） |
| `sub_issues` | `[]`（作成直後は子なし） |
| `depends_on` | `objective.prerequisites` の `type: issue` エントリから取得。なければ `[]` |
| `metadata.parent_branch` | `objective.prerequisites` の `type: branch` エントリが含まれる場合はブランチ名を設定。なければキーを省略 |
| `summary.decision_rationale` | `"コメントなし"`（作成直後はコメントなし） |

`parent` セクションは `parent_issue` が指定されている場合のみ含める。以下で情報を取得する：

```bash
REPO=$(bash .claude/skills/github-pr/scripts/get-repo.sh)
gh api repos/${REPO}/issues/{parent_issue_number} \
  --jq '{number: .number, title: .title, state: .state, url: .html_url}'
```

### Step 6: 親 Issue YAML への sub_issues 追記

`iddue:issue-yaml` の「親 Issue YAML への sub_issues 追記」ルールに従い実施する。

### Step 7: オーダーシートファイルを削除する

```bash
rm -f "{order_sheet_path}"
```

失敗してもフローを継続する（警告不要）。

### Step 8: 結果を返す

```
Issue: #{NNN}
URL: {URL}
YAML: .iddue/issue/{NNN}.yaml
```

---

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| `gh` コマンドが失敗した | エラーメッセージを表示して終了（オーダーシートは残す） |
| Sub Issue 登録が失敗した | 警告を表示してフローを継続（Issue 自体は作成済み） |
| YAML 書き出しが失敗した | 警告を表示してフローを継続（Issue 自体は作成済み） |
| 親 YAML への追記が失敗した | 警告を表示してフローを継続 |
| オーダーシート削除が失敗した | 警告なしでフローを継続 |
