return {
  -- Mason: LSP/Formatter/Linter installer
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      -- Auto-install formatters
      local ensure_installed = {
        "prettier",
      }

      local mr = require("mason-registry")
      for _, tool in ipairs(ensure_installed) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
          p:install()
        end
      end
    end,
  },

  -- Mason LSP config bridge
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",           -- Lua
          "ts_ls",            -- TypeScript/JavaScript
          "pyright",          -- Python
          "gopls",            -- Go
          "rust_analyzer",    -- Rust
          "html",             -- HTML
          "cssls",            -- CSS
          "jsonls",           -- JSON
          "marksman",         -- Markdown
          "eslint",           -- ESLint (LSP version)
        },
        automatic_installation = true,
      })
    end,
  },

  -- LSP keymaps (Nvim 0.11+ style)
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- LSP servers to enable
      local servers = {
        "lua_ls",
        "ts_ls",
        "pyright",
        "gopls",
        "rust_analyzer",
        "html",
        "cssls",
        "jsonls",
        "marksman",
        "eslint",
      }

      -- Enable LSP servers using vim.lsp.enable (Nvim 0.11+)
      vim.lsp.enable(servers)

      -- Setup keymaps when LSP attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local keymap = vim.keymap.set
          local opts = { buffer = bufnr, silent = true }

          keymap("n", "gd", vim.lsp.buf.definition, opts)
          keymap("n", "gD", vim.lsp.buf.declaration, opts)
          keymap("n", "gr", vim.lsp.buf.references, opts)
          keymap("n", "gi", vim.lsp.buf.implementation, opts)
          keymap("n", "<Leader>rn", vim.lsp.buf.rename, opts)
          keymap("n", "<Leader>ca", vim.lsp.buf.code_action, opts)
          keymap("n", "<Leader>f", function()
            vim.lsp.buf.format({
              async = true,
              filter = function(client)
                -- Prefer null-ls (prettier) for formatting
                if client.name == "null-ls" then
                  return true
                end
                -- Fallback to other LSPs only if null-ls is not available
                local clients = vim.lsp.get_clients({ bufnr = bufnr })
                for _, c in ipairs(clients) do
                  if c.name == "null-ls" then
                    return false
                  end
                end
                return true
              end,
            })
          end, opts)
          keymap("n", "[d", vim.diagnostic.goto_prev, opts)
          keymap("n", "]d", vim.diagnostic.goto_next, opts)
          keymap("n", "<Leader>d", vim.diagnostic.open_float, opts)
        end,
      })
    end,
  },
}
