# トラブルシューティング

`idd:start:orchestrate` / `idd:start:worker` の一般的な問題と対処法。

## オーケストレーター側

### config.yaml が見つからない

```
Config file not found: .idd/orchestration/config.yaml
```

**原因:** `idd:setup-orchestration` が完了していない。

**対処:** `idd:setup-orchestration {parent}` を実行してから再度 `/idd:start:orchestrate {parent}` を実行する。

---

### ScheduleWakeup 復帰後に status.yaml が古い

**原因:** status.yaml の commit+push が失敗している可能性がある。

**対処:**

```bash
git fetch origin "idd/{parent}"
git log --oneline "origin/idd/{parent}" -- .idd/orchestration/status.yaml
```

コミット履歴がない場合は status.yaml を手動でコミット：

```bash
git checkout "idd/{parent}"
git add .idd/orchestration/status.yaml
git commit -m "orchestration: recover status.yaml"
git push origin "idd/{parent}"
```

---

### コンフリクト（complete-task.sh 終了コード 5）

**対処:**

1. コンフリクトしているファイルを確認：
   ```bash
   git diff --name-only --diff-filter=U
   ```

2. AI がコンフリクトを解消し、修正をコミット：
   ```bash
   git add {resolved-files}
   git commit -m "Merge sub-issue #{sub} into idd/{parent} (conflict resolved)"
   git push origin "idd/{parent}"
   ```

3. 解消が困難な場合はユーザーに報告して停止。

---

### ワーカーがクラッシュ（CRASHED:{sub}）

**対処:**

1. ログを確認：
   ```bash
   cat .idd/orchestration/tasks/{sub}/worker.log
   ```

2. エラー内容を確認して再実行を検討：
   ```bash
   node tasks.js fail {sub} "crash: {error-summary}"
   ```

3. 再実行が適切な場合は手動でワーカーを起動し、`tasks.js start {sub} {new-pid}` で登録。

---

## ワーカー側

### setupBranch が取得できない

**原因:** `idd:setup-orchestration` で `parent.linked_pr.branch` が設定されていない。

**対処:** `idd:fetch-issue {sub} force:true` の出力を確認。
`parent.linked_pr.branch` が空なら `idd:setup-orchestration` からやり直す。

---

### finalize.sh が失敗する

**原因:** リモートへの push 権限、またはブランチ保護ルール。

**対処:**

```bash
git push origin "idd/{sub}" --force-with-lease
```

force-with-lease で解消しない場合はオーケストレーターに報告する。

---

### implement.md が検知されない

**原因:** ワーカーの Step 6 が失敗している可能性がある。

**確認:**

```bash
git log --oneline "origin/idd/{sub}" -- .idd/orchestration/reports/{sub}/implement.md
```

コミットがない場合はワーカーの worker.log を確認し、Step 6 を手動で再実行。

---

## 手動リカバリー

### タスクを強制完了にする

実装は完了しているがオーケストレーターが検知しない場合：

```bash
node .claude/skills/idd:start:orchestrate/scripts/tasks.js complete {sub}
git add .idd/orchestration/status.yaml
git commit -m "orchestration: manually complete #${sub}"
git push origin "idd/{parent}"
```

### タスクをスキップする

実装を諦めてスキップする場合：

```bash
node .claude/skills/idd:start:orchestrate/scripts/tasks.js skip {sub}
git add .idd/orchestration/status.yaml
git commit -m "orchestration: skip #${sub}"
git push origin "idd/{parent}"
```
