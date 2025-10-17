---@module 'config/menu/keymaps.lua'
-- Sets keymaps for <A-b> and RightMouse. Replaces mappings/contextmenu.lua usage.

local M = {}

function M.setup()
  local map = vim.g.__map_helper or function(mode, lhs, rhs, opts) vim.keymap.set(mode, lhs, rhs, opts or {}) end

  -- Alt-b opens top-level custom menu if present, otherwise default
  map("n", "<A-b>", function()
    local ok_menu, menu = pcall(require, "menu")
    if not ok_menu then
      vim.notify("menu module not found", vim.log.levels.WARN)
      return
    end
    -- prefer custom if registered
    if vim.g._menu_custom_registered then
      menu.open("custom")
    else
      menu.open("default")
    end
  end, {})

  -- RightMouse: tries to detect NeoTree / NvimTree
  vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
    local ok_utils, utils = pcall(require, "menu.utils")
    if ok_utils then pcall(utils.delete_old_menus) end

    -- replay native <RightMouse>
    vim.cmd.exec('"normal! \\<RightMouse>"')

    local winid = 0
    local ok_mouse, m = pcall(vim.fn.getmousepos)
    if ok_mouse and type(m) == "table" and m.winid and m.winid ~= 0 then
      winid = m.winid
    else
      winid = vim.api.nvim_get_current_win()
    end

    local ok_buf, buf = pcall(vim.api.nvim_win_get_buf, winid)
    if not ok_buf or not buf then buf = vim.api.nvim_get_current_buf() end
    local ft = vim.bo[buf].ft or ""

    local options = "default"
    if ft == "neo-tree" or ft == "neo_tree" then
      options = "neo-tree"
    elseif ft == "NvimTree" or ft:match("^NvimTree") then
      options = "nvimtree"
    else
      -- if custom registered and we're in a normal buffer prefer custom
      if vim.g._menu_custom_registered then options = "custom" end
    end

    local ok_menu, menu = pcall(require, "menu")
    if ok_menu then menu.open(options, { mouse = true }) end
  end, {})
end

return M
