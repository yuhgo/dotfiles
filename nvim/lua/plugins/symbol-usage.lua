return {
  -- symbol-usage.nvim: VS Code風のコードレンズ（参照数表示）
  -- 関数・メソッド・インターフェース・型定義の上に参照数を表示
  {
    "Wansmer/symbol-usage.nvim",
    event = "BufReadPre",
    opts = {
      vt_position = "above",
    },
    keys = {
      { "<leader>uR", function() require("symbol-usage").toggle_globally() end, desc = "Toggle Reference Count" },
    },
  },
}
