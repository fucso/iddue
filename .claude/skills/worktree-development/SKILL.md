---
name: worktree-development
description: |
  git worktree ベースの開発環境管理機能を提供する。
  コマンド実行・品質チェック・セットアップ後処理をリポジトリ固有フックに委譲することで、
  言語・ツールチェーン・実行環境を問わず利用できる汎用スキル。
  以下の場合に使用:
  (1) git worktree を利用した開発を行う時
  (2) 現在のメインブランチとは別のブランチをベースとした開発、調査を行う時
  (3) 複数ブランチに渡る並列開発を行う時
---

# Worktree Development

メインの作業環境に影響を与えずに独立した git worktree 環境で実装作業を行うための汎用機能を提供する。

**重要**: このスキルは機能を提供するのみであり、具体的なワークフロー（どの順序で何を行うか、品質チェックが必要かなど）は呼び出し元が決定する。

## フックスクリプト

リポジトリ固有の処理（コマンド実行方法・品質チェック内容・セットアップ後の初期化など）は
`.claude/worktree-hooks/` 配下にフックスクリプトを配置することでカスタマイズできる。
詳細は [references/hooks.md](references/hooks.md) を参照。

## 提供機能

このスキルは git worktree 開発で利用する機能をスクリプトとして提供する。
詳細は [references/features.md](references/features.md) を参照。

## 操作ルール

worktree 環境での作業は以下のルールに従うこと。

**許可する操作:**
- このスキルが提供するスクリプト（`exec.sh`、`setup.sh`、`commit.sh` 等）の実行
- Write/Edit ツールによる worktree 内ファイルの直接編集

**禁止する操作:**
- **worktree 内の直接コマンド実行**: `exec.sh` を経由せず `bash -c "cd .worktree/..."` や `git -C .worktree/...` などを直接呼び出すことは禁止
- **メインディレクトリのファイル編集**: 必ず worktree 内のファイルを編集すること
- **クリーンアップせずに終了**: 作業終了後は必ず `cleanup.sh` で作業環境を削除すること

## 関連ドキュメント

| ドキュメント | 説明 |
|--------------|------|
| [references/features.md](references/features.md) | 提供機能の詳細・パラメータ・実行コマンド |
| [references/hooks.md](references/hooks.md) | フックスクリプトの仕様・引数・実装例 |
