---@module 'mappings.contextmenu'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- Alt-b to open default menu
  map("n", "<A-b>", function()
    local ok, menu = pcall(require, "menu"); if ok then menu.open("default") end
  end, {})

  -- RightMouse context menu (mouse users + nvimtree users)
  vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
    local ok_utils, utils = pcall(require, "menu.utils")
    if ok_utils then utils.delete_old_menus() end

    -- Replay native <RightMouse>
    vim.cmd.exec('"normal! \\<RightMouse>"')

    local winid = vim.fn.getmousepos().winid
    local buf = vim.api.nvim_win_get_buf(winid)
    local options = (vim.bo[buf].ft == "NvimTree") and "nvimtree" or "default"

    local ok_menu, menu = pcall(require, "menu")
    if ok_menu then menu.open(options, { mouse = true }) end
  end, {})
end

return M
