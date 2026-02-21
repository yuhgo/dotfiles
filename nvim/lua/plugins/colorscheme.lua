return {
  -- LazyVimのデフォルトカラースキームを変更
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
    },
  },

  -- kanagawaカラースキームを追加
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      compile = true,
      undercurl = true,
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = true,
      dimInactive = false,
      terminalColors = true,
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd("colorscheme kanagawa")

      -- カラースキーム適用後に全ウィンドウ系の背景を透過
      local function set_transparent()
        -- 背景をNONEにするグループ（fgは元の色を保持）
        local bg_none = {
          "Normal",
          "NormalNC",
          "NormalSB",
          "NormalFloat",
          "FloatBorder",
          "FloatTitle",
          "SignColumn",
          "LineNr",
          "LineNrAbove",
          "LineNrBelow",
          "FoldColumn",
          "CursorLineSign",
          "CursorLineFold",
          "SnacksNormal",
          "SnacksNormalNC",
          "SnacksDashboardNormal",
          "SnacksPickerNormal",
          "NeoTreeNormal",
          "NeoTreeNormalNC",
          "NeoTreeEndOfBuffer",
        }
        for _, group in ipairs(bg_none) do
          local hl = vim.api.nvim_get_hl(0, { name = group })
          hl.bg = nil
          vim.api.nvim_set_hl(0, group, hl)
        end

        -- 行番号を薄い白に（fujiGray）、現在行はオレンジ（bold）のまま
        vim.api.nvim_set_hl(0, "LineNr", { fg = "#727169" })
        vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#727169" })
        vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#727169" })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#FFB380", bold = true })

        -- DiagnosticSign系・GitSigns系も背景だけ消す
        for _, name in ipairs({
          "DiagnosticSignError", "DiagnosticSignWarn", "DiagnosticSignInfo", "DiagnosticSignHint",
          "GitSignsAdd", "GitSignsChange", "GitSignsDelete",
        }) do
          local hl = vim.api.nvim_get_hl(0, { name = name })
          hl.bg = nil
          vim.api.nvim_set_hl(0, name, hl)
        end

        -- カーソル十字ハイライト（fujiWhite #DCD7BA を ~15% opacity で合成した白みのある色）
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#3A3A42" })
        vim.api.nvim_set_hl(0, "CursorColumn", { bg = "#3A3A42" })

        -- 行番号の右側にボーダー（WinSeparator）
        vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#727169", bg = "NONE" })
      end

      set_transparent()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_transparent,
      })
    end,
  },
}
