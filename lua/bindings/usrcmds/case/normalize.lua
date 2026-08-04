---@module 'bindings.usrcmds.case.normalize'
--- The fix-it counterpart to doctor.lua (ROADMAP.md v6): turns every
--- unambiguous finding (`to ~= nil`) into a rename/move step. Findings
--- doctor.lua already marked ambiguous (`to == nil`, because the target
--- exists) are never touched here — they're reported so a human can look,
--- same policy as apply.lua never overwriting an existing file.

local doctor = require("bindings.usrcmds.case.doctor")
local mkdirp = require("lib.nvim.fs.mkdirp")

local M = {}

local uv = vim.uv or vim.loop

---@class Lib.Case.NormalizeStep
---@field short string
---@field kind string
---@field from string
---@field to string

--- What WOULD be renamed, split from what doctor found but can't safely fix.
--- Two findings in the same case can independently compute the same `to`
--- (e.g. a case with BOTH CaseNote.md and TillNow.md present, neither
--- Summary.md yet — doctor.lua checks each alias in isolation) — applying
--- both would have the second rename silently clobber the first, so any
--- target claimed by more than one finding is treated as ambiguous too.
---@return Lib.Case.NormalizeStep[] steps
---@return Lib.Case.DoctorFinding[] skipped  Ambiguous findings (to == nil, or to claimed by >1 finding).
function M.plan()
  local candidates, skipped = {}, {}
  for _, f in ipairs(doctor.check()) do
    if f.to then
      candidates[#candidates + 1] = f
    else
      skipped[#skipped + 1] = f
    end
  end

  local target_count = {}
  for _, f in ipairs(candidates) do
    target_count[f.to] = (target_count[f.to] or 0) + 1
  end

  local steps = {}
  for _, f in ipairs(candidates) do
    if target_count[f.to] > 1 then
      skipped[#skipped + 1] = f
    else
      steps[#steps + 1] = { short = f.short, kind = f.kind, from = f.from, to = f.to }
    end
  end

  return steps, skipped
end

---@param steps Lib.Case.NormalizeStep[]
---@return string[]
function M.describe(steps)
  if #steps == 0 then
    return { "Nothing to normalize." }
  end
  local lines = {}
  for _, s in ipairs(steps) do
    lines[#lines + 1] = ("%-10s rename  %s  ->  %s"):format(s.short, s.from, s.to)
  end
  return lines
end

---@class Lib.Case.NormalizeResult
---@field step Lib.Case.NormalizeStep
---@field ok boolean
---@field err string|nil

---@param steps Lib.Case.NormalizeStep[]
---@return Lib.Case.NormalizeResult[]
function M.run(steps)
  local results = {}
  for _, s in ipairs(steps) do
    mkdirp(vim.fn.fnamemodify(s.to, ":h"))
    local ok, err = uv.fs_rename(s.from, s.to)
    results[#results + 1] = { step = s, ok = ok and true or false, err = err }
  end
  return results
end

---@param results Lib.Case.NormalizeResult[]
---@return boolean all_ok
---@return string[] errors
function M.errors(results)
  local errs = {}
  for _, r in ipairs(results) do
    if not r.ok then
      errs[#errs + 1] = ("%s -> %s: %s"):format(r.step.from, r.step.to, r.err or "unknown error")
    end
  end
  return #errs == 0, errs
end

return M
