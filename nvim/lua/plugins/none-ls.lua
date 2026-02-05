return {
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local null_ls = require("null-ls")
      opts.sources = opts.sources or {}
      table.insert(opts.sources, null_ls.builtins.formatting.prettier.with({
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
      }))
    end,
  },
}
