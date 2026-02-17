return {
  -- symbol-usage.nvim: VS Code風のコードレンズ（参照数表示）
  -- 関数・メソッド・インターフェース・型定義の上に参照数を表示
  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
    opts = {
      -- 定義行の上に表示（VS Code風）
      vt_position = "above",
      -- 読み込み中テキストを非表示（ちらつき防止）
      request_pending_text = false,
      -- 参照数の表示対象シンボル
      kinds = {
        vim.lsp.protocol.SymbolKind.Function,
        vim.lsp.protocol.SymbolKind.Method,
        vim.lsp.protocol.SymbolKind.Interface,
        vim.lsp.protocol.SymbolKind.TypeParameter,
        vim.lsp.protocol.SymbolKind.Class,
      },
      -- 参照カウントの設定
      references = { enabled = true, include_declaration = false },
      definition = { enabled = false },
      implementation = { enabled = true },
      -- TypeScript/TSXのみに絞る
      disable = {
        filetypes = {},
        cond = {
          function()
            local ft = vim.bo.filetype
            return ft ~= "typescript" and ft ~= "typescriptreact"
          end,
        },
      },
      -- 表示フォーマットのカスタマイズ
      text_format = function(symbol)
        local fragments = {}
        if symbol.references and symbol.references > 0 then
          table.insert(fragments, { string.format("󰌹 %d references", symbol.references), "Comment" })
        end
        if symbol.implementation and symbol.implementation > 0 then
          table.insert(fragments, { string.format("󰡱 %d implementations", symbol.implementation), "Comment" })
        end
        if #fragments == 0 then
          return nil
        end
        -- フラグメント間にスペースを挿入
        local result = {}
        for i, frag in ipairs(fragments) do
          if i > 1 then
            table.insert(result, { "  ", "NonText" })
          end
          table.insert(result, frag)
        end
        return result
      end,
    },
    keys = {
      { "<leader>cl", function() require("symbol-usage").toggle_globally() end, desc = "Toggle Code Lens" },
    },
  },
}
