# Issue YAML スキーマ

`.iddue/issue/{number}.yaml` のスキーマ定義。

---

## スキーマ

```yaml
fetched_at: "{ISO 8601 形式の日時}"  # 例: "2026-04-22T10:00:00+09:00"

issue:
  number: {Issue 番号}
  title: "{Issue タイトル}"
  state: "{open|closed}"
  url: "{Issue URL}"
  linked_pr:               # 紐づく PR がない場合はこのキーごと省略
    number: {PR 番号}
    branch: "{ブランチ名}"
    url: "{PR URL}"
    state: "{open|closed|merged}"

parent:                    # 親 Issue がない場合はこのキーごと省略
  number: {親 Issue 番号}
  title: "{親 Issue タイトル}"
  state: "{open|closed}"
  url: "{親 Issue URL}"
  linked_pr:               # 紐づく PR がない場合はこのキーごと省略
    number: {PR 番号}
    branch: "{ブランチ名}"
    url: "{PR URL}"
    state: "{open|closed|merged}"

sub_issues:                # 子 Issue がない場合は空配列 []
  - number: {子 Issue 番号}
    title: "{子 Issue タイトル}"
    state: "{open|closed}"
    url: "{子 Issue URL}"
    linked_pr:             # 紐づく PR がない場合はこのキーごと省略
      number: {PR 番号}
      branch: "{ブランチ名}"
      url: "{PR URL}"
      state: "{open|closed|merged}"

depends_on:                # 依存 Issue がない場合は空配列 []
  - number: {依存 Issue 番号}
    title: "{依存 Issue タイトル}"
    state: "{open|closed}"
    url: "{依存 Issue URL}"
    linked_pr:             # 紐づく PR がない場合はこのキーごと省略
      number: {PR 番号}
      branch: "{ブランチ名}"
      url: "{PR URL}"
      state: "{open|closed|merged}"

summary:
  implementation_content: |
    {何を実装するか。Issue 本文の実装内容を解釈して記述}
  system_impact: |
    {この実装によりシステムがどう変わるか。API の変更・挙動の変化・影響範囲など}
  completion_conditions: |
    {何をもってこの Issue の対応が完了したと言えるか}
  decision_rationale: |
    {なぜこの実装方針になったか。検討・却下された案があれば併記する}

metadata:
  docs_path: "{docs/specs/{feature-name}.md のパス}"  # 存在しない場合はこのキーごと省略
  parent_branch: "{親 Issue のブランチ名}"              # 存在しない場合はこのキーごと省略
```
