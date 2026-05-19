# 提供機能

## environment_name の指定方法

すべてのスクリプトで使用する `environment_name` は、`.worktree/` からの相対パスで指定する。

**例:**
- worktree パス: `.worktree/my-feature/task-01`
- environment_name: `my-feature/task-01`

```bash
# 正しい例
bash .claude/skills/worktree-development/scripts/setup.sh "my-feature/task-01" develop

# 間違った例（.worktree/ は不要）
bash .claude/skills/worktree-development/scripts/setup.sh ".worktree/my-feature/task-01" develop
```

---

## 1. 作業環境の準備

独立した git worktree 環境を作成する。
`environment_name` と同名のブランチを作成し、worktree をそのブランチに紐づける。
同名ブランチが既存の場合はそのブランチの最新コミットから開始する。
作成後に `post-setup` フックを呼び出す。

**パラメータ:**
- `environment_name`: 作業環境の識別名（`.worktree/` からの相対パス、ブランチ名としても使用される）
- `branch`: ベースとなるブランチ名（`environment_name` ブランチが存在しない場合のみ使用）

**実行コマンド:**
```bash
bash .claude/skills/worktree-development/scripts/setup.sh {environment_name} {branch}
```

**スクリプト**: [../scripts/setup.sh](../scripts/setup.sh)

---

## 2. 作業環境内でのコマンド実行

`exec` フック経由でコマンドを実行する。
フックが存在しない場合は worktree ディレクトリ内で直接実行する。

**パラメータ:**
- `environment_name`: 作業環境の識別名
- `command`: 実行するコマンド

**実行コマンド:**
```bash
bash .claude/skills/worktree-development/scripts/exec.sh {environment_name} "{command}"
```

**スクリプト**: [../scripts/exec.sh](../scripts/exec.sh)

---

## 3. 品質チェック

`quality-check` フック経由で品質チェックを実行する。
フックが存在しない場合はスキップする。

**パラメータ:**
- `environment_name`: 作業環境の識別名
- `changed_files`: worktree で変更したファイルのリスト（スペース区切り、省略可）

どのファイルをテスト対象とするかはリポジトリ固有の `quality-check` フックが決定する。

**実行コマンド:**
```bash
# 変更ファイルの取得
bash .claude/skills/worktree-development/scripts/exec.sh {environment_name} "git diff --name-only"

# 品質チェック実行（取得した変更ファイルをそのまま渡す）
bash .claude/skills/worktree-development/scripts/quality-check.sh {environment_name} "{changed_files}"
```

**スクリプト**: [../scripts/quality-check.sh](../scripts/quality-check.sh)

---

## 4. コミット

変更をコミットする。

**パラメータ:**
- `environment_name`: 作業環境の識別名
- `commit_message`: コミットメッセージ
- `branch_name`: （オプション）新しいブランチ名

**実行コマンド:**
```bash
bash .claude/skills/worktree-development/scripts/commit.sh {environment_name} "{commit_message}" [branch_name]
```

**スクリプト**: [../scripts/commit.sh](../scripts/commit.sh)

---

## 5. プッシュ

作業環境のコミットをリモートにプッシュする。

worktree は named branch で動作するため、クリーンアップ後もローカルブランチにコミットは保持される。
プッシュはリモートへの公開・CI 実行・他環境との共有が必要な場合に使用する。

**パラメータ:**
- `environment_name`: 作業環境の識別名
- `branch`: プッシュ先のブランチ名

**実行コマンド:**
```bash
bash .claude/skills/worktree-development/scripts/push.sh {environment_name} {branch}
```

**スクリプト**: [../scripts/push.sh](../scripts/push.sh)

---

## 6. クリーンアップ

作業環境を削除する。**作業完了後は必ず実行すること。**

**パラメータ:**
- `environment_name`: 作業環境の識別名

**実行コマンド:**
```bash
bash .claude/skills/worktree-development/scripts/cleanup.sh {environment_name}
```

**スクリプト**: [../scripts/cleanup.sh](../scripts/cleanup.sh)
