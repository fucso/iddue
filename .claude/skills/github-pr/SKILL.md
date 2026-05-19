---
name: github-pr
description: |
  GitHub PR の情報取得・差分取得・レビュー投稿・スレッド操作をスクリプトとして提供する。
  PR を扱うスキルから呼び出される共通ライブラリ。
---

# GitHub PR

GitHub Pull Request の操作に必要なスクリプトを提供する。

**重要**: このスキルは機能を提供するのみであり、具体的なワークフローは呼び出し元が決定する。

## 提供機能

各スクリプトの詳細は [references/features.md](references/features.md) を参照。

## 呼び出し方法

```bash
bash .claude/skills/github-pr/scripts/{script_name}.sh {args}
```
