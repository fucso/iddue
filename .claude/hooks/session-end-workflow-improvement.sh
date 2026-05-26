#!/bin/bash
# SessionEnd hook: セッション中に発生したワークフロー改善を自動的に PR として作成する
#
# 判断ロジックはすべて claude -p に委ねる。
# shell の役割は claude -p に渡す情報（変更ファイル一覧・diff・transcript_path）を整形するだけ。

set -euo pipefail

# stdin から hook 入力 JSON を受け取る
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

cd "$CWD"

# .claude/skills/** の変更ファイル一覧と差分を取得
CHANGED_FILES=$(git diff --name-only HEAD -- '.claude/skills/' 2>/dev/null || true)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard -- '.claude/skills/' 2>/dev/null || true)
ALL_CHANGED=$(printf '%s\n%s' "$CHANGED_FILES" "$UNTRACKED_FILES" | grep -v '^$' | sort -u || true)

DIFF=""
if [ -n "$ALL_CHANGED" ]; then
  DIFF=$(git diff HEAD -- '.claude/skills/' 2>/dev/null || true)
fi

claude -p "あなたはワークフロー改善の自動 PR 作成エージェントです。

## セッション情報

transcript_path: ${TRANSCRIPT_PATH}

## .claude/skills/** の現在の変更状況

### 変更・未追跡ファイル
${ALL_CHANGED:-（なし）}

### 差分
\`\`\`diff
${DIFF:-（なし）}
\`\`\`

## 指示

1. transcript_path の JSONL ファイルを Read ツールで読み、セッション中に .claude/skills/ 配下のスクリプトや SKILL.md のバグ・フロー定義の問題が発見・修正されたかを確認してください
2. 以下を **両方** 満たす場合のみ、何もせず終了してください:
   - ワークフロー改善が不要（セッション中に問題が発見・修正されていない）
   - .claude/skills/** に変更がない
3. 上記以外（ワークフロー改善あり または .claude/skills/** に変更あり）の場合:
   - main ブランチから新しいブランチを作成（命名例: fix/workflow-YYYYMMDD）
   - .claude/skills/** の変更をコミット（他のファイルはコミットしない）
   - リモートにプッシュ
   - PR を作成（トランスクリプトから読み取った「なぜこの修正が必要だったか」を PR 説明に活用する）

## スコープ

- 対象: .claude/skills/** の変更のみ
- 対象外: アプリケーションコード・idd:start で実装した成果物・その他の変更
" \
  --allowedTools "Bash,Read" \
  2>&1 || true
