-- LazyVim用のオプション設定
-- LazyVimのデフォルト設定を上書きしたい場合はここに書く

local opt = vim.opt

-- 例: スワップファイルを無効化（LazyVimのデフォルトを上書き）
opt.swapfile = false

-- カーソル位置の列をハイライト（cursorlineと合わせて十字表示になる）
opt.cursorcolumn = true

-- 行番号の右側にボーダーを表示（LazyVimのstatuscolumnをラップ）
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local orig_sc = LazyVim.statuscolumn
    LazyVim.statuscolumn = function()
      local result = orig_sc()
      if result ~= "" then
        result = result .. "%#WinSeparator#│ "
      end
      return result
    end
  end,
})

-- Markdownのconcealをカーソル行でも維持（カーソル移動時のガタつきを防止）
opt.concealcursor = "nc"

-- 組み込みspellを無効化（スペルチェックはcspell + none-lsに任せる）
-- SpellBad等のハイライトを消して波線を非表示にする
opt.spell = false
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    vim.api.nvim_set_hl(0, "SpellBad", {})
    vim.api.nvim_set_hl(0, "SpellCap", {})
    vim.api.nvim_set_hl(0, "SpellLocal", {})
    vim.api.nvim_set_hl(0, "SpellRare", {})
  end,
})
