---@module 'config.harpoon.api'
--- Every Harpoon action this config exposes, in one place. Both entry points —
--- the `:Harpoon <sub>` verb (config.harpoon.usrcmds) and the keymaps
--- (bindings.mappings.harpoon) — call in here, so a keymap and its documented
--- command equivalent can never drift apart.
---
--- All list mutations go through config.harpoon.persist_paths, which pins
--- harpoon's project key to PINS_KEY for the duration of the call (see the
--- "ONE global list" rationale there).

local M = {}

local notify = require("lib.nvim.notify").create("[config.harpoon.api]")
local pp = require("config.harpoon.persist_paths")

---@return table|nil
local function get_harpoon()
  local ok, harpoon = pcall(require, "harpoon")
  if not ok then
    notify.warn("[harpoon] not installed")
    return nil
  end
  return harpoon
end

--------------------------------------------------------------------------------
-- List mutation
--------------------------------------------------------------------------------

---@class Cfg.Harpoon.AddOpts
---@field front boolean|nil      insert at slot 1 instead of appending
---@field permanent boolean|nil  also store as a persistent default pin

---Add a file to the Harpoon list. Defaults to the current buffer.
---@param path string|nil
---@param opts Cfg.Harpoon.AddOpts|nil
---@return boolean ok
function M.add(path, opts)
  opts = opts or {}
  local abs, err = pp.resolve_path(path)
  if not abs then
    notify.warn("[harpoon] add: " .. tostring(err))
    return false
  end

  if opts.permanent then
    return pp.pin(abs, { front = opts.front })
  end

  local changed = pp.insert_into_list(abs, { front = opts.front })
  notify.info(string.format("[harpoon] %s: %s", changed and "added" or "already listed", abs))
  return true
end

---Remove a file from the Harpoon list (the live entry only — an entry that is
---also a persistent default comes back on the next `:Harpoon defaults sync`;
---use `:Harpoon unpin` for that).
---@param path string|nil
---@return boolean ok
function M.remove(path)
  local abs, err = pp.resolve_path(path)
  if not abs then
    notify.warn("[harpoon] remove: " .. tostring(err))
    return false
  end

  local normkey = require("lib.nvim.fs.normkey")
  local key = normkey(abs, { realpath = true })

  local ok, removed = pp.with_pins_key(function(harpoon, list)
    for i = 1, #list.items do
      local it = list.items[i]
      local v = (type(it) == "table") and it.value or it
      if type(v) == "string" and normkey(v, { realpath = true }) == key then
        list:remove_at(i)
        -- remove_at only nils the slot; close the hole so the next add lands
        -- at the end instead of in the gap.
        pp.compact(list)
        pp.save_bucket(harpoon, list)
        notify.info("[harpoon] removed: " .. abs)
        return true
      end
    end
    notify.info("[harpoon] not in list: " .. abs)
    return false
  end)

  if not ok then
    notify.error("[harpoon] remove failed: " .. tostring(removed))
    return false
  end
  return removed == true
end

---@param path string|nil
---@return boolean ok
function M.pin(path)
  return pp.pin(path)
end

---@param path string|nil
---@return boolean ok
function M.unpin(path)
  return pp.unpin(path)
end

--------------------------------------------------------------------------------
-- Defaults
--------------------------------------------------------------------------------

---Top up: add every missing default path, leave everything else alone.
---@return nil
function M.defaults_sync()
  local changed = pp.inject_now()
  notify.info(string.format("[harpoon] defaults sync: %s", changed and "changed" or "no change"))
end

---Hard reset: rebuild the list from the default paths, in that exact order.
---@return nil
function M.defaults_reset()
  if pp.set_defaults() then
    notify.info("[harpoon] defaults reset")
  end
end

--------------------------------------------------------------------------------
-- Navigation / UI
--------------------------------------------------------------------------------

---@alias Cfg.Harpoon.MenuKind "default"|"telescope"|"fzf"

---Open a Harpoon list UI.
---@param kind Cfg.Harpoon.MenuKind|nil  default: "default" (harpoon's quick menu)
---@return nil
function M.menu(kind)
  kind = kind or "default"
  if kind == "telescope" or kind == "fzf" then
    local mod = require("config.harpoon.ui.menu_" .. kind)
    -- menu_telescope returns an EMPTY module when telescope is missing (it
    -- bails at require time), so `open` may legitimately be nil here.
    if type(mod.open) == "function" then
      mod.open()
      return
    end
    notify.warn(("[harpoon] %s not available, falling back to the quick menu"):format(kind))
  end

  local harpoon = get_harpoon()
  if not harpoon then
    return
  end
  harpoon.ui:toggle_quick_menu(harpoon:list())
end

---Jump to list entry `idx`.
---@param idx integer 1-based
---@return nil
function M.select(idx)
  local harpoon = get_harpoon()
  if not harpoon then
    return
  end
  harpoon:list():select(idx)
end

---Open the read-only full-screen preview of list entry `idx` ('q' to close).
---@param idx integer 1-based
---@return nil
function M.preview(idx)
  require("config.harpoon.preview").open_index(idx)
end

--------------------------------------------------------------------------------
-- Diagnostics
--------------------------------------------------------------------------------

---@return nil
function M.debug()
  require("config.harpoon.debug").dump()
end

---@return nil
function M.health()
  require("config.harpoon.health").check()
end

return M
