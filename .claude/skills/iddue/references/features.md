# IDDUE スキル一覧

`iddue:` プリフィックスを持つスキルの役割・種別・呼び出し元の一覧。

---

## スキル一覧

| スキル | 種別 | 呼び出し元 | 担当領域 |
|--------|------|-----------|---------|
| [`iddue`](#iddue) | 知識提供 | — | IDDUE ワークフロー共通知識 |
| [`iddue:issue-yaml`](#iddissue-yaml) | 知識提供 | — | Issue YAML スキーマ・記述原則 |
| [`iddue:open`](#iddopen) | コマンド（ユーザー起動） | ユーザー | 起票レベルの判定・`iddue:open:{level}` への委譲 |
| [`iddue:open:concrete`](#iddopenconcrete) | コマンド（ユーザー起動 / 委譲） | ユーザー / `iddue:open` | 具体的な改修の要件検討・起票内容の決定 |
| [`iddue:open:bug`](#iddopenbug) | コマンド（ユーザー起動 / 委譲） | ユーザー / `iddue:open` | 不具合の分析・要件検討・起票内容の決定 |
| [`iddue:open:idea`](#iddopenidea) | コマンド（ユーザー起動 / 委譲） | ユーザー / `iddue:open` | アイデアの整理・起票内容の決定 |
| [`iddue:open:problem`](#iddopenproblem) | コマンド（ユーザー起動 / 委譲） | ユーザー / `iddue:open` | 問題の整理・起票内容の決定 |
| [`iddue:create-issue`](#iddcreate-issue) | コマンド（内部） | `iddue:open:*` | オーダーシートから GitHub Issue を起票 |
| [`iddue:update-issue`](#iddupdate-issue) | コマンド（内部） | `iddue:open:*` / `iddue:issue:revise` | オーダーシートから GitHub Issue を更新 |
| [`iddue:issue:revise`](#iddissuerevise) | コマンド（ユーザー起動） | ユーザー | 起票済み Issue の内容を修正・補完 |
| [`iddue:fetch-issue`](#iddfetch-issue) | コマンド（内部 / 直接呼び出し可） | `iddue:start` / `iddue:judging-ready-to-implementation` | Issue コンテキストを収集して YAML 化 |
| [`iddue:judging-ready-to-implementation`](#iddjudging-ready-to-implementation) | コマンド（内部） | `iddue:start` / `iddue:open:concrete` / `iddue:open:bug` / `iddue:start:orchestrate` | Issue の実装可能性を判定 |
| [`iddue:start`](#iddstart) | コマンド（ユーザー起動） | ユーザー | Issue を起点に worktree 実装・PR 作成（サブ Issue あり → `iddue:start:orchestrate` へ委譲） |
| [`iddue:setup-orchestration`](#iddsetup-orchestration) | コマンド（ユーザー起動 / 委譲） | ユーザー / `iddue:open:concrete` | 並列実装準備（メイン Issue ブランチ・config.yaml・メイン Issue PR の作成・readiness チェック） |
| [`iddue:start:orchestrate`](#iddstartorchestrate) | コマンド（委譲） | `iddue:start` | サブ Issue の並列ワーカーディスパッチ・監視・マージ |
| [`iddue:start:worker`](#iddstartworker) | コマンド（自動起動） | `iddue:start:orchestrate`（`claude -p` サブプロセス） | サブ Issue 単体の worktree 実装・report.md 送信 |
| [`iddue:pr:review`](#iddprreview) | コマンド（ユーザー起動） | ユーザー | IDDUE Issue に紐づいた PR を複数観点でレビューし、PR にコメントする |
| [`iddue:pr:address-review-feedback`](#iddpraddress-review-feedback) | コマンド（ユーザー起動） | ユーザー | PR の未解決レビューコメントをタスクに整理して修正を実装・プッシュする |
| [`iddue:pr:check-feedback-resolution`](#iddprcheck-feedback-resolution) | コマンド（内部） | `iddue:pr:review` | 未解決レビューコメントの解消確認・異議スレッドのユーザー議論・自動 resolve を行う |

---

## 各スキルの詳細

### `iddue`

- **種別:** 知識提供（`user-invocable: false`）
- **担当領域:** IDDUE ワークフロー全体の共通知識を集約する。GitHub Issues による開発管理と `docs/specs/` による仕様ドキュメンテーション、2軸の連携ワークフローの知識・ルールを提供する。

---

### `iddue:issue-yaml`

- **種別:** 知識提供（`user-invocable: false`）
- **担当領域:** `.iddue/issue/{number}.yaml` のスキーマ定義・記述原則・構造操作ルールを提供する。Issue YAML を作成・更新するすべてのスキル（`iddue:create-issue`・`iddue:update-issue`・`iddue:fetch-issue`）が参照する。

---

### `iddue:open`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す）
- **担当領域:** `iddue:open:*` 系スキルへのエントリーポイント。引数の説明文や対話からレベル（concrete / bug / problem / idea）を判定し、対応する `iddue:open:{level}` スキルへ委譲する。レベルが明確でない場合は追加質問で情報を引き出す。

---

### `iddue:open:concrete`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す / `iddue:open` から委譲される）
- **担当領域:** 具体的な改修の起票内容をユーザーと対話しながら検討・決定する。変更対象ファイル・実装内容・完了条件をユーザーから引き出してオーダーシートにまとめ、`iddue:create-issue` に渡して GitHub Issue を起票させる。起票後は `iddue:judging-ready-to-implementation` で実装可能性を判定し、NG の場合はユーザーと対話して内容を補完・`iddue:update-issue` で更新するループも担う。

---

### `iddue:open:bug`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す / `iddue:open` から委譲される）
- **担当領域:** 不具合の起票内容をユーザーと対話しながら検討・決定する。エラーログ・Bugsnag URL などをもとに原因を分析し、再現手順・期待値・実際の動作・対応方針をユーザーと対話しながら整理してオーダーシートにまとめ、`iddue:create-issue` に渡して GitHub Issue を起票させる。対応方針が確定している場合は `iddue:judging-ready-to-implementation` での実装可能性判定も行う。

---

### `iddue:open:idea`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す / `iddue:open` から委譲される）
- **担当領域:** アイデアの起票内容をユーザーと対話しながら整理・決定する。解決したい課題・動機・想定アプローチ・期待される効果を収集してオーダーシートにまとめ、`iddue:create-issue` に渡して GitHub Issue を起票させる。実装可能性判定は行わない。

---

### `iddue:open:problem`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す / `iddue:open` から委譲される）
- **担当領域:** 問題の起票内容をユーザーと対話しながら整理・決定する。問題の内容・発生箇所・影響をユーザーから引き出してオーダーシートにまとめ、`iddue:create-issue` に渡して GitHub Issue を起票させる。リファクタリング・技術的負債・設計上の問題が典型例。具体化が進んだ後に `iddue:open:concrete` へ移行することを想定している。

---

### `iddue:create-issue`

- **種別:** ワークフローコマンド（`iddue:open:*` から呼び出される内部コマンド）
- **担当領域:** オーダーシート YAML（`.iddue/orders/*.yaml`）を受け取り、Issue タイトル・本文の組み立てから `gh` コマンドによる GitHub Issue 作成、Issue YAML の書き出しまでを一貫して行う。ユーザー対話なしで自動実行するスタンドアローンワークフロー。`open` 系スキルとの唯一の受け渡し手段はオーダーシートファイル。

---

### `iddue:update-issue`

- **種別:** ワークフローコマンド（`iddue:open:*` / `iddue:issue:revise` から呼び出される内部コマンド）
- **担当領域:** オーダーシート YAML（`.iddue/orders/*.yaml`）を受け取り、現在の Issue 内容に変更を適用して本文を再構築し、`gh` コマンドで更新・コメント追記・YAML 管理まで一貫して行う。ユーザー対話なしで自動実行するスタンドアローンワークフロー。

---

### `iddue:issue:revise`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す）
- **担当領域:** 起票済みの Issue の内容を修正・補完する。実装中の発見・要件変更・レビュー指摘など起票後に判明した情報を Issue に反映する。ユーザーとの対話で変更内容を具体化し、オーダーシートを生成して `iddue:update-issue` に渡す。親 Issue を指定した場合はサブ Issue も確認して変更対象を特定し、ユーザー合意のうえで複数 Issue を一括更新する。

---

### `iddue:fetch-issue`

- **種別:** ワークフローコマンド（`iddue:start` / `iddue:judging-ready-to-implementation` から呼び出される内部コマンド / 直接呼び出しも可）
- **担当領域:** GitHub Issue・親 Issue・Sub Issue・依存 Issue・紐づく PR の情報を一括取得し、`.iddue/issue/{number}.yaml` に書き出す。キャッシュ機能付き（`force:true` で強制再取得）。実装開始・実装可否判定に必要なコンテキストを提供するインフラ層に相当する。

---

### `iddue:judging-ready-to-implementation`

- **種別:** ワークフローコマンド（`iddue:start` / `iddue:open:concrete` / `iddue:open:bug` から呼び出される内部コマンド）
- **担当領域:** GitHub Issue がエージェントによる自律実装に十分な具体性・粒度を持つかを判定する。判定基準（変更対象ファイルの特定・実装内容の明確さ・完了条件の定義・実装範囲の適切さ）を評価し、✅/❌ と不足内容・推奨アクションを返す。実装可能と判断した場合は `ready to implementation` ラベルを付与する。

---

### `iddue:start`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す）
- **担当領域:** Issue 番号を受け取り、`iddue:fetch-issue` でコンテキスト収集 → `iddue:judging-ready-to-implementation` で実装可否判定 → `worktree-development` で独立した worktree 環境を準備 → コード実装・品質チェック → コミット・プッシュ → PR 作成まで一貫して自動実行する。IDDUE ワークフローの「実装」フェーズ全体のオーケストレーターに相当する。サブ Issue が存在する場合はユーザーに確認後 `iddue:start:orchestrate` へ委譲する。

---

### `iddue:setup-orchestration`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す / `iddue:open:concrete` から委譲される）
- **担当領域:** 親 Issue と Sub Issue が起票済みの状態から並列実装に必要な情報を付与する。メイン Issue ブランチ（`iddue/{parent}`）の作成・push、`.orchestrate/config.yaml` の生成・コミット、メイン Issue PR の作成（ドラフト）、各サブ Issue YAML への `parent.linked_pr.branch` 設定、readiness チェックまで一貫して処理する。Sub Issue が存在しない場合はエラーで終了する。完了後は `/iddue:start {parent}` でオーケストレーター実装を開始できる状態になる。

---

### `iddue:start:orchestrate`

- **種別:** ワークフローコマンド（`iddue:start` から委譲される）
- **担当領域:** サブ Issue を持つ親 Issue のオーケストレーターモード実装を担う。`iddue:setup-orchestration` で準備済みの `config.yaml` を読み込み、依存グラフに基づいてブロックなしのサブ Issue を `iddue:start:worker` ワーカープロセス（`env -u CLAUDECODE claude -p` サブプロセス）で並列ディスパッチする。`ScheduleWakeup` で定期的に完了シグナル（`report.md` コミット）を検知し、完了したサブ Issue をメイン Issue ブランチへマージする。全タスク処理完了後にメイン Issue PR をレディにしてレポートを表示する。

---

### `iddue:start:worker`

- **種別:** ワークフローコマンド（`iddue:start:orchestrate` が `claude -p` サブプロセスで自動起動する）
- **担当領域:** サブ Issue 1件の worktree 実装を担う独立プロセス。`iddue:fetch-issue` で親ブランチ（`parent.linked_pr.branch`）を取得 → readiness チェック → worktree セットアップ（ベース = `iddue/{parent}`）→ 実装 → 品質チェック → commit+push → `report.md` 作成 → `commit-report.sh` で report.md をサブ Issue ブランチにコミットして完了シグナルを送信する。エラー時も report.md でオーケストレーターに通知する。

---

### `iddue:pr:review`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す）
- **担当領域:** IDDUE Issue に紐づいた PR を複数観点でレビューする。最初に `iddue:pr:check-feedback-resolution` を呼び出して前回の未解決コメントを処理してから、worktree を作成してコード全体を参照しつつ、①完了状況（オーケストレーション PR のみ）②要件充足性 ③設計整合性 ④CI ステータス ⑤コード品質の 5 観点を順に評価する。CRITICAL が 1 件でも見つかれば `REQUEST_CHANGES` コメントを投稿して終了、全観点 OK なら `COMMENT` でレビュー OK を投稿して `iddue: review ok` ラベルを付与する。単独 Issue PR とオーケストレーション PR の両方に対応する。

---

### `iddue:pr:address-review-feedback`

- **種別:** ワークフローコマンド（ユーザーが明示的に呼び出す）
- **担当領域:** PR の未解決レビューコメントを修正タスクにグループ化してバックグラウンドエージェントで並列実装する。worktree を作成して最新コードを参照しながら各コメントの修正を実施し、コミット後にブランチへプッシュする。対応不可のコメントはユーザーに報告する。完了後に `/iddue:pr:review` を実行するよう案内する。

---

### `iddue:pr:check-feedback-resolution`

- **種別:** ワークフローコマンド（`iddue:pr:review` から呼び出される内部コマンド）
- **担当領域:** PR の未解決レビュースレッドを「異議スレッド」と「コード修正待ちスレッド」に分類して処理する。異議スレッド（`<!-- iddue:pr:review -->` マーカー付きコメントへのユーザー返信）はユーザーと議論して解消し、残りのスレッドはコメント後の差分と最新コードを照合して解消判定・自動 resolve を行う。未解決が残る場合は `REQUEST_CHANGES` コメントを投稿して終了する。`iddue:pr:review` の Phase 1 として呼び出されるが、単独でも使用可能。
