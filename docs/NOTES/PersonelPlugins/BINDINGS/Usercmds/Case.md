# `:Case` / `:Cases` / `:Tricentis` — SAP-Support case scaffolding (casedesk)

casedesk moved out of this config on 2026-09-04 and is now the
[`casedesk.nvim`](https://github.com/StefanBartl/casedesk.nvim) plugin
(`lua/casedesk/`), scaffolding and querying SAP-Support cases for the
Tricentis/Tosca support workflow. The old tree under
`lua/bindings/usrcmds/case/` is still on disk but frozen and not loaded —
see `docs/ROADMAP/casedesk/PLUGIN.md`. Listed here because the commands are
part of the day-to-day binding surface either way; the full command
reference, concept, and workflow have their own doc set — not duplicated
here:

- [Usercmds.md](../../../casedesk/Usercmds.md) — full command tables for `:Case`, `:Cases`, `:Tricentis`
- [Workflow.md](../../../casedesk/Workflow.md) — day-to-day use cases, worked examples
- [CONCEPT.md](../../../../ROADMAP/casedesk/CONCEPT.md) — module design, §8a–8i per-feature writeups
- [ROADMAP.md](../../../../ROADMAP/casedesk/ROADMAP.md) — what's still open

Three verbs, one line each:

- **`:Case`** — always resolves to exactly **one** case (explicit arg →
  current buffer → `kit.select`): `new`/`info`/`summary`/`notes`/
  `similar`/`timeline`/`ki`/`ki import`/`ocr`/`copy`/`sync`/`versions`/
  `doclinks`/`close`/`reassign`/`snow`/`sla`/`reply check`/…
- **`:Cases`** — the cross-case querschnitt: `list`/`close`/`find`/`grep`/
  `stale`/`sla`/`sla report`/`history`/`recent`/`stats`/`doctor`/
  `normalize`/`linkcheck`/`pickers`/`terminology`/`export`.
- **`:Tricentis`** — reaches across the whole work repo (`Notes/`,
  `Workflow/`, `Terminologie/`, `Tosca/`), not just `Cases/SAP_Support`.
