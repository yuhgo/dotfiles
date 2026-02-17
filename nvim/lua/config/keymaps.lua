-- LazyVim用のキーマップ設定
-- LazyVimのデフォルトキーマップを上書きしたい場合はここに書く

local keymap = vim.keymap.set

-- jjでエスケープ（インサートモードから抜ける）
keymap("i", "jj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })
-- 日本語入力中のjj（っj）でもエスケープ
keymap("i", "っj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode (Japanese)" })

-- J/Kで5行移動（nowait: which-keyのtimeout待ちをスキップして即座に実行）
keymap({ "n", "v" }, "J", "5j", { noremap = true, silent = true, nowait = true, desc = "5行下へ移動" })
keymap({ "n", "v" }, "K", "5k", { noremap = true, silent = true, nowait = true, desc = "5行上へ移動" })

-- 元のJ（行結合）をLeader+jに移動
keymap("n", "<Leader>j", "J", { noremap = true, silent = true, desc = "行を結合" })

-- LSP UI（lspsaga）
keymap("n", "<Leader>k", "<cmd>Lspsaga hover_doc<CR>", { noremap = true, silent = true, desc = "ホバードキュメント表示" })
keymap("n", "gl", "<cmd>Lspsaga show_line_diagnostics<CR>", { noremap = true, silent = true, desc = "行の診断を表示" })
keymap("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { noremap = true, silent = true, desc = "前の診断へ" })
keymap("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", { noremap = true, silent = true, desc = "次の診断へ" })
keymap("n", "<Leader>ca", "<cmd>Lspsaga code_action<CR>", { noremap = true, silent = true, desc = "コードアクション" })
keymap("n", "<Leader>cr", "<cmd>Lspsaga rename<CR>", { noremap = true, silent = true, desc = "リネーム" })
keymap("n", "gp", "<cmd>Lspsaga peek_definition<CR>", { noremap = true, silent = true, desc = "定義をプレビュー" })
keymap("n", "gf", "<cmd>Lspsaga finder<CR>", { noremap = true, silent = true, desc = "参照・定義を検索" })

-- cmd+left/right で行頭/行末移動（Ghosttyから送られるHome/Endシーケンスに対応）
keymap("n", "<Home>", "0", { noremap = true, silent = true, desc = "行頭へ移動" })
keymap("n", "<End>", "$", { noremap = true, silent = true, desc = "行末へ移動" })
keymap("i", "<Home>", "<C-o>0", { noremap = true, silent = true, desc = "行頭へ移動" })
keymap("i", "<End>", "<C-o>$", { noremap = true, silent = true, desc = "行末へ移動" })
keymap("v", "<Home>", "0", { noremap = true, silent = true, desc = "行頭へ移動" })
keymap("v", "<End>", "$", { noremap = true, silent = true, desc = "行末へ移動" })
keymap("c", "<Home>", "<C-b>", { desc = "行頭へ移動" })
keymap("c", "<End>", "<C-e>", { desc = "行末へ移動" })

-- 現在のファイルをFinderで表示
keymap("n", "<Leader>fo", function()
  vim.fn.system("open -R " .. vim.fn.shellescape(vim.fn.expand("%:p")))
end, { noremap = true, silent = true, desc = "Finderで表示" })
