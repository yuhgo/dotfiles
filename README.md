# dotfiles

個人の設定ファイル管理リポジトリ

## 構成

- `cursor/` - Cursor IDE設定
- `zsh/` - Zsh設定

## セットアップ

### Cursor

ln -s $(pwd)/cursor/settings.json ~/Library/Application\ Support/Cursor/User/settings.json

### Zsh

ln -s $(pwd)/zsh/.zshrc ~/.zshrc

## 秘密情報の管理

`.zshrc` はこのリポジトリでバージョン管理するため、APIキーやトークンなどの秘密情報を直接記載しないこと。

マシン固有の秘密情報が必要な場合は `~/.zshrc.local` に記載する。このファイルは `.zshrc` から自動的に読み込まれるが、dotfilesリポジトリの管理対象外。

```zsh
# ~/.zshrc.local の例
export GITHUB_TOKEN=xxx
export OPENAI_API_KEY=xxx
```
