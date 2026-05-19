# フックスクリプト仕様

リポジトリルートの `.claude/orchestration-hooks/` にフックスクリプトを配置することで、
並列実装ワークフローの特定処理をリポジトリごとにカスタマイズできる。

フックが存在しない場合はデフォルト動作にフォールバックするため、
必要なフックのみを実装すればよい。

## フック一覧

| フック | 引数 | デフォルト動作 |
|--------|------|----------------|
| `before-merge.sh` | `<sub-issue-number> <sub-branch> <main-branch>` | スキップ（ファイルが存在しない場合） |

---

## `before-merge.sh`

**実行タイミング:** ワーカーブランチ（`idd/{sub}`）をメイン Issue ブランチ（`idd/{parent}`）にマージする直前

**引数:**
- `$1` `sub_issue_number`: サブ Issue 番号（例: `105`）
- `$2` `sub_branch`: サブ Issue ブランチ名（例: `idd/105`）
- `$3` `main_branch`: メイン Issue ブランチ名（例: `idd/103`）

**終了コード:**
- `0`: マージを続行する
- `非0`: マージを中断する（オーケストレーターはエラーを報告して停止）

**実装例（AI コードレビューの自動実行）:**
```bash
#!/bin/bash
SUB_ISSUE="${1:?}"
SUB_BRANCH="${2:?}"
MAIN_BRANCH="${3:?}"

# AI レビューを実行し、重大な指摘があればマージを中断する
# ...
exit 0
```

**実装例（PR 作成 + 承認待ち）:**
```bash
#!/bin/bash
SUB_ISSUE="${1:?}"
SUB_BRANCH="${2:?}"
MAIN_BRANCH="${3:?}"

# PR を作成して承認を待つ
gh pr create --base "${MAIN_BRANCH}" --head "${SUB_BRANCH}" --title "Sub-issue #${SUB_ISSUE}"
# 承認を待機する処理...
exit 0
```
