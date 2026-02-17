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
        -- K（ホバー）を無効化: keymaps.luaで5k移動に使っているため
        -- opts_extendにより他のデフォルトキーマップ(gd,gr等)はマージされて残る
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
