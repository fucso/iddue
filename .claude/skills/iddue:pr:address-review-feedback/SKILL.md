---
name: iddue:pr:address-review-feedback
description: |
  PR の未解決レビューコメントへの対応を実装するスキル
  コメントをタスクに整理して修正を実装し、ブランチにプッシュする
argument-hint: "{Issue 番号}"
---

# `/iddue:pr:address-review-feedback` — PR レビューフィードバック対応

## 使い方

```
/iddue:pr:address-review-feedback {Issue 番号}
例: /iddue:pr:address-review-feedback 123
```

**前提条件:**
- `iddue/{parent}` ブランチの PR に未解決のレビューコメントが存在すること

---

## 実行フロー

```
Phase 1: コンテキスト収集 + worktree 作成
    → CONFLICTING → コンフリクト解消 → コミット（以降は通常フローへ）
    → 未解決スレッドなし → 対応不要としてユーザーに報告して終了（cleanup）
         ↓ 未解決スレッドあり
Phase 2: 修正タスクの整理
         ↓
Phase 3: バックグラウンドエージェントで並列実装
         ↓
Phase 4: 完了報告 + cleanup
```

---

## Phase 1: コンテキスト収集

### 1.1 IDDUE Issue コンテキストの取得

```
/iddue:fetch-issue {parent} force:true
```

結果から以下を取得・保持する：
- `issue.linked_pr.number` → PR番号（`pr_number`）
- `sub_issues` → サブ Issue 一覧（空でなければオーケストレーション PR）

**オーケストレーション PR の場合**: `sub_issues` の各番号についても取得する：

```
/iddue:fetch-issue {sub.number}
```

### 1.2 PR 情報の取得

```bash
bash .claude/skills/github-pr/scripts/get-pr-info.sh {pr_number}
```

結果を `pr_info` として保持（`headRefOid`, `headRefName`, `baseRefName`, `url`, `mergeable`, `mergeStateStatus`）。

### 1.3 未解決レビュースレッドの取得

```bash
bash .claude/skills/github-pr/scripts/get-review-feedback.sh {pr_number}
```

結果が空配列であれば「対応不要」としてユーザーに報告して終了。

### 1.4 PR 差分の取得

```bash
bash .claude/skills/github-pr/scripts/get-diff.sh {pr_number}
```

コメントの背景理解と変更範囲の把握に使用する。

### 1.5 worktree の作成

```
bash .claude/skills/worktree-development/scripts/setup.sh "iddue-review/{parent}" "iddue/{parent}"
```

**オーケストレーション PR の場合**（`sub_issues` が空でない）、`Read` ツールで以下を読み取る：
- `.worktree/iddue-review/{parent}/.orchestrate/reports/{sub}/implement.md`
- `.worktree/iddue-review/{parent}/.iddue/issue/{parent}.yaml`（存在する場合）

### 1.6 コンフリクトチェックと解消

`pr_info.mergeable` を確認する。

- `MERGEABLE` または `UNKNOWN` → スキップして Phase 2 へ
- `CONFLICTING` → 以下の手順でコンフリクトを解消する

**コンフリクト解消手順:**

**1. ベースブランチをマージ（--no-commit でコンフリクト状態を確認）**

```bash
git -C .worktree/iddue-review/{parent} merge origin/{pr_info.baseRefName} --no-commit --no-ff
```

**2. コンフリクトファイルの特定**

```bash
git -C .worktree/iddue-review/{parent} diff --name-only --diff-filter=U
```

**3. 各コンフリクトファイルの解消**

`github-pr` の analyze-conflicts.sh を使って両側の差分を取得し、PR の Issue コンテキストと照合して解消方針を判断する：

```bash
bash .claude/skills/github-pr/scripts/analyze-conflicts.sh \
  {pr_info.baseRefName} {pr_info.headRefName}
```

`Read` ツールでコンフリクトマーカーを含むファイルを読み取り、`Edit` ツールで解消する。
解消後、`git -C .worktree/iddue-review/{parent} add {file}` でステージングする。

**4. マージコミット**

```bash
bash .claude/skills/worktree-development/scripts/commit.sh \
  "iddue-review/{parent}" \
  "fix: {pr_info.baseRefName} をマージしてコンフリクトを解消する"
```

コンフリクト解消後、Phase 2 へ進む（他に未解決スレッドがなければそのまま Phase 3.4 のプッシュへ）。

---

## Phase 2: 修正タスクの整理

未解決スレッドを修正タスクにグループ化する。

### グループ化の基準

| 基準 | 説明 |
|------|------|
| **同一ファイルの隣接コメント** | 同じファイルの近い箇所への複数コメントは 1 タスクにまとめる |
| **論理的に関連するコメント** | 同じ問題の別側面を指摘するコメントは 1 タスクにまとめる |
| **独立したコメント** | 別ファイル・別問題は別タスクに分割（並列実行できる） |

### タスク定義

各タスクには以下を含める：

```
タスク #{n}: {タスクのタイトル}
対象ファイル: {path1}, {path2}, ...
コメント内容:
  - [{author}] {コメント本文}
実装方針: {何をどう修正すべきか。Issue コンテキストから読み取れる意図}
ブランチ: iddue/{parent}
```

### 並列/直列の判定

- **並列可**: 対象ファイルが重複しない独立タスク
- **直列**: 同じファイルや同じ機能領域に影響するタスク（実行順序を明示する）

---

## Phase 3: バックグラウンドエージェントで実装

### 3.1 並列タスクの実行

独立タスクはバックグラウンドエージェントで並列実行する。各エージェントへの指示に含める情報：

- タスクの概要（コメント内容・実装方針）
- 対象ファイルのパス（worktree から `Read` して現在のコードを把握）
- Issue コンテキスト（親 Issue・サブ Issue）
- コミットメッセージの方針
- 使用するコミット・プッシュスクリプトのパス

### 3.2 直列タスクの実行

依存関係のあるタスクは前のタスク完了後に順次実行する。

### 3.3 各エージェントの実装手順

1. worktree から対象ファイルを `Read` してコードを把握
2. コメントの指摘内容を理解し、Issue コンテキストと照合して修正方針を確定
3. `Edit` ツールでコードを修正
4. コミット：

```
bash .claude/skills/worktree-development/scripts/commit.sh "iddue-review/{parent}" "fix: {コメント内容の要約} in response to review feedback"
```

### 3.4 変更のプッシュ

全タスク完了後にプッシュする：

```
bash .claude/skills/worktree-development/scripts/push.sh "iddue-review/{parent}"
```

---

## Phase 4: 完了報告 + cleanup

### 4.1 worktree のクリーンアップ

```
bash .claude/skills/worktree-development/scripts/cleanup.sh "iddue-review/{parent}"
```

### 4.2 ユーザーへの報告

```
✅ レビューフィードバック対応完了

対応したコメント: {N} 件（{M} タスク）
ブランチ: iddue/{parent}

### 対応内容
| タスク | 対象ファイル | 対応内容 |
|--------|-------------|---------|
| #{n} | {path} | {修正内容の要約} |

### 次のステップ
/iddue:pr:review {parent} を実行して対応状況を確認してください。
```

### 4.3 対応できなかったコメントがある場合

```
⚠️ 以下のコメントは自動対応できませんでした。手動での確認をお願いします：

- {path}: {コメント内容の要約}
  理由: {対応できなかった理由}
```
