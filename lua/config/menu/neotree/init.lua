---@module 'config.menu.neotree'
--- Compose a patched Neo-tree context menu by merging the original menus.neo-tree
--- entries with an explicit, maintainable list of custom entries (see
--- config.menu.neotree.entries). The generator only exposes entries
--- that are both enabled in the entries list and implemented in
--- config.neotree.keymaps().window().

local notify = require("lib.nvim.notify").create("[config.menu.neotree]")

require("config.@types.menu")

local M = {}

--- Default icon used when an entry does not specify one.
---@type string
M.DEFAULT_ICON = ""

--- Safe require helper that returns (ok, module_or_error)
---@param modname string
---@return boolean, any
local function safe_require(modname)
  local ok, res = pcall(require, modname)
  if not ok then
    return false, res
  end
  return true, res
end

--- Wrap a neo-tree window mapping handler so it can be called by the menu system.
--- The handler may be a function(state) or a table where the first element is such a function.
---@param handler any
---@return fun()
local function build_neotree_cmd_wrapper(handler)
  return function()
    local ok_mgr, manager = safe_require("neo-tree.sources.manager")
    if not ok_mgr or type(manager) ~= "table" or type(manager.get_state_for_window) ~= "function" then
      notify.error("neo-tree manager not available")
      return
    end
    local state = manager.get_state_for_window()
    if not state then
      notify.warn("neo-tree state not found for current window")
      return
    end

    local fn = nil
    if type(handler) == "function" then
      fn = handler
    elseif type(handler) == "table" and type(handler[1]) == "function" then
      fn = handler[1]
    end

    if not fn then
      notify.debug("invalid neo-tree handler for menu entry")
      return
    end

    local ok, err = pcall(fn, state)
    if not ok then
      notify.error(("neo-tree custom menu handler failed: %s"):format(tostring(err)))
    end
  end
end

--- Normalize the original neo-tree menu into a sequence (list-like) table.
--- Preserves numeric order when the original is list-like; falls back to value collection otherwise.
---@param orig any
---@return table
local function normalize_orig_menu(orig)
  local out = {}
  if type(orig) ~= "table" then
    return out
  end

  local is_list = false
  for k, _ in pairs(orig) do
    if type(k) == "number" then
      is_list = true
      break
    end
  end

  if is_list then
    for _, v in ipairs(orig) do
      table.insert(out, v)
    end
  else
    for _, v in pairs(orig) do
      table.insert(out, v)
    end
  end

  return out
end

--- Load entries definitions from the entries module.
---@return table<integer, table>
local function load_entries_definitions()
  local ok, defs = safe_require("config.menu.neotree.entries")
  if not ok or type(defs) ~= "table" then
    return {}
  end
  return defs
end

--- Build the merged menu table.
--- Steps:
--- 1. load original menus.neo-tree
--- 2. normalize it into a list
--- 3. load config.neotree.keymaps and call .window() to get mapping handlers
--- 4. iterate entries from entries module, and for each enabled entry that has
---    a handler in window_map, convert into a menu entry (with icon/label/rtxt/hl)
---@return table
function M.build()
  -- 1) original neo-tree menu
  local ok_orig, orig_menu = safe_require("menus.neo-tree")
  if not ok_orig then
    orig_menu = {}
  end
  local menu = normalize_orig_menu(orig_menu)

  -- 2) load the mappings module and window_map
  local ok_km, keymaps_mod = safe_require("config.neotree.keymaps")
  local window_map = nil
  if ok_km and type(keymaps_mod) == "table" and type(keymaps_mod.window) == "function" then
    local ok, res = pcall(keymaps_mod.window)
    if ok and type(res) == "table" then
      window_map = res
    end
  end

  -- 3) load explicit entries list
  local entries = load_entries_definitions()

  -- 4) helper to append a menu entry when handler exists
  local function maybe_add_entry(entry)
    if type(entry) ~= "table" or not entry.key or not entry.enabled then
      return
    end
    if not window_map then
      return
    end

    local handler = window_map[entry.key]
    if handler == nil then
      -- mapping not present in current M.window() -> skip silently
      return
    end

    local icon = entry.icon or (keymaps_mod and keymaps_mod.icons and keymaps_mod.icons[entry.key]) or M.DEFAULT_ICON
    local label = entry.label or (type(handler) == "table" and handler.desc) or tostring(entry.key)
    local name = (icon and (icon .. " ") or "") .. label

    table.insert(menu, {
      name = name,
      cmd = build_neotree_cmd_wrapper(handler),
      rtxt = entry.rtxt or tostring(entry.key),
      hl = entry.hl,
    })
  end

  -- 5) append a separator and the enabled custom entries (preserve entries order from file)
  local any_added = false
  for _, e in ipairs(entries) do
    if e.enabled and window_map and window_map[e.key] ~= nil then
      any_added = true
      break
    end
  end

  if any_added then
    table.insert(menu, { name = "separator" })
  end

  for _, e in ipairs(entries) do
    maybe_add_entry(e)
  end

  return menu
end

--- Convenience loader for requiring this module as a table (so menu.open can require it directly).
--- Returns the built menu table.
---@return table
function M.load()
  return M.build()
end

---@type menu_neotree_module
return M.load()
