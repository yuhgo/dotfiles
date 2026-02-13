return {
  -- git-blame.nvim: GitLensのようにカーソル行のblame情報を常時表示
  {
    "f-person/git-blame.nvim",
    event = "BufReadPost",
    opts = {
      enabled = true,
      date_format = "%Y-%m-%d",
      message_when_not_committed = "未コミット",
      virtual_text_column = 80,
    },
  },

  -- gitsigns.nvim: ポップアップでblame詳細を表示（キーマップで呼び出し）
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = false,
    },
    keys = {
      { "<leader>gB", function() require("gitsigns").blame_line({ full = true }) end, desc = "Blame Line (popup)" },
    },
  },
}
