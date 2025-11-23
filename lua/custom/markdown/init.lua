---@module 'custom.markdown'
--- Public entry: wires config + UI; re-exports core API. Pure cores; side effects only here.

local M = {}

local cfg = require("custom.markdown.config")
local fold = require("custom.markdown.core.fold")
local head = require("custom.markdown.core.headings")
local wrap = require("custom.markdown.core.wrap")
local autocmds = require("custom.markdown.setup.autocmds")
local tableview = require("custom.markdown.tableview")
local tableview_live = require("custom.markdown.tableview.live")

---@param opts MarkdownConfig|nil
---@return nil
function M.setup(opts)
  cfg.setup(opts or {})
  autocmds.setup()
  tableview.setup()
  tableview_live.setup_autocmds()
end

M.foldexpr = fold.foldexpr
M.goto_prev_heading = head.goto_prev_heading
M.goto_next_heading = head.goto_next_heading
M.shift_increase = head.increase
M.shift_decrease = head.decrease
M.toggle_visual_bold = wrap.toggle_visual_bold

-- require("custom.markdown.codeblock_formatter").setup()
local formatter = require("custom.markdown.codeblock_formatter2")

formatter.setup({
  -- Optional: Custom formatters hinzufügen
  formatters = {
    lua = { cmd = "stylua", args = { "-" } },
    python = { cmd = "black", args = { "--quiet", "-" } },
  },
  -- Optional: Nur bestimmte Sprachen erlauben
  supported_langs = { "lua", "typescript", "javascript", "ts", "js" },
})

-- Keybindings für Visual Mode
vim.keymap.set("v", "<leader>fc", function()
  formatter.format_range()
end, { desc = "Format codeblock in selection" })

-- Keybinding für gesamten Buffer
vim.keymap.set("n", "<leader>fb", function()
  formatter.format_buffer()
end, { desc = "Format all codeblocks" })

-- Oder direkt mit Range
vim.keymap.set("v", "<leader>fc", function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  formatter.format_range_async(start_line, end_line)
end, { desc = "Format codeblock" })



vim.api.nvim_create_user_command("FormatMdCodeblocks", function()
  formatter.format_buffer_async()
end, { desc = "Async format supported fenced codeblocks in buffer" })

vim.api.nvim_create_user_command("FormatMdCodeblocksRange", function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  formatter.format_range_async(start_line, end_line)
end, { desc = "Async format supported fenced codeblocks inside given range", range = true })





-- AUDIT:
---@diagnostic disable-next-line
require("custom.markdown.fenced_fix")
  .setup({
    -- Falls „noch oranger“ gewünscht ist, Reihenfolge hier anpassen oder direkt "Special" wählen.
    inline_base_hl = { "DiagnosticWarn", "Special", "Constant", "String" },
    inline_style = { italic = false, bold = false },
    delimiter_hl = "Comment",
  })
  .apply()

---@type MarkdownPublicAPI
return M
