---
name: iddue:start
description: |
  IDD Issue を指定して git worktree で実装を開始し PR を作成する。
  GitHub Issue からコンテキストを収集し、iddue:judging-ready-to-implementation で
  実装可能性を判定してから、worktree-development スキルで
  独立した worktree 環境で実装・品質チェック・PR 作成まで自動実行する。
argument-hint: "{Issue 番号}"
disable-model-invocation: true
---

# `/iddue:start` — Issue 実装開始

IDD Issue を指定して、独立した git worktree 環境で実装を行い PR を作成する。
任意の Issue を受け付け、実装可能性を判定してから実装に進む。

## スクリプト

- [`scripts/get-branch-info.js`](scripts/get-branch-info.js) — issue YAML から setupBranch を抽出
- [`scripts/quality-check.sh`](scripts/quality-check.sh) — 変更ファイル取得 + 品質チェックを一括実行
- [`scripts/finalize.sh`](scripts/finalize.sh) — コミット・プッシュ・クリーンアップを一括実行
- [`scripts/create-pr.sh`](scripts/create-pr.sh) — 既存 PR の確認と PR 作成を一括実行

## テンプレート

- [`templates/commit-message.md`](templates/commit-message.md) — コミットメッセージ
- [`templates/issue-spec-change-comment.md`](templates/issue-spec-change-comment.md) — 仕様変更時の Issue コメント
- [`templates/pr-body.md`](templates/pr-body.md) — PR 本文
- [`templates/completion-report.md`](templates/completion-report.md) — 完了報告

## 使い方

```
/iddue:start {Issue 番号}
例: /iddue:start 103
```

任意の Issue 番号を指定可能。

---

## 実行内容

### Phase 1: コンテキスト収集

`iddue:fetch-issue` スキルを実行して Issue コンテキストを収集する。

```
/iddue:fetch-issue {Issue 番号}
```

返された YAML 内容を以降の Phase で参照する。

**エラー:** `iddue:fetch-issue` がエラーを返した場合はその内容を表示して終了する。

**branch 情報の取得:**

以下のスクリプトを実行し、JSON 出力の値を以降の Phase で使用する。

```bash
node .claude/skills/iddue:start/scripts/get-branch-info.js {issue_number}
```

**サブ Issue の確認（オーケストレーターモード分岐）:**

取得した YAML の `sub_issues` フィールドを確認する。

- `sub_issues` が空でない場合（例: `[124, 125, 126]`）:

  ```
  {N}件のサブ Issue があります。
  オーケストレーターモードで並列実装しますか？

  サブ Issue:
  - #{sub1}: {タイトル（取得可能な場合）}
  - #{sub2}: ...

  [Yes / No]
  ```

  - **Yes** → `/iddue:start:orchestrate {issue_number}` へデリゲートして終了
  - **No** → 通常フローを終了（実装しない）

- `sub_issues` が空（または未設定）の場合 → Phase 2 へ

---

### Phase 2: 実装可能性の判定

`iddue:judging-ready-to-implementation` スキルを実行して Issue の実装可能性を評価する。
Phase 1 で `force:true` 付きの fetch が済んでいるため、内部の `iddue:fetch-issue` 呼び出し（force なし）はキャッシュを返し GitHub fetch は発生しない。

```
/iddue:judging-ready-to-implementation {issue_number}
```

判定結果が ❌ の場合は、判定結果と推奨アクションをユーザーに表示して終了する。
判定結果が ✅ の場合は、Phase 3（実装環境の準備）を開始する。

---

### Phase 3: 実装環境の準備

Phase 1 で取得した `setupBranch` を使用する。

`worktree-development` スキルの「作業環境の準備」を使用する。

```bash
bash .claude/skills/worktree-development/scripts/setup.sh "iddue/{issue_number}" {setupBranch}
```

---

### Phase 4: 実装

#### 4.1 要件確認

作業環境内の関連ファイルを読み取り、Issue の「実装内容」と照合して実装方針を確定する。

#### 4.2 コード実装

Issue の実装内容に従ってコードを実装する。

**実装の原則:**
- `worktree-development` スキルの操作ルールに従う（コマンド実行は提供スクリプト経由、ファイル編集は Write/Edit 直接可）
- インターフェース変更時は呼び出し箇所を追従修正

**仕様変更が発生した場合:**

実装中に Issue の記載と異なる仕様が必要になった場合は、**同一 PR 内**でドキュメントとコードの両方を更新する。
コミットは分けてよい。PR マージ時点でドキュメントとコードが整合していれば十分。

1. `docs/specs/{feature-name}.md` を更新（現時点の正確な仕様に修正）
2. 対象 Issue にコメントを追加（[`templates/issue-spec-change-comment.md`](templates/issue-spec-change-comment.md) を使用）

#### 4.3 品質チェック

```bash
bash .claude/skills/iddue:start/scripts/quality-check.sh "iddue/{issue_number}"
```

**失敗時:** 修正してリトライ（最大3回）。設計レベルの問題の場合はユーザーに報告して停止。

---

### Phase 5: コミット・プッシュ・クリーンアップ

[`templates/commit-message.md`](templates/commit-message.md) を参照してコミットメッセージを作成し、一括実行する。
Phase 1 で取得した `taskBranch` を使用する。

```bash
bash .claude/skills/iddue:start/scripts/finalize.sh "iddue/{issue_number}" "{commit_message}" {taskBranch}
```

**重要:** 3番目の引数（実装ブランチ名）を必ず指定すること。
省略すると親 Issue のブランチに直接コミットされてしまう。

**issue ファイルの更新（新規ブランチを作成した場合のみ）:**

finalize.sh 完了後、`.iddue/issue/{issue_number}.yaml` の `issue.linked_pr.branch` を更新する。

```yaml
issue:
  linked_pr:
    branch: "{taskBranch}"  # 追加または更新
```

---

### Phase 6: PR 作成

[`templates/pr-body.md`](templates/pr-body.md) を使用して PR 本文を構成し、一時ファイルに書き出す。
`Closes #{NNN}` を含めることで PR マージ時に Issue が自動クローズされる。

```bash
BODY_FILE=$(mktemp /tmp/iddue-pr-body.XXXXXX.md)
cat > "$BODY_FILE" << 'EOF'
{templates/pr-body.md の内容を埋め込んだ PR 本文}
EOF
```

以下のスクリプトを実行する（既存 PR の確認と PR 作成を一括処理）：

```bash
bash .claude/skills/iddue:start/scripts/create-pr.sh \
  "{task_branch}" \
  "[Issue#{NNN}] {Issue タイトル}" \
  "{setupBranch}" \
  "$BODY_FILE"
```

一時ファイルを削除する：

```bash
rm -f "$BODY_FILE"
```

出力の形式は `{status}:{pr_number}:{pr_url}` で、`status` は `exists`（既存 PR）または `created`（新規作成）。

**issue ファイルの更新:**

PR 作成後（または既存 PR が見つかった場合）、`.iddue/issue/{issue_number}.yaml` の `issue.linked_pr` を完全な情報に更新する。

```yaml
issue:
  linked_pr:
    number: {PR 番号}
    branch: "{task_branch}"
    url: "{PR URL}"
    state: "open"
```

---

### Phase 7: 完了報告

[`templates/completion-report.md`](templates/completion-report.md) を使用して完了報告を表示する。

---

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| `iddue:fetch-issue` がエラーを返した | エラー内容を表示して終了（Issue 不在・クローズ済み・依存 Issue 未クローズ・親ブランチ取得不可を含む） |
| 実装可能性の判定で不可 | 判定結果と推奨アクションを表示して終了 |
| 品質チェック失敗（実装の問題） | 修正してリトライ（最大3回） |
| 品質チェック失敗（設計の問題） | エラー報告して終了（worktree はクリーンアップ） |

---

## worktree の命名規則

| 項目 | 形式 | 例 |
|------|------|-----|
| 作業環境名 | `iddue/{issue_number}` | `iddue/103` |
| worktree パス | `.worktree/iddue/{issue_number}` | `.worktree/iddue/103` |
| 実装ブランチ | `iddue/{issue_number}` | `iddue/103` |
