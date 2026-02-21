return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        columns = {
          "icon",
        },
        win_options = {
          signcolumn = "yes:2",
        },
        view_options = {
          show_hidden = true,
        },
        keymaps = {
          ["g?"] = { "actions.show_help", desc = "ヘルプを表示" },
          ["<CR>"] = { "actions.select", desc = "エントリを開く" },
          ["<C-v>"] = { "actions.select_vsplit", desc = "垂直分割で開く" },
          ["<C-s>"] = { "actions.select_split", desc = "水平分割で開く" },
          ["<C-t>"] = { "actions.select_tab", desc = "新しいタブで開く" },
          ["<C-p>"] = { "actions.preview", desc = "プレビュー" },
          ["<C-c>"] = { "actions.close", desc = "閉じる" },
          ["<C-r>"] = { "actions.refresh", desc = "再読み込み" },
          ["-"] = { "actions.parent", desc = "親ディレクトリへ移動" },
          ["_"] = { "actions.open_cwd", desc = "作業ディレクトリを開く" },
          ["`"] = { "actions.cd", desc = "cdする" },
          ["~"] = { "actions.tcd", desc = "tcdする" },
          ["gs"] = { "actions.change_sort", desc = "ソート順を変更" },
          ["gx"] = { "actions.open_external", desc = "外部アプリで開く" },
          ["g."] = { "actions.toggle_hidden", desc = "隠しファイルを切り替え" },
          ["yy"] = {
            desc = "ファイル名をコピー",
            callback = function()
              local entry = require("oil").get_cursor_entry()
              if entry then
                vim.fn.setreg("+", entry.name)
                vim.notify("Copied: " .. entry.name)
              end
            end,
          },
          ["yp"] = {
            desc = "相対パスをコピー",
            callback = function()
              local entry = require("oil").get_cursor_entry()
              local dir = require("oil").get_current_dir()
              if entry and dir then
                local path = vim.fn.fnamemodify(dir .. entry.name, ":.")
                vim.fn.setreg("+", path)
                vim.notify("Copied: " .. path)
              end
            end,
          },
          ["yP"] = {
            desc = "絶対パスをコピー",
            callback = function()
              local entry = require("oil").get_cursor_entry()
              local dir = require("oil").get_current_dir()
              if entry and dir then
                local path = dir .. entry.name
                vim.fn.setreg("+", path)
                vim.notify("Copied: " .. path)
              end
            end,
          },
        },
      })

      -- Open oil with <Leader>e
      vim.keymap.set("n", "<Leader>e", "<CMD>Oil<CR>", { desc = "Open file explorer" })
      -- Open oil with -
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end,
  },
  -- Git status signs for oil.nvim
  {
    "refractalize/oil-git-status.nvim",
    dependencies = { "stevearc/oil.nvim" },
    config = true,
  },
}
