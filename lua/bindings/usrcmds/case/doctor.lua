---@module 'bindings.usrcmds.case.doctor'
--- Read-only bestand-consistency report (MIGRATION.md §4: the case-note
--- file named five different ways, Research as a folder vs. a flat file,
--- Solution/Solutions naming variance, two known typo'd filenames). Never
--- writes — but every finding carries the safe rename target `normalize.lua`
--- (ROADMAP.md v6) would apply, or `to = nil` when the target already exists
--- and an automatic fix would clobber something (normalize.lua then skips
--- it, reported as ambiguous rather than silently guessed at).

local registry = require("bindings.usrcmds.case.registry")
local collect_recursive = require("lib.nvim.fs.collect_recursive")

local M = {}

local uv = vim.uv or vim.loop

local SUMMARY_ALIASES = { "ProblemSummary.md", "WorkNote.md", "CaseNote.md", "TillNow.md" }

local KNOWN_TYPOS = {
  ["00_Initital.md"] = "00_Initial.md",
  ["00_RequestInfrmations.md"] = "00_RequestInformations.md",
}

---@class Lib.Case.DoctorFinding
---@field short string
---@field kind string
---@field detail string
---@field from string  Absolute path of the file or directory as it exists now.
---@field to string|nil  Absolute path normalize.lua would rename/move `from` to. `nil` means the target already exists — ambiguous, normalize.lua skips it.

---@param path string
---@return boolean
local function exists(path)
  return uv.fs_stat(path) ~= nil
end

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
    local has_summary = exists(e.dir .. "/Summary.md")

    -- summary-alias: flat file at case root, target is the case root's Summary.md.
    for _, alias in ipairs(SUMMARY_ALIASES) do
      local from = e.dir .. "/" .. alias
      if exists(from) then
        findings[#findings + 1] = {
          short = e.short,
          kind = "summary-alias",
          detail = has_summary and (alias .. " (alongside an existing Summary.md)") or alias,
          from = from,
          to = has_summary and nil or (e.dir .. "/Summary.md"),
        }
      end
    end

    -- research-as-file: flat file at case root, target moves it into Research/.
    do
      local from = e.dir .. "/Research.md"
      if exists(from) then
        local to = e.dir .. "/Research/Research.md"
        findings[#findings + 1] = {
          short = e.short,
          kind = "research-as-file",
          detail = "Research.md (Research/ folder is the convention)",
          from = from,
          to = exists(to) and nil or to,
        }
      end
    end

    -- naming-variant: Solutions/ (plural) folder, target renames it to Solution/.
    for _, dirname in ipairs(top_level_dirs(e.dir)) do
      if dirname:lower() == "solutions" then
        local from = e.dir .. "/" .. dirname
        local to = e.dir .. "/Solution"
        findings[#findings + 1] = {
          short = e.short,
          kind = "naming-variant",
          detail = "Solutions/ (Solution/ singular is the convention)",
          from = from,
          to = exists(to) and nil or to,
        }
      end
    end

    -- naming-variant: Solution.md flat file, target moves it into Solution/.
    do
      local from = e.dir .. "/Solution.md"
      if exists(from) then
        local to = e.dir .. "/Solution/Solution.md"
        findings[#findings + 1] = {
          short = e.short,
          kind = "naming-variant",
          detail = "Solution.md (Solution/ folder is the convention)",
          from = from,
          to = exists(to) and nil or to,
        }
      end
    end

    -- typo: wherever it occurs in the tree, target is the fix in the same dir.
    for typo, fix in pairs(KNOWN_TYPOS) do
      local from = basenames[typo]
      if from then
        local to = vim.fn.fnamemodify(from, ":h") .. "/" .. fix
        findings[#findings + 1] = {
          short = e.short,
          kind = "typo",
          detail = ("%s -> %s"):format(typo, fix),
          from = from,
          to = exists(to) and nil or to,
        }
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
    local suffix = f.to and "" or "  [ambiguous — target exists, needs manual fix]"
    lines[#lines + 1] = ("%-10s %-16s %s%s"):format(f.short, f.kind, f.detail, suffix)
  end
  return lines
end

return M
