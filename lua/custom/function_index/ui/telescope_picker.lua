---@module 'custom.function_index.ui.telescope_picker'
---@brief Telescope integration for function index
---@description
--- This module provides a Telescope picker for browsing and selecting
--- function definitions. Supports pre-filled queries, fuzzy matching,
--- and syntax-highlighted previews.

local M = {}

local indexer_mod = require("custom.function_index.core.indexer")

--- Language icons (requires nerd fonts)
local lang_icons = {
  lua = " ",
  python = " ",
  javascript = " ",
  typescript = " ",
  go = " ",
  rust = " ",
  c = " ",
  cpp = " ",
  java = " ",
  ruby = " ",
  php = " ",
}

--- Function type indicators
local type_indicators = {
  local_ = "[L]",
  module = "[M]",
  exported = "[E]",
  method = "[m]",
  global = "[G]",
  anonymous = "[a]",
  unknown = "[?]",
}

--- Format entry for display in Telescope
---@param entry table
---@param config table
---@return string # Formatted display string
local function format_entry_display(entry, config)
  local parts = {}

  -- Language icon
  if config.ui.show_language_icons then
    local icon = lang_icons[entry.language] or "  "
    parts[#parts + 1] = icon
  end

  -- Function type indicator
  if config.ui.show_function_types then
    local indicator = type_indicators[entry.func_type] or "[?]"
    parts[#parts + 1] = indicator
  end

  -- Signature
  parts[#parts + 1] = entry.signature

  -- Filename and line number
  parts[#parts + 1] = " "
  parts[#parts + 1] = entry.filename .. ":" .. entry.lnum

  return table.concat(parts, " ")
end

--- Create Telescope entry maker
---@param config table
---@return function # Entry maker function
local function make_entry_maker(config)
  return function(entry)
    return {
      value = entry,
      display = format_entry_display(entry, config),
      ordinal = entry.signature .. " " .. entry.filename .. " " .. entry.language,
      filename = entry.filename,
      lnum = entry.lnum,
      col = entry.col,
    }
  end
end

--- Open Telescope picker with function index
---@param config table
---@param opts table|nil # Optional picker options
function M.pick(config, opts)
  opts = opts or {}

  -- Check if Telescope is available
  local ok, _ = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope is not installed", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- Get index
  local entries, msg = indexer_mod.get_index(config, false)

  if #entries == 0 then
    vim.notify("No functions found. " .. (msg or ""), vim.log.levels.WARN)
    return
  end

  if msg then
    vim.notify(msg, vim.log.levels.INFO)
  end

  -- Create picker
  pickers
    .new(opts, {
      prompt_title = "Function Index",
      finder = finders.new_table({
        results = entries,
        entry_maker = make_entry_maker(config),
      }),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          -- Open file and jump to function
          vim.cmd("edit " .. selection.filename)
          vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.col - 1 })

          -- Center cursor
          vim.cmd("normal! zz")
        end)

        return true
      end,
    })
    :find()
end

--- Open picker with pre-filled query
---@param config table
---@param query string # Initial search query
function M.pick_with_query(config, query)
  M.pick(config, {
    default_text = query,
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
