-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key before loading lazy.nvim (LazyVim requirement)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Load options and keymaps before lazy.nvim
require("config.options")
require("config.keymaps")

-- Setup lazy.nvim with LazyVim
require("lazy").setup({
	spec = {
		-- LazyVimをインポート
		{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
		-- LazyVim extras
		{ import = "lazyvim.plugins.extras.lang.tailwind" },
		-- 自分のプラグイン設定を読み込む
		{ import = "plugins" },
	},
	defaults = {
		lazy = true,
		version = false,
	},
	install = { colorscheme = { "tokyonight", "habamax" } },
	checker = { enabled = false },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
