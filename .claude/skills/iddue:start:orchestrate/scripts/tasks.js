#!/usr/bin/env node
// tasks.js - IDD オーケストレーション状態管理
//
// データソース:
//   .iddue/orchestration/config.yaml  (依存グラフ、read-only)
//   .iddue/orchestration/status.yaml  (実行状態、read-write)
//
// サブコマンド:
//   unblocked              pending かつブロックなしの issue 番号を改行区切りで出力
//   active                 in_progress の issue 一覧（issue:pid 形式）を出力
//   start <issue> <pid>    pending → in_progress
//   complete <issue>       in_progress → completed
//   fail <issue> <msg>     → failed
//   status                 status.yaml の内容を出力
//   init <main-issue-branch>  status.yaml を初期化（config.yaml が必要）

'use strict';

const fs = require('fs');
const path = require('path');

// ──────────────────────────────────────────────
// YAML パーサー（シンプルな構造のみ対応）
// ──────────────────────────────────────────────

function parseYAML(content) {
  const lines = content.split('\n');
  const result = {};
  let currentKey = null;
  let currentArray = null;
  let currentArrayIndent = -1;
  let currentArrayItem = null;
  let currentSubArrayProp = null;

  for (const line of lines) {
    if (line.trim() === '' || line.trim().startsWith('#')) continue;

    const indent = line.match(/^( *)/)[0].length;
    const trimmed = line.trim();

    if (indent === 0) {
      if (trimmed.endsWith(':')) {
        currentKey = trimmed.slice(0, -1);
        result[currentKey] = undefined;
        currentArray = null;
        currentArrayIndent = -1;
        currentArrayItem = null;
        currentSubArrayProp = null;
      } else if (trimmed.includes(':')) {
        const colonIdx = trimmed.indexOf(':');
        const key = trimmed.slice(0, colonIdx).trim();
        const value = trimmed.slice(colonIdx + 1).trim();
        result[key] = parseValue(value);
        currentKey = key;
        currentArray = null;
        currentArrayIndent = -1;
        currentArrayItem = null;
        currentSubArrayProp = null;
      }
    } else if (trimmed.startsWith('- ')) {
      if (currentArrayItem && currentSubArrayProp !== null && indent > currentArrayIndent) {
        const itemContent = trimmed.slice(2).trim();
        currentArrayItem[currentSubArrayProp].push(parseValue(itemContent));
      } else {
        if (!currentArray) {
          currentArray = [];
          result[currentKey] = currentArray;
          currentArrayIndent = indent;
        }
        const itemContent = trimmed.slice(2).trim();
        if (itemContent.includes(':')) {
          currentSubArrayProp = null;
          currentArrayItem = {};
          const colonIdx = itemContent.indexOf(':');
          const key = itemContent.slice(0, colonIdx).trim();
          const value = itemContent.slice(colonIdx + 1).trim();
          currentArrayItem[key] = parseValue(value);
          currentArray.push(currentArrayItem);
        } else {
          currentArray.push(parseValue(itemContent));
          currentArrayItem = null;
          currentSubArrayProp = null;
        }
      }
    } else if (currentArrayItem && trimmed.includes(':')) {
      const colonIdx = trimmed.indexOf(':');
      const key = trimmed.slice(0, colonIdx).trim();
      const value = trimmed.slice(colonIdx + 1).trim();
      if (value === '') {
        currentSubArrayProp = key;
        currentArrayItem[key] = [];
      } else {
        currentSubArrayProp = null;
        currentArrayItem[key] = parseValue(value);
      }
    }
  }

  return result;
}

function parseValue(value) {
  if (value === '' || value === 'null' || value === '~') return null;
  if (value === 'true') return true;
  if (value === 'false') return false;
  if (/^-?\d+$/.test(value)) return parseInt(value, 10);
  if (value.startsWith('"') && value.endsWith('"')) return value.slice(1, -1);
  if (value.startsWith("'") && value.endsWith("'")) return value.slice(1, -1);
  if (value === '[]') return [];
  if (value.startsWith('[') && value.endsWith(']')) {
    const inner = value.slice(1, -1).trim();
    if (inner === '') return [];
    return inner.split(',').map(v => parseValue(v.trim()));
  }
  return value;
}

// ──────────────────────────────────────────────
// YAML シリアライザー
// ──────────────────────────────────────────────

function statusToYAML(status) {
  const now = new Date().toISOString();

  let yaml = `status: ${status.status || 'pending'}\n`;
  yaml += `main_issue_branch: "${status.main_issue_branch}"\n`;
  yaml += `started_at: "${status.started_at || now}"\n`;
  yaml += `updated_at: "${now}"\n`;
  yaml += '\n';

  yaml += `active_tasks:\n`;
  if (status.active_tasks && status.active_tasks.length > 0) {
    for (const task of status.active_tasks) {
      yaml += `  - issue: ${task.issue}\n`;
      yaml += `    branch: "iddue/${task.issue}"\n`;
      yaml += `    worker_pid: ${task.worker_pid}\n`;
      yaml += `    started_at: "${task.started_at}"\n`;
    }
  }
  yaml += '\n';

  yaml += `completed_tasks:\n`;
  if (status.completed_tasks && status.completed_tasks.length > 0) {
    for (const issue of status.completed_tasks) {
      yaml += `  - ${issue}\n`;
    }
  }
  yaml += '\n';

  yaml += `pending_tasks:\n`;
  if (status.pending_tasks && status.pending_tasks.length > 0) {
    for (const issue of status.pending_tasks) {
      yaml += `  - ${issue}\n`;
    }
  }
  yaml += '\n';

  yaml += `skipped_tasks:\n`;
  if (status.skipped_tasks && status.skipped_tasks.length > 0) {
    for (const issue of status.skipped_tasks) {
      yaml += `  - ${issue}\n`;
    }
  }

  if (status.failed_task != null) {
    yaml += `\nfailed_task: ${status.failed_task}\n`;
    yaml += `error_message: "${status.error_message || ''}"\n`;
  } else {
    yaml += `\nfailed_task: null\n`;
    yaml += `error_message: null\n`;
  }

  return yaml;
}

// ──────────────────────────────────────────────
// ヘルパー
// ──────────────────────────────────────────────

function getRepoRoot() {
  const { execSync } = require('child_process');
  return execSync('git rev-parse --show-toplevel', { encoding: 'utf-8' }).trim();
}

function findUnblockedTasks(config, status) {
  const completed = new Set((status.completed_tasks || []).map(Number));
  const skipped   = new Set((status.skipped_tasks  || []).map(Number));
  const done      = new Set([...completed, ...skipped]);
  const pending   = (status.pending_tasks || []).map(Number);
  const unblocked = [];

  for (const issueNum of pending) {
    const taskDef = (config.tasks || []).find(t => Number(t.issue) === issueNum);
    const deps = taskDef ? (taskDef.dependencies || []).map(Number) : [];
    if (deps.every(dep => done.has(dep))) {
      unblocked.push(issueNum);
    }
  }

  return unblocked;
}

// ──────────────────────────────────────────────
// メイン
// ──────────────────────────────────────────────

function main() {
  const command = process.argv[2];
  const arg1    = process.argv[3];
  const arg2    = process.argv[4];

  const repoRoot   = getRepoRoot();
  const configFile = path.join(repoRoot, '.iddue', 'orchestration', 'config.yaml');
  const statusFile = path.join(repoRoot, '.iddue', 'orchestration', 'status.yaml');

  // init コマンドのみ config.yaml と status.yaml を生成
  if (command === 'init') {
    const mainIssueBranch = arg1;
    if (!mainIssueBranch) {
      process.stderr.write('Usage: tasks.js init <main-issue-branch>\n');
      process.exit(1);
    }

    if (!fs.existsSync(configFile)) {
      process.stderr.write(`Config file not found: ${configFile}\n`);
      process.exit(1);
    }

    const config = parseYAML(fs.readFileSync(configFile, 'utf-8'));
    const allIssues = (config.tasks || []).map(t => Number(t.issue));

    const status = {
      status: 'pending',
      main_issue_branch: mainIssueBranch,
      started_at: new Date().toISOString(),
      active_tasks: [],
      completed_tasks: [],
      pending_tasks: allIssues,
      skipped_tasks: [],
      failed_task: null,
      error_message: null,
    };

    fs.mkdirSync(path.dirname(statusFile), { recursive: true });
    fs.writeFileSync(statusFile, statusToYAML(status));
    process.stdout.write(`Initialized status.yaml with ${allIssues.length} tasks\n`);
    return;
  }

  // 以降のコマンドは config.yaml / status.yaml が必要
  if (!fs.existsSync(configFile)) {
    process.stderr.write(`Config file not found: ${configFile}\n`);
    process.exit(1);
  }
  if (!fs.existsSync(statusFile)) {
    process.stderr.write(`Status file not found: ${statusFile}\n`);
    process.exit(1);
  }

  const config = parseYAML(fs.readFileSync(configFile, 'utf-8'));
  const status = parseYAML(fs.readFileSync(statusFile, 'utf-8'));

  // 配列の正規化
  status.active_tasks    = status.active_tasks    || [];
  status.completed_tasks = status.completed_tasks || [];
  status.pending_tasks   = status.pending_tasks   || [];
  status.skipped_tasks   = status.skipped_tasks   || [];

  switch (command) {

    case 'unblocked': {
      const unblocked = findUnblockedTasks(config, status);
      if (unblocked.length > 0) {
        process.stdout.write(unblocked.join('\n') + '\n');
      }
      break;
    }

    case 'active': {
      if (status.active_tasks.length > 0) {
        for (const task of status.active_tasks) {
          process.stdout.write(`${task.issue}:${task.worker_pid}\n`);
        }
      }
      break;
    }

    case 'start': {
      if (!arg1 || !arg2) {
        process.stderr.write('Usage: tasks.js start <issue> <pid>\n');
        process.exit(1);
      }
      const issueNum = parseInt(arg1, 10);
      const pid      = parseInt(arg2, 10);

      status.pending_tasks = status.pending_tasks.filter(i => Number(i) !== issueNum);
      status.active_tasks.push({
        issue:      issueNum,
        worker_pid: pid,
        started_at: new Date().toISOString(),
      });
      status.status = 'in_progress';

      fs.writeFileSync(statusFile, statusToYAML(status));
      process.stdout.write(`Issue #${issueNum} started (PID: ${pid})\n`);
      break;
    }

    case 'complete': {
      if (!arg1) {
        process.stderr.write('Usage: tasks.js complete <issue>\n');
        process.exit(1);
      }
      const issueNum = parseInt(arg1, 10);

      status.active_tasks    = status.active_tasks.filter(t => Number(t.issue) !== issueNum);
      status.pending_tasks   = status.pending_tasks.filter(i => Number(i) !== issueNum);
      status.completed_tasks = [...(status.completed_tasks || []), issueNum];

      if (status.pending_tasks.length === 0 && status.active_tasks.length === 0) {
        status.status = 'completed';
      }

      fs.writeFileSync(statusFile, statusToYAML(status));
      process.stdout.write(`Issue #${issueNum} completed\n`);
      break;
    }

    case 'skip': {
      if (!arg1) {
        process.stderr.write('Usage: tasks.js skip <issue> [reason]\n');
        process.exit(1);
      }
      const issueNum = parseInt(arg1, 10);

      status.active_tasks  = status.active_tasks.filter(t => Number(t.issue) !== issueNum);
      status.pending_tasks = status.pending_tasks.filter(i => Number(i) !== issueNum);
      status.skipped_tasks = [...(status.skipped_tasks || []), issueNum];

      if (status.pending_tasks.length === 0 && status.active_tasks.length === 0) {
        status.status = 'completed';
      }

      fs.writeFileSync(statusFile, statusToYAML(status));
      process.stdout.write(`Issue #${issueNum} skipped\n`);
      break;
    }

    case 'fail': {
      if (!arg1 || !arg2) {
        process.stderr.write('Usage: tasks.js fail <issue> <error-message>\n');
        process.exit(1);
      }
      const issueNum    = parseInt(arg1, 10);
      const errorMessage = arg2;

      status.active_tasks  = status.active_tasks.filter(t => Number(t.issue) !== issueNum);
      status.pending_tasks = status.pending_tasks.filter(i => Number(i) !== issueNum);
      status.failed_task   = issueNum;
      status.error_message = errorMessage;
      status.status        = 'failed';

      fs.writeFileSync(statusFile, statusToYAML(status));
      process.stdout.write(`Issue #${issueNum} failed: ${errorMessage}\n`);
      break;
    }

    case 'status': {
      process.stdout.write(fs.readFileSync(statusFile, 'utf-8'));
      break;
    }

    default:
      process.stderr.write(`Unknown command: ${command}\n`);
      process.stderr.write('Commands: unblocked, active, start, complete, skip, fail, status, init\n');
      process.exit(1);
  }
}

main();
