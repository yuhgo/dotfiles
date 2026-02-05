# Neovim LazyVim設定計画

## 概要
既存のnvim設定を削除し、LazyVimを使用した新しいnvim設定をdotfilesで管理する。

## 要件
- LazyVimを使用したプラグイン管理
- テーマ: kanagawa
- カスタムキーマップ: `J` で5行下移動、`K` で5行上移動
- dotfilesでシンボリックリンク管理

## ディレクトリ構成

```
dotfiles/
└── nvim/
    ├── init.lua                    # エントリーポイント（lazy.nvimのブートストラップ）
    └── lua/
        ├── config/
        │   ├── options.lua         # 基本オプション設定
        │   ├── keymaps.lua         # カスタムキーマップ（J/K移動など）
        │   └── lazy.lua            # lazy.nvimの設定
        └── plugins/
            └── colorscheme.lua     # kanagawaテーマ設定
```

## 実装フェーズ

### Phase 1: 既存nvim設定のバックアップと削除
- [ ] `~/.config/nvim` をバックアップ（存在する場合）
- [ ] `~/.local/share/nvim` を削除（プラグインキャッシュ）
- [ ] `~/.local/state/nvim` を削除（状態ファイル）
- [ ] `~/.cache/nvim` を削除（キャッシュ）

### Phase 2: dotfiles内にnvim設定を作成

#### 2.1 init.lua（エントリーポイント）
```lua
-- lazy.nvimのブートストラップ
require("config.lazy")
```

#### 2.2 lua/config/lazy.lua（lazy.nvim設定）
```lua
-- lazy.nvimのインストールとセットアップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  change_detection = {
    notify = false,
  },
})
```

#### 2.3 lua/config/options.lua（基本設定）
```lua
local opt = vim.opt

-- 行番号
opt.number = true
opt.relativenumber = true

-- インデント
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- 検索
opt.ignorecase = true
opt.smartcase = true

-- その他
opt.termguicolors = true
opt.signcolumn = "yes"
opt.clipboard = "unnamedplus"
```

#### 2.4 lua/config/keymaps.lua（キーマップ）
```lua
local keymap = vim.keymap.set

-- jjでエスケープ（インサートモードから抜ける）
keymap("i", "jj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

-- J/Kで5行移動
keymap({ "n", "v" }, "J", "5j", { noremap = true, silent = true, desc = "Move 5 lines down" })
keymap({ "n", "v" }, "K", "5k", { noremap = true, silent = true, desc = "Move 5 lines up" })

-- 元のJ（行結合）をLeader+jに移動
keymap("n", "<Leader>j", "J", { noremap = true, silent = true, desc = "Join lines" })
```

#### 2.5 lua/plugins/colorscheme.lua（テーマ設定）
```lua
return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        compile = false,
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = { bold = true },
        typeStyle = {},
        transparent = false,
        dimInactive = false,
        terminalColors = true,
      })
      vim.cmd("colorscheme kanagawa")
    end,
  },
}
```

### Phase 3: シンボリックリンクの設定
- [ ] `~/.config/nvim` → `dotfiles/nvim` へのシンボリックリンク作成
- [ ] READMEにセットアップ手順を追記

### Phase 4: 動作確認
- [ ] nvimを起動してlazy.nvimが自動インストールされることを確認
- [ ] kanagawaテーマが適用されることを確認
- [ ] `J`で5行下、`K`で5行上に移動できることを確認

## シンボリックリンクコマンド

### ユーザーが手動で実行するコマンド
以下のコマンドは権限の都合上、ユーザー自身で実行してください。

```bash
# 既存設定のバックアップ（存在する場合）
mv ~/.config/nvim ~/.config/nvim.bak

# キャッシュ削除（クリーンな状態にするため）
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim

# シンボリックリンク作成（dotfilesディレクトリで実行）
ln -s $(pwd)/nvim ~/.config/nvim
```

## 注意事項
- `J`キーを5行移動に使うため、元の行結合機能（Join lines）は`<Leader>j`に移動
- `K`キーを5行移動に使うため、元のヘルプ表示機能は上書きされる

## 検証方法
1. `nvim`を起動 → プラグインが自動インストールされる
2. テーマがkanagawaになっていることを目視確認
3. インサートモードで`jj`を押してノーマルモードに戻ることを確認
4. ノーマルモードで`J`を押して5行下に移動することを確認
5. ノーマルモードで`K`を押して5行上に移動することを確認
