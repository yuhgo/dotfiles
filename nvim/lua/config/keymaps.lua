-- LazyVim用のキーマップ設定
-- LazyVimのデフォルトキーマップを上書きしたい場合はここに書く

local keymap = vim.keymap.set

-- jjでエスケープ（インサートモードから抜ける）
keymap("i", "jj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })
-- 日本語入力中のjj（っj）でもエスケープ
keymap("i", "っj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode (Japanese)" })

-- J/Kで5行移動
keymap({ "n", "v" }, "J", "5j", { noremap = true, silent = true, desc = "5行下へ移動" })
keymap({ "n", "v" }, "K", "5k", { noremap = true, silent = true, desc = "5行上へ移動" })

-- 元のJ（行結合）をLeader+jに移動
keymap("n", "<Leader>j", "J", { noremap = true, silent = true, desc = "行を結合" })

-- 元のKの機能（ホバードキュメント）をLeader+kに移動
keymap("n", "<Leader>k", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "ホバードキュメント表示" })

-- cmd+left/right で行頭/行末移動（Ghosttyから送られるHome/Endシーケンスに対応）
keymap("n", "<Home>", "0", { noremap = true, silent = true, desc = "行頭へ移動" })
keymap("n", "<End>", "$", { noremap = true, silent = true, desc = "行末へ移動" })
keymap("i", "<Home>", "<C-o>0", { noremap = true, silent = true, desc = "行頭へ移動" })
keymap("i", "<End>", "<C-o>$", { noremap = true, silent = true, desc = "行末へ移動" })
keymap("v", "<Home>", "0", { noremap = true, silent = true, desc = "行頭へ移動" })
keymap("v", "<End>", "$", { noremap = true, silent = true, desc = "行末へ移動" })
keymap("c", "<Home>", "<C-b>", { desc = "行頭へ移動" })
keymap("c", "<End>", "<C-e>", { desc = "行末へ移動" })
