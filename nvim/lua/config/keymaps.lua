local keymap = vim.keymap.set

-- jj to escape insert mode
keymap("i", "jj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

-- J/K to move 5 lines
keymap({ "n", "v" }, "J", "5j", { noremap = true, silent = true, desc = "Move 5 lines down" })
keymap({ "n", "v" }, "K", "5k", { noremap = true, silent = true, desc = "Move 5 lines up" })

-- Remap original J (join lines) to Leader+j
keymap("n", "<Leader>j", "J", { noremap = true, silent = true, desc = "Join lines" })
