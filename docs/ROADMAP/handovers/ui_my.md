# ui.nvim / my.nvim
## Notes

Roadmap und Handover files findest du hier:
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/ui.nvim`
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/my.nvim`

- never start more than 1 agents simultaneously; if more are needed, run multiple rounds of up to 1 agents each
- antwortet immer auf Deutsch; im Quellcode (Code und Kommentare usw.) immer Englisch verwenden
- Die Installations-Specs meiner Pluigns findest du in: vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua
- Gib immer aus was du gerade machst / ob es interessante unde gab - damit ich Bescheuid weiß.
- Docs / ../README-New/README.md des Plugins updaten sofern es Sinn macht
- Keine Co-Authorenschaft von Claude in den Commits
- Wenn du mit etwas fertig bist committe / pushe / pulle so dass das uupdate sofort im main branch, sodass ich es gleich verwenden kann.
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOL-PLACEMENT.md` (Tool bauen vs. Wegwerf-Skript, wohin damit)
- Beachte `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` (keine großen/escapehaltigen Literale durch die Shell)
- code der implementiert wurde muss luacheck / stylua grün sein

---

## Handover Notes

**2026-09-13/14, ui.nvim-Session (Worktree `busy-bassi-c01118`), gestoppt auf
Nutzeranfrage mitten in der Umsetzung:**

Bereits fertig, getestet, direkt nach `origin/main` gepusht (Commits
`cd58c8d`, `f8c7757`, `f0b5795`):
- **Deferred-Close-Bug** (`ui.tabline.utils.close_buffer`/`close_all_bufs`):
  der `vim.defer_fn`-Callback war nicht `pcall`'d, ein ungültig gewordener
  Buffer konnte unabgefangen aus dem Timer-Callback werfen. Gefixt + Test.
- **"1 ohne Icon"-Bug**: sechs Icon-Glyphen in
  `ui.statusline.utils.primitives` (Git added/changed/removed/branch,
  LSP-Error/Warning, LSP-Client-Label) waren komplett verschwunden (bloße
  ASCII-Leerzeichen statt Glyph) — Byte-für-Byte-Vergleich mit
  `nvchad/stl/utils.lua` bestätigt, wiederhergestellt als `\xEE`/`\xEF`-Escapes.
- **Tabline-Style-Preset-System**: `ui.tabline.styles` (Registry, analog zu
  `ui.config.variants`) + `:UI tabline-style`/`:UI tabline-styles`, volle
  Laufzeit-Parität zur Statusline-Variantenauswahl.

**Statusline-Ideen-Sichtung**: alle offenen Punkte aus `IDEEN-statusline.md`
durchgegangen, Nutzer hat 16 von ~18 zur Umsetzung ausgewählt — explizit
**als eigenständige, opt-in Preset-Module**, nicht in Shipped-Defaults oder
die persönliche Config verdrahtet (wie `undo_depth`/`search_count` schon).
Vereinbarte Reihenfolge: Klick-Layer zuerst, dann alles Klickbare darauf.

**Gerade in Arbeit, NICHT committed/gepusht, Session hier gestoppt:**
Plan approved (`structured-waddling-newt.md`), Dateien bereits geschrieben,
aber Tests/Full-Suite-Lauf/Commit noch offen:
- `lua/ui/statusline/utils/clickable.lua` (neu) — generischer Klick-Layer
  fürs Statusline-Äquivalent zu `ui.tabline.utils`'
  `btn`/`register_click_handlers`, `%N@UiSlClick@...%X`-Protokoll, Registry
  nach Integer-Id, `wrap(segment_fn, handlers)`.
- `lua/ui/statusline/modules/diagnostics_clickable/init.lua` (neu) —
  Linksklick → `vim.diagnostic.goto_next()`.
- `lua/ui/statusline/modules/git_clickable/init.lua` (neu) — Linksklick:
  dependency-freier Branch-Switcher (`git branch`/`checkout` per
  `vim.fn.systemlist`/`vim.ui.select`); Rechtsklick: `lib.nvim.contextmenu`
  mit "Branch wechseln"/"Branch-Name kopieren"/"Details" — deckt zugleich
  die "Rechtsklick-Segment-Optionen"-Idee als Referenzbeispiel ab.
- `lua/ui/statusline/modules/variant/init.lua` (neu) — noch nie
  existierendes Segment, zeigt aktive Statusline-Variante, Linksklick öffnet
  Quick-Switch-Menü über `ui.config.variants.list()` + `:UI variant`.
- `lua/ui/statusline/utils/primitives.lua`: Branch-Name in `M.git()` jetzt
  `%`-escaped (Fund beim Bauen des Klick-Layers: derselbe Bug-Typ wie schon
  bei `ui.tabline.utils.stl_escape`, aber bislang nirgends für Statusline
  gefixt).
- `lua/ui/statusline/catalog.lua`, `docs/modules.md`: 3 neue Katalog-Einträge
  + neue "Clickable modules"-Doku-Sektion.
- `TESTS/statusline_clickable_spec.lua` (neu, noch nicht laufen gelassen).

**Nächster Schritt bei Wiederaufnahme:** `luacheck`/`stylua` (bereits grün
laut letztem Check), dann volle Suite (`bash scripts/test.sh`), dann
manueller Headless-Check, dann commit + Push nach `main` — wie im
gespeicherten Plan (`structured-waddling-newt.md`) unter "Verification"
beschrieben.

---

## Offene Tasks

Aus der Statusline-Ideen-Auswahl, nach dem Klick-Layer (s.o.) noch offen,
jeweils als eigener Umsetzungsschritt (nicht in dieser Session begonnen):
- Diagnostics-Sparkline
- Makro-Tastendruck-Zähler
- Zeit in dieser Datei (seit `BufEnter`)
- Recommender-Badge
- GitHub-Stats-Ticker
- Runtime-Analysis-Ampel
- Casedesk-SLA-Countdown
- Filetree-Verlaufspunkte
- Idle-Erweiterung (nach N Sekunden Inaktivität)
- Seit-letztem-Save-Indikator
- Adaptive Segmentauswahl nach Fensterbreite (Design bereits geklärt:
  pro-Fenster via `nvim_win_get_width(vim.g.statusline_winid)`, Mechanismus
  über ein generisches `essential`-Tag im Statusline-Katalog statt
  parallelen `order_compact`-Listen pro Preset)

Aus der ursprünglichen Roadmap, noch nicht angegangen:
- Rechtsklick-Menü nach ui.nvim migrieren (bewusst ganz zum Schluss, 30
  Repos hängen dran)
- rules.nvim-Pass über ui.nvim (nachrangig zu my.nvim)
- Kreuzfeature-Check gegen die ~30 Schwesterplugins

---
