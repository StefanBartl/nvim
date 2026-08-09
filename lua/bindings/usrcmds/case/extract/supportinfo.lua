---@module 'bindings.usrcmds.case.extract.supportinfo'
--- `Ressources/ToscaSupportInfo*.txt` — the Tosca Commander-generated
--- dump: a fixed header block (EXTRACTION.md §2 "Kopfblock", the only
--- exactly-positioned part) followed by ~1600 alternating directory
--- headers and file entries. Parsed once per `:Case versions` call, no
--- cache — the file is ~250 KB, streaming it once is cheap, and a case's
--- support-info rarely changes within a session.
---
--- Validated against four real support-info files across three Tosca
--- generations (EXTRACTION.md §1) — the parser choices below (never a
--- fixed `%d+%.%d+%.%d+` version pattern, directory boundaries detected
--- structurally by "unindented line starting `<letter>:\`" rather than a
--- path whitelist, `report_created` kept as opaque text) all trace back to
--- a concrete finding in that table, not a hypothetical edge case.

local config = require("bindings.usrcmds.case.config")
local collect_recursive = require("lib.nvim.fs.collect_recursive")

local M = {}

local uv = vim.uv or vim.loop

--- Newest `ToscaSupportInfo*.txt` under a case's folder, by mtime —
--- EXTRACTION.md §10's risk table: more than one can exist
--- (`ToscaSupportInfo (1).txt`), and they can be two different machines,
--- not just two points in time, so "newest" is a default, not a claim of
--- correctness — the digest always shows `report_created` alongside so a
--- stale/wrong pick is visible, never silent.
---@param case_dir string
---@return string|nil path
function M.find(case_dir)
  local best, best_mtime = nil, -1
  for _, path in ipairs(collect_recursive.files(case_dir)) do
    if path:match("[Tt]osca[Ss]upport[Ii]nfo.*%.txt$") then
      local st = uv.fs_stat(path)
      local mtime = st and st.mtime and st.mtime.sec or 0
      if mtime > best_mtime then
        best, best_mtime = path, mtime
      end
    end
  end
  return best
end

---@class Lib.Case.SupportInfoHeader
---@field tcsupportinfo_version string|nil  Kopfzeile 4 — NEVER "the" version, see testsuite_version (EXTRACTION.md §2 Parser-Falle: the two can differ, e.g. 26.1.0.3180 vs. 2026.1)
---@field report_created string|nil  Raw text, deliberately never parsed as a timestamp — two locale formats seen (12h vs. 24h) with no field distinguishing them
---@field testsuite_version string|nil  e.g. "25.1.7" or "2026.1" — the stable anchor `detect.tosca_version` already reads
---@field entry_assembly string|nil
---@field tricentis_home string|nil
---@field commander_home string|nil
---@field tbox_home string|nil  The path entries are compared against to mean "TBox root", e.g. for the digest's "Auffällig" section

---@param content string
---@return Lib.Case.SupportInfoHeader
local function parse_header(content)
  local function line(pattern)
    local v = content:match(pattern)
    return v and vim.trim(v) or nil
  end
  return {
    tcsupportinfo_version = line("TCSupportInfo Version%s+([%d%.]+)"),
    report_created = line("Report created%s+([^\r\n]+)"),
    testsuite_version = line("Tosca Testsuite Version:%s*([^\r\n]+)"),
    entry_assembly = line("Entry Assembly:%s*([^\r\n]+)"),
    tricentis_home = line("Tricentis Home Directory:%s*([^\r\n]+)"),
    commander_home = line("Commander Home Directory:%s*([^\r\n]+)"),
    tbox_home = line("Tbox Home Directory:%s*([^\r\n]+)"),
  }
end

---@class Lib.Case.SupportInfoEntry
---@field name string  Filename only, e.g. "Tricentis.AutomationBase.dll".
---@field version string|nil  Kept as a STRING, never parsed as a number — EXTRACTION.md §2 Parser-Falle: formats seen include "34.8.0.280 (280)", "2, 8, 0", "3.3.0". Compare for equality only, never for ordering.
---@field dir string|nil  Absolute directory this entry was listed under.

--- The file list: alternating unindented directory headers (`C:\…`, always
--- a drive letter — never assume `TRICENTIS\Tosca Testsuite`, EXTRACTION.md
--- §2 saw `C:`/`D:`/`E:` and `Tosca Installation` instead of the usual
--- subpath) and 4-space-indented entries, an entry optionally followed by
--- its own 4-space-indented `Version:` line. A `Version:` line only ever
--- attaches to the entry immediately above it — a blank line (or a new
--- entry/header) always resets that link, so a malformed or reordered file
--- degrades to "no version" rather than mis-attaching one.
---@param content string
---@return Lib.Case.SupportInfoEntry[]
local function parse_entries(content)
  local entries = {}
  local current_dir = nil
  local pending = nil ---@type Lib.Case.SupportInfoEntry|nil
  for line in (content:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
    if line:match("^%a:\\") then
      current_dir = line
      pending = nil
    elseif line:match("^    Version:%s") then
      if pending then
        pending.version = vim.trim(line:match("^    Version:%s*(.*)$") or "")
      end
    elseif line:match("^    %S") then
      pending = { name = vim.trim(line), version = nil, dir = current_dir }
      entries[#entries + 1] = pending
    else
      pending = nil
    end
  end
  return entries
end

---@class Lib.Case.SupportInfoParsed
---@field header Lib.Case.SupportInfoHeader
---@field entries Lib.Case.SupportInfoEntry[]

---@param content string
---@return Lib.Case.SupportInfoParsed
function M.parse(content)
  return {
    header = parse_header(content),
    entries = parse_entries(content),
  }
end

---@param name string
---@return boolean
local function is_known_vendor(name)
  for _, prefix in ipairs(config.known_vendor_prefixes) do
    if name:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

---@class Lib.Case.SupportInfoDigest
---@field testsuite string|nil
---@field tbox_build string|nil
---@field api_core string|nil
---@field install_root string|nil
---@field report_created string|nil
---@field watched Lib.Case.SupportInfoEntry[]  config.version_watch hits, in that order
---@field unusual Lib.Case.SupportInfoEntry[]  TBox-root entries not matching any known_vendor_prefixes — EXTRACTION.md §2's "1600 Zeilen, 4 Zahlen" finding: this is the section worth actually reading, not the full list

--- The curated few numbers, not the 1600-line list (EXTRACTION.md §2: "Ein
--- Picker über 1588 Versionseinträge ist unbenutzbar"). "Auffällig" is the
--- core of the digest, not the headline numbers — a customer-added DLL
--- sitting in the TBox root is a real support signal (changes the scope,
--- a frequent error cause) that's invisible in a 1600-line flat list.
---@param parsed Lib.Case.SupportInfoParsed
---@return Lib.Case.SupportInfoDigest
function M.digest(parsed)
  local header = parsed.header
  ---@type table<string, Lib.Case.SupportInfoEntry>
  local root_by_name = {}
  for _, e in ipairs(parsed.entries) do
    if e.dir == header.tbox_home and not root_by_name[e.name] then
      root_by_name[e.name] = e
    end
  end

  local watched = {}
  for _, name in ipairs(config.version_watch) do
    if root_by_name[name] then
      watched[#watched + 1] = root_by_name[name]
    end
  end

  -- .dll/.exe only: EXTRACTION.md's "Auffällig" concern is specifically a
  -- customer-authored DLL, not a license text or a companion .deps.json/
  -- .runtimeconfig.json/.dll.config that a real library ships alongside
  -- its actual assembly (all three appear in the TBox root for real,
  -- correctly-vendored files — flagging them would just be noise).
  local unusual = {}
  for name, e in pairs(root_by_name) do
    if (name:match("%.dll$") or name:match("%.exe$")) and not is_known_vendor(name) then
      unusual[#unusual + 1] = e
    end
  end
  table.sort(unusual, function(a, b)
    return a.name < b.name
  end)

  local tbox_entry = root_by_name["Tricentis.AutomationBase.dll"]
  local api_entry = root_by_name["Tricentis.Automation.Api.Core.dll"]

  return {
    testsuite = header.testsuite_version,
    tbox_build = tbox_entry and tbox_entry.version,
    api_core = api_entry and api_entry.version,
    install_root = header.tbox_home,
    report_created = header.report_created,
    watched = watched,
    unusual = unusual,
  }
end

--- Resolve `key` (a `config.version_components` friendly name, OR any
--- substring of any entry's filename — EXTRACTION.md §3: "jedem
--- Substring-Treffer im Dateinamen", so `:Case versions tesseract` finds
--- `Tesseract.dll` without ever being in the table). A curated `file`
--- component that exists both under the TBox root AND elsewhere (seen for
--- real: `Tricentis.AutomationBase.dll` also ships its own copy under
--- `ToscaCommander\` with a DIFFERENT version) resolves to the TBox-root
--- copy specifically — that's the "main" one `config.version_components`
--- means; a bare substring search returns every match instead, since
--- there's no single "main" answer to prefer for an uncurated lookup.
---@param parsed Lib.Case.SupportInfoParsed
---@param key string
---@return { label: string, value: string }[] header_hits  At most one — a curated `header`-type component.
---@return Lib.Case.SupportInfoEntry[] entry_hits
function M.lookup(parsed, key)
  local spec = config.version_components[key:lower()]
  if spec then
    if spec.header == "Tosca Testsuite Version" then
      return { { label = "Tosca Testsuite Version", value = parsed.header.testsuite_version or "unknown" } }, {}
    elseif spec.file then
      local hits, preferred = {}, nil
      for _, e in ipairs(parsed.entries) do
        if e.name == spec.file then
          hits[#hits + 1] = e
          if e.dir == parsed.header.tbox_home then
            preferred = e
          end
        end
      end
      return {}, preferred and { preferred } or hits
    end
  end

  local needle = key:lower()
  local hits = {}
  for _, e in ipairs(parsed.entries) do
    if e.name:lower():find(needle, 1, true) then
      hits[#hits + 1] = e
    end
  end
  return {}, hits
end

return M
