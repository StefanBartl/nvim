---@module 'config.ui_open'
--- Works around a Windows bug: core's vim.ui.open() hands URLs to cmd.exe
--- unquoted when they contain `&` but no whitespace (e.g. "...?id=x&y=z"),
--- and cmd.exe silently truncates at the bare `&`. `explorer.exe` isn't
--- affected (no shell tokenizing). Full mechanic + why this used to replace
--- _get_open_cmd() wholesale (and no longer does -- filesystem paths keep
--- core's own launcher):
--- wkdbook-Neovim/nvim-lua-api/LuaModule-vim.ui.md#windows-bug-in-urls-wird-von-cmdexe-abgeschnitten
---
--- Scoped to URLs only: core's `vim.ui.open(path, { cmd = ... })` option lets
--- us swap the launcher per call instead of globally, so plain paths keep
--- the default.

local env = require("lib.nvim.system.env")

local M = {}

---Whether `target` is a URL/URI rather than a filesystem path. Requires a
---scheme of at least two characters so a Windows drive letter ("C:\...")
---is never mistaken for one.
---@param target string
---@return boolean
local function is_url(target)
  return target:match("^%a[%w+.-]+:") ~= nil
end

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
      opt = vim.tbl_extend("force", opt or {}, { cmd = { "explorer.exe" } })
    end
    return orig_open(target, opt)
  end
  M._orig_open = orig_open
end

return M
