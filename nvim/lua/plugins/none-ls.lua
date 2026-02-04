return {
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "williamboman/mason.nvim",
    },
    config = function()
      local null_ls = require("null-ls")

      null_ls.setup({
        sources = {
          -- Formatters
          null_ls.builtins.formatting.prettier.with({
            filetypes = {
              "javascript",
              "typescript",
              "javascriptreact",
              "typescriptreact",
              "css",
              "scss",
              "html",
              "json",
              "yaml",
              "markdown",
              "graphql",
            },
          }),
        },
      })
    end,
  },

  -- ESLint integration via eslint-lsp (more reliable than eslint_d)
  {
    "neovim/nvim-lspconfig",
    opts = function()
      -- eslint is handled by eslint-lsp which is included in mason
    end,
  },
}
