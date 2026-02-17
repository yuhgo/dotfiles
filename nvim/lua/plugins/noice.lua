return {
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      -- ホバーは lspsaga に任せるので noice の LSP ホバーは無効化
      lsp = {
        hover = {
          enabled = false,
        },
        signature = {
          enabled = false,
        },
      },
    },
  },

  -- フローティングウィンドウのハイライト調整
  {
    "rebelot/kanagawa.nvim",
    opts = function(_, opts)
      opts.overrides = function(colors)
        local theme = colors.theme
        return {
          NormalFloat = { bg = theme.ui.bg_p1 },
          FloatBorder = { bg = theme.ui.bg_p1, fg = theme.ui.ind },
          NoicePopup = { bg = theme.ui.bg_p1 },
          NoicePopupBorder = { bg = theme.ui.bg_p1, fg = theme.ui.ind },
        }
      end
      return opts
    end,
  },
}
