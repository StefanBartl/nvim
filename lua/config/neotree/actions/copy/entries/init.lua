---@module 'config.neotree.actions.copy.entries'

local notify = require("lib.nvim.notify").create("[config.neotree.actions.copy.entries]")

local tree = require("config.neotree.utils.tree")

---@param state Cfg.NeoTree.State # Neotrees table object
---@param opts Cfg.NeoTree.Actions.CopyClipboardOpts
---@return boolean
return function(state, opts)
  local entries, _ = tree.collect_for_node(state, "files")

  if #entries == 0 then
    notify.warn("No files found")
    return false
  end

  require("config.neotree.actions.copy.to_clipboard")(entries, opts)
  return true
end
