---@module 'config.neotree.actions.copy.to_clipboard'
---@brief Copy entries to system clipboard with preview and formatting options

local M = {}

---Format entries based on options
---@param entries string[]
---@param opts Cfg.NeoTree.Copy.ClipboardOpt
---@return string formatted
local function format_entries(entries, opts)
  local lines = {}

  for i = 1, #entries do
    local entry = entries[i]

    -- Convert to relative if requested
    if opts.relative_to_cwd then
      local rel = vim.fn.fnamemodify(entry, ":.")

      -- Only use relative if it's actually shorter/clearer
      if #rel < #entry and not rel:match("^%.%.") then
        entry = rel
      end
    end

    -- Quote if needed
    if opts.quote_paths or entry:match("[%s]") then
      entry = '"' .. entry .. '"'
    end

    lines[#lines + 1] = entry
  end

  -- Format output
  if opts.format == "json" then
    return vim.fn.json_encode(lines)
  elseif opts.format == "quoted" then
    return table.concat(lines, '", "')
  else
    return table.concat(lines, "\n")
  end
end

---Create preview message
---@param entries string[]
---@param opts Cfg.NeoTree.Copy.ClipboardOpt
---@return string message
local function create_preview_message(entries, opts)
  local count = #entries
  local limit = opts.preview_limit or 10
  local preview_count = math.min(count, limit)

  local lines = { string.format("Copied %d entries:", count) }

  for i = 1, preview_count do
    local entry = entries[i]
    local basename = vim.fn.fnamemodify(entry, ":t")
    lines[#lines + 1] = string.format("  • %s", basename)
  end

  if count > limit then
    lines[#lines + 1] = string.format("  ... and %d more", count - limit)
  end

  return table.concat(lines, "\n")
end

---Copy entries to system clipboard
---@param entries string[] Absolute paths to copy
---@param opts? Cfg.NeoTree.Copy.ClipboardOpt Options
---@return boolean success
function M.copy(entries, opts)
  opts = vim.tbl_extend("force", {
    relative_to_cwd = false,
    preview_limit = 10,
    quote_paths = false,
    format = "list",
  }, opts or {})

  if not entries or #entries == 0 then
    vim.notify("No entries to copy", vim.log.levels.WARN)
    return false
  end

  local formatted = format_entries(entries, opts)

  -- Copy to system clipboard (+)
  vim.fn.setreg("+", formatted, "c")

  -- Show preview notification
  local preview = create_preview_message(entries, opts)
  vim.notify(preview, vim.log.levels.INFO)

  return true
end

---Main function (callable as module)
---@param entries string[]
---@param opts? Cfg.NeoTree.Copy.ClipboardOpt
---@return boolean
return function(entries, opts)
  return M.copy(entries, opts)
end
