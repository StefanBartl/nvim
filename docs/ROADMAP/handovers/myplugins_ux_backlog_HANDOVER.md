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

### [x] T8 — `:MyPlugins reclone`: Popup-Prompt mit Summary
- **Ist:** Bereits umgesetzt (23.09.), läuft über `ui.kit.confirm` async
  statt `getcharstr()`. Datei: `bindings/usrcmds/plugin_repos/init.lua`
  (`reclone_all`, `finish_reclone`, Aufruf `confirm.yesno(...)` ~Zeile 765).
- **Aufgabe:** Nur verifizieren, ob der Summary-Text vor Ja/Nein inhaltlich
  ausreicht (Anzahl/Namen der betroffenen Plugins sichtbar). Kein Neubau.
- **Aufwand:** XS

### [x] T7 — runtime-analysis.nvim: 7-Tage-Reminder als Popup + :messages
- **Ist:** Läuft bereits über eine `lib.nvim.notify`-Instanz (nicht rohes
  `vim.notify`), gebatcht via `vim.schedule`. Dateien:
  `telemetry/reminder.lua` (Defaults/Message), `telemetry/init.lua`
  (`flush_reminders`, `notify.info(...)`).
- **Aufgabe:** Verifizieren, ob dadurch schon Chip + `:messages` ankommt;
  falls kein Popup-Channel benutzt wird, auf `lib.nvim.output`-Facade mit
  `channel="popup"` umstellen.
- **Aufwand:** S

### [x] T3 — lsp.nvim: keine Autocompletion bei `---` in Markdown
- **Ist:** Diagnostiziert, Konzept im WKDBooks-Backlog fertig, nicht
  umgesetzt. Ursache: blink.cmp-Variante der "Plugin-Namen"-Source
  (`lsp/completion/personal_names/init.lua`) hat keinen Keyword-Filter
  (nur die alte nvim-cmp-Variante nutzte `keyword_pattern`); `-` ist kein
  Keyword-Zeichen -> bei `---` leerer Kontext -> volle Liste erscheint.
- **Aufgabe:** `enabled()`-Callback oder `min_keyword_length`-Guard in
  `lsp/pack/completion_blink.lua:86` einbauen, gegen Markdown-Separator/
  Frontmatter testen.
- **Aufwand:** S

### [x] T6 — replacer.nvim: Preview-Scroll + Legende + Cheatsheet nachziehen
- **Korrigierter Ist-Zustand (nach Deep-Dive, ursprüngliche Annahme war
  falsch):** replacer.nvim rendert sein Picker-UI gar nicht über
  `pickers.nvim` — das dreigeteilte UI (Resultatsliste/Prompt/Preview), das
  der User beschreibt, ist **fzf-lua** (Default-Engine, da installiert;
  `pickers.refine` wird nur als optionales Filter-Modul mitbenutzt, nicht
  als UI). Beide Engines bringen die gewünschten Features bereits nativ mit:
  fzf-lua `<S-Up>/<S-Down>` (Preview Page), `<M-S-Up>/<M-S-Down>` (Preview
  Zeile), `<F3>` (Preview-Wrap toggeln — löst "lange URLs abgeschnitten"
  eleganter als horizontales Scrollen), `<F1>` (volles Keymap-Cheatsheet,
  ersetzt genau den gewünschten `C-?`-Legend-Popup). Telescope:
  `<C-u>/<C-d>` (Preview vertikal), `<C-f>/<C-k>` (Preview horizontal —
  existiert dort sogar schon nativ). Nichts davon war dokumentiert.
- **Aufgabe (umgesetzt):** Statt Neubau nur Doku ergänzt
  (`docs/BINDINGS.md`, neuer Abschnitt "Preview navigation"), inkl. eines
  gefundenen Nebenbefunds: `keymaps.filter` (Default `<C-f>`) überschreibt
  auf beiden Engines eine vorhandene Standard-Bindung (Telescope:
  `preview_scrolling_left`; fzf-lua: `ctrl-f`/`half-page-down` auf der
  Liste) — dokumentiert als bekannter Caveat, nicht verändert.
- **Aufwand:** ursprünglich auf S geschätzt (Neubau angenommen); tatsächlich
  nur Doku, da Engine-Feature bereits vorhanden war.

### [x] T2 — filetree.nvim: blinkendes "unsaved changes"-Icon
- **Ist:** Kein eigenes Icon, natives Neo-tree-Marker-Feature
  (`enable_modified_markers`). Blinking beim Collapse bereits bekannt,
  über `redraw_soon()`/Debounce in `adapter/neotree.lua` teilweise
  gemildert; laut Code-Kommentar von filetree aus nicht vollständig
  eliminierbar (Neo-tree eigene Redraw-Zyklen). Regressionstest existiert:
  `TESTS/neotree_collapse_redraw_coalesce.lua`.
- **Aufgabe:** Prüfen, ob es einen zusätzlichen Neo-tree-Upstream-Hook gibt;
  sonst als dokumentierte Grenze schließen ("won't fix, bereits gemildert").
- **Aufwand:** S

### [x] T9 — Statusline-Progress: Hover-Live-State + zentraler Popup-Befehl
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

### [x] T4 — lib.nvim output: Chip + ":messages"-Duplikat / Hit-Enter-Prompt
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

### [x, teilweise — Rest technisch nicht möglich] T5 — Chip-Konzept: Titel/Kurztext + automatische Fehler-Erkennung
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

- **2026-09-29, T8:** Verifiziert, kein Codeänderungsbedarf. Summary-Text vor
  Ja/Nein in `finish_reclone` zeigt bereits Anzahl + alle Repo-Namen + Basis-
  Ordner (`bindings/usrcmds/plugin_repos/init.lua:759-765`). Kein Commit.
- **2026-09-29, T7:** Verifiziert, kein Codeänderungsbedarf. Globaler
  `require("lib.nvim.notify").setup({ popup = true })` in
  `lua/plugins/personal/init.lua:52` (nvim-config) schaltet für **alle**
  `lib.nvim.notify`-Consumer (~30 Plugins, inkl. runtime-analysis.nvim's
  Telemetry-Reminder) automatisch Chip + `:messages` frei. Kein Commit.
- **2026-09-29, T3:** Umgesetzt. `min_keyword_length = 1` für den
  `personal_names`-Provider in `lsp.nvim` ergänzt (blockt den leeren
  Keyword-Kontext, den blink.cmp nach reinen Satzzeichen wie `---` sieht).
  Commits: `lsp.nvim@79b5714` (fix), `WKDBooks@79bc69e` (Backlog-Eintrag
  auf "umgesetzt" aktualisiert). `md_words` hat denselben Root Cause,
  wurde bewusst nicht mit angefasst (kein Teil der gemeldeten Beschwerde) —
  als Beobachtungspunkt vermerkt, falls es dort auch auffällt.
- **2026-09-29, T4:** Tief geprüft (`lib.nvim/lua/lib/nvim/notify/popup.lua`,
  `write_messages`) — **echter Blocker, keine Umsetzung ohne Rückfrage.**
  `nvim_echo(..., true, {})` ist laut Nvims eigener API (gegen 0.12
  verifiziert, `api.txt` gelesen) die EINZIGE Möglichkeit, eine Message in
  `:messages`-History aufzunehmen, und sie ECHOT dabei zwangsläufig kurz
  sichtbar — es gibt kein `opts`-Feld, das das unterdrückt (`verbose`
  steuert nur Log-Datei-Ausgabe, nicht das). Git-History des Moduls zeigt
  bereits zwei gescheiterte frühere Versuche (`:silent! echomsg` — silenced
  nichts; `vim.ui_attach` — hing bei offenem Float) — das aktuelle
  `nvim_echo` + `vim.o.more = false` ist bereits der dritte, beste bekannte
  Kompromiss (verhindert wenigstens den blockierenden "Press ENTER"-Prompt,
  der kurze Flash bleibt aber). `gitsuite.util.notify` (das Pull-Beispiel
  des Users) ist nur ein plain `lib.nvim.notify.create("[gitsuite]")` ohne
  Sonderfall — kein separater Doppel-Notify-Bug am Call-Site, sondern
  derselbe globale Mechanismus wie überall.
  **Echte Entscheidung, keine Bugfix-Frage:** entweder (a) den kurzen Flash
  als Nvim-Limitation akzeptieren (Status quo), oder (b) `messages` global
  auf `false` umstellen und stattdessen `:Lib notify history` (eigene,
  bereits vorhandene History-Ansicht) als "voller Text"-Ziel bewerben —
  das würde aber echte `:messages`/`noice.nvim`-Kompatibilität aufgeben,
  die der User explizit erwähnt hat. Betrifft ~30 Plugins global
  (`lua/plugins/personal/init.lua:43-52`).
  **Entscheidung des Users: Option (b).** `config.messages` Default in
  `lib.nvim/lua/lib/nvim/notify/popup.lua` von `true` auf `false`
  umgestellt — Chip bleibt, aber es landet nichts mehr automatisch in
  echten `:messages`; `:Lib notify history`/`:Lib notify last` (liest
  weiterhin unconditional die eigene History) ist jetzt die Anlaufstelle
  für den vollen Text. Pro Call/Notifier/global weiterhin mit
  `messages = true` reaktivierbar (z.B. für einen expliziten
  noice.nvim-Anwendungsfall). Vier bestehende Tests im lib.nvim-Testsuite
  gingen implizit vom alten Default aus (gefunden durch vollen Testlauf,
  nicht nur Lesen) und wurden korrigiert, plus neue Tests für den neuen
  Default ergänzt — komplette Suite (alle Module, nicht nur notify) läuft
  grün. README + Code-Kommentare aktualisiert. **Breaking Change** für
  jeden Call-Site, der sich bisher auf den impliziten Default verlassen
  hat, um wirklich in `:messages` zu landen — laut Repo-Suche verlässt
  sich aktuell kein anderes Plugin-Testsuite darauf. Commits:
  `lib.nvim@27d8251`, `nvim-config@73961182` (Kommentar-Korrektur).
- **2026-09-29, T5:** Titel+Truncation-Teil umgesetzt: ohne explizites
  `opts.title` wird jetzt die erste Zeile einer mehrzeiligen Message zum
  Toast-Titel (z.B. `"[gitsuite] docmap-desktop: push failed"` statt
  `"[gitsuite] error"`), der Rest (git-Hinweiszeilen) wandert in den Body;
  bereits vorhandenes `wrap()` schneidet weiterhin ab und verweist auf
  `:Lib notify last`. Guard gegen einen echten gefundenen Bug beim ersten
  Anlauf: eine riesige einzeilige Message plus `deliver()`s eigener
  `entry_max_bytes`-Kürzungsmarker ("\n... (truncated)") sah für die
  Split-Logik ebenfalls wie "hat eine erste Zeile" aus — durch vollen
  Testlauf (nicht nur Lesen) gefunden und mit einer Zeilenlängen-Schwelle
  gefixt; neue Regressionstests dafür ergänzt. Commit: `lib.nvim@53db016`.
  **Automatische Error-vs-Info-Erkennung für ECHTE, nicht von einem Plugin
  kommende Nvim-Fehler (das `E354`-Beispiel) ist technisch nicht umsetzbar**
  — native `:echoerr`/Message-Subsystem-Ausgaben laufen nie durch
  `vim.notify` oder irgendeinen von Lua aus erreichbaren Hook; nur ein
  vollständiges `ext_messages`-UI (das, was `noice.nvim` tatsächlich tut)
  könnte das abfangen — das wäre kein Feature-Zusatz mehr, sondern im
  Kern ein eigenes noice.nvim nachbauen. `ui.notify` (ui.nvim, aktuell in
  dieser Config NICHT aktiviert) fängt zwar `vim.notify`-Aufrufe von
  Drittplugins ab, aber eben nicht echte Nvim-interne Fehler. Bewusst nicht
  umgesetzt statt eine Scheinlösung zu bauen.
- **2026-09-29, T6:** Ursprüngliche Annahme (Feature existiert in
  pickers.nvim, muss nur eingehängt werden) war falsch — replacer.nvim
  nutzt fzf-lua/Telescope als eigentliches Picker-UI, nicht pickers.nvim.
  Beide Engines hatten die gewünschten Features (Preview-Scroll,
  Wrap-Toggle, Cheatsheet) bereits nativ, nur undokumentiert. Nur Doku
  ergänzt, kein Verhalten geändert. Commit: `replacer.nvim@27fc1e2`.
- **2026-09-29, T2:** Geprüft, ob es einen bislang ungenutzten Neo-tree-
  Hook gibt, der den Rest-Blink abfangen könnte — es gibt keinen
  (`defaults.lua` hat kein Debounce/Throttle-Setting für
  `opened_buffers_changed`, das direkt und synchron auf jedem
  `VIM_BUFFER_MODIFIED_SET`/`VIM_BUFFER_ADDED`/`VIM_BUFFER_DELETED`-Event
  redrawt). Bereits vorhandene Doku in filetree.nvim war schon korrekt und
  vollständig. Geschlossen als bestätigte, dokumentierte Grenze — kein
  Commit. Eine größere Alternative (eigene Icon-Rendering-Pipeline statt
  Neo-trees nativer Marker) wäre möglich, aber XL-Aufwand und nicht Teil
  dieses Durchgangs.
- **2026-09-29, T9:** Umgesetzt. `ui.statusline.catalog`-Einträge können
  jetzt ein optionales `live()` deklarieren; `ui.statusline.hover` zeigt
  dessen Text statt der statischen `summary`, solange er nicht leer ist
  (`plugin_progress` an `lib.nvim.progress.styles.statusline` angebunden).
  Neuer Befehl `:UI progress` (Namensgebung an bestehende `:UI`-Konvention
  angepasst, nicht `:Ui statusline showProgress` wie ursprünglich
  vorgeschlagen — das Präfix und der Subcommand-Stil sind in `ui.nvim`
  bereits einheitlich `:UI <subcommand>`) zeigt dieselbe Registry als
  Popup, ohne Hover/Maus. 10 + 4 neue Tests (`statusline_catalog_spec.lua`,
  `statusline_hover_menu_spec.lua`), alle grün; luacheck/stylua grün.
  Commit: `ui.nvim@9f1e792`.
