# 観点①: サブ Issue 完了状況

## 目的

オーケストレーションで実行されたすべてのサブ Issue が正常に実装完了しているかを確認する。
実装が揃っていない状態で後続の観点（設計・要件・CI）を評価しても意味がないため、最初に確認する。

---

## 入力

| データ | 参照元 |
|--------|--------|
| config.yaml | worktree: `.worktree/iddue-review/{parent}/.iddue/orchestration/config.yaml` |
| 各サブ `implement.md` | worktree: `.worktree/iddue-review/{parent}/.iddue/orchestration/reports/{sub}/implement.md` |
| 各サブ Issue 本文 | Phase 2 で取得済み（`gh issue view` の結果） |

---

## 判定基準

### CRITICAL（フロー停止・COMMENT）

以下のいずれかに該当するサブ Issue が 1 件でもある場合：

| 状態 | 判定条件 |
|------|---------|
| implement.md 未存在 | worktree 上にファイルが存在しない |
| 実装失敗 | implement.md の `status` フィールドが `failed` |

### WARNING

| 状態 | 判定条件 |
|------|---------|
| status フィールド不正 | implement.md は存在するが `status` が `completed` でも `failed` でもない |

### OK

全サブ Issue の implement.md が worktree に存在し、すべての `status` が `completed`。

---

## レビューフロー

1. config.yaml から全サブ Issue 番号のリストを確認する
2. 各サブ Issue の implement.md を worktree から確認する
   - ファイルが存在しない → CRITICAL 記録
   - 存在する場合 → `status` フィールドを確認
     - `failed` → CRITICAL 記録
     - `completed` → OK
     - その他 → WARNING 記録
3. CRITICAL が 1 件でもあれば → コメント投稿してフロー終了（cleanup 実行）
4. CRITICAL なし → 次の観点へ

---

## コメントフォーマット

### 問題あり（CRITICAL）

`SKILL.md Phase 4.1` の COMMENT で投稿。`comments` は空配列（inline 紐づけ不要）。

```markdown
## AI Review — 観点①サブ Issue 完了状況

未完了または失敗しているサブ Issue があります。
実装が揃った後に再度レビューを実行してください。

| # | タイトル | 状態 | 詳細 |
|---|--------|------|-----|
| #{sub} | {title} | ❌ 失敗 | implement.md の status: failed |
| #{sub} | {title} | ❌ 未完了 | implement.md が存在しない |

{WARNING がある場合}
### 注意

| # | タイトル | 状態 | 詳細 |
|---|--------|------|-----|
| #{sub} | {title} | ⚠️ 不明 | status フィールドが不正: {値} |
```

### 問題なし（OK → 次の観点へ）

コメント投稿はしない。内部メモとして以下を記録：

```
観点① 完了状況: ✅ 全 {N} サブ Issue が completed
```
