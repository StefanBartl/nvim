---@module 'bindings.usrcmds.case.terminology'
--- Collects every `## Term` entry out of every `Terminologie.md` across the
--- whole work repo (`config.repo_root`, not just `Cases/SAP_Support` — a
--- term explained while working an SAP case is just as useful from a
--- Tosca onboarding doc or a NOT_SAP case) into one searchable index.
---
--- ROADMAP.md's "Terminologie-Sammler": right now a term explained in one
--- case's local `Terminologie.md` is invisible to every other case — this
--- makes it findable from anywhere, without moving or duplicating the
--- source files.

local config = require("bindings.usrcmds.case.config")
local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")

local M = {}

--- Headings that are structural, not a term — a literal "## Terminologie"
--- (mirroring the file's own H1) or the "## Table of content" a couple of
--- these files start with.
local SKIP_HEADINGS = {
  ["table of content"] = true,
  ["terminologie"] = true,
}

---@class Lib.Case.TerminologyEntry
---@field term string
---@field body string  Trimmed body text (the `---` rules between entries stripped).
---@field path string  Absolute path of the `Terminologie.md` it came from.
---@field line integer  1-based line of the heading, for jumping straight to it.

--- Some files link the term itself instead of just naming it — e.g.
--- `## [Completed Scenario](https://docs.tricentis.com/...)` throughout
--- `Tosca/Notes/OSV/Terminologie.md`. The URL isn't useful in a term list;
--- the link text is the term.
---@param heading string
---@return string
local function clean_heading(heading)
  return vim.trim((heading:gsub("%[([^%]]+)%]%([^%)]+%)", "%1")))
end

---@param path string
---@return Lib.Case.TerminologyEntry[]
local function parse_file(path)
  local content = read(path)
  if not content then
    return {}
  end
  local lines = vim.split(content:gsub("\r", ""), "\n", { plain = true })

  local entries = {}
  local term, line_no, body = nil, nil, {}

  local function flush()
    if term and not SKIP_HEADINGS[term:lower()] then
      local text = vim.trim(table.concat(body, "\n"))
      if text ~= "" then
        entries[#entries + 1] = { term = term, body = text, path = path, line = line_no }
      end
    end
  end

  -- H2 *and* H3: most files here are flat (H1 title, H2 = term), but at
  -- least one (PART4 - DEX and CICD) groups terms under a numbered H2
  -- ("## 1. Kernkonzepte & Infrastruktur") with the actual terms one level
  -- down as H3. A bare group heading has no prose before its first H3
  -- child, so `flush()`'s own "text ~= ''" check already drops it as an
  -- entry on its own — no extra "is this a group" logic needed.
  for i, line in ipairs(lines) do
    local heading = line:match("^##%s+(.+)$") or line:match("^###%s+(.+)$")
    if heading then
      flush()
      term, line_no, body = clean_heading(heading), i, {}
    elseif term and line ~= "---" then
      body[#body + 1] = line
    end
  end
  flush()

  return entries
end

--- Every term across the whole repo, sorted alphabetically. A term defined
--- in more than one file appears more than once, deliberately — different
--- files may define it slightly differently (e.g. general Tosca usage vs.
--- one case's specific angle on it), and picking a "winner" would hide
--- that instead of surfacing it.
---@return Lib.Case.TerminologyEntry[]
function M.list()
  local out = {}
  for _, path in ipairs(collect_recursive.files(config.repo_root)) do
    if vim.fn.fnamemodify(path, ":t") == "Terminologie.md" then
      vim.list_extend(out, parse_file(path))
    end
  end
  table.sort(out, function(a, b)
    return a.term:lower() < b.term:lower()
  end)
  return out
end

return M
