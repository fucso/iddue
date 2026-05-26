# ファイル構造・ブランチ戦略・依存関係

---

## ファイル構造

```
.orchestrate/
├── config.yaml                 iddue:setup-orchestration が生成（read-only）       ✅ git 追跡
├── status.yaml                 オーケストレーターが管理・更新（read-write）          ✅ git 追跡
├── reports/
│   └── {sub-issue-number}/
│       ├── implement.md        iddue:start:worker が生成（完了シグナル + 実装サマリー）✅ git 追跡
│       └── conflict.md         complete-task.sh が生成（コンフリクト解消時のみ）     ❌ ローカルのみ
├── tasks/
│   └── {sub-issue-number}/
│       ├── judging.log         dispatch-unblocked.sh が出力（readiness 判定）       ❌ ローカルのみ
│       └── worker.log          start-worker.sh が出力（デバッグ用）                 ❌ ローカルのみ
└── escalation.yaml             オーケストレーターが exit 99 直前に書く              ❌ ローカルのみ
```

---

## ファイル所有権と git 管理方針

| ファイル | 書き込み主体 | git 管理 | 備考 |
|---------|------------|---------|------|
| `config.yaml` | `iddue:setup-orchestration` | ✅ コミット | read-only。オーケストレーション開始前に確定 |
| `status.yaml` | オーケストレーターのみ | ✅ コミット+push | 状態変化のたびに即コミット。再開可能性の根拠 |
| `reports/{sub}/implement.md` | ワーカーのみ | ✅ コミット+push | `iddue/{sub}` ブランチへ。完了検知の唯一の手段 |
| `escalation.yaml` | オーケストレーターのみ | ❌ ローカルのみ | exit 99 直前に書く。push する前に停止するため git 不要 |
| `reports/{sub}/conflict.md` | オーケストレーターのみ | ❌ ローカルのみ | コンフリクト解消時のみ生成。デバッグ用途 |
| `tasks/{sub}/judging.log` | オーケストレーターのみ | ❌ ローカルのみ | readiness チェックの stdout |
| `tasks/{sub}/worker.log` | オーケストレーターのみ | ❌ ローカルのみ | ワーカープロセスの stdout |

**所有権の原則:**
- `status.yaml` はオーケストレーターのみが書く（ワーカーは読まない）
- `implement.md` はワーカーのみが書く（オーケストレーターは読むだけ）
- 両者が同一ファイルに書き込むケースはない

---

## `status.yaml` のコミットタイミング

| タイミング | スクリプト |
|-----------|----------|
| ワーカー起動後（dispatch） | `dispatch-unblocked.sh` |
| タスク完了後（1件ごと） | `complete-task.sh` |
| 全完了・最終削除前 | `orchestrate.sh` |

---

## `.orchestrate/` の最終削除

`iddue:pr:review` によるレビュー OK 判定後、`.orchestrate/` ディレクトリを `git rm -r` で削除するコミットを追加する。最終 PR の diff に orchestration 管理ファイルが残らない。各ファイルの中間コミットは git history に残るため監査トレースは維持される。

---

## 主要ファイルの役割

### config.yaml — 依存グラフ（read-only）

`iddue:setup-orchestration` が生成。オーケストレーターはこれを読んで実行順序を決める。

```yaml
parent_issue: 123
main_issue_branch: "iddue/123"
created_at: "2026-04-30T12:00:00Z"
tasks:
  - issue: 124
    title: "API エンドポイント実装"
    dependencies: []
  - issue: 125
    title: "フロントエンド実装"
    dependencies: [124]
```

詳細: `.claude/skills/iddue:orchestration-development/templates/config-yaml.md`

### status.yaml — 実行状態（read-write）

`iddue:start:orchestrate` が管理。状態が変化するたびに commit+push される。
ScheduleWakeup で復帰したセッションがここから状態を読み込む。

```yaml
status: "in_progress"
main_issue_branch: "iddue/123"
active_tasks:
  - issue: 124
    worker_pid: 12345
completed_tasks: [125]
pending_tasks: [126]
skipped_tasks: []
failed_task: null
```

詳細: `.claude/skills/iddue:orchestration-development/templates/status-yaml.md`

### reports/{sub}/implement.md — 完了シグナル + 実装サマリー

`iddue:start:worker` が実装完了後に書き込み、サブ Issue ブランチに commit+push する。
このコミットがオーケストレーターの唯一の完了検知手段。

```bash
git log --oneline origin/iddue/{sub} -- .orchestrate/reports/{sub}/implement.md
```

詳細: `.claude/skills/iddue:orchestration-development/templates/report-md.md`

### reports/{sub}/conflict.md — コンフリクト解消ログ（発生時のみ）

`complete-task.sh` がコンフリクト解消成功後に生成。
コンフリクトが発生しなかった場合は存在しない。git 管理されないローカルファイル。

---

## ブランチ戦略

```
main
  └── iddue/{parent}          メイン Issue ブランチ（メイン Issue PR → main）
        ├── iddue/{sub1}      サブ Issue ブランチ（ワーカーが実装、orchestrate がマージ）
        ├── iddue/{sub2}      サブ Issue ブランチ
        └── iddue/{sub3}      サブ Issue ブランチ
```

- サブ Issue ブランチは `iddue/{parent}` をベースに作成される（worktree setup）
- ワーカーが実装完了後 `iddue/{sub}` に commit+push
- オーケストレーターが `iddue/{sub}` → `iddue/{parent}` へ `--no-ff` マージ
- サブ Issue に個別 PR は作らない（ミニマム設計）
- 最終的に `iddue/{parent}` のメイン Issue PR が main にマージされる

---

## 依存関係の管理

依存情報は2箇所に存在する：

| 場所 | 用途 | 更新者 |
|------|------|--------|
| Issue 本文の `Depends on: #NNN` | 人間向け（GitHub UI で閲覧） | `iddue:setup-orchestration` |
| `config.yaml` の `dependencies` | 機械読み取り（オーケストレーター） | `iddue:setup-orchestration` |

`tasks.js unblocked` は `config.yaml` の `dependencies` を参照し、`completed` または `skipped` になったタスクの依存は解消済みとして扱う。
