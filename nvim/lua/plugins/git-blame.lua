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
      -- パフォーマンス: CursorMoved(毎移動)→CursorHold(停止後)に変更
      schedule_event = "CursorHold",
      clear_event = "CursorHoldI",
      delay = 500, -- 500ms debounce
    },
  },

  -- gitsigns.nvim: ポップアップでblame詳細を表示（キーマップで呼び出し）
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = false,
      update_debounce = 200, -- デフォルト100ms→200msに緩和
      attach_to_untracked = false, -- 未追跡ファイルをスキップ
    },
    keys = {
      { "<leader>gB", function() require("gitsigns").blame_line({ full = true }) end, desc = "Blame Line (popup)" },
    },
  },
}
