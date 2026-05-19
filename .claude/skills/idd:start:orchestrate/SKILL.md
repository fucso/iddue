---
name: idd:start:orchestrate
description: |
  サブ Issue を持つ親 Issue のオーケストレーターモード実装スキル。
  idd:setup-orchestration で準備済みの config.yaml と feature branch をベースに、
  各サブ Issue を並列ワーカープロセスで実装し、完了次第メイン Issue ブランチへマージする。
argument-hint: "{親 Issue 番号}"
---

# `/idd:start:orchestrate` — オーケストレーターモード実装

サブ Issue を並列ワーカーで実装し、メイン Issue ブランチに逐次マージする。

## スクリプト

| スクリプト | 役割 | 担当 |
|---|---|---|
| [`scripts/orchestrate.sh`](scripts/orchestrate.sh) | メインループ（dispatch→wait→complete を繰り返す） | Script |
| [`scripts/dispatch-unblocked.sh`](scripts/dispatch-unblocked.sh) | unblocked タスクの readiness チェック + ワーカー起動 | Script + subprocess |
| [`scripts/wait-for-completion.sh`](scripts/wait-for-completion.sh) | active ワーカーをポーリング、最初の完了/クラッシュを検知 | Script |
| [`scripts/complete-task.sh`](scripts/complete-task.sh) | マージ + 状態更新 | Script + subprocess |
| [`scripts/start-worker.sh`](scripts/start-worker.sh) | ワーカープロセス起動 | Script |
| [`scripts/tasks.js`](scripts/tasks.js) | config.yaml / status.yaml の状態管理 | Script |
| [`scripts/report.sh`](scripts/report.sh) | 定型完了レポートを stdout に出力 | Script |
| [`scripts/check-completion.sh`](scripts/check-completion.sh) | 全タスク正常完了の判定（exit 0/1）、report.md パスを stdout 出力 | Script |

## 使い方

```
/idd:start:orchestrate {親 Issue 番号}
例: /idd:start:orchestrate 123
```

`idd:start` からサブ Issue 検出時に自動デリゲートされる。

**前提条件（`idd:setup-orchestration` で準備済み）:**
- `.idd/orchestration/config.yaml` が存在する
- メイン Issue ブランチ `idd/{parent}` が存在する

---

## 実行内容

### Phase 1: 前提確認

`.idd/orchestration/config.yaml` が存在するか確認する。
存在しない場合はエラーを表示して終了し、`idd:setup-orchestration` を案内する。

---

### Phase 2: オーケストレーションループ

以下を実行する：

```bash
bash .claude/skills/idd:start:orchestrate/scripts/orchestrate.sh {parent}
```

`orchestrate.sh` が担う処理：
- status.yaml 未存在時の初期化・コミット・push
- `dispatch-unblocked.sh` → `wait-for-completion.sh` → `complete-task.sh` のループ
- ワーカークラッシュの記録（`tasks.js fail`）と継続
- 全タスク完了後の status.yaml 最終コミット・push・`report.sh` 出力

---

### Phase 3: 結果ハンドリング

**`orchestrate_exit = 0`（正常完了）**

`report.sh` の出力はすでに stdout に表示済み。続けて以下の後処理を行う。

#### Step 1: 全完了チェック

```bash
bash .claude/skills/idd:start:orchestrate/scripts/check-completion.sh {parent}
```

- **exit 1（未完了）**: pending または judging NG が残っている。レポートの「未処理・judging NG のサブ Issue」セクションをユーザーに伝えて Issue 補完を促し、後処理はスキップして終了する。
- **exit 0（全完了）**: stdout に完了タスクの `report.md` パスが出力される。Step 2 へ進む。

#### Step 2: 設計逸脱チェック（agent による判定）

以下を参照し、元の設計から逸脱があったかを第三者目線で判定する。

**参照資料:**

| 資料 | 内容 |
|------|------|
| `.idd/issue/{parent}.yaml` | 親 Issue の元設計・要件 |
| `.idd/orchestration/config.yaml` | タスク定義と依存グラフ |
| Step 1 で出力された各 `report.md` | ワーカーの実装報告 |

**逸脱と判定する例:**
- 実装アプローチを元設計から変更した
- スコープ（対象ファイル・機能）を追加または削除した
- インターフェース・データ構造の設計を変更した

**逸脱と判定しない例:**
- テストの追加・充実
- 実装範囲内の軽微なリファクタリング
- コメントや命名の改善

**逸脱が見つかった場合:** `gh issue comment` で親 Issue にコメントを追加する。

```bash
REPO=$(bash .claude/skills/github-pr/scripts/get-repo.sh)
gh issue comment {parent} --repo "${REPO}" --body "$(cat <<'EOF'
## 実装における設計からの変更点

### #{sub}: {title}
{変更内容と理由の説明}

### #{sub}: {title}
{変更内容と理由の説明}
EOF
)"
```

複数サブ Issue に逸脱がある場合は1件のコメントにまとめる。

**逸脱がなかった場合:** 何もしない。

#### Step 3: 後処理

PR をドラフト解除する：

```bash
REPO=$(bash .claude/skills/github-pr/scripts/get-repo.sh)
PR_URL=$(gh pr list --head "idd/{parent}" --repo "${REPO}" --json url --jq '.[0].url')
gh pr ready "$PR_URL"
echo "PR ドラフト解除: $PR_URL"
```

ユーザーへ完了を報告する。

---

**`orchestrate_exit = 99`（エスカレーション）**

`.idd/orchestration/escalation.yaml` を読み、原因を分析する：

```yaml
reason: "{理由}"
detail: "{詳細}"
log: "{ログパス}"   # あれば
```

#### 原因別の対処

| reason | 意味 | 対処方針 |
|---|---|---|
| `worker-crashed` | ワーカープロセスが予期せず終了 | ログを確認し再試行可能か判断 |
| `conflict-resolution-failed` | AI によるコンフリクト解消が失敗 | コンフリクト内容を確認し手動解消を試みる |
| `merge-failed` | git merge 自体が失敗 | git ログを確認し原因を修正 |
| `before-merge-hook-aborted` | before-merge フックが意図的に中断 | フックログを確認しユーザーに報告 |
| `task-failed-during-execution` | ワーカークラッシュが記録されたままループ終了 | 他の完了タスクの状況を確認して判断 |

#### 継続可否の判断

以下の観点で「他のサブ Issue でサイクルを継続できるか」を判断する：

1. `status.yaml` を確認し、完了済み・進行中・未着手のタスクを把握する
2. 失敗した sub issue が他のタスクのブロッカーになっていないか確認する
3. 失敗した sub issue を除いても全体の目的が達成できるか判断する

**継続可能と判断した場合：**

問題の sub issue の状態を修正し、`orchestrate.sh` を再起動する。

```bash
# 例: クラッシュした sub issue をスキップして継続
node .claude/skills/idd:start:orchestrate/scripts/tasks.js skip {sub} "crashed-skipped"
# failed_task と error_message をクリア（status.yaml を直接編集）
bash .claude/skills/idd:start:orchestrate/scripts/orchestrate.sh {parent}
```

**継続不可能と判断した場合：**

ユーザーに以下を報告して停止する：
- 発生した問題の概要
- 現在の完了済みタスク
- 推奨アクション（再設計・手動対応・中止）

---

## エラーハンドリング早見表

| 状況 | orchestrate.sh の動作 | agent の対応 |
|---|---|---|
| ワーカークラッシュ | `tasks.js fail` → ループ継続 → 完了後 exit 99 | 継続可能か判断 → 再起動 or ユーザー報告 |
| マージ失敗 | exit 99 即時 | 原因修正 → 再起動 or ユーザー報告 |
| コンフリクト解消失敗 | exit 99 即時 | 手動解消 → 再起動 or ユーザー報告 |
| フック中断 | exit 99 即時 | ユーザーに報告して停止 |
| pending/judging NG が残る | `report.sh` → exit 0 | レポートの未処理・judging NG セクションを確認しユーザーに報告 |
