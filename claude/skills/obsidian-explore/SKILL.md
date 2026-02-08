
---
name: obsidian-explore
description: Obsidian vault配下のディレクトリやファイルを効率的に探索し、指定されたファイルやディレクトリを見つけ出す。ユーザーが「obsidianの○○を探して」「ノートを検索して」「obsidianのworkを見て」と言ったときに使用。
allowed-tools: mcp__obsidian-vault__list_directory, mcp__obsidian-vault__directory_tree, mcp__obsidian-vault__search_files, mcp__obsidian-vault__read_file, mcp__obsidian-vault__read_text_file, mcp__obsidian-vault__read_multiple_files, mcp__obsidian-vault__get_file_info, mcp__obsidian-vault__list_directory_with_sizes, Read, Glob, Grep
---

# Obsidian Vault Explorer

Obsidian vault内のディレクトリやファイルを効率的に探索し、ユーザーが指定した情報を素早く見つけ出します。

## Vault ルート

```
/Users/yamamotoyugo/ghq/github.com/yuhgo/obsidian
```

---

## ツールの選択戦略

まずMCPツールを試し、`Access denied` エラーが出たら標準ツールにフォールバックする。

| MCPツール | フォールバック |
|----------|-------------|
| `list_directory` | `Glob(pattern: "*", path: "<vault_root>/<dir>")` |
| `directory_tree` | `Glob(pattern: "**/*.md", path: "<vault_root>/<dir>")` |
| `search_files` | `Grep(pattern: "keyword", path: "<vault_root>")` |
| `read_file` | `Read(file_path: "<vault_root>/<path>")` |
| `read_multiple_files` | 複数の `Read` を並列実行 |
| `get_file_info` | `Glob` で更新日時順に確認 |
| `list_directory_with_sizes` | `Glob` で確認 |

---

## Obsidian Vault ディレクトリ構造

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

## 実行手順

### Step 1: ユーザーの要求を理解する

ユーザーの指示から以下を判断:
- **対象**: どのディレクトリ・ファイルを探しているか
- **操作**: リスト表示 / 内容読み取り / 検索 / ファイル情報確認
- **範囲**: 特定パス / キーワード検索 / 全体探索

### Step 2: 最適な探索戦略を選択

| ユーザーの要求 | 推奨手順 |
|--------------|---------|
| 「○○ディレクトリの中身を見て」 | 指定パスを直接リスト表示 |
| 「○○の全体構造を見て」 | ツリー表示（大きいディレクトリは絞り込み） |
| 「○○というファイルを探して」 | ファイル名・内容で検索 |
| 「○○の内容を見て」 | ファイルを読み取り |
| 「○○のファイルをまとめて」 | リスト後に一括読み取り |
| 「○○のファイル情報を教えて」 | サイズ・更新日時など |

### Step 3: 探索の実行

1. **パスの構築**: ディレクトリ構造を参考に絶対パスを構築
2. **段階的な探索**: まず概要を掴み、必要に応じて深掘り
3. **検索が必要な場合**: キーワード検索で絞り込み
4. **大量の結果**: カテゴリ分けして見やすく整理

### Step 4: 結果の報告

- **ディレクトリリスト**: ディレクトリとファイルを区別して表示
- **ファイル内容**: 要求に応じて全文または要約
- **検索結果**: マッチしたファイルのパスと該当箇所

---

## 探索のコツ

1. **ディレクトリ構造を活用**: 上記の構造を手がかりに、まず最も可能性の高い場所を探す
2. **段階的に深掘り**: いきなり全体を取得するのではなく、1階層ずつ確認
3. **検索を活用**: ファイル名や内容が分かっている場合は検索が最速
4. **並列実行**: 複数の候補ディレクトリがある場合は並列で探索

---

## エラーハンドリング

| ケース | 対応 |
|--------|------|
| MCP `Access denied` | 標準ツール（Read, Glob, Grep）にフォールバック |
| パスが存在しない | 親ディレクトリを確認し、正しいパスを提案 |
| 検索結果が0件 | 検索キーワードを変えて再試行、またはディレクトリを手動探索 |
| ディレクトリ構造が想定と異なる | ルートをリスト表示して実際の構造を確認 |
