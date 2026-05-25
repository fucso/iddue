---
name: iddue:setup-orchestration
description: |
  親 Issue と Sub Issue が GitHub 上に存在する状態で、
   /iddue:start:orchestrate による並列実装を実行するための前提情報を整備する。
argument-hint: "{親 Issue 番号}"
---

# `/iddue:setup-orchestration` — 並列実装前提整備

親 Issue と Sub Issue が GitHub 上に起票済みであることを前提に、
オーケストレーターモードによる並列実装を開始するための情報を整備する。

**このスキルのゴール:**
- メイン Issue ブランチ `iddue/{parent}` の作成と push
- `.orchestrate/config.yaml` の生成
- メイン Issue PR の作成（ドラフト）
- 各サブ Issue YAML に `parent.linked_pr.branch` を設定

完了後は `/iddue:start {parent}` でオーケストレーター実装を開始できる。

## 使い方

```
/iddue:setup-orchestration {親 Issue 番号}
例: /iddue:setup-orchestration 123
```

**実行タイミング:** 親 Issue と Sub Issue が GitHub 上に起票済みで、/iddue:start:orchestrate による並列実装を開始したいとき。

---

## 実行内容

### Phase 1: 親 Issue と Sub Issue の確認・収集

**親 Issue を取得:**

```
/iddue:fetch-issue {parent}
```

`.iddue/issue/{parent}.yaml` の `sub_issues` フィールドを確認する。

**Sub Issue が存在しない場合:** エラーを表示して終了する。

```
エラー: Sub Issue が存在しません。
先に Sub Issue を起票してから実行してください。
```

**Sub Issue が存在する場合:** 各 Sub Issue の YAML を取得する。

```
/iddue:fetch-issue {sub1}
/iddue:fetch-issue {sub2}
...
```

各 Sub Issue YAML から以下を収集する（これらが `config.yaml` の生成に使われる）：

| 収集する値 | 取得元フィールド | config.yaml での用途 |
|---|---|---|
| Issue 番号 | `issue.number` | `tasks[].issue` |
| タイトル | `issue.title` | `tasks[].title` |
| 依存 Issue 番号リスト | `depends_on[].number` | `tasks[].dependencies` |

---

### Phase 2: メイン Issue ブランチ & config.yaml の作成

worktree-development スキルを使い、メインディレクトリのブランチ状態に依存せず作業する。

**Step 1: ベースブランチの決定**

Phase 1 で読み込んだ親 Issue YAML の `metadata.parent_branch` を確認する：

```bash
DEFAULT_BRANCH=$(bash .claude/skills/github-pr/scripts/get-default-branch.sh)
BASE_BRANCH = metadata.parent_branch が設定されていればその値、なければ ${DEFAULT_BRANCH}
```

**Step 2: worktree セットアップ**

```bash
bash .claude/skills/worktree-development/scripts/setup.sh "iddue/{parent}" {BASE_BRANCH}
```

**Step 3: config.yaml を worktree に書き出す**

Write ツールで以下のパスに直接書き出す:

```
.worktree/iddue/{parent}/.orchestrate/config.yaml
```

内容は Phase 1 で iddue:fetch-issue から返された YAML を使用する。
（`.iddue/issue/` は gitignore 対象のため worktree には存在しないが、Phase 1 で既に取得済み）

スキーマの詳細は `.claude/skills/iddue:orchestration-development/templates/config-yaml.md` を参照。

```yaml
parent_issue: {parent}
main_issue_branch: "iddue/{parent}"
created_at: "{現在時刻 ISO 8601}"

tasks:
  - issue: {sub1の issue.number}
    title: "{sub1の issue.title}"
    dependencies: []                        # depends_on が空の場合
  - issue: {sub2の issue.number}
    title: "{sub2の issue.title}"
    dependencies:
      - {sub1の issue.number}               # depends_on[].number を列挙
```

**Step 4: コミット（新ブランチ作成込み）**

```bash
bash .claude/skills/worktree-development/scripts/commit.sh \
  "iddue/{parent}" \
  "orchestration: add config.yaml for #{parent}" \
  "iddue/{parent}"
```

第3引数で `iddue/{parent}` ブランチを worktree 内に作成してからコミットする。

**Step 5: プッシュ**

```bash
bash .claude/skills/worktree-development/scripts/push.sh "iddue/{parent}" "iddue/{parent}"
```

**Step 6: クリーンアップ**

```bash
bash .claude/skills/worktree-development/scripts/cleanup.sh "iddue/{parent}"
```

---

### Phase 3: メイン Issue PR の作成（ドラフト）

PR 本文を作成する（`Closes #{parent}` を含める）：

```bash
BODY_FILE=$(mktemp /tmp/iddue-pr-body.XXXXXX.md)
cat > "$BODY_FILE" << 'EOF'
Closes #{parent}

## 概要

{親 Issue の実装内容の概要}

## サブ Issue

| Issue | タイトル | 依存 |
|-------|---------|------|
| #{sub1} | {title1} | - |
| #{sub2} | {title2} | #{sub1} |

## 実装方針

オーケストレーターモードで並列実装します。
各サブ Issue ブランチがこのメイン Issue ブランチにマージされます。
EOF
```

メイン Issue PR をドラフトとして作成する：

```bash
PR_OUTPUT=$(gh pr create \
  --title "[Issue#{parent}] {親 Issue タイトル}" \
  --body-file "$BODY_FILE" \
  --head "iddue/{parent}" \
  --base "${DEFAULT_BRANCH}" \
  --draft)
rm -f "$BODY_FILE"
```

PR 番号・URL を取得して記録する。

---

### Phase 4: サブ Issue YAML の更新

各サブ Issue の `.iddue/issue/{sub}.yaml` を更新して `parent.linked_pr.branch` を設定する。

`iddue:issue-yaml` スキルを参照してフィールドを更新する：

```yaml
parent:
  linked_pr:
    branch: "iddue/{parent}"
```

**親 Issue YAML の更新:**

`.iddue/issue/{parent}.yaml` の `issue.linked_pr` を更新：

```yaml
issue:
  linked_pr:
    number: {PR 番号}
    branch: "iddue/{parent}"
    url: "{PR URL}"
    state: "open"
```

---

### Phase 5: 完了報告

```
✅ /iddue:setup-orchestration 完了

**親 Issue:** #{parent} {タイトル}
**メイン Issue ブランチ:** iddue/{parent}
**メイン Issue PR:** {PR URL}

**サブ Issue:**
| Issue | タイトル | 依存 |
|-------|---------|------|
| #{sub1} | {title} | - |
| #{sub2} | {title} | #{sub1} |

**次のステップ:**
並列実装を開始する: /iddue:start {parent}
```

---

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| Sub Issue が存在しない | エラーを表示して終了 |
| 親 Issue が存在しない | エラーを表示して終了 |
| メイン Issue ブランチ作成失敗 | エラーメッセージを表示して終了 |
| メイン Issue PR 作成失敗 | 警告を表示（後で手動で作成するよう案内）。フローは継続 |
