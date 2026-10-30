-- config/neotree/job_handle_close.lua -- local patch for neo-tree's `utils.job`.
--
-- `require("neo-tree.utils").job` spawns git (status on BufWritePost and
-- DirChanged, rev-parse, ls-files, diff) with `vim.uv.spawn`, but never calls
-- `handle:close()` on the returned uv_process_t: the exit callback only records
-- the code and finishes the job. Every call therefore leaves one inactive
-- process handle in the loop for the rest of the session (measured: 984 of them
-- after 11 h), and on Windows each one keeps the process object and its PID
-- alive. Still unfixed upstream as of neo-tree.nvim v3.x 1a14083 (2026-10-30).
--
-- The patch wraps `utils.job`: it passes its own exit callback that closes the
-- job's handle (when it is not already closing) and then calls the caller's
-- callback with the same arguments. Callers reach the function through the
-- module table (`utils.job(...)`), so replacing the field covers all of them.

local M = {}

local MODULE = "neo-tree.utils"
local MARK = "__job_handle_close_original"

--- Closes a uv handle unless it is gone or already closing.
---@param handle uv.uv_handle_t|nil
local function close(handle)
  if handle and not handle:is_closing() then
    handle:close()
  end
end

--- Wraps a `utils.job`-shaped function so the spawned process handle gets closed.
---@param fn fun(cmd: string[], opts: table?, on_exit: function?): table?, any
---@return fun(cmd: string[], opts: table?, on_exit: function?): table?, any
function M.wrap(fn)
  return function(cmd, opts, on_exit)
    local job
    local result = {
      fn(cmd, opts, function(...)
        close(job and job.handle)
        if on_exit then
          return on_exit(...)
        end
      end),
    }
    -- The exit callback runs from the event loop, never before `fn` returns,
    -- so `job` is set by the time it fires.
    job = result[1]
    return unpack(result, 1, table.maxn(result))
  end
end

--- Installs the patch on neo-tree's utils table (idempotent).
---@param utils table|nil the `neo-tree.utils` module; required when nil
---@return boolean installed true when the patch is (now) in place
function M.install(utils)
  if utils == nil then
    local ok, mod = pcall(require, MODULE)
    if not ok then
      return false
    end
    utils = mod
  end
  if type(utils) ~= "table" or type(utils.job) ~= "function" then
    return false
  end
  if utils[MARK] then
    return true
  end
  utils[MARK] = utils.job
  utils.job = M.wrap(utils.job)
  return true
end

return M
