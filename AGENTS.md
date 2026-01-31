
# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

個人のdotfiles管理リポジトリ。各種開発ツールの設定ファイルをシンボリックリンクで管理する。

## セットアップコマンド

### Claude Code
```bash
# 設定ファイル（エージェント、コマンド、権限設定を含む）
ln -s $(pwd)/claude ~/.claude
```

### OpenCode
```bash
# グローバル設定（AGENTS.md、エージェント、コマンド、設定ファイル）
ln -s $(pwd)/opencode ~/.config/opencode
```

### Cursor IDE
```bash
ln -s $(pwd)/cursor/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
```

### Ghostty
```bash
ln -s $(pwd)/ghostty/config ~/.config/ghostty/config
```

### Inkdrop
```bash
ln -s $(pwd)/inkdrop/init.js ~/.config/inkdrop/init.js
ln -s $(pwd)/inkdrop/keymap.json ~/.config/inkdrop/keymap.json
```

## アーキテクチャ

### Claude Code拡張 (`claude/`)

**エージェント** (`agents/`): 専門特化型エージェント20種
- `code-reviewer.md`: コードレビュー、バグ・セキュリティ問題検出
- `backend-architect.md`: バックエンド設計、データ整合性、フォールトトレランス
- `plan-creator.md` / `plan-executor.md`: 実装計画の作成と実行
- `pm-agent.md`: プロジェクト管理、ドキュメント維持、ミス分析

**コマンド** (`commands/`):
- `/sc:*` (27種): SuperClaudeコマンド群（analyze, build, design, implement, review, test等）
- `/git:*` (4種): Git操作（branch-name, commit-message, history, pr）
- `/create-plan`, `/start-plan`: 実装計画ワークフロー
- `/serena`: Serena MCP連携コマンド

**設定ファイル**:
- `settings.json`: 権限設定（allow/deny）、通知フック、ステータスライン
- `statusline-git.sh`: コンテキスト使用率、gitブランチ/差分、セッションコスト表示
- `mcp-templates.json`: MCPサーバーテンプレート

### OpenCode設定 (`opencode/`)

**グローバルAGENTS.md**:
- プロジェクト固有のAGENTS.mdがない場合に参照される
- dotfilesリポジトリ全体の設定方針を記載

**エージェント** (`agents/`):
- `~/.config/opencode/agents/`に配置される専門特化型エージェント
- Markdownファイルで定義

**コマンド** (`commands/`):
- `~/.config/opencode/commands/`に配置されるカスタムコマンド
- 頻繁に使用するタスクのテンプレート

**設定ファイル**:
- `opencode.json`: グローバル設定（テーマ、モデル、権限等）

### エディタ共通設定方針
- **Vim統一**: Cursor, Inkdrop共にVimモード有効
  - `jj` → Escape（インサートモード）
  - `J/K` → 5行移動、`H/L` → 行頭/行末
- **フォーマッター**: JS/TSはPrettier、GoはGolang標準、DartはDart標準
- **フォント**: JetBrains Mono + HackGenNerd（日本語対応）

### Ghostty設定
テーマ: Kanagawa Wave、背景透過80%、ぼかし20、タブスタイルタイトルバー

## 注意事項

- `.local`/`.private`拡張子ファイルはgitignore対象（機密情報用）
- 設定変更時は元アプリケーションの動作確認を行うこと
- Claude Code権限設定で`sudo`, `rm`, `git push`等は明示的に禁止済み
