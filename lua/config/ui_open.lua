---@module 'config.ui_open'
--- Works around a Windows bug: core's vim.ui.open() hands URLs to cmd.exe
--- unquoted when they contain `&` but no whitespace (e.g. "...?id=x&y=z"),
--- and cmd.exe silently truncates at the bare `&`. Full mechanic + why this
--- used to replace _get_open_cmd() wholesale (and no longer does -- filesystem
--- paths keep core's own launcher):
--- wkdbook-Neovim/nvim-lua-api/LuaModule-vim.ui.md#windows-bug-in-urls-wird-von-cmdexe-abgeschnitten
---
--- The launcher is `rundll32 url.dll,FileProtocolHandler` (ShellExecute
--- in-process: `?`, `&`, `%xx` and long URLs arrive intact). It used to be
--- `explorer.exe`, which is a folder browser, not an opener: given a URL with
--- `?`, `&` or a `%xx` escape it takes the argument for a path pattern, drops
--- it and opens the Documents folder instead -- in a hidden window, because
--- Neovim starts children hidden -- while exiting 1 exactly as on success.
--- That was the "a link sometimes opens no tab" bug (measured 2026-10-14
--- against Chrome: `https://x/plain` opened; `https://x/?q=1`,
--- `https://x/a&b=1` and `https://x/a%3Fq=1` opened nothing and each left an
--- explorer.exe host process with a hidden "Documents" window behind).
---
--- Scoped to URLs only: core's `vim.ui.open(path, { cmd = ... })` option lets
--- us swap the launcher per call instead of globally, so plain paths keep
--- the default.

local env = require("lib.nvim.system.env")

---@class config.ui_open.Debug
---@field orig_open fun(path: string, opt?: table): vim.SystemObj?, string? # core vim.ui.open before setup()

---@class config.ui_open
---@field _debug? config.ui_open.Debug # set by setup() on Windows; inspection only
local M = {}

---Whether `target` is a URL/URI rather than a filesystem path. Requires a
---scheme of at least two characters so a Windows drive letter ("C:\...")
---is never mistaken for one.
---@param target string
---@return boolean
local function is_url(target)
  return target:match("^%a[%w+.-]+:") ~= nil
end

---@return nil
function M.setup()
  if not env.get().is_windows then
    return
  end

  local orig_open = vim.ui.open
  -- Deliberate override, and the point of this module: core's `vim.ui.open`
  -- stays reachable as `orig_open` and every call still ends up there. LuaLS
  -- reports any write to a `vim.*` field it already types.
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.open = function(target, opt)
    if type(target) == "string" and not (opt and opt.cmd) and is_url(target) then
      opt = vim.tbl_extend(
        "force",
        opt or {},
        { cmd = { "rundll32.exe", "url.dll,FileProtocolHandler" } }
      )
    end
    return orig_open(target, opt)
  end
  -- Debug handle only, deliberately inside a table: runtime-analysis'
  -- telemetry wraps every function-valued field of a `config.*` module (only
  -- top-level fields, no recursion into tables). A top-level `M._orig_open`
  -- therefore read back as a telemetry wrapper in a live session and looked
  -- like a second setup(). The truth is the upvalue chain of vim.ui.open.
  M._debug = { orig_open = orig_open }
end

return M
