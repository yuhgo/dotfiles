-- 画像プレビュー (snacks.nvim Image)
-- Ghostty の Kitty Graphics Protocol を利用して画像をNeovim内で表示する
-- 依存: ImageMagick, Ghostscript (PDF用), mermaid-cli (Mermaid図用)
return {
  -- snacks.nvim Image 設定
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        doc = {
          enabled = true,
          -- 自動レンダリングを完全に無効化
          inline = false,
          float = false,
          -- 画像プレビューは <leader>ip キーバインドで手動表示
        },
      },
    },
    keys = {
      {
        "<leader>ip",
        function()
          -- hover()で表示し、カーソル移動で自動的に閉じる
          Snacks.image.hover()
          -- 一度だけ発火するautocmdでカーソル移動時に閉じる
          local group = vim.api.nvim_create_augroup("snacks_image_hover_close", { clear = true })
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
            group = group,
            once = true,
            callback = function()
              Snacks.image.doc.hover_close()
              vim.api.nvim_del_augroup_by_name("snacks_image_hover_close")
            end,
          })
        end,
        desc = "画像プレビュー (Image Preview)",
      },
    },
  },

  -- Treesitter: 画像プレビューに必要な言語パーサーを追加
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "css",
        "scss",
        "svelte",
        "vue",
        "norg",
      },
    },
  },
}
