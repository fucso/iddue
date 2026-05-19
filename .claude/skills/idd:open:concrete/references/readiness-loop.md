# 実装可能性判定・補完ループ

Issue 1件に対する readiness チェックと、NG 時の補完ループの手順。

単一 Issue・Sub Issue ともにこの手順を適用する。
Sub Issue が複数ある場合は Issue ごとにこの手順を繰り返す。

---

## 手順

### 1. 実装可能性の判定

```
/idd:judging-ready-to-implementation {issue番号}
```

- **OK** → 完了（次のステップへ進む）
- **NG** → 手順 2 へ

---

### 2. NG 時のユーザー確認

判定結果の「不足している内容」と「推奨アクション」をユーザーに提示する。

ユーザーに選択肢を提示する：

```
判定結果: NG

不足している内容:
- {不足内容}

推奨アクション: {推奨アクション}

どうしますか？
  [続ける] 不足内容を補完して再判定する
  [中断する] 現時点の内容で Issue を残してフローを終了する
```

---

### 3. 「続ける」を選択した場合

不足項目についてユーザーとの対話で情報を収集する。

収集した情報をもとに update オーダーシートを作成する：

```yaml
# .idd/orders/{YYYYMMDD-HHMMSS}-update.yaml
type: update
issue_number: {issue番号}
objectives:
  - what: "{補完する内容の概要}"
    why: "{判定 NG の理由・不足していた情報・対話で確定した事項}"
    how: "{追記・変更の内容}"
    detail:  # 設計詳細が変わる場合
      - type: design
        target: "..."
        change: "..."
```

オーダーシートの内容をユーザーに確認する。
確認後、`idd:update-issue` スキルで Issue を更新する：

```
/idd:update-issue .idd/orders/{ファイル名}
```

更新後、再判定する：

```
/idd:judging-ready-to-implementation {issue番号} refresh:true
```

判定 OK になるまで手順 2〜3 を繰り返す。

---

### 4. 「中断する」を選択した場合

現時点の内容で Issue を残し、フローを終了する（判定 NG のまま）。
