---@module 'custom.open.handlers.notepad'
---@brief Handler that opens arbitrary text in the system default text editor.
---@description
--- Writes the context text to a temporary file, then opens that file in the
--- platform's GUI text editor.
---   • Windows / WSL  → notepad.exe
---   • macOS          → open -e (TextEdit)
---   • Linux          → first of: xdg-open, gedit, kate, mousepad, leafpad, pluma
--- "editor" is registered as an alias for "notepad".

local notify   = require("lib.notify").create("[custom.open.handlers.notepad]")
local platform = require("custom.open.platform")
local util     = require("custom.open.util")

local M = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Write text to a temporary file and return the path.
---@param text string
---@return string|nil path, string|nil err
local function write_temp(text)
  local tmpfile = vim.fn.tempname() .. ".txt"

  local ok, err = pcall(function()
    local f = assert(io.open(tmpfile, "w"))
    f:write(text)
    f:close()
  end)

  if not ok then
    return nil, tostring(err)
  end

  return tmpfile, nil
end

---Pick a suitable GUI text editor on Linux.
---@return string|nil
local function linux_editor()
  return util.find_exec({
    "xdg-open",
    "gedit",
    "kate",
    "mousepad",
    "leafpad",
    "pluma",
    "xed",
  })
end

---Core run logic shared by "notepad" and "editor".
---@param ctx Custom.Open.Context
---@return boolean
local function run(ctx)
  local tmpfile, err = write_temp(ctx.text)
  if not tmpfile then
    notify.error("[custom.open.notepad] Failed to create temp file: " .. tostring(err))
    return false
  end

  local plat = platform.get()
  local cmd

  if plat.is_win or plat.is_wsl then
    cmd = { "notepad.exe", tmpfile }
  elseif plat.is_mac then
    cmd = { "open", "-e", tmpfile } -- TextEdit
  else
    local ed = linux_editor()
    if not ed then
      notify.error("[custom.open.notepad] No suitable GUI text editor found on PATH")
      return false
    end
    cmd = { ed, tmpfile }
  end

  local ok = util.run_detached(cmd, "notepad")
  if ok then
    notify.info("[custom.open.notepad] Opened temp file: " .. tmpfile)
  end
  return ok
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---@param register_fn fun(h: Custom.Open.Handler): boolean
function M.register_all(register_fn)
  register_fn({
    key  = "notepad",
    desc = "Open text in the system default text editor (via temp file)",
    run  = run,
  })

  -- "editor" is a user-friendly alias.
  register_fn({
    key  = "editor",
    desc = "Alias for notepad: open text in system default text editor",
    run  = run,
  })
end

return M
