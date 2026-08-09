# casedesk — Features

`:Case` / `:Cases` / `:Tricentis` — SAP-Support case scaffolding for the
Tricentis/Tosca support workflow. Full command tables:
[Usercmds.md](../../../../../docs/NOTES/casedesk/Usercmds.md), worked
examples: [Workflow.md](../../../../../docs/NOTES/casedesk/Workflow.md),
module design: [CONCEPT.md](../../../../../docs/ROADMAP/casedesk/CONCEPT.md).
This file tracks features finished after the initial build that don't
warrant their own CONCEPT.md §-entry — currently just the session-startup
comfort layer below.

Module: `lua/bindings/usrcmds/case/`.

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
