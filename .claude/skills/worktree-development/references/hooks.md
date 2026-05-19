# フックスクリプト仕様

リポジトリルートの `.claude/worktree-hooks/` にフックスクリプトを配置することで、
コマンド実行方法・品質チェック内容・セットアップ後の初期化をリポジトリごとに定義できる。

フックが存在しない場合はデフォルト動作にフォールバックするため、
必要なフックのみを実装すればよい。

## フック一覧

| フック | 引数 | デフォルト動作 |
|--------|------|----------------|
| `exec.sh` | `<worktree_path> <command>` | `bash -c "cd {path} && {cmd}"` で直接実行 |
| `quality-check.sh` | `<worktree_path> <changed_files>` | スキップ（exit 0） |
| `post-setup.sh` | `<worktree_path>` | 何もしない（exit 0） |

---

## `exec.sh`

worktree 内でコマンドを実行する方法を定義する。

**引数:**
- `$1` `worktree_path`: worktree のパス（例: `.worktree/idd/103`）
- `$2` `command`: 実行するコマンド

**デフォルト動作:** `bash -c "cd {worktree_path} && {command}"`

**実装例（Docker Compose 経由）:**
```bash
#!/bin/bash
WORKTREE_PATH="${1:?}"
COMMAND="${2:?}"
docker compose exec -T web bash -c "cd ${WORKTREE_PATH} && ${COMMAND}"
```

---

## `quality-check.sh`

品質チェックの内容を定義する。
変更ファイルのリストを受け取り、どのファイルをテスト対象とするかはこのフックが決定する。

**引数:**
- `$1` `worktree_path`: worktree のパス（例: `.worktree/idd/103`）
- `$2` `changed_files`: worktree で変更したファイルのリスト（スペース区切り）

**デフォルト動作:** スキップ（exit 0）

**実装例（Sorbet + Rubocop + RSpec）:**
```bash
#!/bin/bash
WORKTREE_PATH="${1:?}"
CHANGED_FILES="${2:-}"

# 変更ファイルから spec ファイルを特定するロジックをここに実装する
# ...

docker compose exec -T web bash -c "cd ${WORKTREE_PATH} && bundle exec rspec ${SPEC_FILES}"
```

---

## `post-setup.sh`

worktree 作成直後に行う初期化処理を定義する。
環境ファイルのコピーや依存関係のインストールなどに使用する。

**引数:**
- `$1` `worktree_path`: worktree のパス（例: `.worktree/idd/103`）

**デフォルト動作:** 何もしない（exit 0）

**実装例（環境ファイルのコピー）:**
```bash
#!/bin/bash
WORKTREE_PATH="${1:?}"
[ -f ".env.development" ] && cp .env.development "${WORKTREE_PATH}/.env.development"
[ -f ".env" ]             && cp .env             "${WORKTREE_PATH}/.env"
```
