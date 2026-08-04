---@module 'bindings.usrcmds.case.apply'
--- Executes a plan.lua action list. "skip" actions are a no-op report, not
--- an error — that's what makes :Case sync safe to run against a case that
--- already has some of its blueprint in place.

local mkdirp = require("lib.nvim.fs.mkdirp")
local write_to_file = require("lib.nvim.fs.write.to_file")
local read = require("lib.nvim.fs.read")

local M = {}

---@class Lib.Case.ApplyResult
---@field action Lib.Case.Action
---@field ok boolean
---@field err string|nil

---@param actions Lib.Case.Action[]
---@return Lib.Case.ApplyResult[] results
---@return string[] opens  Absolute paths flagged open=true that succeeded
function M.run(actions)
  local results, opens = {}, {}

  for _, a in ipairs(actions) do
    if a.kind == "skip" then
      results[#results + 1] = { action = a, ok = true }
    elseif a.kind == "mkdir" then
      local ok, err = mkdirp(a.path)
      results[#results + 1] = { action = a, ok = ok, err = err }
    elseif a.kind == "write" then
      local ok, err = write_to_file(a.path, table.concat(a.lines, "\n"))
      results[#results + 1] = { action = a, ok = ok, err = err }
      if ok and a.open then
        opens[#opens + 1] = a.path
      end
    elseif a.kind == "copy" then
      local content, rerr = read(a.from)
      if not content then
        results[#results + 1] = { action = a, ok = false, err = rerr }
      else
        local ok, err = write_to_file(a.path, content)
        results[#results + 1] = { action = a, ok = ok, err = err }
        if ok and a.open then
          opens[#opens + 1] = a.path
        end
      end
    end
  end

  return results, opens
end

---@param results Lib.Case.ApplyResult[]
---@return boolean all_ok
---@return string[] errors
function M.errors(results)
  local errs = {}
  for _, r in ipairs(results) do
    if not r.ok then
      errs[#errs + 1] = ("%s: %s"):format(r.action.path, r.err or "unknown error")
    end
  end
  return #errs == 0, errs
end

return M
