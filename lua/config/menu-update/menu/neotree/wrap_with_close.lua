---@module 'config.menu.neotree.wrap_with_close'

local menu_state = require("menu.state")

--- Wrap any callback so that the context menu closes afterwards
---@param cb fun()
---@return fun()
return function(cb)
  return function()
    pcall(cb)

    -- close the current menu window, if it exists
    if menu_state.win and vim.api.nvim_win_is_valid(menu_state.win) then
      vim.api.nvim_win_close(menu_state.win, true)
    end

    -- clear menu state safely
    if menu_state then
      menu_state.win = nil
      if menu_state.old_data ~= nil then
        menu_state.old_data = nil
      end
    end
  end
end
