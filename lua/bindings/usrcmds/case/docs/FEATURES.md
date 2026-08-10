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

## KI-Faktenblock + Widerspruchsprüfung (EXTRACTION.md Paket 5 — letztes Paket)

Konzept: [EXTRACTION.md](../../../../../docs/ROADMAP/casedesk/EXTRACTION.md)
§7, §12 (Paket 5, steht seit 2026-08-10 — mit diesem Paket ist
Artefakt-Extraktion komplett fertig, alle 5 Pakete).

- **`extract/facts.lua`** rendert das "Ermittelte Fakten"-Markdown-Block
  aus §7s Worked Example — reiner Aggregator, kein neues Parsing:
  liest aus `extract.supportinfo` (TBox-Build/Api-Core/Custom-DLLs),
  `extract.stream`/`sla.stream` (aktueller SNOW-Zustand, Impact,
  Awaiting-User-Info-Historie), `sla` (Clock-Status), `extract.doclinks`
  (Versions-Tally der zitierten Doku-Links), und `.case.json` selbst
  (Priorität, SAP Component, Versionen). Gegen drei echte Cases
  verifiziert (977392, 1041708, 996010) — kombiniert dabei automatisch
  Funde aus Paket 1/2/3 (996010s Custom-DLL, 1041708s
  Doku-Link-Mismatch, 977392s Impact) an einer Stelle, ohne Absturz bei
  fehlenden Daten.
- **`{facts}`-Token** in `templates/KiPrompt.md`, gefüllt von `ui.lua`s
  `M.ki` — landet vor der eigentlichen Analyse-Aufgabe im Prompt, mit
  der Anweisung, den Fakten nicht zu widersprechen.
- **Widerspruchsprüfung in `:Case ki import`** (§7 Richtung 2): scannt
  die importierte Solution/Reply-Sektion nach `docs.tricentis.com`-Links
  und warnt sofort, wenn einer auf eine andere Version zeigt als der
  Kunde tatsächlich fährt — die zweite Verteidigungslinie neben dem
  Prompt-Wächter selbst.
- **Teilweise gebaut**: §7 Richtung 3 (zitierte Doku-Links als
  Referenzsammlung mit Zitat/Kontext) steckt nur als
  Versions-Aggregat im Faktenblock (`extract.doclinks.all_links`) — eine
  echte Zitat-mit-Kontext-Sammlung pro Link (Textauszüge um jeden Fund)
  ist ein eigenständig größeres Stück, nicht gebaut.

## Korrekturmaßnahme-Pause + auto `last_reply_sent` (EXTRACTION.md Paket 4)

Konzept: [EXTRACTION.md](../../../../../docs/ROADMAP/casedesk/EXTRACTION.md)
§5, §12, and [SLA.md](../../../../../docs/ROADMAP/casedesk/SLA.md)'s
second Nachtrag to §3 (Paket 4, steht seit 2026-08-10 — letztes offenes
Stück von Artefakt-Extraktion, außer Paket 5).

- **`sla/init.lua`'s `fix` clock now extends for Awaiting-User-Info time**
  — deliberately a PAUSE (deadline + budget both grow by the paused
  duration), not the `cadence` clock's RESET, since `fix` is a one-time
  cumulative deadline: resetting it on every customer reply would give
  effectively unlimited budget across a multi-round exchange. New
  `total_awaiting_seconds(states, now)` sums every `Awaiting User Info`
  interval from the full state history (an ongoing one counts to `now`).
  Isolated test (no real stream with a real Awaiting-User-Info history in
  the bestand): 2h paused → a P1's 4h budget becomes 6h; unpaused stays
  exactly 4h.
- **`:Case activity` auto-detects `last_reply_sent`** from a stream's
  "Send to Customer, updates that transfer case ownership to the
  customer" memo — the same field `:Case reply check`'s manual "sent?"
  prompt sets. Only ever advances it, never regresses a newer manual
  stamp with an older stream-detected one.
- Both pieces are built to EXTRACTION.md §5's documented wording but not
  independently re-verified against a real occurrence — the one real
  stream in the bestand uses neither an Awaiting-User-Info cycle nor a
  "Send to Customer" memo.

## `:Case doclinks` (EXTRACTION.md Paket 3)

Konzept: [EXTRACTION.md](../../../../../docs/ROADMAP/casedesk/EXTRACTION.md)
§6, §12 (Paket 3, steht seit 2026-08-10). `extract/doclinks.lua` compares
every `docs.tricentis.com/tosca-<version>/` link found in a case (Activity
Streams + Replies) against the customer's actual Tosca version — a live
doc link on the wrong product version is worse than a dead one, because
the customer follows it.

- **Three-tier version resolution**, most reliable first: `.case.json`'s
  `tosca_version` (hand-confirmed) → the support-info header
  (`detect.tosca_version`) → the newest Activity Stream's Commander
  version (`extract.stream`, prose, last resort).
- **Both Tosca version shapes normalized to the doc-link's own form**
  (`<4-digit-year>.<minor>`) before comparing — `25.1.7` and `2026.1` both
  need to become `2025.1`/`2026.1`, since a doc URL never carries a patch
  digit. Comparing raw strings would flag every case as a false mismatch.
- **Real find, not just the worked example**: case 1041708 runs `25.1.2`
  per its own support-info; a reply in that same case links `tosca-2026.1`
  — exactly the class of mistake EXTRACTION.md §6 was written to catch,
  present in the actual bestand.
- **`:Case doclinks [nr]`** stands alone AND is folded into `:Case reply
  check`'s report (EXTRACTION.md §11 Q5 — decided "both, not either/or").

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
