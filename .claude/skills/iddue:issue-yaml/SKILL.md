---
name: iddue:issue-yaml
description: |
  .iddue/issue/{number}.yaml を作成・編集・参照する際に利用する知識スキル。
  YAML のスキーマ定義・記述原則・構造操作のルールを提供する。
user-invocable: false
---

# `iddue:issue-yaml` — Issue YAML 構成ルール

`.iddue/issue/{number}.yaml` のスキーマ・記述方針・構造操作ルールを定義する。

## スキーマ

[`templates/schema.md`](templates/schema.md) を参照。

---

## 保存先

```
.iddue/issue/{Issue 番号}.yaml
```

ディレクトリが存在しない場合は `mkdir -p .iddue/issue` で作成してから書き出す。

---

## 記述原則

- Issue 本文をそのまま転記しない。「何を」「なぜ」「どうなるか」が伝わる文章に解釈して整理する
- `summary` 配下は Issue 本文・コメントを読み取り、自分の言葉で記述する
- 存在しないフィールド（`parent`・`linked_pr`・`metadata.docs_path` 等）はキーごと省略する

---

## 親 Issue YAML への sub_issues 追記

Sub Issue 作成時、親 Issue 番号が判明しており、かつ `.iddue/issue/{parent_issue_number}.yaml` が存在する場合：

親 YAML の `sub_issues` リストに以下のエントリを追記する：

```yaml
- number: {子 Issue 番号}
  title: "{子 Issue タイトル}"
  state: "open"
  url: "{子 Issue URL}"
```

`sub_issues` が空配列 `[]` の場合はリスト形式に変換して追記する。
親 YAML が存在しない場合はスキップする（警告不要）。
