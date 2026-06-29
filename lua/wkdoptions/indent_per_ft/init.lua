---@module 'wkdoptions.indent_per_ft'

-- ── Indent width per filetype ─────────────────────────────────
-- Add or change entries as needed. Unlisted filetypes get DEFAULT_INDENT.
local INDENT_BY_FT = {
  lua = 2,
  markdown = 2,
  javascript = 2,
  typescript = 2,
  css = 2,
  html = 2,
  python = 4,
  java = 4,
  go = 4,
  rust = 4,
  c = 4,
  cpp = 4,
}
local DEFAULT_INDENT = 2

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    local w = INDENT_BY_FT[vim.bo.filetype] or DEFAULT_INDENT
    vim.bo.shiftwidth = w
    vim.bo.tabstop = w
    vim.bo.softtabstop = w
    vim.bo.expandtab = true
  end,
})
