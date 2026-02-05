return {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<Leader>gd", "<CMD>DiffviewOpen<CR>", desc = "Diffview: 変更を表示" },
      { "<Leader>gh", "<CMD>DiffviewFileHistory %<CR>", desc = "Diffview: ファイル履歴" },
      { "<Leader>gH", "<CMD>DiffviewFileHistory<CR>", desc = "Diffview: 全体履歴" },
      { "<Leader>gq", "<CMD>DiffviewClose<CR>", desc = "Diffview: 閉じる" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = {
          layout = "diff2_horizontal",
        },
        merge_tool = {
          layout = "diff3_mixed",
        },
        file_history = {
          layout = "diff2_horizontal",
        },
      },
      file_panel = {
        win_config = {
          position = "left",
          width = 35,
        },
      },
      keymaps = {
        view = {
          ["q"] = "<CMD>DiffviewClose<CR>",
        },
        file_panel = {
          ["q"] = "<CMD>DiffviewClose<CR>",
        },
        file_history_panel = {
          ["q"] = "<CMD>DiffviewClose<CR>",
        },
      },
    },
  },
}
