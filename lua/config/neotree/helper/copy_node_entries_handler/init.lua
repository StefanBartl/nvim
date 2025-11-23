---@module 'config.neotree.helper.copy_node_entries_handler'
-- High-level helper that gathers entries for the node and copies them to clipboard.
-- This returns true when something was copied; false + message when nothing to copy.

local gather_entries_for_node = require("config.neotree.helper.gather_entries_for_node")
local copy_entries_to_clipboard = require("config.neotree.helper.copy_entries_to_clipboard")

local notify = vim.notify

---@return boolean copied
return function (state, opts)
  opts = opts or {}
  local entries, node_path = gather_entries_for_node(state)
  if not node_path or node_path == "" then
    notify("No node under cursor", vim.log.levels.WARN)
    return false
  end
  if not entries or #entries == 0 then
    notify("No files found to copy", vim.log.levels.WARN)
    return false
  end
  copy_entries_to_clipboard(entries, { relative_to_cwd = opts.relative_to_cwd, preview_limit = opts.preview_limit })
  return true
end
