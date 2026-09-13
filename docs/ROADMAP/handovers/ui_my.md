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

**Nachgeholt 2026-09-14 (neue Session, Worktree `strange-shamir-7a4175`):**
der oben geplante Klick-Layer war nie committet — der Arbeitsbaum von
`busy-bassi-c01118` war beim Wiederaufnehmen bereits recycelt, alle fünf
geplanten Dateien nicht mehr auf der Platte. Neu gebaut nach genau dieser
Spezifikation — `clickable.lua`, `diagnostics_clickable`, `git_clickable`,
`variant`, Katalog + Doku, den `%`-Escape-Fix in `primitives.git()` gleich
mit —, nicht identisch im Code, gleichwertig im Verhalten, inklusive Tests.
Gepusht als `ui.nvim@73f36a4` + `ui.nvim@0551cb8`.

Zwei echte Lua/Neovim-Fallstricke beim Testen gefunden: `require()`
reduziert das Ergebnis eines Moduls immer auf einen Wert, egal wie viele das
Modul zurückgibt (die Klick-Id kann deshalb nicht über einen zweiten
`require()`-Rückgabewert an einen Test durchgereicht werden — geparst aus
dem gerenderten `%id@UiSlClick@...%X`-Text stattdessen); `vim.v.shell_error`
ist auch über `vim.api.nvim_set_vvar()` schreibgeschützt. Volle Suite grün
(217 Tests), `luacheck`/`stylua` clean. Details: `$REPOS_DIR/WKDBooks/
Development/wkdbook-myplugins/ui.nvim/handovers/ERLEDIGT/
statusline-click-layer.md`.

Bewusst nicht gemacht: keine Live-Verdrahtung in die persönliche Statusline
(alle drei Module bleiben `used_by = {}`, opt-in, wie `undo_depth`/
`search_count` vor ihrer eigenen Verdrahtungsrunde) und kein manueller
Maus-Klick-Test im echten Host (keine GUI in dieser Sandbox) — nur headless
verifiziert.

**Nebenbei entdeckt:** der `custom_menu`-Roadmap-Eintrag (die deklarative
Menu-Entry-API-Idee), am 2026-09-08 in dieser Datei dokumentiert und nach
`nvim-config@main` gepusht, ist im aktuellen `main` nicht mehr vorhanden —
vermutlich durch einen späteren Force-Push von `main` verloren gegangen
(erwartetes Risiko, siehe `nvim-config-main-gets-force-pushed`-Memory).
Nicht selbstständig wiederhergestellt, da unklar ist, ob das absichtlich
raus ist oder nur beim Force-Push mitgerissen wurde — beim Nutzer
nachgefragt.

**2026-09-14, direkt danach: Statusline-Vordergrund vereinheitlicht + vier
der elf Module (`ui.nvim@63bd747`…`240e890`).**

**Live-Feedback zwischendurch:** "Statusline-Schrift ist nicht durchgehend —
sollte alles weiß sein, außer der Mode-Chip." `St_gitIcons`/`St_LspMsg`/
`St_Lsp`/`St_cwd_icon`/`St_cwd_text`/`St_LspProgress` lasen eine gedimmte,
`"Comment"`-abgeleitete Farbe, während `St_file`/`St_pos_icon`/`St_pos_text`
die normale Vordergrundfarbe lasen — ohne inhaltlichen Grund unterschiedlich.
Vereinheitlicht; Mode-Chip und der `blocks`-Preset-Cursor-Chip unverändert
(sitzen auf einem gefüllten Akzent-Hintergrund, nicht der schlichten
Statusline-Fläche); Diagnostics-Farben (Error/Warning/Hint/Info) bewusst
nicht angefasst, die sind bedeutungstragend.

Der Reihe nach umgesetzt, wie unten gelistet:
1. `diagnostics_sparkline` — 20-Glyph-Dichte-Zeile, `cursor_ctl.renderer
   .pct_bar` dafür öffentlich gemacht statt dupliziert.
2. `macro_counter` — Live-Tastendruckzähler während Makro-Aufnahme, über
   `vim.on_key()` geklammert von `RecordingEnter`/`RecordingLeave`.
3. `time_in_buffer` — "12m" seit dem ersten `BufEnter` dieser Session,
   bewusst ohne die `sessions.nvim`-Cross-Session-Erweiterung.
4. `github_stats_badge` — "👁 42 diese Woche" fürs aktuelle Repo, nur
   sichtbar innerhalb eines getrackten Repos.

Zwei echte Bugs beim Bauen gefunden: `macro_counter`s erster Entwurf nutzte
`string.format`, dessen literales `%` aus `%#Group#` Lua selbst als
ungültige Format-Direktive las (auf Konkatenation umgestellt);
`github_stats_badge`s erster `owner/repo`-Regex schloss Punkte aus dem
Repo-Namen aus und kürzte deshalb jedes `*.nvim`-Repo dieses Ökosystems
("ui.nvim" → "ui") — vom eigenen Test gefunden.

**Ein Idee-Punkt hält der Realität nicht stand, noch nicht umgesetzt:**
"Recommender-Badge" beschreibt `recommender.nvim` als Perf-/Security-Scanner
mit einem `:RecommenderCheck`-Befehl — beides existiert im tatsächlichen
Repo nicht. `recommender.nvim` findet stattdessen wiederholte Dotted-Chains,
die sich als Alias lohnen würden (siehe dessen README). **Frage an den
Nutzer:** Idee auf die reale Funktion anpassen (Badge zeigt: "N
Alias-Vorschläge für diese Datei offen"), oder ganz streichen?

20 neue Tests seit der letzten Runde. Volle Suite grün (235 Tests),
`luacheck`/`stylua` clean. Details: `$REPOS_DIR/WKDBooks/Development/
wkdbook-myplugins/ui.nvim/NOTES.md`s achtzehnte Runde.

---

## Offene Tasks

Aus der Statusline-Ideen-Auswahl noch offen, jeweils als eigener
Umsetzungsschritt:
- Recommender-Badge — **blockiert auf die Nutzerantwort oben** (Idee passt
  nicht zur realen Plugin-Funktion)
- GitHub-Stats-Ticker — ~~erledigt~~ siehe oben (`github_stats_badge`)
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
