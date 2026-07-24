---@module 'config.telescope.file_browser.keymaps'
--- Provides modular key mappings for Telescope File Browser.
--- Includes insert- and normal-mode mappings, such as `?` for help popup.

local M = {}

---@param actions table The actions table from telescope plugin
---@return table
function M.get(actions)
  if type(actions) ~= "table" then
    return {}
  end

  return {
    i = {
      ["?"] = actions.which_key,
    },
    n = {
      ["?"] = actions.which_key,
    },
  }
end

return M
