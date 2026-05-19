# ファイル構造・ブランチ戦略・依存関係

---

## ファイル構造

```
.idd/
└── orchestration/                  git commit して main issue PR に含まれる
    ├── config.yaml                 idd:setup-orchestration が生成（read-only）
    ├── status.yaml                 idd:start:orchestrate が生成・更新（read-write）
    ├── reports/
    │   └── {sub-issue-number}/
    │       ├── implement.md        idd:start:worker が生成（完了シグナル + 実装サマリー）
    │       └── conflict.md         complete-task.sh が生成（コンフリクト解消時のみ）
    └── tasks/
        └── {sub-issue-number}/
            ├── judging.log         dispatch-unblocked.sh が出力（readiness 判定）
            └── worker.log          start-worker.sh が出力（デバッグ用）
```

---

## 主要ファイルの役割

### config.yaml — 依存グラフ（read-only）

`idd:setup-orchestration` が生成。オーケストレーターはこれを読んで実行順序を決める。

```yaml
parent_issue: 123
main_issue_branch: "idd/123"
created_at: "2026-04-30T12:00:00Z"
tasks:
  - issue: 124
    title: "API エンドポイント実装"
    dependencies: []
  - issue: 125
    title: "フロントエンド実装"
    dependencies: [124]
```

詳細: `.claude/skills/idd:orchestration-development/templates/config-yaml.md`

### status.yaml — 実行状態（read-write）

`idd:start:orchestrate` が管理。状態が変化するたびに commit+push される。
ScheduleWakeup で復帰したセッションがここから状態を読み込む。

```yaml
status: "in_progress"
main_issue_branch: "idd/123"
active_tasks:
  - issue: 124
    worker_pid: 12345
completed_tasks: [125]
pending_tasks: [126]
skipped_tasks: []
failed_task: null
```

詳細: `.claude/skills/idd:orchestration-development/templates/status-yaml.md`

### reports/{sub}/implement.md — 完了シグナル + 実装サマリー

`idd:start:worker` が実装完了後に書き込み、サブ Issue ブランチに commit+push する。
このコミットがオーケストレーターの唯一の完了検知手段。

```bash
git log --oneline origin/idd/{sub} -- .idd/orchestration/reports/{sub}/implement.md
```

詳細: `.claude/skills/idd:orchestration-development/templates/report-md.md`

### reports/{sub}/conflict.md — コンフリクト解消ログ（発生時のみ）

`complete-task.sh` がコンフリクト解消成功後に `resolve-conflict.log` を移動して生成。
コンフリクトが発生しなかった場合は存在しない。

---

## ブランチ戦略

```
develop
  └── idd/{parent}          メイン Issue ブランチ（メイン Issue PR → develop）
        ├── idd/{sub1}      サブ Issue ブランチ（ワーカーが実装、orchestrate がマージ）
        ├── idd/{sub2}      サブ Issue ブランチ
        └── idd/{sub3}      サブ Issue ブランチ
```

- サブ Issue ブランチは `idd/{parent}` をベースに作成される（worktree setup）
- ワーカーが実装完了後 `idd/{sub}` に commit+push
- オーケストレーターが `idd/{sub}` → `idd/{parent}` へ `--no-ff` マージ
- サブ Issue に個別 PR は作らない（ミニマム設計）
- 最終的に `idd/{parent}` のメイン Issue PR が develop にマージされる

---

## 依存関係の管理

依存情報は2箇所に存在する：

| 場所 | 用途 | 更新者 |
|------|------|--------|
| Issue 本文の `Depends on: #NNN` | 人間向け（GitHub UI で閲覧） | `idd:setup-orchestration` |
| `config.yaml` の `dependencies` | 機械読み取り（オーケストレーター） | `idd:setup-orchestration` |

`tasks.js unblocked` は `config.yaml` の `dependencies` を参照し、`completed` または `skipped` になったタスクの依存は解消済みとして扱う。
