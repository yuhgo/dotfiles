---
name: obsidian-file
description: Obsidian vaultのファイルを読み書き・編集する汎用スキル。MCPツールが使えない場合はRead/Write/Edit/Globで代替する。ユーザーが「obsidianのファイルを読んで」「obsidianにメモを書いて」「ノートを編集して」と言ったときに使用。
allowed-tools: mcp__obsidian-vault__read_file, mcp__obsidian-vault__read_text_file, mcp__obsidian-vault__read_multiple_files, mcp__obsidian-vault__write_file, mcp__obsidian-vault__edit_file, mcp__obsidian-vault__create_directory, mcp__obsidian-vault__list_directory, mcp__obsidian-vault__search_files, mcp__obsidian-vault__get_file_info, mcp__obsidian-vault__move_file, Read, Write, Edit, Glob, Grep
---

# Obsidian File Operations

Obsidian vault内のファイルを読み書き・編集する汎用スキルです。
MCPツールが利用できない環境では、標準ツール（Read, Write, Edit, Glob, Grep）で代替します。

## Vault ルート

```
/Users/yamamotoyugo/ghq/github.com/yuhgo/obsidian
```

---

## ディレクトリ構造

```
/Users/yamamotoyugo/ghq/github.com/yuhgo/obsidian/
├── 00_Inbox/              # 未整理のメモ・アイデア（一時置き場）
├── 01_Daily/              # デイリーノート（日報）
│   └── YYYY/MM/           #   例: 01_Daily/2026/02/2026-02-07.md
├── 02_Weekly/             # 週報
│   └── YYYY/              #   例: 02_Weekly/2026/2026-W06.md
├── 03_Monthly/            # 月報
│   └── YYYY/              #   例: 03_Monthly/2026/2026-01.md
├── 05_Keyboard/           # キーボード関連のメモ
├── 06_Work/               # 仕事関連のノート
│   ├── farm-in/           #   farm-in プロジェクト
│   │   └── report/        #     レポート類
│   └── link/              #   link プロジェクト
│       └── meetings/      #     議事録
├── 07_Dev/                # 開発・技術関連のメモ
├── 99_Archives/           # アーカイブ（完了済み・古いノート）
└── Templates/             # テンプレートファイル
    ├── daily.md           #   デイリーノートテンプレート
    ├── weekly.md          #   週報テンプレート
    ├── monthly.md         #   月報テンプレート
    ├── meeting.md         #   議事録テンプレート
    └── book.md            #   読書メモテンプレート
```

---

## ツール選択

まずMCPツールを試し、`Access denied` エラーが出たら標準ツールにフォールバックする。

### 読み取り

| 操作 | MCP ツール | フォールバック |
|------|-----------|-------------|
| ファイル読み取り | `mcp__obsidian-vault__read_file` | `Read(file_path: "<vault_root>/<path>")` |
| 複数ファイル読み取り | `mcp__obsidian-vault__read_multiple_files` | 複数の `Read` を並列実行 |
| ファイル検索 | `mcp__obsidian-vault__search_files` | `Grep(pattern: "keyword", path: "<vault_root>")` |
| ディレクトリ一覧 | `mcp__obsidian-vault__list_directory` | `Glob(pattern: "*", path: "<vault_root>/<dir>")` |
| ファイル情報 | `mcp__obsidian-vault__get_file_info` | `Glob` で更新日時順に確認 |

### 書き込み・編集

| 操作 | MCP ツール | フォールバック |
|------|-----------|-------------|
| ファイル作成 | `mcp__obsidian-vault__write_file` | `Write(file_path: "<vault_root>/<path>", content: "...")` |
| ファイル編集 | `mcp__obsidian-vault__edit_file` | `Edit(file_path: "<vault_root>/<path>", old_string: "...", new_string: "...")` |
| ディレクトリ作成 | `mcp__obsidian-vault__create_directory` | `Bash(mkdir -p <vault_root>/<dir>)` |
| ファイル移動 | `mcp__obsidian-vault__move_file` | `Bash(mv <src> <dst>)` |

---

## 実行手順

### Step 1: 要求の理解

ユーザーの指示から以下を判断:
- **操作**: 読み取り / 作成 / 編集 / 移動 / 検索
- **対象パス**: ディレクトリ構造を参考にパスを特定
- **内容**: 書き込み・編集の場合は具体的な内容

### Step 2: パスの解決

1. ユーザーが指定した名前・キーワードから対象パスを推定
2. ディレクトリ構造を参考に絶対パスを構築
   - 例: 「workのlinkの議事録」→ `/Users/yamamotoyugo/ghq/github.com/yuhgo/obsidian/06_Work/link/meetings/`
   - 例: 「今日の日報」→ `/Users/yamamotoyugo/ghq/github.com/yuhgo/obsidian/01_Daily/2026/02/2026-02-07.md`
3. パスが不明な場合は `list_directory` or `Glob` で確認

### Step 3: ツールの実行

1. MCPツールで実行を試みる
2. `Access denied` エラーが発生した場合、標準ツールにフォールバック
3. 書き込み・編集前は必ず対象ファイルを先に読み取る（存在確認 + 内容把握）

### Step 4: 結果の報告

実行結果をわかりやすく報告:
- 読み取り: ファイル内容を表示
- 作成: 作成したファイルのパスと内容の概要
- 編集: 変更箇所の差分
- 検索: マッチしたファイル一覧

---

## エラーハンドリング

| ケース | 対応 |
|--------|------|
| MCP `Access denied` | 標準ツール（Read, Write, Edit, Glob）にフォールバック |
| ファイルが存在しない | パスを確認し、作成するか提案 |
| ディレクトリが存在しない | 必要に応じてディレクトリを先に作成 |
| 編集対象の文字列が見つからない | ファイル内容を再確認し、正しい文字列を特定 |
