---
description: "Upgrade Claude Code via Homebrew Cask"
---

## 概要

Homebrew CaskでインストールされたClaude Codeを最新バージョンにアップグレードします。

## 実行手順

1. **現在のバージョン確認**
   ```bash
   brew info --cask claude-code
   ```

2. **アップグレード実行**
   ```bash
   brew upgrade --cask claude-code
   ```

3. **結果報告**
   - アップグレード成功時：新しいバージョン番号を表示
   - 既に最新の場合：その旨を報告
   - エラー発生時：エラー内容を報告

## 使用方法

```
/upgrade-claude
```

## 注意事項

- Homebrewがインストールされている必要があります
- Claude Codeが `brew install --cask claude-code` でインストールされている必要があります
