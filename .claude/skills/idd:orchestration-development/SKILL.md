---
name: idd:orchestration-development
description: |
  IDD における並列実装ワークフローの共通知識を提供する。
  サブ Issue の依存グラフに基づいたオーケストレーター/ワーカーパターンによる
  並列実装の全体像・設計方針・ファイル構造・スキルの役割分担を集約する。
  以下の場合に使用:
  (1) 並列実装ワークフロー（idd:setup-orchestration / idd:start:orchestrate / idd:start:worker）の仕組みを理解したいとき
  (2) オーケストレーター・ワーカー・setup スキルの実装を修正・拡張するとき
  (3) 並列実装がどのフェーズで何を行うかを確認したいとき
user-invocable: false
---

# IDD 並列実装ワークフロー（Orchestration Development）

IDD において複数のサブ Issue を並列に実装するためのオーケストレーター/ワーカーパターンのワークフロー定義、知識。

---

## なぜ並列実装が必要か

標準的な IDD（`idd:start`）は Issue 1件を1プロセスで直列に実装する。
しかし親 Issue が複数の独立したサブ Issue に分割できる場合、並列実装によって：

- 実装時間の短縮（依存のないサブ Issue を同時進行）
- サブ Issue ごとの実装範囲の明確化

を実現できる。

**使用する判断基準:**
- 親 Issue に2件以上のサブ Issue がある
- うち少なくとも1件が他と独立して実装可能（依存なし）

---

## 関連スキルと役割分担

| スキル | フェーズ | 担当 |
|--------|---------|------|
| `idd:open:concrete` | 設計 | サブ Issue の分割案を決定・起票 |
| `idd:setup-orchestration` | 設計 | メイン Issue ブランチ・config.yaml・メイン Issue PR の作成 |
| `idd:start` | 実装 | サブ Issue 検出 → orchestrate への委譲 |
| `idd:start:orchestrate` | 実装 | ワーカーのディスパッチ・監視・マージ |
| `idd:start:worker` | 実装 | サブ Issue 単体の worktree 実装 |

---

## 詳細ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [references/workflow.md](references/workflow.md) | 全体ワークフロー（フロー図・分岐含む） |
| [references/files-and-branches.md](references/files-and-branches.md) | ファイル構造・主要ファイルの役割・ブランチ戦略・依存関係 |
| [references/hooks.md](references/hooks.md) | カスタムフックスクリプトの仕様・設定方法 |
