---@module 'utils.open_path'
--- Facade: configuration + optional default keymaps (gt/gtw/gtt) + public API.

--- @package

local TargetEdit = require("utils.open_path.targets.edit")
local TargetWin = require("utils.open_path.targets.window")
local TargetTab = require("utils.open_path.targets.tab")
local TargetFM  = require("utils.open_path.targets.filemanager")

---@type OpenPathConfig
local CONFIG = {
  require_existing = true,
  notify = false,
  split = "vertical",
  set_default_keymaps = false, -- keep user's existing mappings by default
}

---@class OpenPath
local M = {}

--- Setup configuration and (optionally) default mappings.
---@param opts OpenPathConfig|nil
function M.setup(opts)
  if type(opts) == "table" then
    for k, v in pairs(opts) do
      if CONFIG[k] ~= nil then CONFIG[k] = v end
    end
  end

  if CONFIG.set_default_keymaps then
    -- opb   -> open in current window (buffer)
    vim.keymap.set("n", "Gpb", function()
      TargetEdit.open(CONFIG.require_existing, CONFIG.notify)
    end, { desc = "open_path: open file under cursor (edit)" })

    -- opv  -> open in new split (vertical by default)
    vim.keymap.set("n", "Gpv", function()
      local o = CONFIG.split == "horizontal" and "horizontal" or "vertical"
      TargetWin.open(o, CONFIG.require_existing, CONFIG.notify)
    end, { desc = "open_path: open file under cursor (split)" })

    -- opt  -> open in new tab
    vim.keymap.set("n", "Gpt", function()
      TargetTab.open(CONFIG.require_existing, CONFIG.notify)
    end, { desc = "open_path: open file under cursor (tab)" })
  end
end

--- Public API: targets as functions (so user can bind any keys elsewhere).
function M.open_in_buffer()
  return TargetEdit.open(CONFIG.require_existing, CONFIG.notify)
end

---@param orientation "vertical"|"horizontal"|nil
function M.open_in_window(orientation)
  local o = (orientation == "horizontal") and "horizontal" or CONFIG.split
  return TargetWin.open(o, CONFIG.require_existing, CONFIG.notify)
end

function M.open_in_tab()
  return TargetTab.open(CONFIG.require_existing, CONFIG.notify)
end

function M.open_in_filemanager()
  return TargetFM.open(CONFIG.require_existing, CONFIG.notify)
end

--- Open in new split and maximize (non-destructive).
function M.open_in_window_max()
  return TargetWin.open(CONFIG.split, CONFIG.require_existing, CONFIG.notify, true, false)
end

--- Open in new split and make it the only window (destructive).
function M.open_in_window_only()
  return TargetWin.open(CONFIG.split, CONFIG.require_existing, CONFIG.notify, false, true)
end

return M
