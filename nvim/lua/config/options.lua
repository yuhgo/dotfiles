-- LazyVim用のオプション設定
-- LazyVimのデフォルト設定を上書きしたい場合はここに書く

local opt = vim.opt

-- 例: スワップファイルを無効化（LazyVimのデフォルトを上書き）
opt.swapfile = false

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
