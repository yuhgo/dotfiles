return {
  -- Mason: 追加でインストールするツールを指定
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "prettier",
      },
    },
  },

  -- LSP servers: LazyVimの設定を拡張
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- 全サーバー共通: Kキーマップを無効化
        ["*"] = {
          keys = {
            { "K", false },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                checkThirdParty = false,
              },
            },
          },
        },
        ts_ls = {},
        pyright = {},
        gopls = {},
        rust_analyzer = {},
        html = {},
        cssls = {},
        jsonls = {},
        marksman = {},
        eslint = {},
      },
    },
  },
}
