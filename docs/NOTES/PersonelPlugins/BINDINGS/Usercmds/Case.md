# `:Case` / `:Cases` / `:Tricentis` — SAP-Support case scaffolding (casedesk)

Not a plugin's own command — casedesk lives in this config itself
(`lua/bindings/usrcmds/case/`), scaffolding and querying SAP-Support cases
for the Tricentis/Tosca support workflow. Listed here for the
config-internal index only; the full command reference, concept, and
day-to-day workflow already have their own doc set — not duplicated here:

- [Usercmds.md](../../../casedesk/Usercmds.md) — full command tables for `:Case`, `:Cases`, `:Tricentis`
- [Workflow.md](../../../casedesk/Workflow.md) — day-to-day use cases, worked examples
- [CONCEPT.md](../../../../ROADMAP/casedesk/CONCEPT.md) — module design, §8a–8i per-feature writeups
- [ROADMAP.md](../../../../ROADMAP/casedesk/ROADMAP.md) — what's still open

Three verbs, one line each:

- **`:Case`** — always resolves to exactly **one** case (explicit arg →
  current buffer → `kit.select`): `new`/`info`/`summary`/`notes`/
  `similar`/`timeline`/`ki`/`ki import`/`copy`/`sync`/`versions`/
  `doclinks`/`close`/`reassign`/`snow`/`sla`/`reply check`/…
- **`:Cases`** — the cross-case querschnitt: `list`/`close`/`find`/`grep`/
  `stale`/`sla`/`sla report`/`history`/`recent`/`stats`/`doctor`/
  `normalize`/`linkcheck`/`pickers`/`terminology`/`export`.
- **`:Tricentis`** — reaches across the whole work repo (`Notes/`,
  `Workflow/`, `Terminologie/`, `Tosca/`), not just `Cases/SAP_Support`.
