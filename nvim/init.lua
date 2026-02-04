-- Set leader key FIRST (before lazy.nvim loads)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Load options
require("config.options")

-- Load keymaps
require("config.keymaps")

-- Bootstrap and setup lazy.nvim
require("config.lazy")

-- Global keymaps (after plugins loaded)
vim.keymap.set("n", "<Leader>f", function()
  vim.lsp.buf.format({ async = true })
end, { noremap = true, silent = true, desc = "Format buffer" })
