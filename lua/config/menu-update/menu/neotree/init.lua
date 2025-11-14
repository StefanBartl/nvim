---@module 'config.menu.neotree'
--- Explicit Neo-tree context menu generator:
--- - wrap_with_close for all handlers
--- - node_type filtering
--- - sections only shown if at least one child is visible
--- - robust nil checks and step-by-step logic

local wrap_with_close = require("config.menu.neotree.wrap_with_close")
local menu_state = require("menu.state")
local api = vim.api

local M = {}

---@type string
M.DEFAULT_ICON = ""

---@param modname string
---@return boolean, any
local function safe_require(modname)
  local ok, res = pcall(require, modname)
  if not ok then return false, res end
  return true, res
end

---@param handler any
---@return fun(state?: table)
local function build_neotree_cmd_wrapper(handler)
  return function(state)
    if state == nil then
      local ok_mgr, manager = safe_require("neo-tree.sources.manager")
      if not ok_mgr then
        vim.notify("Neo-tree manager not available", vim.log.levels.ERROR)
        return
      end
      if type(manager) ~= "table" or type(manager.get_state_for_window) ~= "function" then
        vim.notify("Neo-tree manager invalid", vim.log.levels.ERROR)
        return
      end
      state = manager.get_state_for_window()
      if state == nil then
        vim.notify("Neo-tree state not available", vim.log.levels.WARN)
        return
      end
    end

    local fn = nil
    if type(handler) == "function" then
      fn = handler
    elseif type(handler) == "table" and type(handler[1]) == "function" then
      fn = handler[1]
    end

    if fn == nil then
      vim.notify("Invalid Neo-tree handler for menu entry", vim.log.levels.DEBUG)
      return
    end

    local ok, err = pcall(fn, state)
    if not ok then
      vim.notify(("Neo-tree custom menu handler failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
    end
  end
end

---@param entry custom_neotree_entry
---@param state table
---@return boolean
local function is_entry_applicable(entry, state)
  if entry == nil then return false end
  if entry.enabled == false then return false end

  local node_type_required = entry.node_type or "any"

  local node_type_actual = nil
  if state ~= nil and state.tree ~= nil and type(state.tree.get_node) == "function" then
    local node = state.tree:get_node()
    if node ~= nil and node.type ~= nil then
      node_type_actual = node.type
    end
  end

  -- Fallback: wenn keine Node info vorhanden, Entry immer anzeigen
  if node_type_actual == nil then
    return true
  end

  if node_type_required == "any" then
    return true
  elseif node_type_required == "file" then
    return node_type_actual == "file"
  elseif node_type_required == "folder" then
    return node_type_actual == "directory"
  else
    return false
  end
end

---@param entry custom_neotree_entry
---@param state table|nil
---@param window_map table|nil
---@return table|nil
local function build_entry(entry, state, window_map)
  if entry == nil then return nil end

  -- 1) Section mit Items
  if entry.items ~= nil and type(entry.items) == "table" then
    local visible_items = {}
    for i = 1, #entry.items do
      local child_entry = entry.items[i]
      local built_child = build_entry(child_entry, state, window_map)
      if built_child ~= nil then
        table.insert(visible_items, built_child)
      end
    end
    if #visible_items == 0 then
      return nil
    end
    return {
      section = true,
      name = entry.name or entry.label or "Group",
      hl = entry.hl,
      items = visible_items
    }
  end

  -- 2) Einzelner Eintrag
  if entry.key ~= nil and window_map ~= nil then
    local handler = window_map[entry.key]
    if handler == nil then return nil end

    -- Sicherstellen, dass menu_state.old_data existiert
    if menu_state.old_data == nil then
      menu_state.old_data = {
        buf = api.nvim_get_current_buf(),
        win = api.nvim_get_current_win(),
        cursor = api.nvim_win_get_cursor(0)
      }
    end

    -- Befehl definieren
    local cmd_fn = function()
      local ok_mgr, manager = safe_require("neo-tree.sources.manager")
      if not ok_mgr then return end
      if type(manager) ~= "table" or type(manager.get_state_for_window) ~= "function" then return end

      local neo_state = manager.get_state_for_window()
      if neo_state == nil then return end

      if is_entry_applicable(entry, neo_state) then
        build_neotree_cmd_wrapper(handler)(neo_state)
      else
        vim.notify("This action is not applicable for the current node.", vim.log.levels.WARN)
      end
    end

    return {
      name = entry.label or ("Neo-tree: " .. tostring(entry.key)),
      cmd = wrap_with_close(cmd_fn),
      rtxt = entry.rtxt or tostring(entry.key),
      hl = entry.hl
    }
  end

  return nil
end

function M.build()
  -- 1) Original-Menu laden
  local ok_orig, orig_menu = safe_require("menus.neo-tree")
  if not ok_orig then orig_menu = {} end
  local menu = {}
  if type(orig_menu) == "table" then
    for i = 1, #orig_menu do
      table.insert(menu, orig_menu[i])
    end
  end

  -- 2) Window mappings laden
  local ok_km, keymaps_mod = safe_require("config.neotree.keymaps")
  local window_map = nil
  if ok_km and type(keymaps_mod) == "table" and type(keymaps_mod.window) == "function" then
    local ok, res = pcall(keymaps_mod.window)
    if ok and type(res) == "table" then
      window_map = res
    end
  end

  -- 3) Custom entries laden
  local ok_entries, entries = safe_require("config.menu.neotree.entries")
  if not ok_entries or type(entries) ~= "table" then
    entries = {}
  end

  -- 4) Custom entries bauen
  local custom_entries = {}
  for i = 1, #entries do
    local entry = build_entry(entries[i], nil, window_map)
    if entry ~= nil then
      table.insert(custom_entries, entry)
    end
  end

  -- 5) Menü zusammenfügen
  for i = 1, #custom_entries do
    table.insert(menu, custom_entries[i])
  end

  return menu
end

---@return table
function M.load()
  return M.build()
end

---@type menu_neotree_module
return M.load()
