#!/usr/bin/env node
// iddue issue YAML から branch 情報を抽出する
// 外部依存なし - Node.js 組み込みモジュールのみ使用
//
// Usage: node get-branch-info.js <issue_number>
// Output: JSON { taskBranch, setupBranch }
//
//   taskBranch  - 実装ブランチ名（issue.linked_pr.branch が存在すればその値、なければ "iddue/{issue_number}"）
//   setupBranch - setup.sh に渡すブランチ
//                   既存ブランチ（issue.linked_pr.branch あり）→ taskBranch（リモートから fetch）
//                   新規ブランチ（issue.linked_pr.branch なし）→ フォーク元ブランチ（parent.linked_pr.branch または "develop"）

'use strict';

const fs = require('fs');

const issueNumber = process.argv[2];
if (!issueNumber) {
  process.stderr.write('Usage: node get-branch-info.js <issue_number>\n');
  process.exit(1);
}

const yamlPath = `.iddue/issue/${issueNumber}.yaml`;
let content;
try {
  content = fs.readFileSync(yamlPath, 'utf8');
} catch {
  process.stderr.write(`File not found: ${yamlPath}\n`);
  process.exit(1);
}

// インデントベースのスタックで YAML を辿り、指定した dot-path の値を返す。
// 対象: iddue:fetch-issue が生成する 2-space インデント・ダブルクォート文字列形式。
// 値が存在しない（キー自体がない、またはキーに値がない）場合は null を返す。
function extract(text, ...path) {
  const stack = []; // [{ indent: number, key: string }]

  for (const raw of text.split('\n')) {
    if (!raw.trim() || raw.trim().startsWith('#')) continue;

    const indent = raw.search(/\S/);
    const rest = raw.trim();
    const colonIdx = rest.indexOf(':');
    if (colonIdx === -1) continue;

    const k = rest.slice(0, colonIdx).trim();
    const v = rest.slice(colonIdx + 1).trim().replace(/^["']|["']$/g, '') || null;

    // 現在のインデント以上のスタックエントリを除去
    while (stack.length > 0 && stack[stack.length - 1].indent >= indent) {
      stack.pop();
    }
    stack.push({ indent, key: k });

    const currentPath = stack.map(s => s.key);
    if (
      currentPath.length === path.length &&
      currentPath.every((p, i) => p === path[i]) &&
      v !== null
    ) {
      return v;
    }
  }
  return null;
}

const existingBranch = extract(content, 'issue', 'linked_pr', 'branch');
const taskBranch     = existingBranch ?? `iddue/${issueNumber}`;
const forkBranch     = extract(content, 'parent', 'linked_pr', 'branch') ?? 'develop';
const setupBranch    = existingBranch !== null ? taskBranch : forkBranch;

process.stdout.write(
  JSON.stringify({ taskBranch, setupBranch }) + '\n'
);
