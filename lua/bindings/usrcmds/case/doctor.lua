---@module 'bindings.usrcmds.case.doctor'
--- Read-only bestand-consistency report (MIGRATION.md §4: the case-note
--- file named five different ways, Research as a folder vs. a flat file,
--- Solution/Solutions naming variance, two known typo'd filenames). Never
--- writes — `:Cases normalize` (not yet built, ROADMAP.md v6) is the
--- fix-it counterpart; this only ever reports.

local registry = require("bindings.usrcmds.case.registry")
local collect_recursive = require("lib.nvim.fs.collect_recursive")

local M = {}

local SUMMARY_ALIASES = { "ProblemSummary.md", "WorkNote.md", "CaseNote.md", "TillNow.md" }

local KNOWN_TYPOS = {
  ["00_Initital.md"] = "00_Initial.md",
  ["00_RequestInfrmations.md"] = "00_RequestInformations.md",
}

---@class Lib.Case.DoctorFinding
---@field short string
---@field kind string
---@field detail string

---@param dir string
---@return table<string, string> basename -> absolute path (last one wins on a clash, irrelevant here)
local function basenames_of(dir)
  local out = {}
  for _, f in ipairs(collect_recursive.files(dir)) do
    out[vim.fn.fnamemodify(f, ":t")] = f
  end
  return out
end

---@param dir string
---@return string[] top-level directory basenames
local function top_level_dirs(dir)
  local uv = vim.uv or vim.loop
  local names = {}
  local fd = uv.fs_scandir(dir)
  if not fd then
    return names
  end
  while true do
    local name, typ = uv.fs_scandir_next(fd)
    if not name then
      break
    end
    if typ == "directory" then
      names[#names + 1] = name
    end
  end
  return names
end

---@return Lib.Case.DoctorFinding[]
function M.check()
  local findings = {}

  for _, e in ipairs(registry.list()) do
    local basenames = basenames_of(e.dir)
    local has_summary = basenames["Summary.md"] ~= nil

    for _, alias in ipairs(SUMMARY_ALIASES) do
      if basenames[alias] then
        findings[#findings + 1] = {
          short = e.short,
          kind = "summary-alias",
          detail = has_summary and (alias .. " (alongside an existing Summary.md)") or alias,
        }
      end
    end

    if basenames["Research.md"] then
      findings[#findings + 1] = {
        short = e.short,
        kind = "research-as-file",
        detail = "Research.md (Research/ folder is the convention)",
      }
    end

    for _, dirname in ipairs(top_level_dirs(e.dir)) do
      if dirname:lower() == "solutions" then
        findings[#findings + 1] = { short = e.short, kind = "naming-variant", detail = "Solutions/ (Solution/ singular is the convention)" }
      end
    end
    if basenames["Solution.md"] then
      findings[#findings + 1] = { short = e.short, kind = "naming-variant", detail = "Solution.md (Solution/ folder is the convention)" }
    end

    for typo, fix in pairs(KNOWN_TYPOS) do
      if basenames[typo] then
        findings[#findings + 1] = { short = e.short, kind = "typo", detail = ("%s -> %s"):format(typo, fix) }
      end
    end
  end

  return findings
end

---@param findings Lib.Case.DoctorFinding[]
---@return string[]
function M.describe(findings)
  if #findings == 0 then
    return { "No inconsistencies found." }
  end
  local lines = {}
  for _, f in ipairs(findings) do
    lines[#lines + 1] = ("%-10s %-16s %s"):format(f.short, f.kind, f.detail)
  end
  return lines
end

return M
