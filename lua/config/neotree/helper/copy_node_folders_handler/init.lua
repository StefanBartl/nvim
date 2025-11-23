---@module 'config.neotree.helper.copy_node_folders_handler'
-- High-level helper that gathers folder entries for the node and copies them to the clipboard.
-- Reuses copy_entries_to_clipboard for normalization/preview/clipboard behavior.

local gather_folders_for_node = require("config.neotree.helper.gather_folders_for_node")
local copy_entries_to_clipboard = require("config.neotree.helper.copy_entries_to_clipboard")

local notify = vim.notify

--- Handler entry: returns true when something was copied; false + message when nothing to copy.
---@param state table Neo-tree state (passed by mapping)
---@param opts table|nil Options: relative_to_cwd (boolean), preview_limit (number)
---@return boolean copied
return function(state, opts)
  opts = opts or {}
  local entries, node_path = gather_folders_for_node(state)
  if not node_path or node_path == "" then
    notify("No node under cursor", vim.log.levels.WARN)
    return false
  end
  if not entries or #entries == 0 then
    notify("No folders found to copy", vim.log.levels.WARN)
    return false
  end

  -- Reuse existing copy function which normalizes and sets clipboard.
  copy_entries_to_clipboard(entries, { relative_to_cwd = opts.relative_to_cwd, preview_limit = opts.preview_limit })
  return true
end
