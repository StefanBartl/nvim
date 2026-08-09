# casedesk — Features

`:Case` / `:Cases` / `:Tricentis` — SAP-Support case scaffolding for the
Tricentis/Tosca support workflow. Full command tables:
[Usercmds.md](../../../../../docs/NOTES/casedesk/Usercmds.md), worked
examples: [Workflow.md](../../../../../docs/NOTES/casedesk/Workflow.md),
module design: [CONCEPT.md](../../../../../docs/ROADMAP/casedesk/CONCEPT.md).
This file tracks features finished after the initial build — the smaller
ones that don't warrant their own CONCEPT.md §-entry; `:Case(s) close`
below got a full CONCEPT.md write-up (state model, extended there) and is
listed here only as a pointer.

Module: `lua/bindings/usrcmds/case/`.

## `:Case(s) close` destination picker + marking system

Was ROADMAP.md's `:Case(s) close & mark system` entry (removed from
ROADMAP.md now that this is built). Full design: CONCEPT.md's §3 (state
model), command tables: [Usercmds.md](../../../../../docs/NOTES/casedesk/Usercmds.md),
keymaps: [Keymaps.md](../../../../../docs/NOTES/casedesk/Keymaps.md), day-
to-day use: [Workflow.md](../../../../../docs/NOTES/casedesk/Workflow.md)
§3. One-paragraph summary:

- **`:Case close [nr]`** no longer assumes "Closed" — it opens a
  `kit.select` over every other state plus a "Delete permanently" sentinel
  (`ui.lua`'s `pick_close_target`). Deleting requires typing the case
  number back, not a plain y/n — the one irreversible action in this
  module.
- **`:Cases close`** is the bulk version: uses whatever's currently marked
  (see below), or falls back to `kit.select({multi = true})`'s native
  `<Tab>`-toggle/`<CR>`-confirm chooser — no `pickers.nvim` dependency
  needed, `kit.select` already had this. One destination picked once,
  applied to every selected case (`close_many`); bulk delete types
  `DELETE` instead of each case's own number.
- **`marks.lua`** — a flat, session-global set of case numbers (not
  buffer-local). `:Cases list` doubles as the mark view: `m` toggles the
  case under the cursor, a Visual-line range + `m` toggles the whole range,
  `c` runs `:Cases close` on the result. Marks persist after that view
  closes, so marking and closing don't have to happen in one sitting.

## Case-Session-Kurzstart (SESSIONS.md Paket 2)

Konzept: [SESSIONS.md](../../../../../docs/ROADMAP/casedesk/SESSIONS.md) §4,
§10 (Paket 2, steht seit 2026-08-09). Baut auf Paket 1 (`<leader>cs`,
Auto-Save bei `:Case new`, s. [Keymaps.md](../../../../../docs/NOTES/casedesk/Keymaps.md))
auf — Paket 2 macht den Wiedereinstieg selbst bequem:

- **`autoload = true`** in `plugins/personal/init.lua`s `sessions.nvim`-Spec.
  Bloßes `nvim` ohne Dateiargumente lädt automatisch die zuletzt geladene
  Session — für "einfach weitermachen, wo ich aufgehört habe" reicht das.
- **PowerShell-`case`-Funktion**, außerhalb dieses Repos im DOTFILES-Repo
  (`Configs/Windows/DOTFILES/WindowsPowerShell/
  Microsoft.PowerShell_profile.ps1`, Region 8): `case 1007631` springt
  gezielt in die gespeicherte Session eines *anderen* Cases als dem zuletzt
  aktiven (`nvim -c "Session load 1007631"` unquotiert per Shell-Wrapper).
  Ohne Nummer: normales `nvim` (greift dann `autoload`).

Offen bleibt nur noch Paket 3 (Sicherheitsnetz gegen verwaiste Sessions
geschlossener Cases über einen neuen `:Cases doctor`-Fund-Typ) — s.
[ROADMAP.md](../../../../../docs/ROADMAP/casedesk/ROADMAP.md).
