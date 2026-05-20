# フックスクリプト仕様

リポジトリルートの `.claude/iddue-hooks/` にフックスクリプトを配置することで、
IDDUE ワークフローの特定処理をリポジトリごとにカスタマイズできる。

フックが存在しない場合はデフォルト動作にフォールバックするため、
必要なフックのみを実装すればよい。

## フック一覧

| フック | 引数 | デフォルト動作 |
|--------|------|----------------|
| `get-ci-failure-details.sh` | `<pr_number> <head_sha> <failed_checks_json_file>` | 何も出力しない（exit 0） |

---

## `get-ci-failure-details.sh`

**実行タイミング:** `iddue:pr:review` の観点④（CI ステータス）で CI 失敗が検出されたとき、
アノテーションを補完するための詳細ログを取得する。

**引数:**

- `$1` `pr_number`: PR 番号（例: `123`）
- `$2` `head_sha`: HEAD コミット SHA（例: `abc1234...`）
- `$3` `failed_checks_json_file`: 失敗した CI チェックの情報が含まれる JSON ファイルのパス

  ファイルの中身（`gh pr checks --json` の失敗分のみを絞り込み、GitHub annotations を付与した形式）:
  ```json
  [
    {
      "name": "rspec",
      "conclusion": "FAILURE",
      "link": "https://example-ci.com/builds/10295",
      "annotations": [
        {
          "path": "spec/models/user_spec.rb",
          "start_line": 42,
          "annotation_level": "failure",
          "message": "expected true, got false"
        }
      ]
    }
  ]
  ```

**出力:**

- **stdout**: CI 失敗の詳細テキスト（自然言語。Claude がそのままレビューコメント生成に使う）
- **exit 0**: 詳細取得成功 または フックなし（スキップ）
- **exit 1**: 詳細取得失敗（CI プロバイダーへの接続エラー等）

**デフォルト動作:** フックが存在しない場合は何も出力せず exit 0。アノテーション情報のみで Claude が判断する。

**実装例（Buildkite）:**

```bash
#!/bin/bash
set -euo pipefail

PR_NUMBER="${1:?}"
HEAD_SHA="${2:?}"
FAILED_CHECKS_JSON_FILE="${3:?}"

ORG="your-org"
PIPELINE="your-pipeline"

BUILD_URL=$(jq -r '.[] | select(.conclusion == "FAILURE") | .link' "${FAILED_CHECKS_JSON_FILE}" | head -1)
[ -z "${BUILD_URL}" ] && exit 0

BUILD_NUMBER=$(echo "${BUILD_URL}" | grep -o '[0-9]*$')

echo "## CI 失敗詳細 (Buildkite #${BUILD_NUMBER})"
echo ""

curl -s \
  "https://api.buildkite.com/v2/organizations/${ORG}/pipelines/${PIPELINE}/builds/${BUILD_NUMBER}" \
  -H "Authorization: Bearer ${BUILDKITE_API_TOKEN}" \
  | jq -c '.jobs[] | select(.state == "failed") | {id, name}' \
  | while read -r JOB; do
    JOB_ID=$(echo "${JOB}" | jq -r '.id')
    JOB_NAME=$(echo "${JOB}" | jq -r '.name')

    echo "### ${JOB_NAME}"
    echo ""
    curl -s \
      "https://api.buildkite.com/v2/organizations/${ORG}/pipelines/${PIPELINE}/builds/${BUILD_NUMBER}/jobs/${JOB_ID}/log" \
      -H "Authorization: Bearer ${BUILDKITE_API_TOKEN}" \
      | jq -r '.content' | tail -80
    echo ""
  done
```
