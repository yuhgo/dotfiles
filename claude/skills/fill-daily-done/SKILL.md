---
name: fill-daily-done
description: claude-memの履歴とGitコミット履歴から、今日のデイリーノートの「今日やったこと」セクションを自動的に埋める。ユーザーが「今日やったことを記入して」「日報の作業内容を埋めて」と言ったときに使用。
allowed-tools: mcp__plugin_claude-mem_mcp-search__search, mcp__plugin_claude-mem_mcp-search__get_observations, mcp__google-calendar__get-current-time, mcp__obsidian-vault__read_file, mcp__obsidian-vault__write_file, mcp__obsidian-vault__get_file_info, Bash, Read, Edit, Grep
---

# Fill Daily Done

claude-memの履歴と各リポジトリのGitコミット履歴から、今日のデイリーノートの「今日やったこと」セクションを自動的に埋めます。

## 前提条件

- MCP `claude-mem` (plugin_claude-mem_mcp-search) が利用可能であること
- 今日のデイリーノート `01_Daily/YYYY/MM/YYYY-MM-DD.md` が既に存在すること（存在しない場合は `/create-daily` を先に実行するよう案内）

---

## 実行手順

### Step 1: 基本情報の準備

1. `get-current-time` ツールで今日の日付を取得（YYYY-MM-DD形式）
2. 今日のデイリーノートのパス `01_Daily/YYYY/MM/YYYY-MM-DD.md` を確認
3. **ファイルが存在しない場合**: 「デイリーノートが見つかりません。先に `/create-daily` を実行してください」と案内して終了
4. 既存の「## 今日やったこと」セクションの内容を確認（既に記入済みの内容は保持する）

### Step 2: claude-memから今日の作業履歴を取得

1. `mcp__plugin_claude-mem_mcp-search__search` で今日の作業を検索:
   - `dateStart`: 今日の日付（YYYY-MM-DD）
   - `dateEnd`: 翌日の日付（YYYY-MM-DD）
   - `query`: "commit コミット 実装 追加 修正 変更 fix feat update"
   - `limit`: 30
2. 検索結果から、以下のタイプのobservationを重点的に取得:
   - ✅ (change): コードの変更・実装
   - 🔴 (bugfix): バグ修正
   - 🔵 (discovery): 調査・発見（コミットを伴わない作業）
3. 関連するobservation IDを `mcp__plugin_claude-mem_mcp-search__get_observations` で詳細取得

### Step 3: Gitコミット履歴を取得

1. 以下の既知のリポジトリディレクトリから今日のコミットを検索:
   ```bash
   for dir in /Users/yamamotoyugo/ghq/github.com/*/*/; do
     repo_name=$(echo "$dir" | sed 's|.*/ghq/github.com/||;s|/$||')
     commits=$(cd "$dir" 2>/dev/null && git log --oneline --since="YYYY-MM-DDT00:00:00" --until="YYYY-MM-DD+1T00:00:00" --all --author="yugo\|yuhgo\|yamamoto" 2>/dev/null)
     if [ -n "$commits" ]; then
       echo "=== $repo_name ==="
       echo "$commits"
     fi
   done
   ```
2. コミットが見つかったリポジトリについて、コミットメッセージからやったことを把握

### Step 4: 情報の統合・整理

claude-memのobservationとGitコミット履歴を統合し、以下のルールで整理:

1. **プロジェクト単位でグループ化**: リポジトリ名やプロジェクト名ごとにまとめる
2. **記述フォーマット**:
   ```markdown
   - プロジェクト名/作業カテゴリ
   	- 具体的な作業内容1 - 補足説明
   	- 具体的な作業内容2 - 補足説明
   ```
3. **重複排除**: 同じ作業がclaude-memとGitの両方にある場合は1つにまとめる
4. **コミットのない調査作業も含める**: claude-memにdiscoveryとして記録されているが、コミットがない作業（ブラウザ調査、設定確認など）も記載
5. **既存の記入内容との統合**: 既にデイリーノートに記入されている内容と重複する場合は追加しない

### Step 5: デイリーノートに記入

1. デイリーノートの「## 今日やったこと」セクションを更新
2. 既存の内容がある場合は、その後ろに新しい項目を追加
3. 既存の内容が `-` のみ（未記入）の場合は置き換え

### Step 6: 完了報告

以下の形式で報告:

```
「今日やったこと」を更新しました: 01_Daily/YYYY/MM/YYYY-MM-DD.md

📊 情報ソース:
  - claude-mem: X件のobservation
  - Gitコミット: X件（Yリポジトリ）

📝 記入内容:
  - プロジェクトA: X項目
  - プロジェクトB: X項目
  - その他: X項目
```

---

## エラーハンドリング

| ケース | 対応 |
|--------|------|
| デイリーノートが存在しない | `/create-daily` の実行を案内 |
| claude-memに接続できない | Gitコミット履歴のみから記入し、claude-memが利用不可だった旨を報告 |
| Gitリポジトリにアクセスできない | claude-memの情報のみから記入 |
| 今日の作業履歴が0件 | 「今日の作業履歴が見つかりませんでした」と報告 |
| 既に「今日やったこと」が充実している | 差分のみ追加し、既存内容は変更しない |
