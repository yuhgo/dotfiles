-- LazyVim用のキーマップ設定
-- LazyVimのデフォルトキーマップを上書きしたい場合はここに書く

local keymap = vim.keymap.set

-- jjでエスケープ（インサートモードから抜ける）
keymap("i", "jj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

-- J/Kで5行移動
keymap({ "n", "v" }, "J", "5j", { noremap = true, silent = true, desc = "5行下へ移動" })
keymap({ "n", "v" }, "K", "5k", { noremap = true, silent = true, desc = "5行上へ移動" })

-- 元のJ（行結合）をLeader+jに移動
keymap("n", "<Leader>j", "J", { noremap = true, silent = true, desc = "行を結合" })

-- 元のKの機能（ホバードキュメント）をLeader+kに移動
keymap("n", "<Leader>k", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "ホバードキュメント表示" })
