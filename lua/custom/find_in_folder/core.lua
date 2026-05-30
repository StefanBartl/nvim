---@module 'custom.find_in_folder.core'
---@brief Resolves the target folder and dispatches to the selected fuzzy-picker.
---@description
--- Provides the central `run(opts)` entry point used by both the keymap and the
--- user-command.  Folder resolution order:
---   1. Explicit `opts.folder` path provided by caller.
---   2. `"."` → current working directory (`vim.fn.getcwd()`).
---   3. `nil` → interactive directory selection via `pick_dir()`.
---
--- Picker dispatch is intentionally thin: each picker module owns its own
--- `find_files` implementation so this module stays free of picker-specific
--- knowledge beyond the interface contract.

local notify = require("lib.notify").create("[find_in_folder]")

local M = {}

-- ---------------------------------------------------------------------------
-- Module-internal state (no globals, no _G)
-- ---------------------------------------------------------------------------

---@type FindInFolder.State
local state = {
  last_folder = nil,
  last_picker = nil,
}

-- ---------------------------------------------------------------------------
-- Private helpers
-- ---------------------------------------------------------------------------

---Resolve and validate a folder path.
---@param raw string|nil
---@return string|nil resolved  Absolute, validated directory path, or nil on error.
local function resolve_folder(raw)
  if not raw or raw == "" then
    return nil
  end

  local path = raw == "." and vim.fn.getcwd() or raw
  path = vim.fn.fnamemodify(path, ":p")

  -- Strip trailing separator for uniformity
  path = path:gsub("[/\\]$", "")

  if vim.fn.isdirectory(path) == 0 then
    notify.error("Not a directory: " .. path)
    return nil
  end

  return path
end

---Dispatch find-files to the chosen picker.
---@param folder string  Absolute directory path.
---@param picker FindInFolder.Picker
local function dispatch(folder, picker)
  state.last_folder = folder
  state.last_picker = picker

  if picker == "fzf" then
    local ok, err = pcall(require("custom.find_in_folders.fzf").find, folder)
    if not ok then
      notify.error("fzf-lua error: " .. tostring(err))
    end
    return
  end

  -- Default: Telescope
  local ok, err = pcall(require("custom.find_in_folder.telescope").find, folder)
  if not ok then
    notify.error("Telescope error: " .. tostring(err))
  end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Main entry point.
---@param opts FindInFolder.Opts|nil
function M.run(opts)
  opts = opts or {}

  ---@type FindInFolder.Picker
  local picker = opts.picker or "telescope"

  -- Validate picker value
  if picker ~= "telescope" and picker ~= "fzf" then
    notify.warn(string.format("Unknown picker '%s', falling back to telescope", picker))
    picker = "telescope"
  end

  -- Fast path: explicit folder supplied
  local folder = resolve_folder(opts.folder)
  if folder then
    dispatch(folder, picker)
    return
  end

  -- Interactive path: let user select a directory
  local pick_dir = require("custom.find_in_folder.dir_select")
  pick_dir.select(picker, function(selected)
    if not selected or selected == "" then
      return -- user cancelled
    end

    local resolved = resolve_folder(selected)
    if resolved then
      dispatch(resolved, picker)
    end
  end)
end

---Return the last-used folder for repeat invocations.
---@return string|nil
function M.last_folder()
  return state.last_folder
end

return M
