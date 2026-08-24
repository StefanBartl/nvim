---@module 'config.menu.mappings'
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

--- Pattern-B plugins (see lib.nvim.contextmenu / RightClick_Contextmenu.md):
--- each ships only `<plugin>.integrations.menu` (`items`/`submenu`, no
--- trigger, no nvzone/menu dependency) and relies on THIS dispatcher to
--- compose it. Every contributor lands as its OWN top-level fly-out entry
--- (`submenu()`) — no shared "MyPlugins" wrapper — so ordering here is
--- just menu-display order, not nesting.
--- `applies(buf)` is a cheap pre-check (usually filetype) that skips the
--- plugin's `require()` entirely when it obviously doesn't qualify, before
--- paying for the plugin's own (possibly pricier) internal gating.
---@type { module: string, applies: fun(buf: integer): boolean }[]
local CONTRIBUTORS = {
  { module = "markdown.integrations.menu", applies = function(buf) return is_markdown(vim.bo[buf].ft) end },
  -- open.nvim: genuinely global (acts on whatever is under the cursor, incl.
  -- tree buffers) — its own items() self-gates per entry, so `applies`
  -- here is just "always try it".
  { module = "open.integrations.menu", applies = function() return true end },
  -- dap.nvim: also global — debugging actions aren't filetype-scoped, and
  -- items() itself returns empty when nvim-dap isn't installed.
  { module = "wkddap.integrations.menu", applies = function() return true end },
  -- cascade.nvim: filetype set is config-driven (lists.filetypes, broader
  -- than just markdown) and items() already re-checks it internally, so
  -- there is nothing cheaper to pre-check here than "always try it".
  { module = "cascade.integrations.menu", applies = function() return true end },
  -- fileops.nvim: also global — acts on "this open file", self-gates
  -- per entry on the buffer actually having a name.
  { module = "fileops.integrations.menu", applies = function() return true end },
  -- images.nvim: filetype-scoped (config.keymaps.filetypes, default
  -- markdown/vimwiki/norg/text) and items() re-checks it internally, same
  -- reasoning as cascade.nvim above — nothing cheaper to pre-check here.
  { module = "images.integrations.menu", applies = function() return true end },
  -- spotlight.nvim: also global — works the same in any buffer/filetype.
  { module = "spotlight.integrations.menu", applies = function() return true end },
  -- color_my_ascii.nvim: markdown-only, and items() re-checks the filetype
  -- (plus fence-under-cursor for the :Fence group) internally.
  { module = "color_my_ascii.integrations.menu", applies = function(buf) return vim.bo[buf].ft == "markdown" end },
  -- Add more Pattern-B plugins here as their menu integrations land, e.g.:
  -- { module = "cascade.integrations.menu", applies = function(buf) return is_markdown(vim.bo[buf].ft) end },
}

--- Collect one fly-out `submenu()` entry per applicable contributor.
---@param buf integer
---@return table[]
local function contributed_submenus(buf)
  local out = {}
  for _, c in ipairs(CONTRIBUTORS) do
    if c.applies(buf) then
      local ok, mod = pcall(require, c.module)
      if ok and type(mod.submenu) == "function" then
        local sub = mod.submenu()
        if sub then out[#out + 1] = sub end
      end
    end
  end
  return out
end

--- Build a composed menu source for `buf`: one fly-out entry per applicable
--- Pattern-B plugin (see CONTRIBUTORS), followed by the general custom menu.
--- Returns nil when nothing contributes for this buffer.
---@param buf integer
---@return table|nil  an nvzone/menu entry table, or nil
local function plugin_menu_source(buf)
  local subs = contributed_submenus(buf)
  if #subs == 0 then return nil end

  local composed = {}
  vim.list_extend(composed, subs)

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
  -- Applicable plugins (CONTRIBUTORS) get their entries composed on top.
  map("n", "<A-b>", function()
    local ok_menu, menu = pcall(require, "menu")
    if not ok_menu then
      notify.warn("menu module not found")
      return
    end
    local plugins_menu = plugin_menu_source(vim.api.nvim_get_current_buf())
    if plugins_menu then
      menu.open(plugins_menu)
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

    -- Applicable plugins (CONTRIBUTORS): each contributes its own top-level
    -- fly-out entry, composed with the general custom menu. Checked before
    -- the ft routing below so it wins whenever at least one plugin applies,
    -- without needing a dedicated named menu per plugin.
    local plugins_menu = plugin_menu_source(buf)
    if plugins_menu then
      menu.open(plugins_menu, { mouse = true })
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
