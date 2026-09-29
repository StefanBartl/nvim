# Handover: UX-Backlog über mehrere .nvim-Plugins (2026-09-29)

## Kontext

Stefan hat eine Liste loser UX-/Bug-Notizen zu mehreren eigenen `.nvim`-Plugins
gesammelt (Chips/Toasts, filetree, lsp completion, pickers/replacer preview,
runtime-analysis reminder, `:MyPlugins reclone`, statusline progress). Diese
Datei ist der aufgeräumte, gegen den aktuellen Code verifizierte Task-Katalog
und wird als laufendes Fortschritts-Log geführt, während die Tasks
nacheinander (max. 1 Agent gleichzeitig, ein Task nach dem anderen)
abgearbeitet werden.

Betroffene Repos liegen alle unter `$REPOS_DIR/repos` (`E:\repos\...`):
`lib.nvim`, `ui.nvim`, `filetree.nvim`, `lsp.nvim`, `pickers.nvim`,
`replacer.nvim`, `runtime-analysis.nvim`, `gitsuite.nvim`. `:MyPlugins
reclone` liegt in der Config selbst (`$NVIM_CONFIG/lua/bindings/usrcmds/...`).

## Guiding Rules für diese Abarbeitung

- 1 Agent gleichzeitig, sequenziell.
- Code englisch, Chat/Commits/Docs-Prosa deutsch, kein Claude-Co-Autor.
- luacheck/stylua muss grün sein; neue Features wenn möglich im
  plugin-eigenen `/TESTS/`-Ordner testen.
- Wo sinnvoll `lib.nvim` verwenden (Wartbarkeit).
- Docs/README je Plugin aktualisieren, wenn inhaltlich sinnvoll; Bindings
  zusätzlich in `$NVIM_CONFIG/docs/NOTES/BINDINGS` pflegen.
- Reports/Handover-Originale -> `$NVIM_CONFIG/docs` (diese Datei), Backlog/
  Feature-Notizen -> `WKDBooks/Development/wkdbook-myplugins/**` (Symlinks
  von dort auf Originale hier, nicht umgekehrt).
- Nach jedem fertigen Task: sofort commit + push im jeweiligen Repo (main).

## Task-Katalog (Ist-Zustand bereits gegen Code verifiziert am 2026-09-29)

Reihenfolge = Abarbeitungsreihenfolge (klein/klar -> groß/konzeptionell).

### [ ] T8 — `:MyPlugins reclone`: Popup-Prompt mit Summary
- **Ist:** Bereits umgesetzt (23.09.), läuft über `ui.kit.confirm` async
  statt `getcharstr()`. Datei: `bindings/usrcmds/plugin_repos/init.lua`
  (`reclone_all`, `finish_reclone`, Aufruf `confirm.yesno(...)` ~Zeile 765).
- **Aufgabe:** Nur verifizieren, ob der Summary-Text vor Ja/Nein inhaltlich
  ausreicht (Anzahl/Namen der betroffenen Plugins sichtbar). Kein Neubau.
- **Aufwand:** XS

### [ ] T7 — runtime-analysis.nvim: 7-Tage-Reminder als Popup + :messages
- **Ist:** Läuft bereits über eine `lib.nvim.notify`-Instanz (nicht rohes
  `vim.notify`), gebatcht via `vim.schedule`. Dateien:
  `telemetry/reminder.lua` (Defaults/Message), `telemetry/init.lua`
  (`flush_reminders`, `notify.info(...)`).
- **Aufgabe:** Verifizieren, ob dadurch schon Chip + `:messages` ankommt;
  falls kein Popup-Channel benutzt wird, auf `lib.nvim.output`-Facade mit
  `channel="popup"` umstellen.
- **Aufwand:** S

### [ ] T3 — lsp.nvim: keine Autocompletion bei `---` in Markdown
- **Ist:** Diagnostiziert, Konzept im WKDBooks-Backlog fertig, nicht
  umgesetzt. Ursache: blink.cmp-Variante der "Plugin-Namen"-Source
  (`lsp/completion/personal_names/init.lua`) hat keinen Keyword-Filter
  (nur die alte nvim-cmp-Variante nutzte `keyword_pattern`); `-` ist kein
  Keyword-Zeichen -> bei `---` leerer Kontext -> volle Liste erscheint.
- **Aufgabe:** `enabled()`-Callback oder `min_keyword_length`-Guard in
  `lsp/pack/completion_blink.lua:86` einbauen, gegen Markdown-Separator/
  Frontmatter testen.
- **Aufwand:** S

### [ ] T6 — replacer.nvim: Preview-Scroll + Legende + Cheatsheet nachziehen
- **Ist:** Existiert bereits vollständig in `pickers.nvim`
  (`preview_scroll_up/down/left/right`-Actions, `<C-/>`-Cheatsheet mit
  Legende aller aktiven Keymaps in `pickers/cheatsheet/init.lua`).
  `replacer.nvim` hat eine eigene `pickers/common.lua` und bindet das nicht
  ein.
- **Aufgabe:** replacer.nvim an vorhandene pickers.nvim-Features anschließen
  statt neu bauen; danach kurz prüfen, welche anderen Picker-Nutzer das noch
  brauchen ("gilt für alle").
- **Aufwand:** S

### [ ] T2 — filetree.nvim: blinkendes "unsaved changes"-Icon
- **Ist:** Kein eigenes Icon, natives Neo-tree-Marker-Feature
  (`enable_modified_markers`). Blinking beim Collapse bereits bekannt,
  über `redraw_soon()`/Debounce in `adapter/neotree.lua` teilweise
  gemildert; laut Code-Kommentar von filetree aus nicht vollständig
  eliminierbar (Neo-tree eigene Redraw-Zyklen). Regressionstest existiert:
  `TESTS/neotree_collapse_redraw_coalesce.lua`.
- **Aufgabe:** Prüfen, ob es einen zusätzlichen Neo-tree-Upstream-Hook gibt;
  sonst als dokumentierte Grenze schließen ("won't fix, bereits gemildert").
- **Aufwand:** S

### [ ] T9 — Statusline-Progress: Hover-Live-State + zentraler Popup-Befehl
- **Ist:** Zentrales Modul existiert schon (`ui.statusline` +
  `lib.nvim.progress.styles.statusline`-Registry) — jedes Plugin mit
  `progress_style = "statusline"` taucht automatisch auf. Hover-Tooltip
  existiert (`ui/statusline/hover.lua`, MouseMove-getriggert), zeigt einen
  `summary`-Text aus dem Catalog — unklar ob live oder statisch.
- **Aufgabe:** Sicherstellen, dass `summary` den echten Live-State zeigt
  (nicht nur eine statische Beschreibung); zusätzlich Befehl
  `:Ui statusline showProgress` ergänzen, der dieselbe Registry als Popup
  auflistet (ohne Hover nötig).
- **Aufwand:** M

### [ ] T4 — lib.nvim output: Chip + ":messages"-Duplikat / Hit-Enter-Prompt
- **Ist:** `config.messages = true` ist bereits Default (Chip UND
  `:messages` laufen parallel, das ist gewollt). Vermutetes eigentliches
  Problem: `nvim_echo(..., true, {})` in `write_messages` (popup.lua
  ~158-201) löst bei mehrzeiligen/mehreren Messages den "Press ENTER"-Prompt
  aus (Beispiel: Gitsuite-Dashboard-Pull zeigt Chip UND Hit-Enter).
- **Aufgabe:** `write_messages`-Verhalten analysieren, Hit-Enter-Trigger
  vermeiden (z.B. `:messages`-Schreiben ohne mehrfaches `nvim_echo` mit
  `history=true` in einem Rutsch), Default beibehalten aber Hit-Enter-frei
  machen, konfigurierbar lassen, an Gitsuite-Fall verifizieren.
- **Aufwand:** M

### [ ] T5 — Chip-Konzept: Titel/Kurztext + automatische Fehler-Erkennung
- **Ist:** Existiert noch nicht. `opts.title` überschreibt bereits den
  Default-Titel (popup.lua:81), aber kein Truncation/"..."-Konzept für
  lange Inhalte, keine automatische Titel/Inhalt-Trennung für rohe,
  nicht-Plugin-Meldungen (z.B. native nvim-Fehler wie `E354`, mehrzeilige
  Git-Fehler).
- **Aufgabe:** Konzept ausarbeiten (Titel + abgeschnittener Text im Chip,
  volle Message weiter in `:messages`/noice), Heuristik für Titel/Error-vs-
  Info-Erkennung bei rohen nvim-Messages (ggf. an `noice.nvim` orientieren),
  danach umsetzen in `popup.lua`. Sauber von T4 abgrenzen.
- **Aufwand:** L

### [ ] T1 — Einheitliches Chip/Toast/UI-Theme-System
- **Ist:** Existiert nicht, ist reine Neu-Konzeption.
- **Aufgabe:** Presets für Chips/Toasts/UIs plugin-übergreifend
  vereinheitlichen (Naming + Styles) in `ui.kit`/`lib.nvim`, inkl. zweier
  Stilrichtungen: "rounded" und "ascii/omarchy/hacker-style". Geht über
  reines Colorscheme-Theming hinaus (ganze UIs gestaltbar).
- **Aufwand:** XL — eigener Konzept-Vorlauf empfohlen (Naming-Konvention,
  welche Plugins/UIs zuerst), bevor implementiert wird. Wird zuletzt
  angegangen bzw. ggf. in eigenem Handover fortgeführt.

## Fortschritt / Log

_(wird pro Task ergänzt: Datum, was gemacht wurde, Commit-Hash + Repo)_
