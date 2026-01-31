# opencode Global AGENTS.md

このファイルはOpenCodeのグローバル設定を提供します。

## リポジトリ概要

個人のdotfiles管理リポジトリ。各種開発ツールの設定ファイルをシンボリックリンクで管理する。

## OpenCodeセットアップ

### グローバル設定
```bash
# グローバル設定ディレクトリをシンボリックリンク
ln -s $(pwd)/opencode ~/.config/opencode
```

### グローバルAGENTS.mdの位置
- プロジェクト固有の`AGENTS.md`がない場合、本ファイルが参照される
- プロジェクト固有の設定が優先される

## エディタ共通設定方針

- **Vim統一**: インサートモードで`jj` → Escape
- **フォーマッター**: 
  - JS/TS: Prettier
  - Go: Golang標準
  - Dart: Dart標準
- **フォント**: JetBrains Mono + HackGenNerd（日本語対応）

## 注意事項

- `.local`/`.private`拡張子ファイルは機密情報用
gitignore対象
- 設定変更時は元アプリケーションの動作確認を行うこと

## 権限設定

以下の操作は明示的な許可が必要:
- `sudo`コマンド
- `rm`による削除
- `git push`

## エージェント構成

`~/.config/opencode/agents/`に配置:
- 専門特化型エージェントを定義
- Markdownファイルで管理

## カスタムコマンド

`~/.config/opencode/commands/`に配置:
- 頻繁に使用するタスクのテンプレート
- `/command-name`で呼び出し可能
