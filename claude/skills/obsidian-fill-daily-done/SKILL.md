---
name: obsidian-fill-daily-done
description: harness-memの履歴とGitコミット履歴から、今日のデイリーノートの「今日やったこと」セクションを自動的に埋める
allowed-tools: Bash, Read, Edit, Glob, mcp__harness__harness_mem_search, mcp__harness__harness_mem_timeline, mcp__harness__harness_mem_get_observations, mcp__obsidian-vault__read_file, mcp__obsidian-vault__edit_file
---

# obsidian-fill-daily-done

今日のデイリーノートの「今日やったこと」セクションに、Gitコミット履歴とharness-memの作業記録を自動で書き込む。

## デフォルト設定

- **対象日**: 今日（YYYY-MM-DD）
- **Vaultパス**: `/Users/yamamotoyugo/ghq/github.com/yuhgo/obsidian`
- **デイリーノートパス**: `01_Daily/YYYY/MM/YYYY-MM-DD.md`
- **リポジトリ**: `~/ghq/` 配下の全Gitリポジトリ（再帰的に探索）
- **Gitユーザー名**: `yugo\|yuhgo\|yamamoto\|Yamamoto`

## 実行フロー

### Step 1: デイリーノートの存在確認

1. 今日の日付からデイリーノートのパスを特定: `01_Daily/YYYY/MM/YYYY-MM-DD.md`
2. ファイルが存在するか確認
3. 存在しない場合は「デイリーノートが見つかりません。先に `/obsidian-create-daily` で作成してください」と案内して終了

### Step 2: Gitコミット履歴取得

`~/ghq/` 配下の全Gitリポジトリからコミットを取得:

```bash
find ~/ghq -name .git -type d -prune | while read gitdir; do
  repo="$(dirname "$gitdir")"
  repo_name=$(basename "$repo")
  cd "$repo" && git log \
    --author="yugo\|yuhgo\|yamamoto\|Yamamoto" \
    --since="YYYY-MM-DDT00:00:00+09:00" \
    --until="YYYY-MM-DDT23:59:59+09:00" \
    --pretty=format:"$repo_name|%aI|%s" \
    --no-merges \
    --all 2>/dev/null
done
```

### Step 3: harness-memから作業記録を取得

1. `harness_mem_search` で今日の作業を検索:
   - `query`: "実装 追加 修正 変更 調査 設定 レビュー 作成 更新 fix feat update refactor"
   - `since`: 今日の日付（YYYY-MM-DD）
   - `until`: 明日の日付（YYYY-MM-DD+1）
   - `limit`: 50
2. 必要に応じて `harness_mem_timeline` や `harness_mem_get_observations` で詳細を展開

### Step 4: 情報の統合・整形

- Conventional Commitsのprefix（`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`, `ci:`, `build:`, `perf:`, `style:`）を除去
- **重複排除**: Gitコミットとharness-memで同じ作業を指す場合は1つにまとめる
- 時刻はJST（UTC+9）で表示
- 時刻の昇順でソート

### Step 5: デイリーノートに書き込み

「今日やったこと」セクションの既存内容を作業リストで置き換える。

**出力形式（箇条書き）:**

```markdown
## 今日やったこと

- HH:MM [リポ名] 作業内容の説明
- HH:MM [リポ名] 別の作業内容
- HH:MM [harness-mem] コミットを伴わない作業（調査・レビューなど）
```

**書き込みルール:**
- `## 今日やったこと` と次の `##` セクションの間を編集する
- 既に内容がある場合は、既存の内容を保持しつつ末尾に追記する（ただし空の `-` のみの場合は置き換える）
- Edit ツールで該当セクションのみを書き換える

## エラーハンドリング

| ケース | 対応 |
|--------|------|
| デイリーノートが存在しない | `/obsidian-create-daily` の利用を案内 |
| harness-memに接続できない | Gitコミット履歴のみで書き込み、harness-memが利用不可だった旨を報告 |
| Gitリポジトリにアクセスできない | harness-memの情報のみで書き込み |
| 今日の作業履歴が0件 | 「今日の作業履歴が見つかりませんでした」と報告（ノートは変更しない） |
