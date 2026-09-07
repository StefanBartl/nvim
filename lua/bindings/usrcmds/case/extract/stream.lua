---@module 'bindings.usrcmds.case.extract.stream'
--- `Research/NN_ActivityStream.md` signals JENSEITS the SLA clock
--- (EXTRACTION.md §4) — `sla/stream.lua` stays deliberately narrow (only
--- what the three SLA clocks need: Priority/Impact, customer/assignment
--- events, state history), so this is a second, independent pass over the
--- same file for everything else: versions mentioned in prose (the
--- SERVER version exists nowhere but here — the support-info only knows
--- the Commander, EXTRACTION.md §4.1), KBA numbers, attachment names, the
--- Stammdaten block, and a completeness check.
---
--- Validated against a real stream (case 977392, EXTRACTION.md's own
--- documented patterns confirmed line-for-line: "Tosca Server - v…"/"Tosca
--- Commander - v…" prose versions, the "3572390 - Required information…"
--- KBA shape, the trailing Stammdaten dump, two-timestamps-per-comment).
--- `error_codes`/`doc_links`/`escalation` are built to EXTRACTION.md §4's
--- documented shapes but this one stream doesn't contain any — not
--- independently re-verified against real data this session, unlike
--- everything else here.
---
--- Three of these functions (`attachments`, `completeness`,
--- `last_reply_sent_at`) additionally understand SAP Resolve's
--- Tampermonkey export via `stream_format.detect` (EXTRACTION.md §13,
--- Paket 6b). The rest split into two groups: `versions_in_text`/`kbas`/
--- `error_codes`/`doc_links`/`escalations` need no dispatch because they
--- scan raw text for self-contained patterns and work on either source
--- unchanged, while `stammdaten` (and with it `case_short`, `sap_component`)
--- has no counterpart in that export at all and stays empty for it — a
--- real gap in what SAP Resolve copies out, not a parser shortcoming.

local render = require("bindings.usrcmds.case.render")
local config = require("bindings.usrcmds.case.config")
local clock = require("bindings.usrcmds.case.sla.clock")
local stream_format = require("bindings.usrcmds.case.stream_format")

local M = {}

local uv = vim.uv or vim.loop

---@param text string
---@return string[]
local function lines_of(text)
  return vim.split((text or ""):gsub("\r", ""), "\n", { plain = true })
end

--- Newest `NN_ActivityStream.md` under a case's `Research/`, by number —
--- same "most recent wins" policy as `extract.supportinfo.find`. Not
--- shared with `sla/init.lua`'s own private equivalent lookup yet
--- (EXTRACTION.md §9 flags consolidating the two as a follow-up, not done
--- here to avoid touching that module's own, already-tested code path).
---@param case_dir string
---@return string|nil path
function M.find(case_dir)
  local research_dir = case_dir .. "/Research"
  local fd = uv.fs_scandir(research_dir)
  if not fd then
    return nil
  end
  local best, best_n = nil, -1
  while true do
    local name = uv.fs_scandir_next(fd)
    if not name then
      break
    end
    local n = name:match("^(%d+)_ActivityStream%.md$")
    if n then
      local num = tonumber(n)
      if num and num > best_n then
        best_n, best = num, research_dir .. "/" .. name
      end
    end
  end
  return best
end

--- "Tosca Server - v2025.1.2" / "Tosca Commander - v2025.1.7" — the ONLY
--- place the server version exists (EXTRACTION.md §4.1); the Commander
--- version duplicates what `extract.supportinfo`/`detect.tosca_version`
--- already read from the support-info header, kept here too since it's
--- free and lets `:Case versions` fall back to the stream when no
--- support-info was attached at all.
---@param text string
---@return { server: string|nil, commander: string|nil }
function M.versions_in_text(text)
  return {
    server = text:match("Tosca Server%s*%-?%s*v?([%d%.]+)"),
    commander = text:match("Tosca Commander%s*%-?%s*v?([%d%.]+)"),
  }
end

---@class Lib.Case.KbaHit
---@field number string  7-digit KBA id.
---@field title string

--- `3572390 - Required information when opening case for…` — a 7-digit
--- number followed by " - "/" — " and text. Deliberately NOT any 7-digit
--- run: EXTRACTION.md §4 Parser-Falle — `customerNumber=3171302` matches
--- the digit-count alone. Requiring the dash-and-text tail is what
--- excludes that case (and a bare case-number reference, e.g. the
--- 10-digit `7153502026` seen in real data, fails on digit count alone).
---@param text string
---@return Lib.Case.KbaHit[]
function M.kbas(text)
  local out, seen = {}, {}
  for number, title in text:gmatch("(%d%d%d%d%d%d%d)%s*[%-–—]%s*([^\r\n]+)") do
    if not seen[number] then
      seen[number] = true
      out[#out + 1] = { number = number, title = vim.trim(title) }
    end
  end
  return out
end

--- Filenames following "New attachment(s) added…" — one per line until a
--- blank line. Also tells you whether a support-info *should* exist
--- (EXTRACTION.md §4.8): if `ToscaSupportInfo` never appears here but a
--- case has no support-info file either, that's worth fetching from SNOW.
---@param text string
---@return string[]
local function attachments_snow(text)
  local out = {}
  local ls = lines_of(text)
  local i = 1
  while i <= #ls do
    if vim.trim(ls[i]):match("^New attachment%(s%) added") then
      -- Real data: filenames are separated by BLANK lines, not terminated
      -- by the first one — "FileServices Properties.png\n\nToscaSupportInfo.txt"
      -- is two attachments, not one. Only "Show less" (which always
      -- follows this block type, same as every other comment/field-change
      -- block) reliably ends it.
      local j = i + 1
      while ls[j] and vim.trim(ls[j]) ~= "Show less" do
        local name = vim.trim(ls[j])
        if name ~= "" then
          out[#out + 1] = name
        end
        j = j + 1
      end
      i = j
    else
      i = i + 1
    end
  end
  return out
end

--- SAP Resolve announces an upload as an entry whose action is bare
--- `Attachment uploaded` — no filename anywhere (EXTRACTION.md §13). So
--- this normally returns nothing, on purpose: an empty list is the honest
--- answer, and inventing a placeholder would poison the one consumer that
--- reads real meaning into these names (`facts.lua`'s "did the customer
--- ever attach a ToscaSupportInfo?" check would start claiming they did).
--- A trailing filename IS picked up if it ever appears — that's the shape
--- an extended Tampermonkey script would produce, and matching it costs
--- one pattern.
---@param text string
---@return string[]
local function attachments_saperesolve(text)
  local out = {}
  for line in ((text or ""):gsub("\r", "")):gmatch("[^\n]+") do
    local h = stream_format.saperesolve_header(line)
    if h then
      local name = h.action:match("^Attachment uploaded%s*[:%-–—]%s*(.+)$")
      if name and vim.trim(name) ~= "" then
        out[#out + 1] = vim.trim(name)
      end
    end
  end
  return out
end

---@param text string
---@return string[]
function M.attachments(text)
  if stream_format.detect(text) == "saperesolve" then
    return attachments_saperesolve(text)
  end
  return attachments_snow(text)
end

--- SCREAMING_SNAKE_CASE tokens — Tricentis error codes
--- (`TRICENTIS_ERROR_CALL_PROVISIONING`, EXTRACTION.md §4.6). Requires at
--- least TWO underscores (3+ segments): one was too loose against real
--- data — it caught `HEC_ABAP` (a genuine SAP `Cloud System Type` value,
--- not an error code) and a truncated `SE_A` fragment out of a mixed-case
--- filename (`SE_ActiveTimeCalc.cs` — lowercase breaks the character
--- class mid-match). Every real Tricentis error code seen in EXTRACTION.md
--- §4's own example has 3+ underscore-separated segments; this is
--- deliberately not validated against a real hit in this session's
--- available data (none of it contains one), only against the two real
--- false positives above.
---@param text string
---@return string[]
function M.error_codes(text)
  local out, seen = {}, {}
  for code in text:gmatch("%u[%u%d]*_[%u%d]+_[%u%d_]+") do
    if not seen[code] then
      seen[code] = true
      out[#out + 1] = code
    end
  end
  return out
end

---@class Lib.Case.StreamDocLink
---@field url string
---@field version string  e.g. "2026.1"

--- `docs.tricentis.com/tosca-<version>/…` — the raw material `:Case
--- doclinks` (EXTRACTION.md §6, Paket 3) compares against the customer's
--- actual version.
---@param text string
---@return Lib.Case.StreamDocLink[]
function M.doc_links(text)
  local out = {}
  for url, version in text:gmatch("(docs%.tricentis%.com/tosca%-([%d%.]+)/[^%s%)%]\"'<>]*)") do
    out[#out + 1] = { url = "https://" .. url, version = version }
  end
  return out
end

--- `Case Task SWTASK0019690 state has been updated from Awaiting T1 to
--- Awaiting T2` — swarming/tier escalation (EXTRACTION.md §4.3).
---@class Lib.Case.EscalationHit
---@field task string
---@field from string
---@field to string
---@param text string
---@return Lib.Case.EscalationHit[]
function M.escalations(text)
  local out = {}
  for task, from, to in
    text:gmatch(
      "Case Task%s+(SWTASK%d+)%s+state has been updated from%s+([^\r\n]-)%s+to%s+([^\r\n]+)"
    )
  do
    out[#out + 1] = { task = task, from = vim.trim(from), to = vim.trim(to) }
  end
  return out
end

--- The trailing Stammdaten dump — the LAST `Field changes` block in a
--- stream, a flat run of `Label\nValue` pairs (`Description`'s value is
--- itself multi-line prose, everything else is one line). Scanned by
--- known label (`config.stream_stammdaten_labels`), not by block
--- position — same "config as data" extensibility as
--- `version_components`/`known_vendor_prefixes`, and it doesn't matter
--- that a couple of these labels (`Priority`/`Impact`) also appear
--- earlier in the file as `sla/stream.lua`'s own single-line fields:
--- those don't have a value line safely between two OTHER known labels,
--- so they don't get picked up as a false Stammdaten entry.
---@param text string
---@return table<string, string>
function M.stammdaten(text)
  local labels = {}
  for _, l in ipairs(config.stream_stammdaten_labels) do
    labels[l] = true
  end

  local ls = lines_of(text)
  local out = {}
  local i = 1
  while i <= #ls do
    local line = vim.trim(ls[i])
    if labels[line] then
      local value_lines = {}
      local j = i + 1
      while ls[j] and not labels[vim.trim(ls[j])] and vim.trim(ls[j]) ~= "Show less" do
        value_lines[#value_lines + 1] = ls[j]
        j = j + 1
      end
      while value_lines[1] and vim.trim(value_lines[1]) == "" do
        table.remove(value_lines, 1)
      end
      while value_lines[#value_lines] and vim.trim(value_lines[#value_lines]) == "" do
        table.remove(value_lines)
      end
      out[line] = table.concat(value_lines, "\n")
      i = j
    else
      i = i + 1
    end
  end
  return out
end

--- Completeness check (EXTRACTION.md §4, free with the header):
--- `<N>` / `<N> total activities.` at the top of the file must equal the
--- number of `Comment`/`Field changes`/`Work notes` type-label blocks —
--- a mismatch means the SNOW view wasn't fully expanded before copying
--- ("Show less"/"Show more" left collapsed), so the stream is incomplete.
---@param text string
---@return integer|nil declared
---@return integer actual
local function completeness_snow(text)
  local declared = tonumber(text:match("(%d+)%s*total activities%."))
  local actual = 0
  for line in text:gmatch("[^\r\n]+") do
    local trimmed = vim.trim(line)
    if trimmed == "Comment" or trimmed == "Field changes" or trimmed == "Work notes" then
      actual = actual + 1
    end
  end
  return declared, actual
end

--- SAP Resolve carries the same check in a sturdier place: every single
--- entry header repeats the total (`[3/19]`), so a truncated paste is
--- detectable even when the very first line got cut off — where SNOW's
--- one-and-only `<N> total activities.` header would have been lost with
--- it. The declared total is read from the LAST header seen rather than
--- the first for exactly that reason.
---@param text string
---@return integer|nil declared
---@return integer actual
local function completeness_saperesolve(text)
  local declared, actual = nil, 0
  for line in ((text or ""):gsub("\r", "")):gmatch("[^\n]+") do
    local h = stream_format.saperesolve_header(line)
    if h then
      actual = actual + 1
      declared = h.total
    end
  end
  return declared, actual
end

---@param text string
---@return integer|nil declared
---@return integer actual
function M.completeness(text)
  if stream_format.detect(text) == "saperesolve" then
    return completeness_saperesolve(text)
  end
  return completeness_snow(text)
end

--- Latest `Send to Customer, updates that transfer case ownership to the
--- customer` event — EXTRACTION.md §5's second finding: the one memo
--- type that unambiguously means "my reply is out, ball's with the
--- customer", the same signal `:Case reply check`'s manual "sent?" prompt
--- already sets `last_reply_sent` from (SLA.md §2). Same two-timestamp
--- shape every comment block has (`sla/stream.lua`'s own `parse_gmt`) —
--- GMT preferred over the local-time line above it. Not independently
--- validated against a real occurrence: this session's one real stream
--- doesn't use this exact memo type, only "Customer added a memo"/"SAP
--- added a memo for the partner"/"...for the customer, not visible to
--- the customer" — built to EXTRACTION.md §4's own documented wording.
---@param text string
---@return integer|nil epoch (UTC), the most recent occurrence
local function last_reply_sent_at_snow(text)
  local latest = nil
  local ls = lines_of(text)
  for i, line in ipairs(ls) do
    if
      vim.trim(line) == "Send to Customer, updates that transfer case ownership to the customer"
    then
      local at_line = ls[i + 1] and vim.trim(ls[i + 1]) or ""
      local gmt = at_line:match("^at:%s*(%d+%-%d+%-%d+ %d+:%d+:%d+)%s*GMT$")
      if gmt then
        local y, mo, d, h, mi, s = gmt:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
        local epoch = clock.utc_captures(y, mo, d, h, mi, s)
        if not latest or epoch > latest then
          latest = epoch
        end
      end
    end
  end
  return latest
end

--- `Returned Case to Customer` — SAP Resolve's own name for the exact same
--- event, and the same string `sla/stream.lua`'s `parse_saperesolve`
--- already maps to an "Awaiting User Info" transition. Unlike the SNOW
--- path this one IS validated against a real export (five occurrences in
--- the 19-entry sample, EXTRACTION.md §13), where SNOW's wording has never
--- yet turned up in real data.
---@param text string
---@return integer|nil epoch # the most recent occurrence
local function last_reply_sent_at_saperesolve(text)
  local latest = nil
  for line in ((text or ""):gsub("\r", "")):gmatch("[^\n]+") do
    local h = stream_format.saperesolve_header(line)
    if h and h.action == "Returned Case to Customer" and (not latest or h.at > latest) then
      latest = h.at
    end
  end
  return latest
end

---@param text string
---@return integer|nil epoch # the most recent occurrence
function M.last_reply_sent_at(text)
  if stream_format.detect(text) == "saperesolve" then
    return last_reply_sent_at_saperesolve(text)
  end
  return last_reply_sent_at_snow(text)
end

---@class Lib.Case.StreamSignals
---@field versions { server: string|nil, commander: string|nil }
---@field kbas Lib.Case.KbaHit[]
---@field attachments string[]
---@field error_codes string[]
---@field doc_links Lib.Case.StreamDocLink[]
---@field escalations Lib.Case.EscalationHit[]
---@field stammdaten table<string, string>
---@field declared_activities integer|nil
---@field actual_activities integer
---@field case_short string|nil  Stammdaten's `Number` (a full SNOW id) normalized via render.to_short.
---@field last_reply_sent_at integer|nil  See M.last_reply_sent_at above.

---@param text string
---@return Lib.Case.StreamSignals
function M.parse(text)
  text = text or ""
  local stammdaten = M.stammdaten(text)
  local declared, actual = M.completeness(text)
  return {
    versions = M.versions_in_text(text),
    kbas = M.kbas(text),
    attachments = M.attachments(text),
    error_codes = M.error_codes(text),
    doc_links = M.doc_links(text),
    escalations = M.escalations(text),
    stammdaten = stammdaten,
    declared_activities = declared,
    actual_activities = actual,
    case_short = stammdaten["Number"] and render.to_short(stammdaten["Number"]) or nil,
    last_reply_sent_at = M.last_reply_sent_at(text),
  }
end

return M
