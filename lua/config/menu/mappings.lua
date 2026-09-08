---@module 'config.menu.mappings'
--- Binds `<A-b>` and `<RightMouse>` to the composed context menu.
---
--- Rendering goes through `lib.nvim.contextmenu.open`, never through
--- `require("menu")` directly: which component actually draws (nvzone/menu
--- or `lib.nvim.ui.kit.menu`) is a `contextmenu.setup{ renderer = … }`
--- decision made once in `config.menu`, and nothing here needs to know.

local map = require("lib.nvim.bindings.keymap")
local contextmenu = require("lib.nvim.contextmenu")

local M = {}

--- Options handed to `config.menu.custom_menu`, captured by `config.menu`'s
--- setup so the general section can be rebuilt per buffer.
---@type table
local custom_opts = {}

--- Markdown filetype test (markdown / md / mdx / markdown.*).
---@param ft string|nil
---@return boolean
local function is_markdown(ft)
  if not ft or ft == "" then
    return false
  end
  return ft == "markdown" or ft == "md" or ft == "mdx" or ft:match("^markdown%.") ~= nil
end

--- Pattern-B plugins (see lib.nvim.contextmenu / RightClick_Contextmenu.md):
--- each ships only `<plugin>.integrations.menu` (`items`/`submenu`, no
--- trigger, no renderer dependency) and relies on THIS dispatcher to
--- compose it. Every contributor lands as its OWN top-level fly-out entry
--- (`submenu()`) — no shared "MyPlugins" wrapper — so ordering here is
--- just menu-display order, not nesting.
--- `applies(buf)` is a cheap pre-check (usually filetype) that skips the
--- plugin's `require()` entirely when it obviously doesn't qualify, before
--- paying for the plugin's own (possibly pricier) internal gating.
---@type { module: string, applies: fun(buf: integer): boolean }[]
local CONTRIBUTORS = {
  {
    module = "markdown.integrations.menu",
    applies = function(buf)
      return is_markdown(vim.bo[buf].ft)
    end,
  },
  -- open.nvim: genuinely global (acts on whatever is under the cursor, incl.
  -- tree buffers) — its own items() self-gates per entry, so `applies`
  -- here is just "always try it".
  {
    module = "open.integrations.menu",
    applies = function()
      return true
    end,
  },
  -- dap.nvim: also global — debugging actions aren't filetype-scoped, and
  -- items() itself returns empty when nvim-dap isn't installed.
  {
    module = "wkddap.integrations.menu",
    applies = function()
      return true
    end,
  },
  -- cascade.nvim: filetype set is config-driven (lists.filetypes, broader
  -- than just markdown) and items() already re-checks it internally, so
  -- there is nothing cheaper to pre-check here than "always try it".
  {
    module = "cascade.integrations.menu",
    applies = function()
      return true
    end,
  },
  -- fileops.nvim: also global — acts on "this open file", self-gates
  -- per entry on the buffer actually having a name.
  {
    module = "fileops.integrations.menu",
    applies = function()
      return true
    end,
  },
  -- images.nvim: filetype-scoped (config.keymaps.filetypes, default
  -- markdown/vimwiki/norg/text) and items() re-checks it internally, same
  -- reasoning as cascade.nvim above — nothing cheaper to pre-check here.
  {
    module = "images.integrations.menu",
    applies = function()
      return true
    end,
  },
  -- spotlight.nvim: also global — works the same in any buffer/filetype.
  {
    module = "spotlight.integrations.menu",
    applies = function()
      return true
    end,
  },
  -- color_my_ascii.nvim: markdown-only, and items() re-checks the filetype
  -- (plus fence-under-cursor for the :Fence group) internally.
  {
    module = "color_my_ascii.integrations.menu",
    applies = function(buf)
      return vim.bo[buf].ft == "markdown"
    end,
  },
  -- lsp.nvim: also global — mirrors the resolved keymap catalogue
  -- (require("lsp").status().keymaps), not tied to a filetype. Replaces
  -- custom_menu's former hand-written "Lsp Actions" section (menus/lsp.lua,
  -- part of nvzone/menu itself, since removed from custom_menu/init.lua):
  -- that section's "Add/Remove workspace folder" entries had no lsp.nvim
  -- keymap-catalogue equivalent, but were confirmed unused and dropped
  -- rather than backfilled.
  {
    module = "lsp.integrations.menu",
    applies = function()
      return true
    end,
  },
  -- Add more Pattern-B plugins here as their menu integrations land, e.g.:
  -- { module = "cascade.integrations.menu", applies = function(buf) return is_markdown(vim.bo[buf].ft) end },
}

--- Record the options the general section is built with.
---@param opts table|nil
function M.set_custom_opts(opts)
  custom_opts = opts or {}
end

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
        if sub then
          out[#out + 1] = sub
        end
      end
    end
  end
  return out
end

--- Build the menu for `buf`: one fly-out entry per applicable Pattern-B
--- plugin (see CONTRIBUTORS), then the general section beneath a divider.
---
--- The general section is rebuilt per call rather than registered once:
--- several of its entries (copy/delete "marked", "delete file") depend on
--- the live selection and buffer, which a table built at setup time cannot
--- see.
---@param buf integer
---@return Lib.ContextMenu.Item[]
local function menu_source(buf)
  local composed = contributed_submenus(buf)

  local ok_custom, custom = pcall(require, "config.menu.custom_menu")
  if ok_custom and type(custom) == "function" then
    local items = custom(custom_opts)
    if type(items) == "table" and #items > 0 then
      if #composed > 0 then
        composed[#composed + 1] = { name = "separator" }
      end
      vim.list_extend(composed, items)
    end
  end

  return composed
end

function M.setup()
  -- Alt-b: the same menu, anchored at the cursor instead of the pointer.
  map("n", "<A-b>", function()
    local items = menu_source(vim.api.nvim_get_current_buf())
    if #items > 0 then
      contextmenu.open(items, { mouse = false })
    end
  end, { desc = "Open the context menu at the cursor" })

  -- RightMouse: the buffer under the pointer decides what the menu holds.
  -- Neo-tree is NOT handled here — filetree.nvim's own context_menu feature
  -- binds a buffer-local <RightMouse> on the tree buffer itself, and a
  -- buffer-local mapping always shadows this global one.
  map({ "n", "v" }, "<RightMouse>", function()
    -- Replay the native click so the cursor lands where the user pointed,
    -- and the menu is built for that buffer rather than the previous one.
    vim.cmd.exec('"normal! \\<RightMouse>"')

    local winid
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

    local items = menu_source(buf)
    if #items > 0 then
      contextmenu.open(items, { mouse = true })
    end
  end, { desc = "Open the context menu at the pointer" })
end

return M
