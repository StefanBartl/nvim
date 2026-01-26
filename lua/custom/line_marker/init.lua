---@module 'custom.line_marker'
---Allows marking lines and yanking all marked lines via mappings.

local notify = require("lib.notify").create("[custom.line_marker]")

local M = {}

local api, fn = vim.api, vim.fn
local km_set = vim.keymap.set
local create_usercommand = api.nvim_create_user_command

-- Stores marked lines: keys = buffer number, values = table of line numbers
---@type table<number, table<number, boolean>>
M.marked_lines = {}

-- Sign/Highlight settings
local sign_name = "LineMarkerSign"
local virt_text_ns = api.nvim_create_namespace("LineMarkerVirtText")

-- Define sign if SignColumn exists
fn.sign_define(sign_name, { text = "●", texthl = "ErrorMsg" })

-- Check if the buffer has signcolumn enabled
local function use_signcolumn()
  local col = vim.api.nvim_get_option_value("signcolumn", { win = 0 })
  return col ~= "no"
end


-- Toggle a line mark
---@param linenr number
---@param bufnr? number
function M.toggle_line(linenr, bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  M.marked_lines[bufnr] = M.marked_lines[bufnr] or {}
  local lines = M.marked_lines[bufnr]

  if lines[linenr] then
    -- unmark
    lines[linenr] = nil
    if use_signcolumn() then
      fn.sign_unplace(sign_name, { buffer = bufnr, id = linenr })
    else
      api.nvim_buf_clear_namespace(bufnr, virt_text_ns, linenr - 1, linenr)
    end
  else
    -- mark
    lines[linenr] = true
    if use_signcolumn() then
      fn.sign_place(linenr, sign_name, sign_name, bufnr, { lnum = linenr })
    else
      api.nvim_buf_set_extmark(bufnr, virt_text_ns, linenr - 1, 0, {
        virt_text = { { "●", "ErrorMsg" } },
        virt_text_pos = "overlay",
      })
    end
  end
end

-- Yank all marked lines
---@param bufnr? number
function M.yank_marked(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local lines = M.marked_lines[bufnr]
  if not lines then return end

  -- Collect lines in buffer order
  local sorted_lines = {}
  for lnum in pairs(lines) do table.insert(sorted_lines, lnum) end
  table.sort(sorted_lines)

  local text = {}
  for _, lnum in ipairs(sorted_lines) do
    table.insert(text, api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1])
  end

  if #text > 0 then
    fn.setreg("+", table.concat(text, "\n")) -- system clipboard
    notify.info("Copied " .. #text .. " marked lines to clipboard")
  else
    notify.warn("No marked lines to copy")
  end
end

-- User commands
function M.enable_commands()
  create_usercommand("MarkLineToggle", function()
    M.toggle_line(api.nvim_win_get_cursor(0)[1], nil)
  end, { desc = "[custom.line_marker] Toggle mark on current line" })

  create_usercommand("MarkLinesYank", function()
    M.yank_marked(nil)
  end, { desc = "[custom.line_marker] Yank all marked lines" })
end

-- Mappings
function M.enable_mappings()
  -- Toggle current line mark
  km_set("n", "<S-m>", function()
    M.toggle_line(api.nvim_win_get_cursor(0)[1], nil)
  end, { desc = "[custom.line_marker] Toggle line mark" })

  -- Yank all marked lines
  km_set("n", "<C-p>", function()
    M.yank_marked(nil)
  end, { desc = "[custom.line_marker] Yank all marked lines" })
end

return M
