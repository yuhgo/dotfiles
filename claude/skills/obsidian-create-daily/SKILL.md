---
name: obsidian-create-daily
description: 今日のデイリーノートを作成（前日の引き継ぎ + Googleカレンダー連携）。ユーザーが「日報を作って」「今日のデイリーノートを作成して」と言ったときに使用。
allowed-tools: mcp__obsidian-vault__read_file, mcp__obsidian-vault__write_file, mcp__obsidian-vault__create_directory, mcp__obsidian-vault__list_directory, mcp__obsidian-vault__get_file_info, mcp__google-calendar__get-current-time, mcp__google-calendar__list-calendars, mcp__google-calendar__list-events, mcp__google-calendar__manage-accounts
---

# Create Daily Note

今日のデイリーノートを作成します（前日の引き継ぎ + Googleカレンダー連携）。

## 前提条件

- MCP `obsidian-vault` がファイル操作可能であること
- MCP `google-calendar` が認証済みであること（未認証の場合は認証手順を案内）

---

## 実行手順

### Step 1: 基本情報の準備

1. **`get-current-time` ツールで現在時刻と曜日を取得**（曜日計算ミス防止のため必須）
   - レスポンスの `dayOfWeek` フィールドで今日の曜日を確認（0=日〜6=土）
2. 現在の日付を取得（YYYY-MM-DD形式、例: 2026-01-04）
3. 前日の日付を計算（例: 2026-01-03）
4. 今日のデイリーノートのパス `01_Daily/YYYY/MM/YYYY-MM-DD.md` を確認
5. **ファイルが既に存在する場合**: 「本日のデイリーノートは既に存在します: [パス]」と報告して終了

### Step 2: 前日のデイリーノート解析

前日のパス: `01_Daily/YYYY/MM/YYYY-MM-DD.md`（前日の日付で計算）

1. 前日のファイルが存在するか確認
2. **存在する場合**:
   - 「## 明日やること」セクションの内容を抽出（`## 明日やること` から次の `##` または `---` まで）
   - 未完了タスク（`- [ ]` で始まる行）をファイル全体から抽出
   - ノート全体の内容をAIで要約（3-5文程度、主要な活動・学び・決定事項をまとめる）
3. **存在しない場合**: 引き継ぎ情報なしとして続行

### Step 3: Google Calendarから予定取得

google-calendar MCPを使用:

1. `list-calendars` で利用可能なカレンダー一覧を取得
2. **今日の予定を取得** (`list-events`):
   - 今日の0:00から23:59までのイベント
   - 時間順にソート
   - フォーマット:
     ```
     - HH:MM-HH:MM イベント名
     - HH:MM-HH:MM イベント名 [カレンダー名]
     ```
   - 終日イベントは「終日」と表記
3. **今週の予定を取得** (`list-events`):
   - 今日から7日間のイベント
   - 日付ごとにグループ化
   - フォーマット:
     ```
     - MM/DD (曜日): イベント概要1, イベント概要2
     ```
   - **曜日の計算方法（重要）**:
     - `get-current-time` ツールで現在時刻を取得し、その `dayOfWeek` フィールドを基準にする
     - 例: 今日が日曜(0)なら、+1日後は月曜(1)、+2日後は火曜(2)...
     - 曜日の対応表: 0=日, 1=月, 2=火, 3=水, 4=木, 5=金, 6=土
     - **自分で曜日を計算せず、必ずツールの結果を使うこと**

### Step 4: デイリーノートの生成

1. 必要に応じてディレクトリ `01_Daily/YYYY/MM/` を作成
2. `Templates/daily.md` を読み込み、以下のプレースホルダを置換:

   | プレースホルダ | 置換内容 |
   |---------------|---------|
   | `{{date}}` | 今日の日付（YYYY-MM-DD） |
   | `{{previous_date}}` | 前日の日付（YYYY-MM-DD） |
   | `{{calendar_events}}` | 今日のカレンダー予定リスト |
   | `{{carryover_tasks}}` | 前日からの引き継ぎタスク |
   | `{{weekly_events}}` | 今週の予定概要 |
   | `{{previous_summary}}` | 前日の内容サマリー |

3. **カレンダー予定の挿入例**:
   ```markdown
   - 09:30-10:15 朝会
   - 10:30-11:00 営業チームとの進捗共有
   - 14:00-15:00 1on1
   ```

4. **前日からの引き継ぎの挿入例**:
   ```markdown
   #### 明日やることから
   - ドキュメントの更新
   - PRレビュー

   #### 未完了タスク
   - [ ] 「単体テストの考え方/使い方」を読む
   - [ ] LisMをZMK Studio化する
   ```

5. **今週の予定概要の挿入例**:
   ```markdown
   - 01/04 (土): 特になし
   - 01/05 (日): 友人との食事
   - 01/06 (月): プロジェクトキックオフ, 週次定例
   ```

6. **前日サマリーの挿入例**:
   ```markdown
   前日は Inkdrop の日記要約コマンドを作成し、Claude 設定を dotfiles 管理下に移行。
   Nothing Phone 3a を購入（59,000円）。読書ログとして「単体テストの考え方/使い方」を開始。
   ```

7. ファイルを作成

### Step 5: 完了報告

以下の形式で報告:

```
デイリーノートを作成しました: 01_Daily/YYYY/MM/YYYY-MM-DD.md

📋 前日からの引き継ぎ:
  - 明日やること: X件
  - 未完了タスク: X件

📅 本日の予定: X件のイベント

📆 今週の概要: X件の予定を表示
```

---

## エラーハンドリング

| ケース | 対応 |
|--------|------|
| 前日のノートが存在しない | 引き継ぎセクションは「前日のノートがありません」と記載 |
| Google Calendar未認証 | 認証手順を案内（下記参照） |
| Google Calendarに接続できない | カレンダーセクションは「カレンダー情報を取得できませんでした」と記載 |
| カレンダーイベントが0件 | 「予定なし」と記載 |

---

## Google Calendar認証手順（未設定の場合）

Google Calendar MCPが未認証の場合、以下の手順を案内してください:

### 1. Google Cloud Console設定

1. https://console.cloud.google.com にアクセス
2. 新規プロジェクト作成（例: `obsidian-calendar-mcp`）
3. 「APIとサービス」→「ライブラリ」→「Google Calendar API」を有効化
4. 「認証情報」→「認証情報を作成」→「OAuthクライアントID」
   - アプリケーションの種類: **デスクトップアプリ**
   - 名前: `obsidian-calendar-mcp`
5. JSONをダウンロード
6. 「OAuth同意画面」→ テストユーザーに自分のメールアドレスを追加

### 2. 認証情報の配置

```bash
mkdir -p ~/.config/google-calendar-mcp
# ダウンロードしたJSONを以下にコピー
cp ~/Downloads/client_secret_*.json ~/.config/google-calendar-mcp/gcp-oauth.keys.json
```

### 3. Claude Codeを再起動

`.mcp.json` の設定が反映されるよう、Claude Codeを再起動してください。

### 4. 初回認証

再起動後、`list-calendars` ツールを呼び出すとブラウザで認証フローが開始されます。
認証を完了すると、以降はカレンダー情報を取得できるようになります。
