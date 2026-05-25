---
name: iddue:pr:check-feedback-resolution
description: |
  PR の未解決レビューコメントが解消済みかを確認するスキル
  コメント後の差分と最新コードを照合して判定し、解消済みのスレッドは resolve する
argument-hint: "{Issue 番号}"
---

# `/iddue:pr:check-feedback-resolution` — PR フィードバック解決確認

## 使い方

```
/iddue:pr:check-feedback-resolution {Issue 番号}
例: /iddue:pr:check-feedback-resolution 123
```

**前提条件:**
- `iddue/{parent}` ブランチの PR が存在すること

---

## チェックの考え方

未解決スレッドには3種類がある。どれも「未解決」だが取得方法と処理が異なる。

| 種別 | 取得方法 | 処理 |
|------|---------|------|
| **異議スレッド** | 未解決スレッド（`isResolved: false`）のうち `<!-- iddue:pr:review -->` 付きコメントへのユーザー返信 | Phase 2: ユーザーと議論して解消 |
| **コード修正待ちスレッド** | 未解決スレッド（`isResolved: false`）のうち上記以外・かつ `isOutdated: false` | Phase 3: コード変更で解消されているか確認 |
| **outdated スレッド** | 未解決スレッド（`isResolved: false`）のうち `isOutdated: true`。コメント後にそのコード位置が変更されたスレッド | Phase 3: 同様にコード変更で解消されているか確認 |

| チェック対象 | 参照元 |
|-------------|--------|
| **コメント後の差分** | `get-diff.sh`（`original_commit_oid` から `headRefOid` まで） |
| **最新のコード全体** | worktree（`.worktree/iddue-review/{parent}/`）を `Read` で参照 |
| **IDDUE Issue コンテキスト** | 親 Issue 本文・サブ Issue 本文（ある場合）・Issue YAML |

---

## 実行フロー

```
Phase 1: コンテキスト収集 + worktree 作成
    → 未解決スレッドなし → 即通過（worktree 不要のためクリーンアップ不要）
         ↓ 未解決スレッドあり
Phase 2: 異議コメント検出・解消
    → 異議スレッドあり? → ユーザーへ提示・議論・スレッドへ返信・必要なら resolve
         ↓ なし or 全解消
    → 残存未解決スレッドなし → 通過（cleanup）
         ↓ 残存未解決スレッドあり
Phase 3: 各スレッドの解決状況を個別チェック（コード変更による解消）
         ↓
解決済みと判定したスレッドを resolve（resolve-thread.sh）
         ↓
未解決スレッドが残る? → REQUEST_CHANGES 投稿して終了（cleanup）
         ↓ 全解決
通過（cleanup）
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

PR が紐づいていない場合（`linked_pr` が null）はエラーを表示して終了。

**オーケストレーション PR の場合**: `sub_issues` の各番号についても取得する：

```
/iddue:fetch-issue {sub.number}
```

### 1.2 PR 情報の取得

```bash
bash .claude/skills/github-pr/scripts/get-pr-info.sh {pr_number}
```

結果を `pr_info` として保持（`headRefOid`, `url`）。

### 1.3 未解決レビューの取得

未解決スレッド（`isOutdated` の値に関わらず）を一括取得し、`unresolved_threads` として保持する。

```bash
bash .claude/skills/github-pr/scripts/get-review-feedback.sh {pr_number} --resolved false
```

**空配列であれば対応不要として即通過**（worktree を作成していないためクリーンアップ不要）。

### 1.4 前回の結果コメントをクローズ

`unresolved_threads` から、このスキルが過去に投稿した結果コメント（本文が `<!-- iddue:pr:check-feedback-resolution -->` で始まるもの）を検出する。
該当するコメントがあれば `minimize-comment.sh` で OUTDATED としてminimizeする：

```bash
bash .claude/skills/github-pr/scripts/minimize-comment.sh {node_id} --classifier OUTDATED
```

### 1.5 worktree の作成

```
bash .claude/skills/worktree-development/scripts/setup.sh "iddue-review/{parent}" "iddue/{parent}"
```

---

## Phase 2: 異議コメント検出・解消

前回のレビューコメント（`<!-- iddue:pr:review -->` マーカー付き）にユーザーが返信を追加している場合、
それを「異議スレッド」として検出し、ユーザーと議論して解消する。

### 2.1 異議スレッドの抽出

`unresolved_threads` の中から、以下の条件を**両方**満たすものを「異議スレッド」として抽出する：

- `comments.nodes` のいずれかの `body` に `<!-- iddue:pr:review -->` が含まれる
- `comments.nodes` が 2 件以上（= ユーザーの返信が存在する）

異議スレッドがない場合は Phase 3 へ進む。

### 2.2 ユーザーへ提示

各異議スレッドを以下の形式で提示する：

```
⚠️ {N} 件の異議コメントが検出されました。

--- {path} ---
[AI レビューコメント]
{<!-- iddue:pr:review --> を含むコメント本文（先頭 300 字）}

[ユーザー返信]
{ユーザーのコメント本文}

URL: {comment.url}
```

### 2.3 ユーザーと議論

各異議スレッドについてユーザーと議論し、以下を確認する：

- 指摘の有効性（コードの修正が必要か / 不要か）
- 不要と判断した場合：その根拠

### 2.4 各異議スレッドの解消

議論が完了したスレッドを順番に処理する。

**1. 議論の経緯と結論をスレッドへ返信として投稿する**

```bash
echo "{議論の経緯・根拠・結論}" | \
  bash .claude/skills/github-pr/scripts/reply-to-review-comment.sh {pr_number} {comment_id}
```

- `comment_id`: `<!-- iddue:pr:review -->` を含むコメントの `databaseId`

**2-a. コードの修正が不要と判断した場合**

スレッドを resolve する：

```bash
bash .claude/skills/github-pr/scripts/resolve-thread.sh {thread.id}
```

`unresolved_threads` からこのスレッドを除外する。
必要であれば Issue を更新する（`/iddue:issue:revise`）。

**2-b. コードの修正が必要と判断した場合**

スレッドを unresolved のままにして Phase 3 に委ねる。

### 2.5 全異議スレッド解消後 → 残存確認

すべての異議スレッドを処理したら、`unresolved_threads` に残存スレッドがないか確認する。

- **残存なし** → 通過（cleanup 実行）
- **残存あり** → Phase 3 へ進む

---

## Phase 3: スレッドごとの解決状況チェック

`unresolved_threads` に残っているスレッドを 1 件ずつチェックする。

### 3.1 コメント投稿後の差分を取得

各スレッドの最初のコメントから `originalCommit.oid` を取得し、差分を取得する：

```bash
bash .claude/skills/github-pr/scripts/get-diff.sh {pr_info.number} {original_commit_oid} {pr_info.headRefOid} [{path}]
```

`path` がないコメント（PR 全体へのコメント）は `path` 引数を省略する。

**outdated スレッド（`isOutdated: true`）の場合:** 元のコード位置がすでに変更されているため、差分に指摘箇所が直接現れないことがある。`path` を指定してファイル単位の差分を取得し、3.2 の最新コード全体の参照を重点的に行って解消状況を判定する。

### 3.2 最新コードを読む

```
Read ツールで .worktree/iddue-review/{parent}/{path} を参照
```

関連する他のファイルも必要に応じて参照する。

### 3.3 解決状況を判定

以下の情報を総合して判定する：

| 情報 | 役割 |
|------|------|
| コメント本文 | 何を指摘しているか |
| コメント後の差分 | その後どう変更されたか |
| 最新コード全体 | 現在どういう状態か |
| Issue コンテキスト | 実装意図・設計方針（意図的な実装との区別） |

**解決済みと判定する基準:**
- 指摘されたコードが削除・修正されている
- 別の箇所での対応により指摘の問題が解消されている
- Issue の設計方針に基づいて意図的な実装であることが明確（かつコメントの懸念が実際には当たらない）

**未解決と判定する基準:**
- コメント後の差分に該当箇所への変更がない
- 変更はあるが指摘の問題が残存している
- 対応の意図が読み取れない

---

## Phase 4: resolve と結果投稿

### 4.1 解決済みフィードバックをクローズ

解決済みと判定したフィードバックを、コメント種別に応じてクローズする：

| 種別 | node_id prefix | 使用スクリプト |
|------|---------------|-------------|
| inline review thread | `PRRT_...` | `resolve-thread.sh` |
| PR review body | `PRR_...` | `minimize-comment.sh --classifier RESOLVED` |
| issue comment | `IC_...` | `minimize-comment.sh --classifier RESOLVED` |

```bash
# inline review thread
bash .claude/skills/github-pr/scripts/resolve-thread.sh {thread.id}

# PR review body / issue comment
bash .claude/skills/github-pr/scripts/minimize-comment.sh {node_id} --classifier RESOLVED
```

### 4.2 未解決スレッドが残る場合 → REQUEST_CHANGES

以下のフォーマットで本文を作成し、`post-review.sh` に渡す：

```bash
echo "{body}" | bash .claude/skills/github-pr/scripts/post-review.sh {pr_info.number} {pr_info.headRefOid} REQUEST_CHANGES
```

**コメント本文フォーマット:**

```markdown
<!-- iddue:pr:check-feedback-resolution -->
# 未解決

| ファイル | コメント要約 | 対応状況 |
|--------|------------|--------|
| [{path}]({comment_url}) | {コメント内容の要約} | 未対応 |
| [（PR全体）]({comment_url}) | {コメント内容の要約} | 未対応 |

# 解決済み

| ファイル | コメント要約 | 対応内容 |
|--------|------------|--------|
| [{path}]({comment_url}) | {コメント内容の要約} | {対応内容の概要} |
```

### 4.3 全解決の場合 → 通過

コメント投稿はしない。ユーザーへの内部報告として記録：

```
✅ 全レビューコメント解決済み（{total} 件）

自動 resolve: {N} 件
手動 resolve 済み（チェック前から）: {N} 件
```

## Phase 5: worktree のクリーンアップ

結果に関わらず必ず実行する（Phase 1.3 で即通過した場合を除く）：

```
bash .claude/skills/worktree-development/scripts/cleanup.sh "iddue-review/{parent}"
```
