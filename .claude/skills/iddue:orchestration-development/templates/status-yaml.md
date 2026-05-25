# status.yaml — オーケストレーション実行状態

`iddue:start:orchestrate` が生成・更新する read-write ファイル。実行状態を管理する。

## ファイルパス

```
.orchestrate/status.yaml
```

## スキーマ

```yaml
status: "in_progress"                # pending | in_progress | completed | failed
main_issue_branch: "iddue/123"
started_at: "2026-04-30T12:00:00Z"
updated_at: "2026-04-30T12:05:00Z"

active_tasks:
  - issue: 124
    branch: "iddue/124"
    worker_pid: 12345
    started_at: "2026-04-30T12:01:00Z"

completed_tasks:
  - 125

pending_tasks:
  - 126

skipped_tasks: []

failed_task: null
error_message: null
```

## ステータス値

| status | 意味 |
|--------|------|
| `pending` | 初期化済み、ディスパッチ未開始 |
| `in_progress` | 1件以上のワーカーが稼働中 |
| `completed` | pending かつ active がゼロになった |
| `failed` | いずれかのサブ Issue が failed になった |

## タスクの状態遷移

```
pending → in_progress → completed
                     ↘ failed
pending → skipped
```

## tasks.js との対応

| tasks.js コマンド | status.yaml への影響 |
|------------------|---------------------|
| `init` | status.yaml を新規生成 |
| `start {sub} {pid}` | pending → active_tasks に追加 |
| `complete {sub}` | active_tasks から削除 → completed_tasks に追加 |
| `skip {sub}` | pending/active → skipped_tasks に追加 |
| `fail {sub} {msg}` | active → failed_task + error_message セット |

## コミットポリシー

状態が変化するたびにメイン Issue ブランチ（`iddue/{parent}`）に commit + push する。
ScheduleWakeup で復帰した際に最新状態を git から読み込める。
