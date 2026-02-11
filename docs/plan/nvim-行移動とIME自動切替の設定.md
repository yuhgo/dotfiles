# Neovim: cmd+left/right 行頭行末移動 & 日本語IME自動切替

## Context

macOSではcmd+left/rightで行頭・行末に移動できるが、ターミナルのNeovimではこのキーが届かない。
また、日本語入力中に`jj`を押してもNormalモードに戻れない問題がある。
この2つを解決して、macOSネイティブに近い操作感をNeovimでも実現する。

## 前提条件

- `im-select` CLIツール: **インストール済み** (`/opt/homebrew/bin/im-select`)
- 英語入力のIM ID: `com.apple.keylayout.ABC`
- ターミナル: Ghostty（macOS）
- Neovim: LazyVim構成

## 変更ファイル

| ファイル | 操作 |
|---------|------|
| `ghostty/config` | 変更（keybind追加） |
| `nvim/lua/config/keymaps.lua` | 変更（Home/Endマッピング追加） |
| `nvim/lua/plugins/im-select.lua` | **新規作成** |

---

## Phase 1: Ghosttyでcmd+left/rightをエスケープシーケンスとして送信

`ghostty/config` に以下を追加:

```
# cmd+left/right で行頭/行末移動（Neovim用）
keybind = super+left=text:\x1b[H
keybind = super+right=text:\x1b[F
```

- `\x1b[H` = ANSI Home キーシーケンス
- `\x1b[F` = ANSI End キーシーケンス
- Neovim以外のターミナルアプリでもHome/Endとして機能する

## Phase 2: Neovimで全モードにHome/Endマッピング追加

`nvim/lua/config/keymaps.lua` の末尾に追加:

```lua
-- cmd+left/right で行頭/行末移動（Ghosttyから送られるHome/Endシーケンスに対応）
keymap("n", "<Home>", "0", { noremap = true, silent = true, desc = "行頭へ移動" })
keymap("n", "<End>", "$", { noremap = true, silent = true, desc = "行末へ移動" })
keymap("i", "<Home>", "<C-o>0", { noremap = true, silent = true, desc = "行頭へ移動" })
keymap("i", "<End>", "<C-o>$", { noremap = true, silent = true, desc = "行末へ移動" })
keymap("v", "<Home>", "0", { noremap = true, silent = true, desc = "行頭へ移動" })
keymap("v", "<End>", "$", { noremap = true, silent = true, desc = "行末へ移動" })
keymap("c", "<Home>", "<C-b>", { desc = "行頭へ移動" })
keymap("c", "<End>", "<C-e>", { desc = "行末へ移動" })
```

既存の `local keymap = vim.keymap.set` を再利用する。

## Phase 3: im-select.nvimプラグインで日本語IME自動切替

`nvim/lua/plugins/im-select.lua` を新規作成:

```lua
return {
  "keaising/im-select.nvim",
  event = "VeryLazy",
  config = function()
    require("im_select").setup({
      default_im_select = "com.apple.keylayout.ABC",
      default_command = "im-select",
      set_default_events = { "VimEnter", "FocusGained", "InsertLeave" },
      set_previous_events = { "InsertEnter" },
      async_switch_im = true,
    })
  end,
}
```

- Normalモードでは自動的に英語入力に切り替わる → `jj`が確実に動く
- Insertモードに戻ると前回のIM（日本語）が復元される

---

## 検証手順

### 1. Ghosttyのキー送信確認
```bash
# Ghosttyを再起動後
cat -v
# cmd+left → ^[[H が表示されること
# cmd+right → ^[[F が表示されること
```

### 2. Neovimでの行頭行末移動
1. `nvim` でファイルを開く
2. テキストの途中にカーソルを置く
3. cmd+left → カーソルが行頭に移動
4. cmd+right → カーソルが行末に移動
5. Insertモード・Visualモード・Commandモードでも同様に確認

### 3. 日本語入力中のjjエスケープ
1. `nvim` でファイルを開く
2. `i` でInsertモードに入る
3. 日本語入力に切り替えて日本語を入力
4. `jj` を押す → Normalモードに戻り、英語入力に自動切替
5. `j`/`k` がカーソル移動として動くことを確認
6. 再度 `i` → 日本語入力が復元されることを確認
