---@module 'config.telescope.file_browser.keymaps'
--- Provides modular key mappings for Telescope File Browser.
--- Includes insert- and normal-mode mappings, such as `?` for help popup.

local M = {}

---@param fb_actions table The actions table from telescope file_browser extension
---@return table
function M.get(fb_actions)
  if type(fb_actions) ~= "table" then
    return {}
  end

  return {
    i = {
      ["?"] = fb_actions.which_key,
    },
    n = {
      ["?"] = fb_actions.which_key,
    },
  }
end

return M
