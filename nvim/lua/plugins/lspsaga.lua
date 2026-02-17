return {
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    opts = {
      -- ホバーのUI設定
      hover = {
        max_width = 0.6,
        max_height = 0.5,
        open_link = "gx",
      },
      -- 診断のUI設定
      diagnostic = {
        show_code_action = true,
        jump_num_shortcut = true,
        max_width = 0.6,
      },
      -- コードアクションのUI設定
      code_action = {
        show_server_name = true,
        extend_gitsigns = false,
      },
      -- シンボルの使用箇所検索
      finder = {
        max_height = 0.5,
        left_width = 0.3,
        right_width = 0.3,
        keys = {
          toggle_or_open = "<CR>",
          quit = "q",
          vsplit = "v",
          split = "s",
        },
      },
      -- 定義プレビュー
      definition = {
        width = 0.6,
        height = 0.5,
      },
      -- ライトバルブ（コードアクションがあるときの表示）
      lightbulb = {
        enable = true,
        sign = true,
        virtual_text = false,
      },
      -- パンくずリスト（ウィンドウバーにシンボルパスを表示）
      symbol_in_winbar = {
        enable = true,
      },
      -- UIの見た目
      ui = {
        border = "rounded",
        title = true,
      },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
}
