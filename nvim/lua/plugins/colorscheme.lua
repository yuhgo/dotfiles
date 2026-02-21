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

        -- 行番号を白に、現在行はオレンジ（bold）のまま
        vim.api.nvim_set_hl(0, "LineNr", { fg = "#DCD7BA" })
        vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#DCD7BA" })
        vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#DCD7BA" })
        local clnr = vim.api.nvim_get_hl(0, { name = "CursorLineNr" })
        clnr.bg = nil
        vim.api.nvim_set_hl(0, "CursorLineNr", clnr)

        -- DiagnosticSign系・GitSigns系も背景だけ消す
        for _, name in ipairs({
          "DiagnosticSignError", "DiagnosticSignWarn", "DiagnosticSignInfo", "DiagnosticSignHint",
          "GitSignsAdd", "GitSignsChange", "GitSignsDelete",
        }) do
          local hl = vim.api.nvim_get_hl(0, { name = name })
          hl.bg = nil
          vim.api.nvim_set_hl(0, name, hl)
        end

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
