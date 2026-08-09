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

## `:Case versions` (EXTRACTION.md Paket 1)

Konzept: [EXTRACTION.md](../../../../../docs/ROADMAP/casedesk/EXTRACTION.md)
§2, §3, §12 (Paket 1, steht seit 2026-08-10). `extract/supportinfo.lua`
parses `Ressources/ToscaSupportInfo*.txt` — validated against all four
real support-info files EXTRACTION.md's own analysis is based on, not just
the design doc's mockups: the digest correctly finds the one real
customer-added DLL (`Achmea_Tosca_Custom_Controls.dll`) in the one case
that has it, and zero false positives across the other three.

- **Digest, not the 1600-line list** (`:Case versions [nr]`) — Testsuite/
  TBox build/Api Core/Install-Root, plus "Auffällig": TBox-root `.dll`/
  `.exe` entries not matching `config.known_vendor_prefixes`. That
  filter list was built by extracting every real filename from a real
  TBox root, not guessed — same "extend the config, not the parser"
  shape as `version_components`.
- **`:Case versions <component>`** copies a version straight to the
  clipboard — resolves via `config.version_components` (curated friendly
  names) first, then falls back to a case-insensitive substring over
  every filename in the report, so anything in the file is reachable even
  without a table entry.
- **`--all`** lists everything, grouped by directory; **`--raw`** opens
  the file itself.
- **`server` component**: falls back to the newest Activity Stream's
  "Tosca Server - v…" prose (EXTRACTION.md §11 Q3, resolved with
  Paket 2) — works even when the case has no support-info file at all
  (confirmed for real: case 977392).

## Stream signals: `extract/stream.lua` (EXTRACTION.md Paket 2)

Konzept: [EXTRACTION.md](../../../../../docs/ROADMAP/casedesk/EXTRACTION.md)
§4, §12 (Paket 2, steht seit 2026-08-10). A second, independent pass over
`Research/NN_ActivityStream.md` — `sla/stream.lua` stays narrow (only
what the three SLA clocks need), this reads everything else. Validated
against the one real stream in the bestand (case 977392): server/commander
versions, KBA numbers, attachment names, and the full Stammdaten block
all matched EXTRACTION.md's own documented examples exactly. Two real
bugs were caught and fixed in the process (see Usercmds.md's Notes) —
attachments separated by blank lines rather than terminated by the first
one, and an error-code pattern loose enough to flag a real SAP field
value (`HEC_ABAP`) as a false positive.

- **`:Case activity`** now auto-detects `sap_component` and
  `versions.server`/`versions.commander` into `.case.json`, same "no
  manual step" pattern Priority already used (SLA.md §6A).
- **`:Case versions server`** — see above.
- **`:Cases doctor`**'s new `stream-incomplete` finding: an Activity
  Stream's declared `"<N> total activities."` header not matching its
  actual block count means the SNOW view wasn't fully expanded before
  copying. Report-only (no rename fixes missing content) — the fix is
  re-pasting from SNOW.
- **Built but not independently re-validated against a real hit** this
  session (none of the available data contains one): `error_codes`
  (`TRICENTIS_ERROR_...`-shaped tokens), `doc_links` in-stream (the
  pattern itself IS validated, just against other case files, not a
  stream), `escalations` (`SWTASK...` tier changes).
- **Not built**: writing `custom_dlls` to `.case.json` (Paket 1's digest
  computes it live but doesn't persist it), state-history duplication
  (already lives in `sla/stream.lua`, not re-parsed here on purpose).

## Active SLA notifications + KI-prompt context (SLA.md Paket 4, last one)

Konzept: [SLA.md](../../../../../docs/ROADMAP/casedesk/SLA.md) §6C, §6E,
§10 (Paket 4, steht seit 2026-08-10 — mit diesem Paket ist SLA-Überwachung
komplett fertig, kein ROADMAP.md-Eintrag mehr).

- **`sla/notify.lua`** — Timer (`config.sla_notify_interval_seconds`,
  Default 15 min) + `FocusGained`-Autocmd prüfen jeden offenen
  `sla_active_priorities`-Case gegen `sla_warn_at` und warnen je Bruch
  genau einmal (Dedup-Key `short|label|deadline`) — auf dem bestehenden
  Statusline-Badge oben drauf, das nur hilft, solange der Case-Buffer
  fokussiert ist. Ein Zustandswechsel, der `deadline` ändert (z. B.
  Rückmeldung-Reset nach Kundenantwort), bewaffnet die Warnung automatisch
  neu — kein separater Reset-Schritt. `config.sla_notifications_enabled
  = false` schaltet alles ab.
- **SLA-Kontext im KI-Prompt** — neuer `{sla}`-Token (kein Unterstrich,
  `templates.lua`s `%{(%w+)%}` matcht keinen) in `templates/KiPrompt.md`,
  gefüllt von `ui.lua`s `sla_context_line` (`ki.lua`s `M.build_prompt`
  reicht ihn nur durch). Eine Zeile Priorität + dringlichste Frist, damit
  das Modell seine Antwort danach skaliert (Aktionsplan bei Stunden,
  ausführlichere Lösung bei Wochen).
- **Wordings-Baustein „laufende Rückmeldung"** — neues
  `Workflow/Templates/Wordings/OngoingUpdate.md` im Arbeits-Repo (drei
  Varianten: ohne neue Info, mit Zwischenschritt, mit Engineering-
  Eskalation), taucht in `:Case template` ohne Codeänderung auf
  (CONCEPT.md §8b).

## `:Cases sla report [--year N]` (SLA.md Paket 3)

Konzept: [SLA.md](../../../../../docs/ROADMAP/casedesk/SLA.md) §6D, §10
(Paket 3, steht seit 2026-08-10 — letztes offenes Stück war nur der Report
selbst, `last_reply_sent` kam schon mit Paket 1). Retrospektiv über **jeden**
Zustand, nicht nur offene Cases wie `:Cases sla`s Dashboard (SLA.md §9 Q5):
Quote erfüllter Erstreaktionsfristen je Priorität, für beide Anker
("ab Ticket-Eingang"/"ab Zuweisung", §9.1 weiterhin offen) getrennt.
Ausreißer namentlich mit Delta (`clock.format_duration`). Ein Case ohne
`last_reply_sent`-Stempel zählt nicht als verpasst — er fällt aus der Quote
raus und wird separat als "ohne last_reply_sent" gezählt, sonst würde ein
schlicht nicht nachgetragener Wert die Zahl schlechter aussehen lassen als
sie ist. Ehrlichkeitsklausel steht als zweite Zeile im Report selbst, nicht
nur in der Doku.

`query.lua`s `sla_report(year)` sammelt (kein `--year` = alle Jahre, Filter
auf `.case.json`s `year`-Feld), `ui.lua`s `M.cases_sla_report` gruppiert und
rendert — kein eigenes `sla/render.lua` wie ursprünglich skizziert, gleicher
Datensammlung/Rendering-Split wie jeder andere `:Cases`-Befehl.

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

**Paket 3 (2026-08-10, letztes Paket — Session-pro-Case ist damit fertig):**
`:Cases doctor`s neuer `stale-session`-Fund-Typ — meldet eine gespeicherte
Session zu einem Case, der nicht mehr offen ist (der aktive Lösch-Hook in
`:Case(s) close`/`reassign` deckt nur Umzüge ab, die durch diese Commands
laufen; ein vor Paket 1 geschlossener Case, oder ein von Hand verschobener
Ordner, hinterlässt eine Session, die niemand mehr braucht). `:Cases
normalize` räumt sie weg — der erste Fund-Typ, der `doctor.lua`s neues
`action`-Feld statt `to` nutzt (ein `fun(): ok, err` für "kein Rename",
hier `sessions.delete(name)`). Details: CONCEPT.md §10.
