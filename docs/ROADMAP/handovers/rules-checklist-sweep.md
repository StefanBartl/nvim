# Handover — RULES.md Checklist-Familien-Sweep

Fortlaufende Arbeit an
[`docs/ROADMAP/personal/All/FINISH/RULES.md`](../personal/All/FINISH/RULES.md):
die 9 Regel-Familien aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`
(`PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) werden Familie für Familie
gegen alle 32 Personal-Plugin-Repos geprüft. `RULES.md` selbst ist die
laufende Quelle der Wahrheit für den Stand — diese Datei ist nur der
Einstiegspunkt für eine neue Session.

## Stand bei Übergabe (2026-09-07, achte Aktualisierung — UI-* läuft)

| Familie | Status |
|---|---|
| `LLS-*` (34) | ✅ fertig |
| `SEC-*` (23) | ✅ fertig |
| `DEP-*` (7) | ✅ fertig |
| `TS-*` (5) | ✅ fertig |
| `ERR-*` (34) | ✅ fertig — 32/32 Repos, 17 echte Bugs gefixt |
| `UI-*` (34) | 🔶 **in Arbeit** — 5/34 Regeln (`UI-57`..`61`) bereits fleet-weit fertig, 19/32 Repos für den Rest (29 Regeln) vollständig gelesen, 13/32 nur Completion-Batch-Check, 0 echte Bugs bisher |
| `PRIN-*` (37) | ⬜ offen |
| `LUA-*` (45) | ⬜ offen |
| `PERF-*` (57) | ⬜ offen |

## UI-* — Stand im Detail

**Wichtig zuerst lesen:** `UI-57`..`UI-61` (Checkhealth-Konventionen) sind
bereits komplett fertig, unabhängig von dieser Datei — ein separater Audit
lief am 2026-08-31/2026-09-06 über alle ~35 `health.lua`-Module. Quelle:
[`ERLEDIGT/checkhealt_conventions.md`](../personal/All/FINISH/ERLEDIGT/checkhealt_conventions.md).
**Nicht erneut prüfen.** Für diesen Durchlauf bleiben **29 Regeln**
(`UI-01`..`04`, `UI-20`..`37`, `UI-50`..`56`) über alle 32 Repos.

**Vollständig gelesen (19/32), 0 echte Bugs:** buffer-ctx.nvim,
cascade.nvim, casedesk.nvim, cmdlog.nvim, color_my_ascii.nvim, dap.nvim,
debugging.nvim, diff.nvim, documentation.nvim, emojis.nvim, fileops.nvim,
filetree.nvim, github_stats.nvim, gopath.nvim, hover.nvim, images.nvim,
insights.nvim, language.nvim, lib.nvim.

**Nur Completion-Lücken durchsucht, voller Regelsatz noch offen (13/32):**
lsp.nvim, markdown.nvim, mdview.nvim, open.nvim, pdfport.nvim,
pickers.nvim, recommender.nvim, replacer.nvim, reposcope.nvim,
runtime-analysis.nvim, sandbox.nvim, sessions.nvim, spotlight.nvim.
Zusätzlich schon per Stichprobe geprüft (aber nicht vollständig): pdfport
(`UI-50`..`56`, strukturell kaum anwendbar — zustandsloser Float),
sandbox.nvim (`UI-51`, andere aber gültige Umsetzung via
`open_named_scratch`), reposcope.nvim (`UI-51`/`54`, hat echtes
`ui_state`-Modul mit `capture_invocation_state()`/`reset()`).

**Fleet-weite mechanische Checks (alle 32 Repos), 0 Funde:**
- `UI-31` (modul-globale Fenster-Registry statt `vim.w[win].custom_tag`) —
  kein einziges Repo hat das beschriebene Anti-Pattern.
- `UI-55` (Buffer mit sichtbaren Fenstern löschen ohne Umleitung) — alle 5
  Repos mit `nvim_buf_delete`-Aufrufen einzeln geprüft, jede löscht nur
  einen Buffer, der ausschließlich im eigenen frisch erzeugten Fenster lebt.
- `UI-22`-Stichprobe (verdächtige Argumentnamen wie `mode`/`scope`/`target`
  ohne `enum`/`values`) — keine echten Treffer, nur plausibler Freitext.

**Einzige Beobachtung (nicht gefixt):** `cascade.nvim`/fleet-weit über
`lib.nvim.bindings.keymap.which_key` — Gruppen-Label hängt am deklarierten
`spec.prefix`, nicht an den nach Nutzer-Remapping tatsächlich aufgelösten
`lhs`-Werten (`UI-27`). Kein demonstrierbarer Bug: which-key zeigt jede
Zuordnung ohnehin über ihr eigenes `desc` an, ein remapptes Item verliert
nur die Submenü-Gruppierung, keine Funktion. Kosmetisch, fleet-weit über
`lib.nvim` geteilt — bewusst nicht angefasst.

## Kalibrierung: Bug vs. Feature-Lücke (wichtig für den Rest der Familie!)

`UI-36` (Quickfix-Export für Trefferlisten) fehlt laut Katalog-Beleg selbst
in fast dem GANZEN Fleet — nur replacer.nvim hat es. Das händisch
nachzurüsten wäre Feature-Entwicklung über 30 Repos, kein Bugfix.
**Nicht pro Repo einzeln (er)finden oder vermerken** — bereits in RULES.md
festgehalten. Ähnlich zurückhaltend behandeln: `UI-28`/`UI-33` (reine
UX-Empfehlungen, nur fixen wenn ein Repo aktiv falsch statt nur suboptimal
handelt). Nur echte, demonstrierbare Defekte fixen (fehlende Completion für
eine geschlossene Menge, Notify-Level-Widerspruch, konkreter
Fensterhandling-Bug) — exakt dieselbe Kalibrierung wie bei `ERR-*`.

## Nächster Schritt

Zwei Optionen, beide sinnvoll:

1. **UI-* zu Ende bringen**: die 13 Batch-Check-Repos noch gegen den vollen
   29-Regel-Satz lesen, mit Fokus auf `UI-50`..`56` (Fenster/Buffer-UI) bei
   den Repos mit eigenen Floats (pdfport, pickers, reposcope, sandbox,
   spotlight sind schon teilweise angefasst — pickers.nvim und
   spotlight.nvim noch komplett offen für diese Regeln).
2. **Nächste Familie anfangen** (`PRIN-*`, 37 Regeln) und `UI-*` später zu
   Ende bringen — beide Familien sind unabhängig voneinander, kein
   Blocker.

Keine feste Vorgabe. Gegeben, wie konsistent sauber das Fleet bei `UI-*`
bisher war (0 echte Bugs in 19 volltändig + 13 teilweise gelesenen Repos,
0 Funde in allen drei fleet-weiten Mechanik-Checks), ist die Erwartung für
den Rest ähnlich niedrig — aber das ist eine Erwartung, keine Abkürzung.

## Standing Rules für diese Arbeit

- Antworten deutsch, Code/Kommentare englisch.
- Docs/README des jeweiligen Plugins mitpflegen, wenn ein echter Fund
  gefixt wird.
- Sofort auf `main` committen/pushen, sobald etwas in einem Repo gefixt
  wurde — nicht sammeln.
- Kein Claude-Co-Autor in Commit-Messages (weder in diesem Repo (nvim-config)
  noch in den einzelnen Plugin-Repos) — siehe Claudes Memory
  `no-coauthor-commits`.
- Diese Handover-Datei bei jedem weiteren Fortschritt aktualisieren, nicht
  nur einmalig anlegen.
- **1 Agent gleichzeitig, mehrere Runden zu je 1**, falls ein Subagent
  gebraucht wird — direktes Lesen in der Unterhaltung ist der Normalfall.
