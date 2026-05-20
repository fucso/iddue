---
name: iddue:pr:review
description: |
  IDD issue に紐づいた PR のレビューを行うスキル
  issue 内容、PR 差分、ブランチの最新コードを複数観点でレビューし、指摘があれば PR レビューとしてコメントする
argument-hint: "{Issue 番号}"
---

# `/iddue:pr:review` — IDD PR AI レビュー

## 使い方

```
/iddue:pr:review {Issue 番号}
例: /iddue:pr:review 123
```

**前提条件:**
- `iddue/{parent}` ブランチの PR が存在すること
- **オーケストレーション PR の場合**: `.iddue/orchestration/status.yaml` で全サブ Issue が `complete` であること
- **単独 Issue PR の場合**: 前提条件なし（PR が存在すること）

**単独 Issue PR とオーケストレーション PR の違い:**

| 項目 | 単独 Issue | オーケストレーション |
|------|-----------|-----------------|
| サブ Issue | なし | あり（fetch-issue の sub_issues に定義） |
| 観点①完了状況 | スキップ | 実行 |
| 観点②要件充足性 | 実行 | 実行 |
| 観点③設計整合性 | 実行（Issue 本文を設計ドキュメントとして参照） | 実行（config.yaml を設計ドキュメントとして参照） |
| Issue 参照 | 親 Issue のみ | 親 Issue + 全サブ Issue |

オーケストレーション PR かどうかは fetch-issue の `sub_issues` の有無で自動判定する。

---

## コード参照の方針

| 情報の種類 | 参照元 | 目的 |
|-----------|--------|------|
| **変更内容・差分** | `gh pr diff`（PR diff） | 何が追加・削除されたかの確認 |
| **実装後のコード全体** | worktree（`.worktree/iddue-review/{parent}/`） | コードの完全なコンテキスト・品質確認 |
| **オーケストレーション成果物** | worktree 内の `.iddue/orchestration/` | status.yaml・implement.md（オーケストレーション PR のみ） |

---

## 実行フロー

```
Phase 1: フィードバック解決確認（iddue:pr:check-feedback-resolution を呼び出す）
    → 異議コメント検出・議論・解消（check-feedback-resolution 内で処理）
    → 未解決コメントあり? → REQUEST_CHANGES で停止（cleanup）
         ↓ OK（または前回コメントなし）
Phase 2: コンテキスト収集 + worktree 作成（自動）
         ↓
（オーケストレーション PR のみ）
観点①完了状況 → CRITICAL? → PR にコメント投稿して終了（cleanup）
         ↓ OK
（以下は常に実行）
観点②要件充足性 → CRITICAL? → PR にコメント投稿して終了（cleanup）
         ↓ OK
観点③設計整合性 → CRITICAL? → PR にコメント投稿して終了（cleanup）
         ↓ OK
観点④CI ステータス → CRITICAL? → PR にコメント投稿して終了（cleanup）
         ↓ OK
観点⑤コード品質 → CRITICAL? → PR にコメント投稿して終了（cleanup）
         ↓ OK
レビュー OK コメント投稿 + ラベル付与（iddue: review ok）
Phase 4: cleanup（worktree 削除）
```

---

## Phase 1: フィードバック解決確認

`iddue:pr:check-feedback-resolution` スキルを呼び出す。

このスキルは以下を処理する：
- 前回のレビューコメント（`<!-- iddue:pr:review -->` マーカー付き）へのユーザー返信（異議コメント）を検出し、ユーザーと議論して解消する
- 異議なし・解消後は、コード変更による解消状況を確認し、解消済みスレッドを resolve する
- 未解決コメントが残る場合は REQUEST_CHANGES コメントを投稿して終了（cleanup 実行）

---

## Phase 2: コンテキスト収集

### 2.1 Issue コンテキストの取得

```
/iddue:fetch-issue {parent} force:true
```

結果から以下を取得・保持する：
- `issue.linked_pr.number` → PR 番号（`pr_number`）
- `sub_issues` → サブ Issue 一覧（空でなければオーケストレーション PR）

PR が紐づいていない場合（`linked_pr` が null）はエラーを表示して終了：
```
❌ Issue #{parent} に紐づく PR が見つかりません。
```

**オーケストレーション PR の場合**: `sub_issues` の各番号についても取得する：

```
/iddue:fetch-issue {sub.number}
```

### 2.2 PR 番号と HEAD SHA の取得

```bash
bash .claude/skills/github-pr/scripts/get-pr-info.sh {pr_number}
```

結果を `pr_info` として保持（`pr_info.number`, `pr_info.headRefOid`, `pr_info.url`, `pr_info.checks`）。

### 2.3 PR 差分の取得

```bash
bash .claude/skills/github-pr/scripts/get-diff.sh {pr_info.number}
```

変更前後の比較・コメントの行番号特定に使用する。

### 2.4 変更ファイル一覧の取得

```bash
bash .claude/skills/github-pr/scripts/get-diff.sh {pr_info.number} --name-only
```

### 2.5 CI ステータスの取得

Phase 2.2 の `pr_info.checks` を参照する（`get-pr-info.sh` の出力に含まれる）。

### 2.6 worktree の作成

`.claude/skills/worktree-development/SKILL.md` の機能を使って worktree を作成する。

```
environment_name: iddue-review/{parent}
base branch:      iddue/{parent}
worktree path:    .worktree/iddue-review/{parent}/
```

**実行コマンド:**
```bash
bash .claude/skills/worktree-development/scripts/setup.sh "iddue-review/{parent}" "iddue/{parent}"
```

以降、**PR ブランチのコード全体**は `.worktree/iddue-review/{parent}/` 配下のファイルを `Read` ツールで参照する。

### 2.7 worktree からのファイル取得と前提条件チェック

worktree 作成後、Phase 2.1 の `sub_issues` の有無で PR 種別を確認する。

**オーケストレーション PR の場合**（`sub_issues` が空でない）、`Read` ツールで以下を読み取る：

| ファイル | パス |
|---------|------|
| **status.yaml** | `.worktree/iddue-review/{parent}/.iddue/orchestration/status.yaml` |
| 各サブ implement.md | `.worktree/iddue-review/{parent}/.iddue/orchestration/reports/{sub}/implement.md` |
| 親 Issue YAML（任意） | `.worktree/iddue-review/{parent}/.iddue/issue/{parent}.yaml` |

**status.yaml の前提条件チェック（オーケストレーション PR のみ）:**

status.yaml を読み取り、全サブ Issue のステータスを確認する。
`complete` 以外のエントリが 1 件でもある場合は cleanup を実行してユーザーにエラー表示し、終了する：

```
❌ レビューの前提条件を満たしていません。

以下のサブ Issue がまだ complete になっていません：
- #{sub}: {status}（例: in_progress, failed）

全サブ Issue が complete になってから再実行してください。
```

**単独 Issue PR の場合**（`sub_issues` が空）、`Read` ツールで以下のみ読み取る：

| ファイル | パス |
|---------|------|
| 親 Issue YAML（任意） | `.worktree/iddue-review/{parent}/.iddue/issue/{parent}.yaml` |

---

## Phase 3: 観点別レビュー

各観点の詳細は `aspects/` 配下のドキュメントを参照して実施する。

### コードの参照方針

各観点でコードを確認する際は以下を使い分ける：

- **変更箇所の把握**: Phase 2 で取得した `get-diff.sh` の出力
- **変更後の完全なコード**: `Read` ツールで `.worktree/iddue-review/{parent}/{ファイルパス}` を参照
- **関連ファイル（変更なし）の参照**: 同じく worktree から `Read` で参照

### 観点の実行可否

| 観点 | 単独 Issue PR | オーケストレーション PR |
|------|-------------|---------------------|
| ①完了状況 | スキップ | 実行 |
| ②要件充足性 | 実行 | 実行 |
| ③設計整合性 | 実行 | 実行 |
| ④CI ステータス | 実行 | 実行 |
| ⑤コード品質 | 実行 | 実行 |

### 観点ごとの判定と次への進め方

各観点では `aspects/*.md` の判定基準に従ってレビューを行い、結果を以下の 3 段階で分類する：

| 分類 | 定義 | 扱い |
|-----|------|-----|
| CRITICAL | 修正が必要な問題 | → コメント投稿して cleanup → 終了（REQUEST_CHANGES） |
| WARNING | 人間レビュー時の注意喚起 | → レビュー OK コメントに付記（ブロックしない） |
| INFO | 提案・参考情報 | → レビュー OK コメントに付記（ブロックしない） |

**CRITICAL が 1 件でもあればその観点でフローを止め、後続の観点は実行しない。**
いずれの場合も終了前に Phase 4 の cleanup を実行する。

---

## Phase 4: レビューコメント投稿 + cleanup

このスキルが投稿するすべてのレビューコメント（本文・インライン）の先頭に `<!-- iddue:pr:review -->` を付与する。
これにより次回レビュー時に `iddue:pr:check-feedback-resolution` がユーザー返信（異議コメント）を検出できる。

### 4.1 REQUEST_CHANGES（CRITICAL あり）

問題箇所を diff の行に紐づけられる場合は inline コメントとして投稿する。
インラインコメントの `body` にも `<!-- iddue:pr:review -->` を付与すること。

```bash
# インラインコメントを JSON ファイルに書き出す
cat > /tmp/review-comments.json << 'EOF'
[{"path": "{変更ファイルパス}", "line": {問題の行番号}, "body": "<!-- iddue:pr:review -->\n{インラインコメント本文}"}]
EOF

echo "<!-- iddue:pr:review -->
{観点ドキュメントのフォーマットに従ったサマリー本文}" | \
  bash .claude/skills/github-pr/scripts/post-review.sh \
  {pr_info.number} {pr_info.headRefOid} REQUEST_CHANGES /tmp/review-comments.json
```

インライン紐づけが困難な問題（設計逸脱・要件未充足など）はインラインなしで投稿する：

```bash
echo "<!-- iddue:pr:review -->
{サマリー本文}" | \
  bash .claude/skills/github-pr/scripts/post-review.sh \
  {pr_info.number} {pr_info.headRefOid} REQUEST_CHANGES
```

### 4.2 レビュー OK コメント（全観点 CRITICAL なし）

PR の Approve は行わない。`COMMENT` イベントでレビュー結果を残す。

```bash
echo "<!-- iddue:pr:review -->
{aspects/05-code-quality.md のレビュー OK フォーマットに従った本文}" | \
  bash .claude/skills/github-pr/scripts/post-review.sh \
  {pr_info.number} {pr_info.headRefOid} COMMENT
```

コメント投稿後、PR に `iddue: review ok` ラベルを付与する：

```bash
bash .claude/skills/github-pr/scripts/add-label.sh -h {pr_info.number} "iddue: review ok"
```

### 4.3 COMMENT（CI pending 時のみ）

```bash
echo "<!-- iddue:pr:review -->
{aspects/04-ci.md の pending フォーマットに従った本文}" | \
  bash .claude/skills/github-pr/scripts/post-review.sh \
  {pr_info.number} {pr_info.headRefOid} COMMENT
```

### 4.4 worktree のクリーンアップ

コメント投稿後（または投稿失敗時も）、必ず実行する：

```bash
bash .claude/skills/worktree-development/scripts/cleanup.sh "iddue-review/{parent}"
```

### 4.5 ユーザーへの完了報告

```
✅ AI レビュー完了

判定: {レビュー OK / 要修正}
PR: {pr_info.url}

{レビュー OK の場合}
すべての観点で CRITICAL なし。PR にレビュー結果コメントを投稿しました。
{WARNING/INFO があれば件数を記載}

{要修正の場合}
観点{①~⑤}: CRITICAL {N} 件
詳細は PR のレビューコメントを確認してください。
```

---

## 観点ドキュメント

| ファイル | 観点 | 対象 |
|---------|-----|------|
| [`aspects/01-completion.md`](aspects/01-completion.md) | ①サブ Issue 完了状況 | オーケストレーション PR のみ |
| [`aspects/02-requirements.md`](aspects/02-requirements.md) | ②要件充足性 | 常に実行 |
| [`aspects/03-design.md`](aspects/03-design.md) | ③設計整合性 | 常に実行（単独 Issue: Issue 本文を参照 / オーケストレーション: config.yaml を参照） |
| [`aspects/04-ci.md`](aspects/04-ci.md) | ④CI ステータス | 常に実行 |
| [`aspects/05-code-quality.md`](aspects/05-code-quality.md) | ⑤コード品質 | 常に実行 |
