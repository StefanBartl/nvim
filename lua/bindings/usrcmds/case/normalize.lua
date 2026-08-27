---@module 'bindings.usrcmds.case.normalize'
--- The fix-it counterpart to doctor.lua (ROADMAP.md v6): turns every
--- unambiguous finding (`to ~= nil`) into a rename/move step. Findings
--- doctor.lua already marked ambiguous (`to == nil`, because the target
--- exists) are never touched here — they're reported so a human can look,
--- same policy as apply.lua never overwriting an existing file.

local doctor = require("bindings.usrcmds.case.doctor")
local mkdirp = require("lib.nvim.fs.mkdirp")
local mutate = require("lib.nvim.cross.fs.mutate")

local M = {}

---@class Lib.Case.NormalizeStep
---@field short string
---@field kind string
---@field from string
---@field to string|nil
---@field action (fun(): boolean, string|nil)|nil  Set instead of `to` — see doctor.lua's Lib.Case.DoctorFinding.

--- What WOULD be fixed, split from what doctor found but can't safely fix
--- automatically. A finding is a candidate when it has a rename target
--- (`to`) OR a self-contained fix (`action`, e.g. deleting a stale session —
--- not every fix is a rename). Two findings in the same case can
--- independently compute the same `to` (e.g. a case with BOTH CaseNote.md
--- and TillNow.md present, neither Summary.md yet — doctor.lua checks each
--- alias in isolation) — applying both would have the second rename
--- silently clobber the first, so any target claimed by more than one
--- finding is treated as ambiguous too. `action` findings have no `to` to
--- collide on, so they skip that check entirely.
---@return Lib.Case.NormalizeStep[] steps
---@return Lib.Case.DoctorFinding[] skipped  Ambiguous findings (to == nil and no action, or to claimed by >1 finding).
function M.plan()
  local candidates, skipped = {}, {}
  for _, f in ipairs(doctor.check()) do
    if f.to or f.action then
      candidates[#candidates + 1] = f
    else
      skipped[#skipped + 1] = f
    end
  end

  local target_count = {}
  for _, f in ipairs(candidates) do
    if f.to then
      target_count[f.to] = (target_count[f.to] or 0) + 1
    end
  end

  local steps = {}
  for _, f in ipairs(candidates) do
    if f.to and target_count[f.to] > 1 then
      skipped[#skipped + 1] = f
    else
      steps[#steps + 1] =
        { short = f.short, kind = f.kind, from = f.from, to = f.to, action = f.action }
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
    if s.action then
      lines[#lines + 1] = ("%-10s %-8s %s"):format(s.short, s.kind, s.from)
    else
      lines[#lines + 1] = ("%-10s rename  %s  ->  %s"):format(s.short, s.from, s.to)
    end
  end
  return lines
end

---@class Lib.Case.NormalizeResult
---@field step Lib.Case.NormalizeStep
---@field ok boolean
---@field err string|nil

--- Renames go through `lib.nvim.cross.fs.mutate`, not a bare `uv.fs_rename`:
--- on Windows, a directory watcher (neo-tree's own leaked `fs_event`
--- handles are the known repeat offender — see the workstation's
--- filetree-handle-guard notes) or an AV/indexer scan can hold a
--- transient, spurious lock on exactly the file being renamed.
--- `mutate.rename_file` retries a few times with backoff before giving up,
--- which a single direct `fs_rename` call never gets the chance to do.
---@param steps Lib.Case.NormalizeStep[]
---@return Lib.Case.NormalizeResult[]
function M.run(steps)
  local results = {}
  for _, s in ipairs(steps) do
    if s.action then
      local ok, err = s.action()
      results[#results + 1] = { step = s, ok = ok and true or false, err = err }
    else
      mkdirp(vim.fn.fnamemodify(s.to, ":h"))
      local ok, err = mutate.rename_file(s.from, s.to)
      results[#results + 1] = { step = s, ok = ok and true or false, err = err }
    end
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
      local label = r.step.to and ("%s -> %s"):format(r.step.from, r.step.to) or r.step.from
      errs[#errs + 1] = ("%s: %s"):format(label, r.err or "unknown error")
    end
  end
  return #errs == 0, errs
end

return M
