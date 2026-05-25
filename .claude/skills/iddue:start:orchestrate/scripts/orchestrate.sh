#!/bin/bash
# orchestrate.sh - オーケストレーションメインループ
#
# Usage: bash orchestrate.sh <parent-issue-number>
#
# 終了コード:
#   0: 全タスク正常完了
#   99: エスカレーション要（.orchestrate/escalation.yaml に詳細）

set -uo pipefail

PARENT="${1:?Usage: $0 <parent-issue-number>}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
MAIN_BRANCH="iddue/${PARENT}"
ESCALATION_FILE=".orchestrate/escalation.yaml"

REPO_ROOT=$(git -C "$SCRIPTS" rev-parse --show-toplevel)
cd "$REPO_ROOT"

# エスカレーション: escalation.yaml を書いて exit 99
escalate() {
  local reason="$1"
  local detail="${2:-}"
  local log_path="${3:-}"
  {
    echo "reason: \"${reason}\""
    echo "detail: \"${detail}\""
    [ -n "$log_path" ] && echo "log: \"${log_path}\""
  } > "$ESCALATION_FILE"
  exit 99
}

# ── Phase 1: 初期化 ────────────────────────────────────────────────────────────

if [ ! -f ".orchestrate/config.yaml" ]; then
  echo "Error: .orchestrate/config.yaml が見つかりません。iddue:setup-orchestration を先に実行してください。" >&2
  exit 1
fi

if [ ! -f ".orchestrate/status.yaml" ]; then
  node "$SCRIPTS/tasks.js" init "$PARENT"
  git add .orchestrate/status.yaml
  git commit -m "orchestration: initialize status.yaml for #${PARENT}"
  git push origin "$MAIN_BRANCH"
fi

# ── Phase 2+3: ディスパッチ → 監視ループ ──────────────────────────────────────

while true; do
  bash "$SCRIPTS/dispatch-unblocked.sh" "$PARENT"

  ACTIVE=$(node "$SCRIPTS/tasks.js" active)
  UNBLOCKED=$(node "$SCRIPTS/tasks.js" unblocked)

  # active も unblocked もなければループ終了（全完了 or 全依存待ち or 全 judging NG）
  [ -z "$ACTIVE" ] && [ -z "$UNBLOCKED" ] && break

  # unblocked があるのに active がない = dispatch したが全タスクが judging NG で起動できなかった
  [ -z "$ACTIVE" ] && break

  # いずれか1つの完了/クラッシュを待つ
  result=""
  wait_exit=0
  result=$(bash "$SCRIPTS/wait-for-completion.sh" "$PARENT") || wait_exit=$?
  sub="${result#*:}"

  case $wait_exit in
    0)  # COMPLETED
      complete_exit=0
      bash "$SCRIPTS/complete-task.sh" "$sub" "$PARENT" || complete_exit=$?
      case $complete_exit in
        0) ;;
        2) escalate "before-merge-hook-aborted" \
             "sub=#${sub}" \
             ".orchestrate/tasks/${sub}/worker.log" ;;
        3) escalate "merge-failed" \
             "sub=#${sub}" \
             ".orchestrate/tasks/${sub}/worker.log" ;;
        5) escalate "conflict-resolution-failed" \
             "sub=#${sub}" \
             ".orchestrate/reports/${sub}/conflict.md" ;;
        *) escalate "complete-task-unexpected-error" \
             "sub=#${sub}, exit_code=${complete_exit}" ;;
      esac
      ;;
    1)  # CRASHED: 記録してループ継続（他タスクがあれば処理を続ける）
      node "$SCRIPTS/tasks.js" fail "$sub" "worker-crashed"
      ;;
    2)  # 監視対象なし（start 直後に active が消えた場合）
      continue
      ;;
  esac
done

# ── Phase 4: 完了処理 ──────────────────────────────────────────────────────────

# 失敗タスクが残っていたらエスカレーション
STATUS_OUT=$(node "$SCRIPTS/tasks.js" status)
FAILED_TASK=$(echo "$STATUS_OUT" | grep "^failed_task:" | grep -v "null" | awk '{print $2}' || true)

if [ -n "$FAILED_TASK" ]; then
  escalate "task-failed-during-execution" \
    "failed_task=#${FAILED_TASK}, see .orchestrate/status.yaml"
fi

# status.yaml 最終コミット
git add .orchestrate/status.yaml
git commit -m "orchestration: finalize #${PARENT}" 2>/dev/null || true
git push origin "$MAIN_BRANCH"

# .orchestrate/ を削除して最終 PR diff から除外
git rm -r .orchestrate/
git commit -m "orchestration: remove .orchestrate/ after completion of #${PARENT}"
git push origin "$MAIN_BRANCH"

# 定型レポート出力
bash "$SCRIPTS/report.sh" "$PARENT"
exit 0
