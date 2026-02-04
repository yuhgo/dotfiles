# novim アンインストール計画

## 概要
`~/.local/bin/novim` にインストールされているnovimを完全にアンインストールする。

## 現状
- **シンボリックリンク**: `~/.local/bin/novim` → `~/.local/share/novim/bin/novim`
- **インストールディレクトリ**: `~/.local/share/novim/`
- Homebrewではなく、手動でインストールされている

## 実行手順

### 1. シンボリックリンクの削除
```bash
rm ~/.local/bin/novim
```

### 2. インストールディレクトリの削除
```bash
rm -rf ~/.local/share/novim
```

## 検証方法
```bash
which novim  # 「not found」になることを確認
ls ~/.local/share/novim  # ディレクトリが存在しないことを確認
```
