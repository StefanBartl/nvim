---@module 'config/menu/keymaps.lua'
-- Sets keymaps for <A-b> and RightMouse. Replaces mappings/contextmenu.lua usage.

local notify = require("lib.nvim.notify").create("[config.menu.mappings]")
local map = require("lib.nvim.map")

local M = {}

--- Markdown filetype test (markdown / md / mdx / markdown.*).
---@param ft string|nil
---@return boolean
local function is_markdown(ft)
  if not ft or ft == "" then return false end
  return ft == "markdown" or ft == "md" or ft == "mdx" or ft:match("^markdown%.") ~= nil
end

--- Build a composed menu source for a markdown buffer: markdown.nvim's own
--- context-aware entries (fold on a heading, TOC, refs — the plugin owns them)
--- followed by the general custom menu. Returns nil when the buffer is not
--- markdown, the plugin/integration is absent, or it yields no entries.
---@param buf integer
---@return table|nil  an nvzone/menu entry table, or nil
local function markdown_menu_source(buf)
  if not is_markdown(vim.bo[buf].ft) then return nil end

  local ok, mdmenu = pcall(require, "markdown.integrations.menu")
  if not ok then return nil end

  local items = mdmenu.items()
  if type(items) ~= "table" or #items == 0 then return nil end

  local composed = {}
  vim.list_extend(composed, items)

  -- Append the general custom menu (format/copy/delete/… ) beneath a divider.
  local ok_custom, custom = pcall(require, "menus.custom")
  if ok_custom and type(custom) == "table" and #custom > 0 then
    table.insert(composed, { name = "separator" })
    vim.list_extend(composed, custom)
  end

  return composed
end

function M.setup()
  local map = vim.g.__map_helper or function(mode, lhs, rhs, opts)
    map(mode, lhs, rhs, opts or {})
  end

  -- Alt-b opens top-level custom menu if present, otherwise default.
  -- Markdown buffers get the plugin's entries composed on top.
  map("n", "<A-b>", function()
    local ok_menu, menu = pcall(require, "menu")
    if not ok_menu then
      notify.warn("menu module not found")
      return
    end
    local md = markdown_menu_source(vim.api.nvim_get_current_buf())
    if md then
      menu.open(md)
    elseif vim.g._menu_custom_registered then
      menu.open("custom")
    else
      menu.open("default")
    end
  end, {})

  -- RightMouse: markdown-aware, detects NvimTree. Neo-tree is NOT handled
  -- here — filetree.nvim's own context_menu feature binds a buffer-local
  -- <RightMouse> on the tree buffer itself (shadows this global one there).
  map({ "n", "v" }, "<RightMouse>", function()
    local ok_utils, utils = pcall(require, "menu.utils")
    if ok_utils then
      pcall(utils.delete_old_menus)
    end

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
    if not ok_buf or not buf then
      buf = vim.api.nvim_get_current_buf()
    end
    local ft = vim.bo[buf].ft or ""

    local ok_menu, menu = pcall(require, "menu")
    if not ok_menu then return end

    -- Markdown buffers: plugin-owned context menu (fold on heading, TOC, refs)
    -- composed with the general custom menu. Checked before the ft routing so
    -- it wins for markdown without a dedicated menu name.
    local md = markdown_menu_source(buf)
    if md then
      menu.open(md, { mouse = true })
      return
    end

    -- Neo-tree: filetree.nvim's own context_menu feature binds a buffer-local
    -- <RightMouse> directly on the tree buffer (using this same
    -- filetree.integrations.menu.items() source) — a buffer-local mapping
    -- always shadows this global one, so this handler's body never actually
    -- runs for ft == "neo-tree"/"neo_tree" and no special case is needed here
    -- anymore. See filetree.nvim's docs/menu.md.

    local options = "default"
    if ft == "NvimTree" or ft:match("^NvimTree") then
      options = "nvimtree"
    elseif vim.g._menu_custom_registered then
      options = "custom"
    end

    menu.open(options, { mouse = true })
  end, {})
end

return M
