---@module 'config.ui_open'
--- Neovim core's vim.ui.open() on Windows builds
--- `{ "cmd.exe", "/c", "start", "", <path> }` and hands it to `vim.system()`.
--- `vim.system`/libuv only quotes an argv entry that contains whitespace, so a
--- URL with no spaces but an unescaped `&` (any link with 2+ query params,
--- e.g. "...?id=x&number=y") reaches cmd.exe unquoted. cmd.exe re-tokenizes
--- its own command line and treats the bare `&` as a command separator, so
--- only the part before the first `&` actually gets opened -- silently, no
--- error, just a truncated URL (symptom: page loads but "access denied" /
--- wrong content, works fine when pasted directly into the browser).
--- `explorer.exe <url>` hands the target straight to the registered
--- protocol handler without any shell tokenizing in between, so it is
--- immune to this. See share/nvim/runtime/lua/vim/ui.lua:_get_open_cmd().
---
--- Scoped to URLs only: this used to replace `_get_open_cmd()` wholesale,
--- which forced `explorer.exe` for *every* target -- including plain
--- filesystem paths, where the cmd.exe `&` problem does not apply and
--- core's own launcher is the maintained, better-tested route (opening a
--- directory via a detached `explorer.exe` proved unreliable, e.g.
--- filetree.nvim's <leader>fm reporting success while no window appeared).
--- Core's `vim.ui.open(path, { cmd = ... })` option lets us swap the
--- launcher per call instead of globally, so paths keep the default.

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
  vim.ui.open = function(target, opt)
    if type(target) == "string" and not (opt and opt.cmd) and is_url(target) then
      opt = vim.tbl_extend("force", opt or {}, { cmd = { "explorer.exe" } })
    end
    return orig_open(target, opt)
  end
  M._orig_open = orig_open
end

return M
