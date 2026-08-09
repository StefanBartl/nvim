---@module 'bindings.usrcmds.case.config'
--- All the policy knobs for the `:Case` scaffolder: where cases live, how
--- the SNOW ticket number is derived, and the default blueprint. Everything
--- else in this module reads from here rather than hardcoding paths.

local templates = require("bindings.usrcmds.case.templates")

local M = {}

--- The whole work knowledge repo. `Cases/` is only one of its areas —
--- `Workflow/`, `Notes/`, `Terminologie/`, `Tosca/` are siblings, and
--- features that reach outside the case tree (the reply-block library
--- below) anchor here rather than walking up from `M.root`.
M.repo_root = "C:/repos/WKDBook-Tricentis"

M.root = M.repo_root .. "/Cases/SAP_Support"

--- The reply-block library `:Case template` offers: real, hand-written
--- snippets (RequestMoreInfo, CloseCase, GermanSpeaker, …) kept as markdown
--- in the work repo, NOT casedesk's own scaffolding templates — those live
--- next to `templates.lua` and are a different thing entirely.
M.workflow_templates_dir = M.repo_root .. "/Workflow/Templates"

--- Files under `workflow_templates_dir` that are not reply blocks: the
--- Summary scaffold (and its filled-in reference copy) belong to
--- `Summary.md`'s own blueprint node, offering them as a snippet to paste
--- into a reply would just be noise.
M.workflow_template_excludes = { "SummaryTemplate.md", "SummaryTemplateBefüllt.md" }

--- Every case lives at `<cases_root>/<state>/<short-number>` — a case's
--- state IS which of these three folders it's in, not a stored field (see
--- docs/ROADMAP/casedesk/MIGRATION.md §1 for why: a value kept in two
--- places drifts, and this bestand already has one scar from exactly that
--- — a folder renamed without the note pointing at it being updated).
M.cases_root = M.root .. "/Cases"

--- `default_state` is where :Case new creates and what "case is open" means
--- for `resolve.pick`'s kit.select fallback. `state_verbs` names the
--- generated `:Case <verb> [nr]` move-command for every OTHER state (falls
--- back to the lowercased state name if a state has no entry here) — see
--- init.lua's state-verb generation loop, the same "add a line, get a
--- command for free" pattern as the file-verbs.
M.states = { "Open", "Closed", "Reassigned" }
M.default_state = "Open"
M.state_verbs = {
  Closed = "close",
  Reassigned = "reassign",
}

---@param state string
---@return string
function M.state_dir(state)
  return M.cases_root .. "/" .. state
end

M.meta_filename = ".case.json"

--- Plausibility range for a short case number (render.is_plausible_case_number).
--- Deliberately generous rather than pinned to one exact width: seen so far
--- is 6 digits (977392), but the real thing this guards against isn't "not
--- exactly 6" — it's empty/near-empty input slipping past `:Case new`'s
--- prompt and being used as a folder name. An unvalidated case number used
--- to be able to land as `config.cases_root .. "/Open/" .. ""`, i.e. the
--- blueprint's files (Replies/, Research/, Summary.md, ...) getting created
--- DIRECTLY inside `Cases/Open/` itself — every other case's parent folder.
M.case_number_min_digits = 4
M.case_number_max_digits = 8

--- Gap (minutes) between two file touches before `:Case timeline` starts a
--- new work session — long enough that a coffee break within one sitting
--- doesn't split it, short enough that yesterday afternoon and today
--- morning don't merge into one.
M.timeline_session_gap_minutes = 120

--- The real SNOW ticket id is `SAP0000` + short-number + 4-digit year,
--- concatenated with no separator (e.g. "SAP00009405612026"). Never stored
--- — always derived from `case` + `year` via render.to_short/to_snow.
M.snow_prefix = "SAP0000"

--- Fill in your ServiceNow instance base URL to enable `:Case snow`, e.g.
--- "https://yourinstance.service-now.com/nav_to.do?uri=incident.do?sys_id=".
--- Left nil: `:Case snow` copies the ticket number to the clipboard instead
--- of guessing a URL that would just 404.
---@type string|nil
M.snow_url_format = nil

--- `# {case} - `{title}` - {filename}` — the mandated H1 for every markdown
--- file a blueprint node creates. filename is the node's basename without
--- extension (e.g. "Research/00_Research.md" -> "00_Research").
M.headline_format = "# %s - `%s` - %s"

--- Every entry here is, for free: a `:Cases <field> [pattern]` filter route
--- (init.lua's filter-route generation) and — the ones `ui.lua`'s
--- `infocard_lines`/`edit_info` also hand-list — an infocard row and
--- `kit.form` edit field. `case` is deliberately excluded — filtering "case
--- number contains X" is what CASE-argtype completion already does.
M.infocard_fields = { "title", "company", "name", "notes", "priority", "tosca_version" }

-- ── SLA (docs/ROADMAP/casedesk/SLA.md) ──────────────────────────────────
-- Source: C:/repos/WKDBook-Tricentis/Workflow/SLA_ServiceLevelAgreement.md
-- — these are SAP's SLAs TOWARDS Tricentis, not necessarily a given SolEx
-- customer's own contract (see that file's own warning). Never surface
-- these numbers to a customer as binding.

--- `:Case sla --doc` opens this.
M.sla_doc_path = M.repo_root .. "/Workflow/SLA_ServiceLevelAgreement.md"

local HOUR = 3600
local DAY = 24 * HOUR
local WEEK = 7 * DAY

--- 08:00-18:00 CET, Mon-Fri (`os.date("*t").wday`: 1=Sun..7=Sat).
---@type Lib.Case.SlaWindow
M.sla_business_hours = { from = 8, to = 18, days = { 2, 3, 4, 5, 6 } }

local BUSINESS_DAY = (M.sla_business_hours.to - M.sla_business_hours.from) * HOUR -- 10h

---@class Lib.Case.SlaLevel
---@field label string
---@field window Lib.Case.SlaWindow|"24x7"        used for Erstreaktion + Rückmeldung
---@field first_response integer                  seconds
---@field cadence integer[]                        [ohne Produktfehler, mit Produktfehler]; [1] used until that signal exists (SLA.md §9.3)
---@field fix integer                              seconds
---@field fix_window Lib.Case.SlaWindow|"24x7"     Korrekturmaßnahme has its own unit per level (Std./Arbeitstage/Kalenderwochen) — see below

--- `fix_window` is a judgment call, not a literal reading of the source
--- table: "Max. 4 Std." (P1) and "6 Kalenderwochen" (P3/P4) are plainly
--- wall-clock, so `fix_window = "24x7"` even though P3/P4's OWN window is
--- 10x5. "Max. 3 Arbeitstage" (P2) is the one that reads as business days,
--- so `fix_window = M.sla_business_hours` even though P2's own window is
--- 24x7. Flagged, not hidden: SLA.md's open questions list this.
---@type table<string, Lib.Case.SlaLevel>
M.sla = {
  ["1"] = {
    label = "Very High",
    window = "24x7",
    first_response = 1 * HOUR,
    cadence = { 1 * HOUR },
    fix = 4 * HOUR,
    fix_window = "24x7",
  },
  ["2"] = {
    label = "High",
    window = "24x7",
    first_response = 2 * HOUR,
    cadence = { 6 * HOUR },
    fix = 3 * BUSINESS_DAY,
    fix_window = M.sla_business_hours,
  },
  ["3"] = {
    label = "Medium",
    window = M.sla_business_hours,
    first_response = 4 * HOUR,
    cadence = { 3 * DAY, 14 * DAY },
    fix = 6 * WEEK,
    fix_window = "24x7",
  },
  ["4"] = {
    label = "Low",
    window = M.sla_business_hours,
    first_response = 1 * BUSINESS_DAY,
    cadence = { 7 * DAY, 21 * DAY },
    fix = 6 * WEEK,
    fix_window = "24x7",
  },
}

--- Fraction of a clock's budget remaining below which `:Case sla`/the
--- statusline badge treat it as urgent (also true for negative, i.e.
--- already overdue).
M.sla_warn_at = 0.25

--- Priorities the statusline badge AND the active notifications below
--- (SLA.md §6C) fire for. P3/P4 have week-plus budgets — a badge/warning
--- for those would be near-permanent noise, not a signal.
M.sla_active_priorities = { "1", "2" }

--- SLA.md §6C Paket 4: push notifications on top of the passive statusline
--- badge, for `sla_active_priorities` only. One notification per (case,
--- clock, deadline) — `sla/notify.lua` never repeats it for the same
--- breach, but re-arms once a clock resets to a fresh period (e.g. cadence
--- after a customer reply changes the deadline). Off entirely: set false.
M.sla_notifications_enabled = true

--- How often the background timer re-checks every open, active-priority
--- case, in seconds. A `FocusGained` autocmd checks immediately on top of
--- this — "im Auge behalten" shouldn't need to wait out a stale interval
--- right when you sit back down. 15 min is deliberately loose: this is a
--- safety net for "case sat untouched", not a live countdown (the
--- statusline badge already covers that while the buffer is focused).
M.sla_notify_interval_seconds = 900

--- `:Cases stale`'s per-priority idle threshold, in days (SLA.md §6C:
--- "für einen P2 sind 7 Tage absurd spät, für einen P4 normal"). Tuned by
--- hand, NOT a formula off `M.sla`'s cadence budgets — P1's 1h cadence
--- would produce an unusably low number that way. `M.stale_days_default`
--- covers a case with no parseable priority yet, same flat 7 the command
--- always used.
---@type table<string, integer>
M.sla_stale_days = {
  ["1"] = 1,
  ["2"] = 2,
  ["3"] = 5,
  ["4"] = 10,
}
M.stale_days_default = 7

M.default_blueprint = "default"

--- Company name (as stored in `.case.json`) -> a key in `M.blueprints`,
--- consulted by `:Case new` before falling back to `default_blueprint`
--- (ROADMAP.md v7). Empty by construction — no company needs a different
--- scaffold yet, so this changes nothing until a case actually asks for
--- one: add a `M.blueprints.<name>` table plus a line here, no code.
---@type table<string, string>
M.company_blueprints = {}

---@type table<string, Lib.Case.BlueprintNode[]>
M.blueprints = {
  default = {
    { type = "dir", path = "Replies" },
    { type = "dir", path = "Research" },
    { type = "dir", path = "Ressources" },

    -- Summary.md is the ServiceNow-facing document and reproduces
    -- `Workflow/Templates/SummaryTemplate.md` verbatim — hence
    -- `headline = false`: the real template starts straight at
    -- "╓ Problem statement", and prepending casedesk's own H1 would mean
    -- deleting it again before every paste into SNOW.
    { type = "file", path = "Summary.md", key = "summary", headline = false, template = templates.SUMMARY },
    -- Notes.md is the private counterpart: what was tried, what a coach
    -- said, tasks out of a meeting. Keeps Summary.md free of anything that
    -- isn't meant for the customer-facing ticket (CONCEPT.md §8a).
    { type = "file", path = "Notes.md", key = "notes", template = templates.NOTES },
    { type = "file", path = "Research/00_Research.md", key = "research", open = true, template = templates.RESEARCH },
    { type = "file", path = "Replies/00_PSO.md", key = "reply", template = templates.REPLY },
  },
}

return M
