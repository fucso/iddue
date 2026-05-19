# 提供機能

## 1. PR 情報の取得

PR 番号・HEAD SHA・URL と CI ステータスをまとめて取得する。

**パラメータ:**
- `pr_number`: PR 番号

**出力:** `{"number": N, "headRefOid": "...", "url": "...", "checks": [{"name": "...", "state": "...", "conclusion": "...", "link": "..."}]}`

PR が見つからない場合は exit 1 でエラー終了する。

**実行コマンド:**
```bash
bash .claude/skills/github-pr/scripts/get-pr-info.sh {pr_number}
```

---

## 2. レビューフィードバックの取得

PR のレビュースレッドを取得する。`--resolved` / `--outdated` フラグでフィルタリングできる。

**パラメータ:**
- `pr_number`: PR 番号
- `--resolved <true|false>`: isResolved でフィルタ（デフォルト: `false`）
- `--outdated <true|false>`: isOutdated でフィルタ（デフォルト: `false`）

**出力:** スレッドの JSON 配列。各スレッドに `id`, `isResolved`, `isOutdated`, `comments` を含む。

**実行コマンド:**
```bash
# 未解決スレッドのみ（デフォルト）
bash .claude/skills/github-pr/scripts/get-review-feedback.sh {pr_number}

# 全スレッド（解決済み含む）
bash .claude/skills/github-pr/scripts/get-review-feedback.sh {pr_number} --resolved true
bash .claude/skills/github-pr/scripts/get-review-feedback.sh {pr_number} --resolved true --outdated true
```

---

## 3. 差分の取得

PR 全体の差分、またはコミット間の差分を取得する。`--name-only` で変更ファイル一覧も取得できる。

**パラメータ:**
- `pr_number`: PR 番号
- `start_oid`（省略可）: 差分の開始コミット SHA
- `end_oid`（省略可、`start_oid` 指定時は必須）: 差分の終了コミット SHA
- `path`（省略可）: 対象ファイルパス（`start_oid` 指定時のみ有効）
- `--name-only`: ファイル名のみ出力

**実行コマンド:**
```bash
# PR 全体の差分
bash .claude/skills/github-pr/scripts/get-diff.sh {pr_number}

# PR の変更ファイル一覧
bash .claude/skills/github-pr/scripts/get-diff.sh {pr_number} --name-only

# コメント時点から PR HEAD までの差分
bash .claude/skills/github-pr/scripts/get-diff.sh {pr_number} {original_commit_oid} {head_ref_oid}

# 特定ファイルに絞った差分
bash .claude/skills/github-pr/scripts/get-diff.sh {pr_number} {original_commit_oid} {head_ref_oid} {path}
```

---

## 4. レビューの投稿

PR にレビューを投稿する。インラインコメントを添付できる。

**パラメータ:**
- `pr_number`: PR 番号
- `sha`: HEAD コミット SHA（`get-pr-info.sh` の `headRefOid`）
- `event`: `REQUEST_CHANGES` または `COMMENT`
- `comments_json_file`（省略可）: インラインコメントの JSON ファイルパス
- stdin: レビュー本文

**`comments_json_file` の形式:**
```json
[
  {"path": "{ファイルパス}", "line": {行番号}, "body": "{コメント本文}"}
]
```

**実行コマンド:**
```bash
# インラインなし
echo "{body}" | bash .claude/skills/github-pr/scripts/post-review.sh {pr_number} {sha} REQUEST_CHANGES

# インライン付き
cat > /tmp/comments.json << 'EOF'
[{"path": "app/models/foo.rb", "line": 42, "body": "指摘内容"}]
EOF
echo "{body}" | bash .claude/skills/github-pr/scripts/post-review.sh {pr_number} {sha} REQUEST_CHANGES /tmp/comments.json

# コメントのみ（REQUEST_CHANGES しない）
echo "{body}" | bash .claude/skills/github-pr/scripts/post-review.sh {pr_number} {sha} COMMENT
```

---

## 5. スレッドの resolve

inline review thread（`PRRT_...`）を resolve する。

**パラメータ:**
- `thread_id`: スレッド ID（`get-review-feedback.sh` 出力の `id` フィールド）

**出力:** `"true"`（resolve 成功時）

**実行コマンド:**
```bash
bash .claude/skills/github-pr/scripts/resolve-thread.sh {thread_id}
```

---

## 6. コメントの minimize

PR review body（`PRR_...`）や issue comment（`IC_...`）を minimize する。
inline review thread には使用しないこと（`resolve-thread.sh` を使う）。

**パラメータ:**
- `node_id`: コメントの node ID
- `--classifier`: `RESOLVED`（デフォルト）/ `OUTDATED` / `SPAM` / `ABUSE` / `OFF_TOPIC` / `DUPLICATE`

**出力:** `true`（minimize 成功時）

**実行コマンド:**
```bash
# RESOLVED（デフォルト）
bash .claude/skills/github-pr/scripts/minimize-comment.sh {node_id}

# 任意の classifier を指定
bash .claude/skills/github-pr/scripts/minimize-comment.sh {node_id} --classifier OUTDATED
```
