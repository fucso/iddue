---
name: iddue
description: |
  Issue-Driven Development（IDD）ワークフローの共通知識を提供する。
  GitHub Issues による開発管理と、docs/specs/ による仕様および意思決定の記録のドキュメンテーション、
  この2軸の連携による実装ワークフローの知識を集約する。
  以下の場合に使用:
  (1) GitHub Issues ベースの開発管理に関する質問・操作
  (2) docs/specs/ の仕様書管理・更新・ドキュメンテーションに関する質問・操作
  (3) iddue: プリフィックスのスキル、コマンドの利用、メンテナンス
user-invocable: false
---

# IDD (Issue-Driven Development) Skill

GitHub Issues による開発管理と、`docs/specs/` による仕様および意思決定の記録のドキュメンテーション、2軸の連携による実装ワークフローの知識を提供する。

## 仕様書管理

### 目的と原則

| | GitHub Issues | docs/specs/ |
|---|---|---|
| **記録するもの** | 開発内容・その開発内容に決まるまでの議論 | 仕様が何であるか（WHAT）・なぜその仕様になったか（WHY） |
| **更新方法** | コメント追加・本文更新 | リポジトリ管理のコードの更新、コミット追加 |

### ファイル配置

```
docs/specs/
├── README.md              # インデックス（ドキュメント一覧・概要・関連 Issue 番号）
└── {feature-name}.md      # 機能ごとの仕様書（常に最新の正しい情報のみ）
```

## ステータス管理

PR ↔ Issue リンクに委ねる：PR 本文に `Closes #NNN` を記述 → PR マージで Issue が自動クローズ

## ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [references/features.md](references/features.md) | スキル一覧・種別・呼び出し元・担当領域 |
| [references/workflow.md](references/workflow.md) | 実装フロー・各コマンドの操作手順 |
| [references/docs.md](references/docs.md) | ローカルドキュメント（docs/specs/）の目的・管理方針・更新ルール |
| [references/hooks.md](references/hooks.md) | IDD フックスクリプト仕様（`.claude/iddue-hooks/` へのカスタマイズポイント） |

## 並列実装ワークフロー

サブ Issue を持つ Issue をオーケストレーター/ワーカーパターンで並列実装する場合は、以下のスキルを参照する。

- [`iddue:orchestration-development`](../iddue:orchestration-development/SKILL.md) — 並列実装ワークフローの全体像・設計方針・ファイル構造

