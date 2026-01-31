---
description: "Homebrew CaskでClaude Codeをアップグレードする"
---

## 実行方法

以下のシェルスクリプトを実行してください:

```bash
$DOTFILES_DIR/claude/scripts/upgrade-claude.sh
```

`$DOTFILES_DIR` が設定されていない場合:

```bash
~/ghq/github.com/yuhgo/dotfiles/claude/scripts/upgrade-claude.sh
```

## スクリプトの処理内容

1. Homebrewの存在確認
2. 現在のバージョン情報を表示
3. `brew upgrade --cask claude-code` を実行
4. 結果を報告（成功/既に最新/エラー）

## 注意事項

- Homebrewがインストールされている必要があります
- Claude Codeが `brew install --cask claude-code` でインストールされている必要があります
