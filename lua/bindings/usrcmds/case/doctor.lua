---@module 'bindings.usrcmds.case.doctor'
--- Read-only bestand-consistency report: the personal work-notes file named
--- four different ways, Research as a folder vs. a flat file, Solution/
--- Solutions naming variance, two known typo'd filenames, ROADMAP.md v6's
--- NN_-prefix convention in Research/Replies, and whether `Summary.md`
--- actually follows the mandated ServiceNow template.
---
--- Two documents, deliberately kept apart (see CONCEPT.md §8a):
---   Summary.md — the SNOW-facing document, fixed four-section template
---                from Workflow/Templates/SummaryTemplate.md
---   Notes.md   — private work notes: what was tried, coach input, tasks
---
--- Never writes. Every finding carries the safe rename target
--- `normalize.lua` would apply, or `to = nil` when no rename can fix it —
--- either because the target already exists (ambiguous) or because the
--- finding is about missing human-written content, which no rename
--- produces. normalize.lua acts on `to ~= nil` only.

local registry = require("bindings.usrcmds.case.registry")
local config = require("bindings.usrcmds.case.config")
local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")

local M = {}

local uv = vim.uv or vim.loop

--- Historical names for the case's *personal work notes* — the running
--- log of what was tried, what the coach said, what to do next.
---
--- These are NOT alternative names for `Summary.md`, and treating them as
--- such was a real bug: `Summary.md` is the ServiceNow-facing document and
--- follows a fixed four-section template (see `SNOW_SECTIONS`), whereas
--- these are private notes in whatever shape the day demanded. An earlier
--- version of this file renamed all four into `Summary.md`, which in one
--- case overwrote the actual SNOW summary (recovered from git; see
--- MIGRATION.md). They normalize to `Notes.md` instead.
local NOTES_ALIASES = { "ProblemSummary.md", "WorkNote.md", "CaseNote.md", "TillNow.md" }

--- The section headings `Workflow/Templates/SummaryTemplate.md` mandates.
--- A `Summary.md` missing any of them is reported, never auto-fixed —
--- the content is human-written and no rename can produce it.
local SNOW_SECTIONS = { "Problem statement", "Case notes", "Links", "Solution or workaround" }

--- Summary.md is pasted into ServiceNow, which renders none of this — a
--- `##` or `**bold**` shows up verbatim in the ticket. The box-drawing
--- rules the template itself uses are not markdown and stay.
---
--- Scope note: bullets (`*`/`-`) and inline links are NOT flagged, because
--- `Workflow/Templates/SummaryTemplateBefüllt.md` — the reference filled-in
--- example — uses both throughout. Only constructs that example never uses
--- are treated as mistakes.
local MARKDOWN_PATTERNS = {
  { pattern = "^#+%s", desc = "heading (#)" },
  { pattern = "%*%*[^%*]+%*%*", desc = "bold (**)" },
  { pattern = "^```", desc = "code fence (```)" },
}

local KNOWN_TYPOS = {
  ["00_Initital.md"] = "00_Initial.md",
  ["00_RequestInfrmations.md"] = "00_RequestInformations.md",
}

-- The two blueprint folders whose files are meant to carry a `NN_` prefix
-- (Research/00_Research.md, Replies/00_PSO.md, and every file `:Case add`
-- creates afterward follow suit) — assets/ is deliberately excluded,
-- attachments there keep whatever name they arrived with.
local NN_PREFIX_DIRS = { "Research", "Replies" }

---@class Lib.Case.DoctorFinding
---@field short string
---@field kind string
---@field detail string
---@field from string  Absolute path of the file/dir as it exists now, OR (when `action` is set) a human-readable label for display only.
---@field to string|nil  Absolute path normalize.lua would rename/move `from` to. `nil` means either the target already exists (ambiguous, normalize.lua skips it) or the finding uses `action` instead of a rename.
---@field action (fun(): boolean, string|nil)|nil  Set instead of `to` for a fix that isn't a rename (e.g. deleting a stale session) — normalize.lua calls this rather than mutate.rename_file. Mutually exclusive with `to`.

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

---@param dir string
---@return string[] direct child file basenames (no recursion)
local function top_level_files(dir)
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
    if typ == "file" then
      names[#names + 1] = name
    end
  end
  return names
end

--- stream-incomplete (EXTRACTION.md §4, Paket 2): every `NN_ActivityStream.md`
--- under a case, checked against its own declared "`<N>` / `<N> total
--- activities.`" header count. A mismatch means the SNOW view wasn't
--- fully expanded before copying ("Show less"/"Show more" left
--- collapsed) — report-only, no rename can fix missing content, the fix
--- is re-pasting from SNOW.
---@param e Lib.Case.RegistryEntry
---@return Lib.Case.DoctorFinding[]
local function stream_completeness_findings(e)
  local out = {}
  local research_dir = e.dir .. "/Research"
  local st = uv.fs_stat(research_dir)
  if not (st and st.type == "directory") then
    return out
  end
  local stream = require("bindings.usrcmds.case.extract.stream")
  for _, name in ipairs(top_level_files(research_dir)) do
    if name:match("_ActivityStream%.md$") then
      local path = research_dir .. "/" .. name
      local content = read(path)
      if content then
        local declared, actual = stream.completeness(content)
        if declared and declared ~= actual then
          out[#out + 1] = {
            short = e.short,
            kind = "stream-incomplete",
            detail = ("%s: declared %d activities, found %d — re-expand \"Show more\" in SNOW before copying"):format(
              name,
              declared,
              actual
            ),
            from = path,
            to = nil,
          }
        end
      end
    end
  end
  return out
end

--- Files directly inside Research/ or Replies/ with no `NN_` prefix. Numbers
--- are assigned sequentially (alphabetical among the unprefixed files)
--- starting right after the highest prefix already in use — the same
--- "scan existing, take max+1" rule `ui.lua`'s `:Case add reply` already
--- uses, just applied to a whole batch instead of one new file at a time.
---@param e Lib.Case.RegistryEntry
---@return Lib.Case.DoctorFinding[]
local function nn_prefix_findings(e)
  local out = {}
  for _, sub in ipairs(NN_PREFIX_DIRS) do
    local dir = e.dir .. "/" .. sub
    local st = uv.fs_stat(dir)
    if st and st.type == "directory" then
      local max_n, unprefixed = -1, {}
      for _, name in ipairs(top_level_files(dir)) do
        local n = name:match("^(%d%d)_")
        if n then
          max_n = math.max(max_n, tonumber(n))
        else
          unprefixed[#unprefixed + 1] = name
        end
      end
      table.sort(unprefixed)
      local next_n = max_n + 1
      for _, name in ipairs(unprefixed) do
        local from = dir .. "/" .. name
        local prefixed = ("%02d_%s"):format(next_n, name)
        local to = dir .. "/" .. prefixed
        out[#out + 1] = {
          short = e.short,
          kind = "missing-nn-prefix",
          detail = ("%s/%s -> %s/%s"):format(sub, name, sub, prefixed),
          from = from,
          to = exists(to) and nil or to,
        }
        next_n = next_n + 1
      end
    end
  end
  return out
end

---@return Lib.Case.DoctorFinding[]
function M.check()
  local findings = {}

  for _, e in ipairs(registry.list()) do
    local basenames = basenames_of(e.dir)
    local has_notes = exists(e.dir .. "/Notes.md")

    -- notes-alias: personal work notes under a historical name, at the case
    -- root. Target is Notes.md — never Summary.md, which is the SNOW
    -- document and a different thing entirely.
    for _, alias in ipairs(NOTES_ALIASES) do
      local from = e.dir .. "/" .. alias
      if exists(from) then
        findings[#findings + 1] = {
          short = e.short,
          kind = "notes-alias",
          detail = has_notes and (alias .. " (alongside an existing Notes.md)") or alias,
          from = from,
          to = has_notes and nil or (e.dir .. "/Notes.md"),
        }
      end
    end

    -- summary-not-snow: report-only (`to = nil` always). Neither a missing
    -- Summary.md nor an off-template one can be fixed by renaming
    -- something, so normalize.lua must never pick these up.
    do
      local summary_path = e.dir .. "/Summary.md"
      local content = exists(summary_path) and read(summary_path) or nil
      if not content then
        findings[#findings + 1] = {
          short = e.short,
          kind = "summary-not-snow",
          detail = "no Summary.md (SummaryTemplate.md's four sections expected)",
          from = summary_path,
          to = nil,
        }
      else
        local missing = {}
        for _, section in ipairs(SNOW_SECTIONS) do
          if not content:find(section, 1, true) then
            missing[#missing + 1] = section
          end
        end
        if #missing > 0 then
          findings[#findings + 1] = {
            short = e.short,
            kind = "summary-not-snow",
            detail = ("Summary.md missing section(s): %s"):format(table.concat(missing, ", ")),
            from = summary_path,
            to = nil,
          }
        end

        local seen_md, md_hits = {}, {}
        for line in (content:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
          for _, m in ipairs(MARKDOWN_PATTERNS) do
            if not seen_md[m.desc] and line:find(m.pattern) then
              seen_md[m.desc] = true
              md_hits[#md_hits + 1] = m.desc
            end
          end
        end
        if #md_hits > 0 then
          findings[#findings + 1] = {
            short = e.short,
            kind = "summary-markdown",
            detail = ("Summary.md uses markdown SNOW won't render: %s"):format(table.concat(md_hits, ", ")),
            from = summary_path,
            to = nil,
          }
        end
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

    -- naming-variant: the case-local attachments folder used to be called
    -- "Ressources" (a typo'd loanword, never actually "Ressourcen" despite
    -- how it's usually pronounced) — target renames it to the current
    -- convention, config.assets_dirname ("assets", ROADMAP.md).
    for _, dirname in ipairs(top_level_dirs(e.dir)) do
      if dirname:lower() == "ressources" and dirname ~= config.assets_dirname then
        local from = e.dir .. "/" .. dirname
        local to = e.dir .. "/" .. config.assets_dirname
        findings[#findings + 1] = {
          short = e.short,
          kind = "naming-variant",
          detail = ("%s/ (%s/ is the convention)"):format(dirname, config.assets_dirname),
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

    vim.list_extend(findings, nn_prefix_findings(e))
    vim.list_extend(findings, stream_completeness_findings(e))
  end

  -- stale-session (SESSIONS.md §6, Paket 3): the safety net behind the
  -- ACTIVE hook in ui.lua's do_move/do_delete, which only deletes a case's
  -- session when the move happens THROUGH :Case(s) close/reassign. A case
  -- closed before that hook existed, or moved/deleted by hand outside
  -- casedesk, leaves an orphaned session sessions.nvim would still happily
  -- offer to load. Not a rename — `action` runs sessions.delete() instead
  -- of normalize.lua's usual mutate.rename_file(from, to).
  --
  -- Optional dependency (`pcall`), same pattern as every other sessions.nvim
  -- touchpoint in this module (CONCEPT.md §9): silently skipped, not an
  -- error, when sessions.nvim isn't loaded (remote mode, different plugin
  -- selection).
  local ok_sessions, sessions = pcall(require, "sessions")
  if ok_sessions then
    for _, path in ipairs(sessions.list()) do
      local name = vim.fn.fnamemodify(path, ":t:r")
      local entry = registry.find(name)
      if entry and entry.state ~= config.default_state then
        findings[#findings + 1] = {
          short = entry.short,
          kind = "stale-session",
          detail = ("session '%s' exists for a %s case"):format(name, entry.state),
          from = path,
          to = nil,
          action = function()
            return sessions.delete(name)
          end,
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
    -- Three cases: `to` set (normalize.lua renames it), `action` set
    -- (normalize.lua runs it — no rename target to show), or neither (never
    -- touched, for one of two different reasons — saying which one is the
    -- difference between a useful report and a confusing one).
    local suffix = ""
    if not f.to and not f.action then
      if f.kind == "summary-not-snow" or f.kind == "summary-markdown" then
        suffix = "  [edit by hand — no rename can fix this]"
      else
        suffix = "  [ambiguous — target exists, needs manual fix]"
      end
    end
    lines[#lines + 1] = ("%-10s %-16s %s%s"):format(f.short, f.kind, f.detail, suffix)
  end
  return lines
end

return M
