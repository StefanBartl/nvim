---@module 'bindings.usrcmds.case.extract.facts'
--- EXTRACTION.md §7 Richtung 1: the "Ermittelte Fakten" block — everything
--- an LLM reliably gets wrong (version numbers, dates, priorities) is
--- exactly what's deterministically parsable here, so it goes into the
--- prompt as a fact block instead of being left for the model to guess or
--- (worse) hallucinate. Pulls from every other `extract/`+`sla/`+`meta`
--- source already built (Paket 1-4) rather than re-parsing anything —
--- this module is purely an aggregator/renderer.
---
--- Every line degrades independently: a case with no support-info still
--- gets a fact block, just without the TBox-Build/Api-Core/Custom-Controls
--- lines (EXTRACTION.md §8: "Fehlen heißt 'nicht ermittelt', nicht
--- 'Fehler'"). Not independently re-verified end-to-end against a real
--- case with every signal present at once — each underlying extractor
--- (supportinfo/stream/sla/doclinks) already was, individually.

local meta = require("bindings.usrcmds.case.meta")
local detect = require("bindings.usrcmds.case.detect")
local supportinfo = require("bindings.usrcmds.case.extract.supportinfo")
local stream_extract = require("bindings.usrcmds.case.extract.stream")
local sla_stream = require("bindings.usrcmds.case.sla.stream")
local doclinks = require("bindings.usrcmds.case.extract.doclinks")
local read = require("lib.nvim.fs.read")

local M = {}

---@param entry Lib.Case.RegistryEntry
---@return string|nil tbox_build, string|nil api_core, string|nil custom_controls
local function supportinfo_facts(entry)
  local path = supportinfo.find(entry.dir)
  if not path then
    return nil, nil, nil
  end
  local content = read(path)
  if not content then
    return nil, nil, nil
  end
  local parsed = supportinfo.parse(content)
  local d = supportinfo.digest(parsed)
  local custom_controls = "keine"
  if #d.unusual > 0 then
    local names = {}
    for _, e in ipairs(d.unusual) do
      names[#names + 1] = e.name
    end
    custom_controls = table.concat(names, ", ")
  end
  return d.tbox_build, d.api_core, custom_controls
end

---@param entry Lib.Case.RegistryEntry
---@return string|nil impact
---@return string|nil current_state
---@return integer|nil since
---@return integer awaiting_count
local function stream_facts(entry)
  local path = stream_extract.find(entry.dir)
  if not path then
    return nil, nil, nil, 0
  end
  local content = read(path)
  if not content then
    return nil, nil, nil, 0
  end
  local parsed = sla_stream.parse(content)
  local current_state, since = nil, nil
  if #parsed.states > 0 then
    local latest = parsed.states[#parsed.states]
    current_state, since = latest.to, latest.at
  end
  local awaiting_count = 0
  for _, s in ipairs(parsed.states) do
    if s.to == "Awaiting User Info" then
      awaiting_count = awaiting_count + 1
    end
  end
  return parsed.impact, current_state, since, awaiting_count
end

--- Filenames the customer's own Activity Stream says they attached
--- (`extract/stream.lua`'s `M.attachments`, parsed off "New attachment(s)
--- added…" lines) — not what's actually sitting in `assets/`. Answers
--- "what did the customer say they sent" as its own fact, independent of
--- whether it was ever downloaded in; a mismatch between the two is for a
--- human to notice, not something this line judges.
---@param entry Lib.Case.RegistryEntry
---@return string[] attachments
local function stream_attachments(entry)
  local path = stream_extract.find(entry.dir)
  if not path then
    return {}
  end
  local content = read(path)
  if not content then
    return {}
  end
  return stream_extract.attachments(content)
end

---@param status Lib.Case.SlaStatus
---@return string
local function sla_line(status)
  local parts = {}
  for _, c in ipairs(status.first_response) do
    local state = c.done and "erfüllt" or (c.remaining < 0 and "überfällig" or "offen")
    parts[#parts + 1] = ("Erstreaktion %s"):format(state)
  end
  if status.cadence then
    parts[#parts + 1] = ("Rückmeldung fällig %s"):format(os.date("%d.%m. %H:%M", status.cadence.deadline))
  elseif status.awaiting_customer then
    parts[#parts + 1] = "Rückmeldung wartet auf Kunden"
  end
  if status.fix then
    local state = status.fix.remaining < 0 and "überfällig" or "offen"
    parts[#parts + 1] = ("Korrekturmaßnahme %s"):format(state)
  end
  return table.concat(parts, " · ")
end

---@param case_dir string
---@param m table|nil
---@return string
local function doclinks_line(case_dir, m)
  local all_links = doclinks.all_links(case_dir)
  if #all_links == 0 then
    return "keine"
  end
  local by_version = {}
  local order = {}
  for _, l in ipairs(all_links) do
    local norm = doclinks.normalize_version(l.version) or l.version
    if not by_version[norm] then
      order[#order + 1] = norm
    end
    by_version[norm] = (by_version[norm] or 0) + 1
  end
  table.sort(order)
  local parts = {}
  for _, version in ipairs(order) do
    parts[#parts + 1] = ("%d× tosca-%s"):format(by_version[version], version)
  end
  local line = table.concat(parts, ", ")
  local mismatches = doclinks.check(case_dir, m and m.tosca_version)
  if #mismatches > 0 then
    line = line .. "  ⚠ Version passt nicht"
  end
  return line
end

--- Render the `## Ermittelte Fakten` block for `:Case ki`'s `{facts}`
--- token — EXTRACTION.md §7's worked example format.
---@param entry Lib.Case.RegistryEntry
---@return string[] lines
function M.render(entry)
  local m = meta.read(entry.dir)
  local guess = detect.guess(entry.dir)

  local lines = { "## Ermittelte Fakten (maschinell, nicht raten)", "" }

  local priority = (m and m.priority) or "unbekannt"
  local impact, current_state, since, awaiting_count = stream_facts(entry)
  lines[#lines + 1] = ("- Case: %s · Priorität %s · Impact %s"):format(entry.short, priority, impact or "unbekannt")

  local sap_component = (m and m.sap_component) or "unbekannt"
  lines[#lines + 1] = ("- SAP Component: %s"):format(sap_component)

  local commander = (m and m.versions and m.versions.commander) or (m and m.tosca_version) or guess.tosca_version
  local server = m and m.versions and m.versions.server
  lines[#lines + 1] = ("- Tosca Commander: %s · Tosca Server: %s"):format(commander or "unbekannt", server or "unbekannt")

  local tbox_build, api_core, custom_controls = supportinfo_facts(entry)
  if tbox_build or api_core then
    lines[#lines + 1] = ("- TBox-Build: %s · Api Core: %s"):format(tbox_build or "unbekannt", api_core or "unbekannt")
  end
  if custom_controls then
    lines[#lines + 1] = ("- Custom Controls: %s"):format(custom_controls)
  end

  if current_state then
    local since_str = since and os.date("%Y-%m-%d", since) or "unbekannt"
    local awaiting_str = awaiting_count > 0 and (", %d× Awaiting User Info in der Historie"):format(awaiting_count) or ""
    lines[#lines + 1] = ("- Zustand: %s (seit %s)%s"):format(current_state, since_str, awaiting_str)
  end

  local ok_sla, sla = pcall(require, "bindings.usrcmds.case.sla")
  if ok_sla then
    local ok_status, status = pcall(sla.status, entry)
    if ok_status and status then
      lines[#lines + 1] = ("- SLA: %s"):format(sla_line(status))
    end
  end

  lines[#lines + 1] = ("- Doku-Links im Case: %s"):format(doclinks_line(entry.dir, m))

  local attachments = stream_attachments(entry)
  lines[#lines + 1] = ("- Attachments laut Activity Stream: %s"):format(
    #attachments > 0 and table.concat(attachments, ", ") or "keine"
  )

  return lines
end

return M
