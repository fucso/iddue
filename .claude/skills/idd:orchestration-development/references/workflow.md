# 全体ワークフロー

スキルの呼び出し順と、各呼び出しによる状態変化を示す。

---

## スキルと状態変化

### STAGE 1: 設計フェーズ

| スキル | 状態変化 |
|--------|---------|
| `/idd:open:concrete` | GitHub: 親 Issue + サブ Issue を起票 |
| `/idd:setup-orchestration {parent}` | ブランチ: `idd/{parent}` 作成・push<br>PR: `idd/{parent}` → develop（ドラフト）作成<br>`.idd/orchestration/config.yaml` 生成・commit<br>各サブ Issue YAML: `parent.linked_pr.branch` をセット |

### STAGE 2: 実装フェーズ

| スキル / タイミング | 状態変化 |
|-------------------|---------|
| `/idd:start:orchestrate`（初回起動） | `.idd/orchestration/status.yaml` 初期化・commit+push<br>ブロックなしサブ Issue を並列ディスパッチ |
| `/idd:start:worker {sub}` | ブランチ: `idd/{sub}` 作成（base: `idd/{parent}`）<br>実装完了後 `idd/{sub}` に commit+push<br>`.idd/orchestration/reports/{sub}/implement.md` commit+push |
| implement.md 検知後（orchestrate） | `idd/{sub}` → `idd/{parent}` マージ<br>`status.yaml` 更新・commit+push<br>コンフリクト発生時は `reports/{sub}/conflict.md` も追加<br>依存解除されたサブ Issue があれば次ワーカーをディスパッチ |
| 全サブ Issue 完了（orchestrate） | PR をドラフト解除・完了レポート出力 |

---

## フロー図

```mermaid
flowchart TD
    A["/idd:open:concrete"] -->|"GitHub: 親+サブ Issue 作成"| B["/idd:setup-orchestration"]
    B -->|"idd/parent ブランチ作成・push\nPR作成（ドラフト）\nconfig.yaml commit"| D["/idd:start:orchestrate"]
    D -->|"status.yaml 初期化・commit"| E["ブロックなしサブ Issue を\n並列ディスパッチ"]

    E -->|"/idd:start:worker 起動"| F["idd/sub ブランチ作成\n実装・commit+push\nreports/sub/implement.md commit+push"]

    F -->|"implement.md 検知:\nidd/sub → idd/parent マージ\nstatus.yaml 更新・commit+push"| G{"依存解除された\nサブ Issue あり?"}

    G -->|"Yes"| E
    G -->|"No"| H{"全サブ Issue\n完了?"}
    H -->|"No（他ワーカー待機中）"| I["ScheduleWakeup\n（完了を待機）"]
    I --> G
    H -->|"Yes"| J["PR ドラフト解除\n完了レポート出力"]
```
