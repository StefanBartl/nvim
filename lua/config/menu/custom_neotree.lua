---@module 'config.menu.custom_neotree'
--- Patched neo-tree context menu that selectively exposes chosen window mappings
--- from `config.neotree.keymaps`. This module follows the explicit-listing
--- approach: only mappings that are intentionally whitelisted via `maybe_add`
--- are exported to the right-click menu. This avoids accidental exposure of
--- navigation or internal mappings such as `<C-f>`, `<Esc>`, `SG`, `SV`, `a`, `dd`.
---
--- Implementation notes (English comments throughout):
--- - Uses a safe_require helper to avoid noisy errors when optional modules are missing.
--- - Uses build_neotree_cmd_wrapper(...) to wrap mapping handlers so they are called
---   with the neo-tree `state` like the original handlers expect.
--- - Explicitly enumerates the mapping keys that should appear in the context menu.
--- - Preserves optional fields: name, rtxt, hl (when provided).
--- - Returns a list-like table that `menu.open(...)` can consume directly.
---
--- Usage:
---  require("config.menu.custom_neotree")  -- returns the patched menu table
---
local notify = require("lib.notify").create("[config.menu.custom_neotree]")

local M = {}

-- Safe require helper: returns (ok, module_or_error)
local function safe_require(modname)
  local ok, res = pcall(require, modname)
  if not ok then
    return false, res
  end
  return true, res
end

-- Build a wrapper that will call a neo-tree window mapping handler.
-- `handler` may be:
--  - a function(state)
--  - a table where first element is a function (neo-tree mapping style)
-- The returned function takes no args (menu system will call it), resolves
-- the current neo-tree state and calls the handler with it.
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

-- Main loader: returns merged menu table (original neo-tree menu + explicit custom entries)
local function load()
  -- 1) load original menu (menus.neo-tree) if present
  local ok_orig, orig_menu = safe_require("menus.neo-tree")
  if not ok_orig then
    orig_menu = {}
  end

  -- Normalize orig_menu into a sequence/list `menu`
  local menu = {}
  if type(orig_menu) == "table" then
    -- detect if orig_menu is list-like
    local is_list = false
    for k, _ in pairs(orig_menu) do
      if type(k) == "number" then
        is_list = true
        break
      end
    end
    if is_list then
      for _, v in ipairs(orig_menu) do
        table.insert(menu, v)
      end
    else
      -- fallback: shallow-copy values (order not guaranteed)
      for _, v in pairs(orig_menu) do
        table.insert(menu, v)
      end
    end
  end

  -- 2) load `config.neotree.keymaps` and extract window mappings
  local ok_km, keymaps_mod = safe_require("config.neotree.keymaps")
  local window_map = nil
  if ok_km and type(keymaps_mod) == "table" and type(keymaps_mod.window) == "function" then
    local ok, res = pcall(keymaps_mod.window)
    if ok and type(res) == "table" then
      window_map = res
    end
  end

  -- 3) build custom entries from an explicit whitelist (only keys added here will appear)
  local custom_entries = {}

  if window_map then
    --- Helper: conditionally add an explicit mapping to custom_entries.
    --- This keeps accidental mappings (like navigation or internal ones) out of the menu.
    --- @param key string mapping key as exposed by keymaps_mod.window()
    --- @param display_name string human-readable menu label
    --- @param rtxt string|nil right-text (visual hint for mapping)
    --- @param hl string|nil optional highlight group
    local function maybe_add(key, display_name, rtxt, hl)
      local handler = window_map[key]
      if handler ~= nil then
        table.insert(custom_entries, {
          name = display_name or ("Neo-tree: " .. tostring(key)),
          cmd = build_neotree_cmd_wrapper(handler),
          rtxt = rtxt or tostring(key),
          hl = hl,
        })
      end
    end

    -- Whitelisted keys
    maybe_add("[t", "󰈙 Copy recursive file list (absolute paths) to clipboard (+)", "[t]")
    maybe_add("[T", "󰈙 Copy recursive file list (relative to cwd) to clipboard (+)", "[T]")
    maybe_add("O", " Open with System Application", "O")
    maybe_add("M", " Open in system file manager", "M")
    maybe_add("+", " Set Neovim cwd to node and focus Neo-tree there", "+")
    maybe_add("-", " Up one level (in-place) and adjust CWD", "-")
    maybe_add("grep", " fzf-lua: live_grep in node directory", "grep")
    maybe_add("Y", " Copy Path to Clipboard", "Y")
  end

  -- 4) append a separator and the custom entries at the end (keeps original menu intact)
  if #custom_entries > 0 then
    table.insert(menu, { name = "separator" })
    for _, e in ipairs(custom_entries) do
      table.insert(menu, e)
    end
  end

  return menu
end

-- Module return: the assembled menu table (sequence)
M = load()

return M
