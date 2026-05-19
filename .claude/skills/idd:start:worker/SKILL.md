---
name: idd:start:worker
description: |
  オーケストレーターから起動されるサブ Issue ワーカー。
  単一のサブ Issue を worktree 環境で実装し、完了後に report.md を
  サブ Issue ブランチにコミットしてオーケストレーターに完了シグナルを送る。
argument-hint: "{サブ Issue 番号} {setupBranch}"
disable-model-invocation: true
hooks:
  PostToolUse:
    - matcher: ".*"
      hooks:
        - type: command
          command: bash "$CLAUDE_PROJECT_DIR/.claude/skills/idd:start:worker/scripts/log-action.sh"
---

# `/idd:start:worker` — サブ Issue ワーカー実装

`idd:start:orchestrate` から起動されるワーカー。
サブ Issue 1件を独立した worktree で実装し、完了シグナルを送る。

## スクリプト

（なし）

## 使い方

このスキルは直接起動せず、`idd:start:orchestrate` スキルが以下のコマンドで起動する：

```bash
env -u CLAUDECODE claude -p "/idd:start:worker {sub} {setupBranch}"
```

---

## 実行内容

### Step 1: Issue コンテキスト収集

```
/idd:fetch-issue {sub}
```

返された YAML 内容から必要な情報を参照する。

**setupBranch の確認:**

`setupBranch` = 第2引数として渡された値（`idd/{parent}`）

---

### Step 2: 実装環境の準備

**既存ブランチの削除:**

IDD ワーカーは常に最初から実装するため、`idd/{sub}` ブランチが既存の場合は事前に削除する。

```bash
git branch -D "idd/{sub}" 2>/dev/null || true
```

`setupBranch`（= `idd/{parent}`）をベースブランチとして worktree を作成する：

```bash
bash .claude/skills/worktree-development/scripts/setup.sh "idd/{sub}" "{setupBranch}"
```

---

### Step 3: 実装

`idd:start` の Phase 4 と同等の手順で実装する。

- `worktree-development` スキルの操作ルールに従う
- インターフェース変更時は呼び出し箇所を追従修正
- 仕様変更が発生した場合は `idd:start` Phase 4.2 と同様に処理

---

### Step 4: 品質チェック

品質チェックを実行し、結果をワークツリー内の一時ファイルに保存する：

```bash
mkdir -p ".worktree/idd/{sub}/tmp"
bash .claude/skills/idd:start/scripts/quality-check.sh "idd/{sub}" \
  | tee ".worktree/idd/{sub}/tmp/quality-check.log"
```

一時ファイルは worktree cleanup 時に自動削除される。

失敗時は修正してリトライ（最大3回）。設計レベルの問題はエラーとして implement.md に記録。

---

### Step 5: 実装をコミット

`idd:start/templates/commit-message.md` を参照してコミットメッセージを作成する。

```bash
bash .claude/skills/worktree-development/scripts/commit.sh "idd/{sub}" "{commit_message}"
```

---

### Step 6: implement.md 作成・コミット

`idd:orchestration-development/templates/report-md.md` のフォーマットに従い、worktree 内に以下のファイルを作成する：

```
.worktree/idd/{sub}/.idd/orchestration/reports/{sub}/implement.md
```

品質チェックセクションには Step 4 で保存した一時ファイルの内容を転記する：

```bash
cat ".worktree/idd/{sub}/tmp/quality-check.log"
# この出力を implement.md の品質チェックセクションに記録する
```

記録する内容：
- 実装概要
- 変更ファイル一覧
- 品質チェック結果（quality-check.log の内容をそのまま転記）
- コミット情報（ブランチ・SHA・メッセージ）
- 引き継ぎ事項（後続サブ Issue や親 Issue のマージ時の注意点）
- ステータス: `completed`

worktree 上でコミットする（このコミットがオーケストレーターの完了シグナルになる）：

```bash
bash .claude/skills/worktree-development/scripts/commit.sh "idd/{sub}" "report: sub-issue #${sub} implementation complete"
```

---

### Step 7: worktree クリーンアップ

```bash
bash .claude/skills/worktree-development/scripts/cleanup.sh "idd/{sub}"
```

---

## エラーハンドリング

どの Step でも回復不能なエラーが発生した場合：

1. worktree 内に `.idd/orchestration/reports/{sub}.md` を作成（ステータス: `failed`、エラー詳細を記録）
2. `commit.sh "idd/{sub}" "report: sub-issue #${sub} failed"` でコミットしてオーケストレーターに通知
3. `cleanup.sh "idd/{sub}"` で worktree を削除
4. 終了

クラッシュ（プロセス死）よりも report.md での通知を優先する。
