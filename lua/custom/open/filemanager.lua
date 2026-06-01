---@module 'custom.open.handlers.filemanager'
---@brief Handler that opens a path in the system file manager.
---@description
--- Resolves the text from the context to an absolute filesystem path,
--- then dispatches the platform-appropriate file manager command.
---   • Windows  → explorer.exe
---   • WSL      → explorer.exe (via wslpath conversion)
---   • macOS    → Finder (open / open -R for files)
---   • Linux    → xdg-open, then common managers as fallback

local notify   = require("lib.notify").create("[custom.open.handlers.filemanager]")
local platform = require("custom.open.platform")
local util     = require("custom.open.util")

local M = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Resolve text to an expanded, absolute-ish path string.
---@param text string
---@return string|nil path
local function resolve_path(text)
  local expanded = vim.fn.expand(text)
  if expanded == "" then
    return nil
  end
  return expanded
end

---Convert a Unix path to a Windows path inside WSL.
---@param unix_path string
---@return string|nil win_path
local function wsl_to_win_path(unix_path)
  local out = vim.fn.system({ "wslpath", "-w", unix_path })
  out = out:gsub("\n", "")
  if out == "" then
    return nil
  end
  return out
end

---Pick the best Linux file manager executable.
---@return string|nil
local function linux_file_manager()
  return util.find_exec({
    "xdg-open",
    "nautilus",
    "thunar",
    "nemo",
    "dolphin",
    "pcmanfm",
    "caja",
  })
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---@param register_fn fun(h: Custom.Open.Handler): boolean
function M.register_all(register_fn)
  register_fn({
    key  = "filemanager",
    desc = "Open path in the system file manager",
    run  = function(ctx)
      if ctx.is_url then
        notify.warn("[custom.open.filemanager] Text looks like a URL, not a path")
        return false
      end

      local path = resolve_path(ctx.text)
      if not path then
        notify.error("[custom.open.filemanager] Cannot resolve path: " .. ctx.text)
        return false
      end

      local plat = platform.get()
      local cmd

      if plat.is_win then
        cmd = { "explorer.exe", path }

      elseif plat.is_wsl then
        local win_path = wsl_to_win_path(path)
        if not win_path then
          notify.error("[custom.open.filemanager] wslpath conversion failed for: " .. path)
          return false
        end
        cmd = { "explorer.exe", win_path }

      elseif plat.is_mac then
        -- open -R reveals the file in Finder; open opens directory.
        local stat = vim.uv.fs_stat(path)
        if stat and stat.type == "file" then
          cmd = { "open", "-R", path }
        else
          cmd = { "open", path }
        end

      else
        local mgr = linux_file_manager()
        if not mgr then
          notify.error("[custom.open.filemanager] No file manager found on PATH")
          return false
        end
        cmd = { mgr, path }
      end

      local ok = util.run_detached(cmd, "filemanager")
      if ok then
        notify.info("[custom.open.filemanager] " .. path)
      end
      return ok
    end,
  })
end

return M
