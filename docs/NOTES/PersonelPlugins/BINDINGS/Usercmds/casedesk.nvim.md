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

- `casedesk.nvim/docs/commands.md` — every route with its exact arguments,
  **generated** from the route tree, so it cannot drift from behaviour
- `casedesk.nvim/CHEATSHEET.md` — the hand-written tour: what each verb is for
- `casedesk.nvim/docs/BINDINGS.md` — commands, keymaps, autocommands
- `casedesk.nvim/docs/CONCEPT.md` — module design, §8a–8i per-feature writeups
- `casedesk.nvim/docs/ROADMAP.md` — what's still open

This file is renamed from `Case.md` so that its stem matches the repository
name. `:Bindings drift` pairs a cheatsheet with a checkout by that stem, and
`Case` matched no repository.

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
