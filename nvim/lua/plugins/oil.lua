return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        columns = {
          "icon",
        },
        view_options = {
          show_hidden = true,
        },
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<C-v>"] = "actions.select_vsplit",
          ["<C-s>"] = "actions.select_split",
          ["<C-t>"] = "actions.select_tab",
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = "actions.close",
          ["<C-r>"] = "actions.refresh",
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["~"] = "actions.tcd",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
        },
      })

      -- Open oil with <Leader>e
      vim.keymap.set("n", "<Leader>e", "<CMD>Oil<CR>", { desc = "Open file explorer" })
      -- Open oil with -
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

      -- J/Kで5行移動のカスタムキーマップ
      vim.keymap.set({ "n", "v" }, "J", "5j", { desc = "5行下へ移動" })
      vim.keymap.set({ "n", "v" }, "K", "5k", { desc = "5行上へ移動" })
      -- 元のJ（行結合）は別のキーに割り当て
      vim.keymap.set("n", "<Leader>j", "J", { desc = "行を結合" })
      -- 元のKの機能（ホバードキュメント）は別のキーに割り当て
      vim.keymap.set("n", "<Leader>k", vim.lsp.buf.hover, { desc = "ホバードキュメント表示" })
    end,
  },
}
