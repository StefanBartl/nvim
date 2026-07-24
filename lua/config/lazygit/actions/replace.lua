---@module 'config.lazygit.actions.replace'
--- Open a file selected in LazyGit *in place of* the file currently shown in the
--- editor window behind the LazyGit float. This is the `<C-o>` action.
---
--- Focus-safe: the edit runs via `nvim_win_call`, so the focused LazyGit
--- terminal float is never disturbed. LazyGit stays open and usable.
---
--- Why no save prompt here (unlike the Neo-tree variant): when this runs, a
--- LazyGit terminal float owns the screen, so a blocking `vim.fn.confirm` would
--- be invisible and its input swallowed by LazyGit. Instead, if the target
--- buffer has unsaved changes, we never clobber it — we fall back to a plain
--- `:badd` so nothing is lost.
---
--- See lua/config/lazygit/README.md for the full nvr/$NVIM mechanism.

local notify = require("lib.nvim.notify").create("[cfg.lazygit.replace]")
local resolve = require("lib.nvim.fs.path").from_repo_relative
local normal = require("lib.nvim.buf_win_tab.normal_buffer")
local badd = require("config.lazygit.actions.badd")

local fn = vim.fn

local M = {}

--- @param raw string path from LazyGit (repo-root-relative or absolute)
--- @return boolean ok
function M.run(raw)
  if type(raw) ~= "string" or raw == "" then
    notify.warn("no path received from LazyGit")
    return false
  end

  local path = resolve(raw)
  if fn.filereadable(path) ~= 1 then
    notify.warn(("file not readable: %s"):format(path))
    return false
  end

  -- The focused window is the LazyGit terminal float; its terminal buffer is
  -- skipped by is_normal_file_buffer, so we don't need to exclude it explicitly.
  local target_buf, target_win = normal.find_last_normal_window()

  -- No editor window to replace -> fall back to a background buffer.
  if not target_win then
    notify.info("no editor window to replace; adding as buffer instead")
    return badd.run(raw)
  end

  -- Never clobber unsaved changes (can't prompt safely behind the float).
  if vim.api.nvim_get_option_value("modified", { buf = target_buf }) then
    notify.info("target buffer modified; adding as buffer instead")
    return badd.run(raw)
  end

  local ok, err = normal.edit_in_window(target_win, path)
  if not ok then
    notify.warn(("replace failed: %s"):format(err or "?"))
    return false
  end

  notify.info(("replaced -> %s"):format(fn.fnamemodify(path, ":t")))
  return true
end

return M
