---@module 'config.neotree.actions.copy.entries'

local tree = require("config.neotree.utils.tree")

---@param state Cfg.NeoTree.State # Neotrees table object
---@param opts Cfg.NeoTree.Copy.ClipboardOpt
---@return boolean
return function(state, opts)
  local entries, _ = tree.collect_for_node(state, "files")

  if #entries == 0 then
    vim.notify("No files found", vim.log.levels.WARN)
    return false
  end

  require("config.neotree.actions.copy.to_clipboard")(entries, opts)
  return true
end
