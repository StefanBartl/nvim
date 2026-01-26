---@module 'config.neotree.actions.copy.folders'

local notify = require("lib.notify").create("[config.neotree.actions.copy.folders]")

local tree = require("config.neotree.utils.tree")

---@param state Cfg.NeoTree.State # Neotrees table object
---@param opts Cfg.NeoTree.Actions.CopyClipboardOpts
---@return boolean
return function(state, opts)
  local entries, _ = tree.collect_for_node(state, "folders")

  if #entries == 0 then
    notify.warn("No folders found")
    return false
  end

  require("config.neotree.actions.copy.to_clipboard")(entries, opts)
  return true
end
