---
name: nvim-debug
description: Debug Neovim configuration, keymaps, plugins, and LSP settings using headless mode
allowed-tools: Bash, Read, Grep, Glob
---

# Neovim Debug Skill

Neovimの設定をヘッドレスモードでデバッグするスキル。

## 使用可能なデバッグコマンド

### 1. キーマップの確認

特定のキーのマッピングを確認：
```bash
nvim --headless -c "map <KEY>" -c "q" 2>&1
# 例: nvim --headless -c "map K" -c "q" 2>&1
```

詳細なマッピング情報（verbose）：
```bash
nvim --headless -c "verbose nmap <KEY>" -c "q" 2>&1
# 例: nvim --headless -c "verbose nmap K" -c "q" 2>&1
```

全キーマップを出力：
```bash
nvim --headless -c "redir! > /tmp/keymaps.txt | silent map | redir END" -c "q" && cat /tmp/keymaps.txt
```

### 2. バッファローカルキーマップの確認

特定ファイルを開いた状態でのバッファローカルマッピング：
```bash
nvim --headless -c "e <FILE>" -c "sleep 2" -c "lua for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, 'n')) do if map.lhs == '<KEY>' then print(vim.inspect(map)) end end" -c "q" 2>&1
```

### 3. プラグイン・設定エラーの確認

起動時のエラーを確認：
```bash
nvim --headless -c "messages" -c "q" 2>&1
```

LazyVimプラグインの状態：
```bash
nvim --headless -c "Lazy" -c "q" 2>&1
```

### 4. LSPの状態確認

LSPサーバーの一覧：
```bash
nvim --headless -c "e <FILE>" -c "sleep 2" -c "lua print(vim.inspect(vim.lsp.get_clients()))" -c "q" 2>&1
```

### 5. オプション・変数の確認

Vimオプションの確認：
```bash
nvim --headless -c "set <OPTION>?" -c "q" 2>&1
# 例: nvim --headless -c "set number?" -c "q" 2>&1
```

Lua変数の確認：
```bash
nvim --headless -c "lua print(vim.inspect(vim.<VARIABLE>))" -c "q" 2>&1
# 例: nvim --headless -c "lua print(vim.inspect(vim.g.mapleader))" -c "q" 2>&1
```

### 6. ヘルスチェック

Neovimのヘルスチェック：
```bash
nvim --headless -c "checkhealth" -c "w! /tmp/health.txt" -c "q" && cat /tmp/health.txt
```

### 7. ランタイムパスの確認

```bash
nvim --headless -c "lua print(vim.inspect(vim.opt.rtp:get()))" -c "q" 2>&1
```

### 8. autocmdの確認

```bash
nvim --headless -c "autocmd <EVENT>" -c "q" 2>&1
# 例: nvim --headless -c "autocmd LspAttach" -c "q" 2>&1
```

## デバッグ手順

1. まずエラーメッセージを確認
2. 関連するキーマップやプラグインの状態を確認
3. バッファローカルの設定が上書きしていないか確認
4. autocmdが意図しない動作をしていないか確認

## よくある問題

### キーマップが効かない
- グローバルマップは設定されているが、バッファローカルで上書きされている
- プラグインが後からキーマップを設定している
- autocmd（LspAttach等）で上書きされている

### プラグインエラー
- `messages`コマンドでエラーを確認
- `Lazy`コマンドでプラグインの状態を確認
- `checkhealth`で依存関係を確認
