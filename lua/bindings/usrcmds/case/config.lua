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
