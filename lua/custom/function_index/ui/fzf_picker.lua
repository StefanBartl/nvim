---@module 'custom.function_index.ui.fzf_picker'
---@brief fzf-lua integration for function index
---@description
--- This module provides an fzf-lua picker for browsing and selecting
--- function definitions. Supports ANSI color codes, pre-filled queries,
--- and fast fuzzy matching.

local M = {}

local indexer_mod = require("custom.function_index.core.indexer")

--- ANSI color codes
local colors = {
  reset = "\27[0m",
  blue = "\27[34m",
  green = "\27[32m",
  yellow = "\27[33m",
  magenta = "\27[35m",
  cyan = "\27[36m",
  gray = "\27[90m",
}

--- Language colors (can be customized)
local lang_colors = {
  lua = colors.blue,
  python = colors.yellow,
  javascript = colors.cyan,
  typescript = colors.cyan,
  go = colors.blue,
  rust = colors.magenta,
  c = colors.green,
  cpp = colors.green,
  java = colors.magenta,
  ruby = colors.magenta,
  php = colors.magenta,
}

--- Format entry for fzf-lua display
---@param entry table
---@param config table
---@return string # ANSI-formatted string
local function format_entry_line(entry, config)
  local parts = {}

  -- Filename and line number (gray)
  parts[#parts + 1] = colors.gray
  parts[#parts + 1] = entry.filename
  parts[#parts + 1] = ":"
  parts[#parts + 1] = tostring(entry.lnum)
  parts[#parts + 1] = colors.reset
  parts[#parts + 1] = " "

  -- Language (colored)
  if config.ui.show_language_icons then
    local lang_color = lang_colors[entry.language] or colors.reset
    parts[#parts + 1] = lang_color
    parts[#parts + 1] = entry.language
    parts[#parts + 1] = colors.reset
    parts[#parts + 1] = " "
  end

  -- Function type indicator
  if config.ui.show_function_types then
    parts[#parts + 1] = colors.gray
    parts[#parts + 1] = "["
    parts[#parts + 1] = entry.func_type
    parts[#parts + 1] = "]"
    parts[#parts + 1] = colors.reset
    parts[#parts + 1] = " "
  end

  -- Signature (main content)
  parts[#parts + 1] = entry.signature

  return table.concat(parts)
end

--- Convert entries to fzf-lua format
---@param entries table[]
---@param config table
---@return string[] # Formatted lines
local function entries_to_lines(entries, config)
  local lines = {}
  for _, entry in ipairs(entries) do
    lines[#lines + 1] = format_entry_line(entry, config)
  end
  return lines
end

--- Parse selected line back to entry
--- This is a heuristic parser for our formatted output
---@param line string # Selected fzf line
---@param entries table[] # Original entries (for lookup)
---@return table|nil # Matched entry
local function parse_selected_line(line, entries)
  -- Extract filename:lnum from the gray prefix
  local file_and_lnum = line:match("^[^:]+:%d+")
  if not file_and_lnum then
    return nil
  end

  local filename, lnum_str = file_and_lnum:match("^([^:]+):(%d+)")
  local lnum = tonumber(lnum_str)

  if not filename or not lnum then
    return nil
  end

  -- Find matching entry
  for _, entry in ipairs(entries) do
    if entry.filename == filename and entry.lnum == lnum then
      return entry
    end
  end

  return nil
end

--- Open fzf-lua picker with function index
---@param config table
---@param opts table|nil # Optional picker options
function M.pick(config, opts)
  opts = opts or {}

  -- Check if fzf-lua is available
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
    return
  end

  -- Get index
  local entries, msg = indexer_mod.get_index(config, false)

  if #entries == 0 then
    vim.notify("No functions found. " .. (msg or ""), vim.log.levels.WARN)
    return
  end

  if msg then
    vim.notify(msg, vim.log.levels.INFO)
  end

  -- Convert entries to formatted lines
  local lines = entries_to_lines(entries, config)

  fzf.fzf_exec(lines, {
    prompt = opts.initial_query or "Functions> ",
    previewer = "builtin",
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then
          return
        end

        local entry = parse_selected_line(selected[1], entries)
        if not entry then
          vim.notify("Failed to parse selected entry", vim.log.levels.ERROR)
          return
        end

        -- Open file and jump to function
        vim.cmd("edit " .. entry.filename)
        vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col - 1 })

        -- Center cursor
        vim.cmd("normal! zz")
      end,
    },
    fzf_opts = {
      ["--ansi"] = "",
      ["--delimiter"] = ":",
      ["--nth"] = "3..", -- Search only in signature part
      ["--with-nth"] = "1..", -- Display everything
    },
  })
end

--- Open picker with pre-filled query
---@param config table
---@param query string # Initial search query
function M.pick_with_query(config, query)
  M.pick(config, {
    initial_query = query,
  })
end

--- Open picker with clipboard content as query
---@param config table
function M.pick_with_clipboard(config)
  local clip = vim.fn.getreg("+")
  if clip and clip ~= "" then
    M.pick_with_query(config, vim.trim(clip))
  else
    M.pick(config)
  end
end

--- Open picker with word under cursor as query
---@param config table
function M.pick_with_cword(config)
  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    M.pick_with_query(config, word)
  else
    M.pick(config)
  end
end

return M
