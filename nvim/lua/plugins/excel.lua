-- Excel ファイルビューア
-- xlsx/xls ファイルを開いたとき:
--   - 自動的に CSV に変換してプレビュー表示（読み取り専用）
--   - <leader>xe で sc-im（ターミナル版スプレッドシート）を起動して編集
-- 依存: xlsx2csv (pipx install xlsx2csv), sc-im (brew install sc-im)

local group = vim.api.nvim_create_augroup("ExcelViewer", { clear = true })

-- xlsx/xls ファイルを開いたときに CSV 変換してプレビュー
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = group,
  pattern = { "*.xlsx", "*.xls" },
  callback = function(args)
    local file = args.file
    local buf = args.buf

    -- xlsx2csv で CSV に変換
    local result = vim.fn.systemlist({ "xlsx2csv", file })

    if vim.v.shell_error ~= 0 then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Excel ファイルの読み込みに失敗しました",
        "xlsx2csv がインストールされているか確認してね: pipx install xlsx2csv",
        "",
        table.concat(result, "\n"),
      })
      return
    end

    -- バッファに CSV 内容をセット
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, result)

    -- CSV として扱う（ハイライトなど）
    vim.bo[buf].filetype = "csv"
    -- 読み取り専用にする（プレビューなので）
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].buftype = "nofile"

    -- バッファローカルのキーマップ: sc-im で編集
    vim.keymap.set("n", "<leader>xe", function()
      vim.cmd("terminal sc-im " .. vim.fn.shellescape(file))
      vim.cmd("startinsert")
    end, { buffer = buf, desc = "sc-im で Excel を編集" })

    vim.notify("Excel プレビュー (CSV) — <leader>xe で sc-im 編集", vim.log.levels.INFO)
  end,
})

return {}
