---
name: idd:orchestration-development:resolve-conflict
description: |
  IDD オーケストレーション中に発生したコンフリクトを worktree 上で解消し、
  品質チェックをパスさせてローカルブランチを更新するスキル。
  complete-task.sh からフォアグラウンドで起動される。
argument-hint: "{サブ Issue 番号} {親 Issue 番号}"
disable-model-invocation: true
---

# `idd:orchestration-development:resolve-conflict` — コンフリクト解消

`complete-task.sh` がマージ時にコンフリクトを検出した場合に起動される。
サブ Issue ブランチの worktree 上で親 Issue ブランチをマージし、
コンフリクトを解消して品質チェックをパスさせる。

**ローカル完結:** push は行わない。最後に `git update-ref` でローカルの `$SUB_BRANCH` を
worktree の HEAD に更新し、`complete-task.sh` が再マージできる状態にする。

---

## 実行内容

### Step 1: 引数と情報の取得

引数から以下を設定する：

- `SUB` = 第1引数（サブ Issue 番号）
- `PARENT` = 第2引数（親 Issue 番号）
- `SUB_BRANCH` = `idd/$SUB`
- `PARENT_BRANCH` = `idd/$PARENT`
- `ENV_NAME` = `conflict-resolve-$SUB`

サブ Issue のコンテキストを取得する：

```
/idd:fetch-issue $SUB
```

返された YAML 内容から実装意図を確認する。

---

### Step 2: Worktree セットアップ

`setup.sh` を使って worktree を作成する。worktree の作成・submodule 初期化・post-setup フック実行をすべて担う。

```bash
bash .claude/skills/worktree-development/scripts/setup.sh \
  "$ENV_NAME" "$SUB_BRANCH"
```

`setup.sh` は内部で `git fetch origin $SUB_BRANCH` を行い、
detached HEAD 状態で `.worktree/$ENV_NAME/` に worktree を作成する。

---

### Step 3: Worktree 内で親ブランチをマージ

`exec.sh` を使い親ブランチをマージ：

```bash
bash .claude/skills/worktree-development/scripts/exec.sh \
  "$ENV_NAME" "git merge --no-ff $PARENT_BRANCH"
```

このマージはコンフリクトで失敗する（それが前提）。
コンフリクトファイルの一覧を確認する：

```bash
bash .claude/skills/worktree-development/scripts/exec.sh \
  "$ENV_NAME" "git diff --name-only --diff-filter=U"
```

---

### Step 4: コンフリクト解消

各コンフリクトファイルについて：

1. **Write/Edit ツール**で `.worktree/$ENV_NAME/{filepath}` を直接編集する
2. `<<<<<<< HEAD` / `=======` / `>>>>>>> $PARENT_BRANCH` マーカーを取り除き、
   両方の変更を統合した正しいコードを書く
3. 解消方針は Step 1 で idd:fetch-issue から返された YAML のサブ Issue の意図を優先する

---

### Step 5: マージコミット完成

解消後は `commit.sh` を使う。MERGE_HEAD が残っている状態で `git commit -m "..."` を実行すると
git は proper merge commit として扱う。

```bash
bash .claude/skills/worktree-development/scripts/commit.sh \
  "$ENV_NAME" \
  "Merge $PARENT_BRANCH into $SUB_BRANCH: conflict resolved"
```

---

### Step 6: 品質チェックループ（最大3回）

変更ファイルのリストを取得する（`exec.sh` を使う）：

```bash
CHANGED_FILES=$(bash .claude/skills/worktree-development/scripts/exec.sh \
  "$ENV_NAME" "git diff --name-only HEAD~1")
```

品質チェックを実行する：

```bash
bash .claude/skills/worktree-development/scripts/quality-check.sh \
  "$ENV_NAME" "$CHANGED_FILES"
```

**品質チェック OK の場合 → Step 7（ローカルブランチ更新）へ**

**品質チェック NG の場合:**

1. エラー出力を読んで原因を特定する
2. コンフリクト解消で採用したコードの意図を参照しながら修正する
3. Write/Edit ツールで `.worktree/$ENV_NAME/{filepath}` を修正する
4. `commit.sh` で修正をコミットする：
   ```bash
   bash .claude/skills/worktree-development/scripts/commit.sh \
     "$ENV_NAME" \
     "fix: quality check failure after conflict resolution"
   ```
5. 品質チェックを再実行する

**3回失敗した場合 → Step 8（失敗）へ**

---

### Step 7: ローカルブランチ更新・クリーンアップ（成功）

`setup.sh` が作る worktree は detached HEAD のため、このままクリーンアップすると
コミットがどのブランチにも属さなくなる。
ローカルの `$SUB_BRANCH` を worktree の HEAD に更新してから cleanup する：

```bash
bash .claude/skills/worktree-development/scripts/exec.sh \
  "$ENV_NAME" "git update-ref refs/heads/$SUB_BRANCH HEAD"
```

```bash
bash .claude/skills/worktree-development/scripts/cleanup.sh "$ENV_NAME"
```

`exit 0` で終了する。
呼び出し元の `complete-task.sh` はローカルの `$SUB_BRANCH` を再マージする。

---

### Step 8: クリーンアップ・失敗終了（3回リトライ消化）

```bash
bash .claude/skills/worktree-development/scripts/cleanup.sh "$ENV_NAME"
```

`exit 1` で終了する。
呼び出し元の `complete-task.sh` が `tasks.js fail` を呼んで status.yaml に記録する。
