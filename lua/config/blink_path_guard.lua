-- config/blink_path_guard.lua -- local patch for blink.cmp's cmdline source.
--
-- `blink.cmp.sources.cmdline.utils.get_completions` drops System32 (Windows) or
-- the /mnt/<drive> mounts (WSL) from `vim.env.PATH` around
-- `vim.fn.getcompletion(..., 'shellcmd')` and restores it afterwards, but not
-- under pcall: an error or interrupt inside getcompletion leaves the shortened
-- PATH in the session for good, and every child process (vim.system, jobstart,
-- LSP servers) inherits it. Still unfixed upstream as of blink.cmp 06096f6
-- (2026-10-30).
--
-- The guard wraps the function: it remembers PATH before the call and puts it
-- back when the call throws, then rethrows the original error. The success path
-- is untouched (blink restores PATH itself there).

local M = {}

local MODULE = "blink.cmp.sources.cmdline.utils"
local MARK = "__path_guard_original"

--- Wraps a `get_completions`-shaped function so a throw cannot leak a changed PATH.
---@param fn fun(...): any
---@return fun(...): any
function M.wrap(fn)
  return function(...)
    local path = vim.env.PATH
    local result = { pcall(fn, ...) }
    if not result[1] then
      vim.env.PATH = path
      error(result[2], 0)
    end
    return unpack(result, 2, table.maxn(result))
  end
end

--- Installs the guard on a cmdline utils table (idempotent).
---@param utils table|nil the `blink.cmp.sources.cmdline.utils` module; required when nil
---@return boolean installed true when the guard is (now) in place
function M.install(utils)
  if utils == nil then
    local ok, mod = pcall(require, MODULE)
    if not ok then
      return false
    end
    utils = mod
  end
  if type(utils) ~= "table" or type(utils.get_completions) ~= "function" then
    return false
  end
  if utils[MARK] then
    return true
  end
  utils[MARK] = utils.get_completions
  utils.get_completions = M.wrap(utils.get_completions)
  return true
end

return M
