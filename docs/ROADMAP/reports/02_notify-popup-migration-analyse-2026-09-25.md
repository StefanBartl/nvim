# Analyse: Umstellung aller .nvim-Repos auf `lib.nvim.notify.popup` (Runde 1)

Stand: 2026-09-25 · Status: **nur Analyse, noch nichts umgestellt** · Scanner:
`lib.nvim.dev.notify_scan` (`:LibNotifyScan`, Commit `17afe44`)

## feedback von mir

`print()` und `nvim_echo()` werden angemerkt, dass  lib.nvm dazu nichts hat. Die frage,ist, wie können wir das mitmachen? vor allem nvim_echo() sehe ich ja als moderne Variante an.

1. Sollten wir ein lib modul mahen, mit dem man dann print, notify und ercho auswöhlen kann, also swas wie `write_back({ "notify"?, "print"?, "echo"? }, ...)`, auch mit kosntrukto, usw.. Oder für jede eine eigene anbeiten? Gäbes es synergy effekte? wäre es möglixh eine funkltnioanzu bieten, und diese wählt dann die korrekte aus? bzw print wäre schwer, aber zwsichen otify und excho kännte man heurotsisch untescheiden dneke ich - aber wäre das einge gute idee oder nicht?
2. [echo progress](./03_notify_echo_progress.md) -> mitdneken, visuell für die statusline

Bevor wir alles umstellen, möchte ich das klären, das ghört aufgearbeitet.

## 1. Kurzfassung

- 37 Repos gescannt (ohne `lib.nvim`, `ui.nvim`; `reposcope.nvim` ist die Referenzumsetzung).
- **Der Großteil nutzt bereits `lib.nvim.notify`** (345 Erzeugungsstellen in ~30 Repos).
  Nur 79 Stellen rufen `vim.notify` direkt auf, 10 `nvim_echo`, 69 `print(`, 7 binden
  `vim.notify` bei Modulload.
- **Größter Hebel: ein globaler Schalter in lib.nvim** statt Repo-für-Repo-Umbau
  (siehe Abschnitt 3). Damit sind die ~30 lib-Nutzer ohne eine Zeile Änderung in den
  Plugins umgestellt; die Installations-Spec setzt ihn einmal.
- Direkt anfassen muss man nur ~12 Repos mit eigenem `vim.notify`-Wrapper (Abschnitt 4)
  und 3 Repos mit Load-Time-Bindung (Abschnitt 5).
- `print(` (69) sind überwiegend Debug-/Inspect-Befehle mit mehrzeiliger Ausgabe. Dafür
  ist ein Toast falsch; die gehören in einen Viewer oder bleiben (Abschnitt 6).
- Die Konfigurierbarkeit der Kappung (Aufgabe aus dem Chat) ist machbar und klein
  (Abschnitt 7).

## 2. Zahlen pro Repo

Scanner-Ausgabe (Spalten: Treffer gesamt, "Wrapper-like" = erstes Argument ist keine
Literalzeichenkette, "bound" = `local notify = vim.notify` bei Modulload, WARN/ERROR =
Level ist ausgeschrieben). Die vollständige Trefferliste (Datei:Zeile, Art, Level,
Textanfang) steht im Anhang. Hinweis: `lib_notify` zählt **Erzeugungsstellen** von
`lib.nvim.notify.create(...)`, nicht jeden einzelnen `notifier.info(...)`-Aufruf.

| Repo | Findings | Wrapper-like | Load-time bound | Multiline | WARN/ERROR | Kinds |
|---|---|---|---|---|---|---|
| lsp.nvim | 65 | 1 | 0 | 0 | 0 | echo=1 lib_notify=63 print=1 |
| color_my_ascii.nvim | 47 | 0 | 4 | 4 | 0 | bound=4 lib_notify=8 print=35 |
| mdview.nvim | 34 | 1 | 1 | 0 | 0 | bound=1 echo=7 lib_notify=24 print=2 |
| sessions.nvim | 31 | 0 | 0 | 0 | 12 | lib_notify=11 notify=20 |
| pickers.nvim | 30 | 1 | 0 | 1 | 0 | lib_notify=29 notify=1 |
| casedesk.nvim | 29 | 0 | 0 | 0 | 0 | lib_notify=29 |
| debugging.nvim | 26 | 0 | 0 | 0 | 0 | lib_notify=23 notify=1 print=2 |
| open.nvim | 24 | 0 | 0 | 0 | 0 | lib_notify=24 |
| language.nvim | 22 | 0 | 0 | 0 | 0 | lib_notify=22 |
| rules.nvim | 18 | 7 | 0 | 1 | 14 | notify=15 print=3 |
| replacer.nvim | 15 | 0 | 0 | 3 | 0 | lib_notify=1 print=14 |
| ai.nvim | 14 | 0 | 0 | 0 | 0 | lib_notify=14 |
| cmdlog.nvim | 14 | 0 | 0 | 0 | 0 | lib_notify=14 |
| runtime-analysis.nvim | 13 | 0 | 0 | 0 | 0 | lib_notify=12 notify=1 |
| dap.nvim | 12 | 0 | 0 | 0 | 3 | lib_notify=9 notify=3 |
| my.nvim | 11 | 1 | 0 | 0 | 3 | lib_notify=8 notify=3 |
| images.nvim | 11 | 0 | 0 | 0 | 0 | lib_notify=11 |
| cascade.nvim | 10 | 2 | 0 | 0 | 0 | lib_notify=8 notify=2 |
| reposcope.nvim | 9 | 1 | 0 | 2 | 0 | lib_notify=2 notify=1 print=6 |
| fileops.nvim | 8 | 4 | 0 | 0 | 2 | lib_notify=3 notify=4 print=1 |
| buffer-ctx.nvim | 7 | 6 | 0 | 0 | 2 | lib_notify=1 notify=6 |
| media.nvim | 6 | 5 | 0 | 1 | 2 | notify=6 |
| gopath.nvim | 6 | 4 | 0 | 0 | 2 | lib_notify=2 notify=4 |
| sandbox.nvim | 6 | 0 | 1 | 0 | 2 | bound=1 lib_notify=2 notify=3 |
| pdfport.nvim | 5 | 0 | 0 | 1 | 0 | lib_notify=2 print=3 |
| emojis.nvim | 5 | 4 | 0 | 0 | 2 | lib_notify=1 notify=4 |
| spotlight.nvim | 4 | 2 | 0 | 0 | 0 | lib_notify=2 notify=2 |
| recommender.nvim | 4 | 1 | 0 | 0 | 0 | lib_notify=3 notify=1 |
| diff.nvim | 4 | 2 | 0 | 1 | 0 | echo=2 lib_notify=2 |
| documentation.nvim | 4 | 0 | 0 | 0 | 0 | lib_notify=4 |
| data.nvim | 3 | 0 | 0 | 0 | 0 | lib_notify=2 print=1 |
| filetree.nvim | 3 | 0 | 1 | 0 | 0 | bound=1 lib_notify=1 print=1 |
| insights.nvim | 3 | 0 | 0 | 1 | 1 | lib_notify=2 notify=1 |
| hover.nvim | 3 | 0 | 0 | 0 | 0 | lib_notify=3 |
| markdown.nvim | 2 | 1 | 0 | 0 | 0 | lib_notify=1 notify=1 |
| github_stats.nvim | 1 | 0 | 0 | 0 | 0 | lib_notify=1 |
| gitsuite.nvim | 1 | 0 | 0 | 0 | 0 | lib_notify=1 |

## 3. Zentraler Hebel: globaler Default in lib.nvim

Die Repos folgen fast alle demselben Muster: ein dünner Wrapper (`util/notify.lua`,
`util/lib.lua`, `util/log.lua`) löst `lib.nvim.notify` auf, ruft
`create("[prefix]")` und fällt nur ohne lib.nvim auf `vim.notify` zurück
(z. B. `fileops.nvim/lua/fileops/util/notify.lua`, `cascade.nvim/lua/cascade/util/lib.lua`,
`lsp.nvim` mit 63 direkten `require("lib.nvim.notify").create("[lsp.nvim]")`).

Vorschlag für Runde 2:

1. `require("lib.nvim.notify").setup({ popup = true, ... })` setzt einen **globalen
   Default**, den `create(prefix, opts)` verwendet, solange `opts.popup` nicht explizit
   gesetzt ist (pro Notifier weiterhin `popup = false` möglich). Aufruf **einmal** in
   `nvim-config/lua/plugins/personal/init.lua` (dort wo lib.nvim konfiguriert wird).
2. Ergebnis: alle lib-Nutzer (Abschnitt 2, Spalte `lib_notify`) zeigen Toasts, ohne dass
   ein Plugin geändert wird. Kein Repo bekommt eine harte Abhängigkeit hinzu.
3. Zusätzlich `toast_min_level` (Default INFO): DEBUG/TRACE erzeugen keinen Toast, nur
   History/`:messages`. Sonst würden chatty Plugins (z. B. `lsp.nvim` mit 63
   Erzeugungsstellen, `debugging.nvim`, `casedesk.nvim`) die Ecke zuspammen.
4. Alternative/Ergänzung ohne jede Plugin-Änderung: `ui.nvim`'s `ui.notify`
   (`ui.setup({ notify = true })`) macht **jedes** `vim.notify` zum Toast mit History.
   `popup.deliver` erkennt das bereits und legt dann kein zweites Popup obendrauf. Es
   deckt aber weder `print` noch `nvim_echo` ab und hat keine `source`-getrennte History.

Risiken: (a) Tests einzelner Repos, die `vim.notify` stubben, müssten `popup = false`
setzen oder `popup.deliver` stubben; (b) beim Start vor dem ersten UI-Redraw können
Toasts kurz nicht sichtbar sein (History bleibt); (c) Plugins, die das Notify-Ergebnis
über `vim.notify`-Hooks weiterverarbeiten (noice-Routen), sehen weiterhin nur die
`:messages`-Schreibung (`messages = true`).

## 4. Repos mit eigenem `vim.notify`-Wrapper (direkt umzustellen)

Bevorzugt den **Wrapper** ändern, nicht die Aufrufer: ein Wrapper-Body = alle Aufrufer.

| Repo | Stelle | Befund | Empfehlung |
|---|---|---|---|
| sessions.nvim | 7 Dateien mit je 2-3 fast identischen Wrappern (`bindings/autocmds`, `bindings/keymaps`, `bindings/usercmds`, `marks/init`, `marks/menu`, `marks/preview`, `picker`) | 20× `vim.notify` mit Präfix `[sessions…]`, davon 12 WARN/ERROR | Einen gemeinsamen `sessions/util/notify.lua` einführen (Duplikat!) auf Basis `lib.nvim.notify.create(..., { popup = true })`; `picker.lua:287` (ERROR: snacks/telescope fehlt) profitiert direkt |
| rules.nvim | `bindings/usrcmds.lua:78-140`, `config/init.lua:61-107`, `init.lua:28-143` | 15× `vim.notify`, 14 WARN/ERROR, mehrzeilige Config-Fehler (`config/init.lua:61`) | Genau der Fall "lange Fehlermeldung": auf popup umstellen; `:Rules messages` ergänzen |
| buffer-ctx.nvim | `util/notify.lua:29-56` | Wrapper mit 4 Leveln | Wrapper → `create(..., { popup = true })`; `health.lua:51,53` bleiben (checkhealth) |
| emojis.nvim | `util/lib.lua:54-63` | Wrapper, lib-first | durch globalen Default (Abschnitt 3) automatisch; Fallback-Zweig unverändert |
| gopath.nvim | `util/log.lua:47-74` | Logger-Wrapper | wie emojis; hier eher Level-Filter beachten (DEBUG) |
| markdown.nvim | `util/notify.lua:29` | Wrapper | wie buffer-ctx |
| recommender.nvim, spotlight.nvim, cascade.nvim | `util/lib.lua` | lib-first + Fallback | durch globalen Default abgedeckt |
| fileops.nvim | `util/notify.lua:29-59` | lib-first + Fallback | durch globalen Default abgedeckt; `usrcmds.lua:660` `print` → prüfen |
| sandbox.nvim | `notify.lua:17-23` | 3 Level, ohne lib | auf `create(..., { popup = true })` |
| media.nvim | `ui.lua:139-180`, `hub/dashboard.lua:373`, `bindings/*` | 6× direkt; `ui.lua:139` mehrzeilig (INFO), `ui.lua:148` ERROR | Wrapper einführen, ERROR/WARN → popup |
| my.nvim | `declarative/clipboard.lua:177-184` | 3× ERROR/WARN (win32yank) | popup; Fehler mit Exitcode + stderr sind typisch mehrzeilig |
| dap.nvim | `languages/rust.lua:138`, `zig.lua:109,119` | 3× WARN, `zig build`-Ausgabe kann lang sein | popup |
| pickers.nvim | `cheatsheet/init.lua:122` | 1× INFO, mehrzeilig | popup oder Viewer (Cheatsheet ist Inhalt, keine Meldung) |
| insights.nvim | `config/init.lua:158` | WARN, mehrzeilig ("config issue(s)") | popup; typischer Kandidat |
| runtime-analysis.nvim | `startup/init.lua:67` | 1× INFO | optional |
| mdview.nvim | `adapter/ws_client.lua:147-395` | 7× `nvim_echo` mit `[mdview]`-Fehlern (health-check, stderr, post failed) | popup ERROR/WARN; stderr-Texte sind lang |
| diff.nvim | `core/directory.lua:281` (mehrzeilig), `core/render.lua:755` | 2× `nvim_echo` | popup |

Nicht anfassen: `buffer-ctx.nvim/health.lua` (checkhealth-Ausgabe), `debugging.nvim/views/debug_helper.lua:260`
("Test message 1", Selbsttest).

## 5. Load-Time-Bindungen von `vim.notify` (umgehen spätere Hooks)

| Repo | Stelle | Befund | Empfehlung |
|---|---|---|---|
| color_my_ascii.nvim | `highlighter.lua:15`, `commands/fence_check.lua:15`, `commands/format.lua:8`, `config/init.lua:10` | `local notify = vim.notify` bei Modulload (4×) - dieselbe Fehlerklasse wie ursprünglich in reposcope: ein später gesetzter Hook (`ui.notify`, noice) wird umgangen | auf `create("[color_my_ascii]", { popup = true })` bzw. Aufrufzeit-Auflösung umstellen |
| filetree.nvim | `features/infra/watcher_quarantine/init.lua:85` | `S.original_notify = vim.notify`: sichert das Original, vermutlich um `vim.notify` temporär zu ersetzen | **prüfen, nicht blind ändern** - Absicht (temporäres Unterdrücken) und ob die Sicherung vor/nach einem Hook passiert |
| sandbox.nvim | `bindings/usrcmds/init.lua:85` | `local saved_notify = vim.notify`: Sicherung um einen Sandbox-Lauf | wahrscheinlich Absicht (Meldungen im Lauf abfangen); belassen, aber Aufrufzeit statt Modulload |
| mdview.nvim | `test/runner.lua:12` | nur Test-Runner | ignorieren |

## 6. `print(` und `nvim_echo`: bewusst differenzieren

| Gruppe | Repos / Stellen | Bewertung |
|---|---|---|
| Debug-/Inspect-Dumps (mehrzeilig, Ausgabe eines Befehls) | color_my_ascii `debug/commands.lua` (35 Zeilen), replacer `debug.lua` (14), lsp `lspdoctor/init.lua:202`, data `bindings/usrcmds.lua:119`, debugging `commands.lua:149`, reposcope `usrcmds.lua` (`providers`/`queries`) | **Kein Toast.** Das ist Befehlsausgabe, kein Ereignis. Besser: ein Viewer (`ui.kit.viewer`, wie `:LibNotifyScan`), oder `print` belassen. Ein einheitlicher Helfer `popup.show_lines(title, lines)` in lib.nvim wäre die saubere Lösung |
| stderr/Tool-Fehler | pdfport `backends/docling.lua:52,54`, `pdfplumber.lua:68`, mdview `ws_client.lua` | **Popup**, oft lang und mehrzeilig |
| Einzeiler-Status | `filetree` `source_switcher/init.lua:410`, `fileops` `usrcmds.lua:660`, `lsp.nvim` `htmx/filter_logs.lua:59` | einzeln prüfen; teils Debug-Rest |

## 7. Konfigurierbare Kappung (Aufgabe zum lib-Modul) - Machbarkeit

Ist-Stand in `lib.nvim.notify.popup`: Toast verarbeitet nur die ersten 4000 Bytes,
zeigt max. 12 Zeilen (Breite 38), History-Eintrag max. 64 KB - alles Modulkonstanten.

**Ja, machbar, ohne Umbau:**

1. **Konfiguration global** in der Installations-Spec:
   `require("lib.nvim.notify.popup").setup({ max_lines = 12, toast_max_bytes = 4000,
   entry_max_bytes = 65536, width = 38, toast_min_level = vim.log.levels.INFO,
   timeouts = { [ERROR] = 10000, ... } })`. Die Konstanten wandern in die vorhandene
   `config`-Tabelle von `popup.lua`; `setup` existiert bereits (`messages`).
2. **Pro Aufruf/Notifier** über `deliver(msg, lvl, { max_lines = ..., max_bytes = ... })`
   und `create(prefix, { popup = true, max_lines = ... })`.
3. **Umschalten "gekürzt ↔ voll" in der UI selbst:**
   - Der Toast ist bewusst `focusable = false` (klaut keinen Fokus) und kann daher
     **keine eigenen Tasten** annehmen. Machbar ist stattdessen eine **globale Taste**,
     die die Konfiguration des Nutzers registriert:
     `popup.expand_last()` öffnet die **volle** letzte Meldung in einem Viewer/Scratch
     (`ui.kit.viewer`, vorhanden) - ist die Meldung gekürzt, zeigt der Toast als letzte
     Zeile den Hinweis darauf (heute schon `... (full text: the popup history)`).
   - `popup.toggle_full()` schaltet den globalen Modus (`max_lines` begrenzt ↔ unbegrenzt,
     Toast wächst bis zur Fensterhöhe); Zustand in `config`, Tastenbindung über
     `lib.nvim.bindings.keymap` (Action-Registry) wie bei den anderen lib-Aktionen, dazu
     `:… messages`-Befehl. Zu ergänzen: `docs/NOTES/BINDINGS` der Nvim-Config, sobald die
     Taste feststeht.
   - Aufwand grob: Config-Konstanten (klein), `expand_last` (klein, Viewer existiert),
     `toggle_full` (klein), Tests + Docs (mittel). Kein Risiko für bestehende Aufrufer.
4. **Offene Entscheidung:** Welche Taste (`<leader>n…`), und ob "voll" im Toast selbst
   (wächst über den Bildschirm) oder immer im Viewer erscheinen soll. Empfehlung: Viewer.

## 8. Empfohlene Reihenfolge für Runde 2

1. lib.nvim: globaler Default (`notify.setup({ popup = true })`), `toast_min_level`,
   Konfiguration der Kappung, `expand_last`/`toggle_full`, Tests, Docs.
2. nvim-config: einmal in `lua/plugins/personal/init.lua` aktivieren; Taste festlegen.
3. Wrapper-Repos aus Abschnitt 4 (sessions, rules, sandbox, media, my, dap, insights,
   mdview, diff, pickers).
4. Load-Time-Bindungen (color_my_ascii zuerst; filetree/sandbox erst prüfen).
5. `print`-Dumps: `popup.show_lines` einführen, danach die Debug-Befehle umstellen.
6. Nach jedem Repo: `:LibNotifyScan` erneut laufen lassen (Verifikation), pro Repo
   `TESTS/`, `stylua`, `luacheck`, commit/push auf `main`.

## 9. Anhang: vollständige Trefferliste (Scanner-Ausgabe)

#### ai.nvim

- `lua/ai/bindings/actions.lua:32` lib_notify
- `lua/ai/bindings/actions.lua:148` lib_notify
- `lua/ai/bindings/actions.lua:238` lib_notify
- `lua/ai/bindings/actions.lua:244` lib_notify
- `lua/ai/bindings/keymaps.lua:46` lib_notify
- `lua/ai/bindings/usrcmds.lua:23` lib_notify
- `lua/ai/bindings/usrcmds.lua:105` lib_notify
- `lua/ai/config/init.lua:45` lib_notify
- `lua/ai/init.lua:39` lib_notify
- `lua/ai/init.lua:55` lib_notify
- `lua/ai/init.lua:64` lib_notify
- `lua/ai/init.lua:74` lib_notify
- `lua/ai/init.lua:82` lib_notify
- `lua/ai/init.lua:125` lib_notify

#### buffer-ctx.nvim

- `lua/buffer_ctx/health.lua:51` notify (dynamic)
- `lua/buffer_ctx/health.lua:53` notify (dynamic)
- `lua/buffer_ctx/util/notify.lua:12` lib_notify
- `lua/buffer_ctx/util/notify.lua:29` notify INFO (dynamic)
- `lua/buffer_ctx/util/notify.lua:38` notify WARN (dynamic)
- `lua/buffer_ctx/util/notify.lua:47` notify ERROR (dynamic)
- `lua/buffer_ctx/util/notify.lua:56` notify DEBUG (dynamic)

#### cascade.nvim

- `lua/cascade/bindings/usrcmds.lua:64` lib_notify
- `lua/cascade/init.lua:11` lib_notify
- `lua/cascade/lists/continue.lua:10` lib_notify
- `lua/cascade/lists/cycle_type.lua:11` lib_notify
- `lua/cascade/lists/indent.lua:11` lib_notify
- `lua/cascade/lists/move.lua:10` lib_notify
- `lua/cascade/lists/quick_toggle.lua:14` lib_notify
- `lua/cascade/util/lib.lua:37` lib_notify
- `lua/cascade/util/lib.lua:47` notify (dynamic)
- `lua/cascade/util/lib.lua:94` notify DEBUG (dynamic)

#### casedesk.nvim

- `lua/casedesk/config/init.lua:11` lib_notify
- `lua/casedesk/meta.lua:74` lib_notify
- `lua/casedesk/sla/notify.lua:20` lib_notify
- `lua/casedesk/ui/activity.lua:7` lib_notify
- `lua/casedesk/ui/add.lua:5` lib_notify
- `lua/casedesk/ui/anonymize.lua:6` lib_notify
- `lua/casedesk/ui/case_new.lua:6` lib_notify
- `lua/casedesk/ui/cases.lua:7` lib_notify
- `lua/casedesk/ui/commands.lua:7` lib_notify
- `lua/casedesk/ui/common.lua:6` lib_notify
- `lua/casedesk/ui/copy.lua:14` lib_notify
- `lua/casedesk/ui/diff.lua:17` lib_notify
- `lua/casedesk/ui/doclinks.lua:6` lib_notify
- `lua/casedesk/ui/file_verbs.lua:6` lib_notify
- `lua/casedesk/ui/infocard.lua:5` lib_notify
- `lua/casedesk/ui/insert.lua:7` lib_notify
- `lua/casedesk/ui/ki.lua:5` lib_notify
- `lua/casedesk/ui/lifecycle.lua:10` lib_notify
- `lua/casedesk/ui/pickers.lua:8` lib_notify
- `lua/casedesk/ui/reply_check.lua:5` lib_notify
- `lua/casedesk/ui/similar.lua:5` lib_notify
- `lua/casedesk/ui/sla.lua:6` lib_notify
- `lua/casedesk/ui/snow.lua:5` lib_notify
- `lua/casedesk/ui/solution.lua:7` lib_notify
- `lua/casedesk/ui/sync.lua:5` lib_notify
- `lua/casedesk/ui/template.lua:5` lib_notify
- `lua/casedesk/ui/timeline.lua:5` lib_notify
- `lua/casedesk/ui/tricentis_links.lua:6` lib_notify
- `lua/casedesk/ui/versions.lua:6` lib_notify

#### cmdlog.nvim

- `lua/cmdlog/bindings/keymaps.lua:48` lib_notify
- `lua/cmdlog/config/init.lua:157` lib_notify
- `lua/cmdlog/config/init.lua:158` lib_notify
- `lua/cmdlog/core/favorites.lua:12` lib_notify
- `lua/cmdlog/core/shell.lua:281` lib_notify
- `lua/cmdlog/core/shell.lua:287` lib_notify
- `lua/cmdlog/core/store.lua:14` lib_notify
- `lua/cmdlog/init.lua:6` lib_notify
- `lua/cmdlog/ui/favorites_picker.lua:8` lib_notify
- `lua/cmdlog/ui/lua_picker.lua:8` lib_notify
- `lua/cmdlog/ui/mappings.lua:4` lib_notify
- `lua/cmdlog/ui/project_picker.lua:9` lib_notify
- `lua/cmdlog/ui/risky_test.lua:10` lib_notify
- `lua/cmdlog/ui/stats_picker.lua:7` lib_notify

#### color_my_ascii.nvim

- `lua/color_my_ascii/commands/config.lua:8` lib_notify
- `lua/color_my_ascii/commands/debug.lua:8` lib_notify
- `lua/color_my_ascii/commands/fence/init.lua:12` lib_notify
- `lua/color_my_ascii/commands/fence/util.lua:7` lib_notify
- `lua/color_my_ascii/commands/fence_check.lua:15` bound
- `lua/color_my_ascii/commands/format.lua:8` bound
- `lua/color_my_ascii/commands/schemes.lua:6` lib_notify
- `lua/color_my_ascii/config/init.lua:10` bound
- `lua/color_my_ascii/debounce_manager.lua:20` lib_notify
- `lua/color_my_ascii/debug/commands.lua:27` print `=== Character Inspection: "`
- `lua/color_my_ascii/debug/commands.lua:28` print `Highlight: `
- `lua/color_my_ascii/debug/commands.lua:29` print `Override: `
- `lua/color_my_ascii/debug/commands.lua:30` print `Groups: `
- `lua/color_my_ascii/debug/commands.lua:42` print `Group not found: `
- `lua/color_my_ascii/debug/commands.lua:46` print `=== Group Inspection: `
- `lua/color_my_ascii/debug/commands.lua:47` print `Highlight: `
- `lua/color_my_ascii/debug/commands.lua:48` print `Character count: `
- `lua/color_my_ascii/debug/commands.lua:49` print `Characters: `
- `lua/color_my_ascii/debug/commands.lua:60` print `=== Inline Code Inspection ===`
- `lua/color_my_ascii/debug/commands.lua:61` print `Line: `
- `lua/color_my_ascii/debug/commands.lua:62` print `Found `
- `lua/color_my_ascii/debug/commands.lua:65` print (multiline) `\n[`
- `lua/color_my_ascii/debug/commands.lua:68` print `  Characters:`
- `lua/color_my_ascii/debug/commands.lua:70` print `    "`
- `lua/color_my_ascii/debug/commands.lua:75` print `  Keywords:`
- `lua/color_my_ascii/debug/commands.lua:77` print `    "`
- `lua/color_my_ascii/debug/commands.lua:92` print `=== Highlight Group Inspection: `
- `lua/color_my_ascii/debug/commands.lua:93` print `Used by `
- `lua/color_my_ascii/debug/commands.lua:95` print `  - `
- `lua/color_my_ascii/debug/commands.lua:106` print `=== color_my_ascii.nvim Statistics ===`
- `lua/color_my_ascii/debug/commands.lua:107` print (multiline) `\nGroups:`
- `lua/color_my_ascii/debug/commands.lua:108` print `  Total: `
- `lua/color_my_ascii/debug/commands.lua:109` print `  By highlight:`
- `lua/color_my_ascii/debug/commands.lua:111` print `    `
- `lua/color_my_ascii/debug/commands.lua:114` print (multiline) `\nLanguages:`
- `lua/color_my_ascii/debug/commands.lua:115` print `  Total: `
- `lua/color_my_ascii/debug/commands.lua:116` print `  Keywords per language:`
- `lua/color_my_ascii/debug/commands.lua:118` print `    `
- `lua/color_my_ascii/debug/commands.lua:121` print (multiline) `\nLookups:`
- `lua/color_my_ascii/debug/commands.lua:122` print `  Character mappings: `
- `lua/color_my_ascii/debug/commands.lua:123` print `  Keyword mappings: `
- `lua/color_my_ascii/debug/commands.lua:124` print `  Unique keywords: `
- `lua/color_my_ascii/debug/commands.lua:125` print `  Overrides: `
- `lua/color_my_ascii/debug/init.lua:47` print `[color_my_ascii.debug]`
- `lua/color_my_ascii/highlighter.lua:15` bound
- `lua/color_my_ascii/init.lua:9` lib_notify
- `lua/color_my_ascii/parser.lua:8` lib_notify

#### dap.nvim

- `lua/wkddap/adapters/init.lua:6` lib_notify
- `lua/wkddap/bindings/init.lua:4` lib_notify
- `lua/wkddap/configurations/init.lua:6` lib_notify
- `lua/wkddap/core/setup.lua:4` lib_notify
- `lua/wkddap/health.lua:40` lib_notify
- `lua/wkddap/languages/lua.lua:5` lib_notify
- `lua/wkddap/languages/rust.lua:138` notify WARN `rustc not found -- starting without Rust's LLDB pretty-printers`
- `lua/wkddap/languages/zig.lua:109` notify WARN `zig build exited `
- `lua/wkddap/languages/zig.lua:119` notify WARN `zig build could not start: `
- `lua/wkddap/registry.lua:5` lib_notify
- `lua/wkddap/utils/mason.lua:5` lib_notify
- `lua/wkddap/utils/notify.lua:4` lib_notify

#### data.nvim

- `lua/data/bindings/usrcmds.lua:119` print (dynamic)
- `lua/data/config/init.lua:10` lib_notify
- `lua/data/init.lua:16` lib_notify

#### debugging.nvim

- `lua/debugging/actions/module_reload.lua:4` lib_notify
- `lua/debugging/actions/neotest.lua:27` lib_notify
- `lua/debugging/actions/neotree_safety.lua:15` lib_notify
- `lua/debugging/actions/reports.lua:8` lib_notify
- `lua/debugging/autocmds/runtime.lua:7` lib_notify
- `lua/debugging/autocmds/sources.lua:25` lib_notify
- `lua/debugging/bindings/keymaps.lua:4` lib_notify
- `lua/debugging/commands.lua:18` lib_notify
- `lua/debugging/commands.lua:149` print (dynamic)
- `lua/debugging/config/init.lua:156` lib_notify
- `lua/debugging/health.lua:70` lib_notify
- `lua/debugging/markdown/inline_debug.lua:10` lib_notify
- `lua/debugging/nvim_options/indent_helpers.lua:8` lib_notify
- `lua/debugging/terminals/keylogger.lua:41` lib_notify
- `lua/debugging/tools/buffer_inspector/init.lua:7` lib_notify
- `lua/debugging/tools/cursor/state.lua:8` lib_notify
- `lua/debugging/tools/cursor/state.lua:15` print (dynamic)
- `lua/debugging/tools/proc_trace.lua:21` lib_notify
- `lua/debugging/tools/startup.lua:13` lib_notify
- `lua/debugging/tools/vardump/init.lua:7` lib_notify
- `lua/debugging/views/capture/clipboard/init.lua:11` lib_notify
- `lua/debugging/views/capture/init.lua:10` lib_notify
- `lua/debugging/views/debug_helper.lua:19` lib_notify
- `lua/debugging/views/debug_helper.lua:260` notify INFO `Test message 1`
- `lua/debugging/views/display.lua:10` lib_notify
- `lua/debugging/views/init.lua:12` lib_notify

#### diff.nvim

- `lua/diff/bindings/keymaps.lua:174` lib_notify
- `lua/diff/core/directory.lua:281` echo (dynamic) (multiline)
- `lua/diff/core/render.lua:755` echo (dynamic)
- `lua/diff/util/notify.lua:11` lib_notify

#### documentation.nvim

- `lua/documentation/bindings/usrcmds/init.lua:243` lib_notify
- `lua/documentation/editor/browse/init.lua:50` lib_notify
- `lua/documentation/editor/health.lua:55` lib_notify
- `lua/documentation/editor/registry.lua:17` lib_notify

#### emojis.nvim

- `lua/emojis/util/lib.lua:42` lib_notify
- `lua/emojis/util/lib.lua:54` notify INFO (dynamic)
- `lua/emojis/util/lib.lua:57` notify WARN (dynamic)
- `lua/emojis/util/lib.lua:60` notify ERROR (dynamic)
- `lua/emojis/util/lib.lua:63` notify DEBUG (dynamic)

#### fileops.nvim

- `lua/fileops/bindings/usrcmds.lua:660` print (dynamic)
- `lua/fileops/health.lua:107` lib_notify
- `lua/fileops/health.lua:109` lib_notify
- `lua/fileops/util/notify.lua:11` lib_notify
- `lua/fileops/util/notify.lua:29` notify INFO (dynamic)
- `lua/fileops/util/notify.lua:39` notify WARN (dynamic)
- `lua/fileops/util/notify.lua:49` notify ERROR (dynamic)
- `lua/fileops/util/notify.lua:59` notify DEBUG (dynamic)

#### filetree.nvim

- `lua/filetree/features/infra/watcher_quarantine/init.lua:85` bound
- `lua/filetree/features/nav/source_switcher/init.lua:410` print (dynamic)
- `lua/filetree/util/notify.lua:13` lib_notify

#### github_stats.nvim

- `lua/github_stats/config/init.lua:15` lib_notify

#### gitsuite.nvim

- `lua/gitsuite/util/notify.lua:6` lib_notify

#### gopath.nvim

- `lua/gopath/util/log.lua:33` lib_notify
- `lua/gopath/util/log.lua:47` notify DEBUG (dynamic)
- `lua/gopath/util/log.lua:56` notify INFO (dynamic)
- `lua/gopath/util/log.lua:65` notify WARN (dynamic)
- `lua/gopath/util/log.lua:74` notify ERROR (dynamic)
- `lua/gopath/util/safe_notify.lua:12` lib_notify

#### hover.nvim

- `lua/hover/health.lua:91` lib_notify
- `lua/hover/health.lua:106` lib_notify
- `lua/hover/notify.lua:22` lib_notify

#### images.nvim

- `lua/images/browse.lua:153` lib_notify
- `lua/images/calibrate.lua:78` lib_notify
- `lua/images/compare.lua:23` lib_notify
- `lua/images/config/init.lua:14` lib_notify
- `lua/images/debug.lua:41` lib_notify
- `lua/images/guard.lua:19` lib_notify
- `lua/images/hover_float.lua:30` lib_notify
- `lua/images/init.lua:31` lib_notify
- `lua/images/paste.lua:31` lib_notify
- `lua/images/redact.lua:41` lib_notify
- `lua/images/zen.lua:26` lib_notify

#### insights.nvim

- `lua/insights/config/init.lua:158` notify WARN (multiline) `[insights] config issue(s) in setup():\n  - `
- `lua/insights/health.lua:30` lib_notify
- `lua/insights/util/notify.lua:5` lib_notify

#### language.nvim

- `lua/language/bindings/usrcmds/init.lua:25` lib_notify
- `lua/language/health.lua:46` lib_notify
- `lua/language/spell/init.lua:16` lib_notify
- `lua/language/spell/providers/codespell.lua:15` lib_notify
- `lua/language/spell/providers/cspell.lua:17` lib_notify
- `lua/language/spell/providers/cspell_server.lua:61` lib_notify
- `lua/language/spell/providers/cspell_server.lua:143` lib_notify
- `lua/language/spell/providers/custom.lua:18` lib_notify
- `lua/language/spell/providers/native.lua:22` lib_notify
- `lua/language/spell/providers/typos.lua:17` lib_notify
- `lua/language/spell/ui/item_menu.lua:12` lib_notify
- `lua/language/spell/ui/panel.lua:11` lib_notify
- `lua/language/thesaurus/init.lua:62` lib_notify
- `lua/language/thesaurus/init.lua:82` lib_notify
- `lua/language/thesaurus/init.lua:94` lib_notify
- `lua/language/thesaurus/init.lua:152` lib_notify
- `lua/language/translate/files.lua:21` lib_notify
- `lua/language/translate/history.lua:10` lib_notify
- `lua/language/translate/history.lua:141` lib_notify
- `lua/language/translate/init.lua:17` lib_notify
- `lua/language/translate/output/init.lua:125` lib_notify
- `lua/language/translate/window.lua:265` lib_notify

#### lsp.nvim

- `lua/lsp/bindings/actions.lua:120` lib_notify
- `lua/lsp/bindings/actions.lua:137` lib_notify
- `lua/lsp/bindings/actions.lua:185` lib_notify
- `lua/lsp/bindings/actions.lua:197` lib_notify
- `lua/lsp/bindings/actions.lua:240` lib_notify
- `lua/lsp/bindings/actions.lua:292` lib_notify
- `lua/lsp/bindings/actions.lua:342` lib_notify
- `lua/lsp/bindings/actions.lua:426` lib_notify
- `lua/lsp/bindings/actions.lua:437` lib_notify
- `lua/lsp/bindings/actions.lua:597` lib_notify
- `lua/lsp/bindings/actions.lua:643` lib_notify
- `lua/lsp/bindings/usrcmds.lua:33` lib_notify
- `lua/lsp/completion/personal_names/init.lua:29` lib_notify
- `lua/lsp/core/call_hierarchy.lua:41` lib_notify
- `lua/lsp/core/implement.lua:33` lib_notify
- `lua/lsp/core/inlay_hints.lua:33` lib_notify
- `lua/lsp/core/lightbulb.lua:59` lib_notify
- `lua/lsp/core/peek/init.lua:42` lib_notify
- `lua/lsp/core/root_scope_picker.lua:9` lib_notify
- `lua/lsp/core/supervisor.lua:55` lib_notify
- `lua/lsp/core/winbar/init.lua:43` lib_notify
- `lua/lsp/core/workspace_diagnostics.lua:72` lib_notify
- `lua/lsp/core/workspace_picker.lua:19` lib_notify
- `lua/lsp/diagnostics/commands.lua:8` lib_notify
- `lua/lsp/formatter/conform.lua:10` lib_notify
- `lua/lsp/init.lua:44` lib_notify
- `lua/lsp/integrations/mason/ensure_install/init.lua:29` lib_notify
- `lua/lsp/languages/app/dart.lua:10` lib_notify
- `lua/lsp/languages/documentation/markdown_words/init.lua:22` lib_notify
- `lua/lsp/languages/webdev/astro/keymaps.lua:5` lib_notify
- `lua/lsp/languages/webdev/astro/usercmds.lua:6` lib_notify
- `lua/lsp/lspdoctor/init.lua:56` lib_notify
- `lua/lsp/lspdoctor/init.lua:202` print (dynamic)
- `lua/lsp/servers/bashls.lua:6` lib_notify
- `lua/lsp/servers/csharp.lua:4` lib_notify
- `lua/lsp/servers/lua_ls/debug.lua:4` lib_notify
- `lua/lsp/servers/lua_ls/error_handler.lua:4` lib_notify
- `lua/lsp/servers/lua_ls/find_type_dirs.lua:14` lib_notify
- `lua/lsp/servers/lua_ls/reload.lua:5` lib_notify
- `lua/lsp/servers/marksman/hints.lua:9` lib_notify
- `lua/lsp/servers/mobiledev/dartls.lua:4` lib_notify
- `lua/lsp/servers/mobiledev/jdtls.lua:5` lib_notify
- `lua/lsp/servers/mobiledev/kotlin_language_server.lua:5` lib_notify
- `lua/lsp/servers/mobiledev/sourcekit.lua:5` lib_notify
- `lua/lsp/servers/webdev/astro/autotag.lua:25` lib_notify
- `lua/lsp/servers/webdev/astro/init.lua:4` lib_notify
- `lua/lsp/servers/webdev/htmx/filter_logs.lua:59` echo (dynamic)
- `lua/lsp/servers/webdev/htmx/init.lua:4` lib_notify
- `lua/lsp/tools/deprecated_help/lsp/lua_ls/lua_ls.lua:13` lib_notify
- `lua/lsp/tools/deprecated_help/lsp_common.lua:11` lib_notify
- `lua/lsp/tools/eslint_prettier/eslint/fix.lua:3` lib_notify
- `lua/lsp/tools/eslint_prettier/prettier/format.lua:5` lib_notify
- `lua/lsp/tools/eslint_prettier/usercmds/init.lua:3` lib_notify
- `lua/lsp/tools/lsp_signature/fallback_providers.lua:14` lib_notify
- `lua/lsp/tools/lsp_signature/request_and_show.lua:10` lib_notify
- `lua/lsp/tools/ts_type_lookup/cmds.lua:4` lib_notify
- `lua/lsp/tools/ts_type_lookup/symbol_picker.lua:35` lib_notify
- `lua/lsp/usercmds/formatter.lua:6` lib_notify
- `lua/lsp/usercmds/init.lua:5` lib_notify
- `lua/lsp/usercmds/mobile_diagnostics/init.lua:4` lib_notify
- `lua/lsp/usercmds/recovery.lua:30` lib_notify
- `lua/lsp/usercmds/restart.lua:13` lib_notify
- `lua/lsp/usercmds/start.lua:27` lib_notify
- `lua/lsp/usercmds/stop.lua:6` lib_notify
- `lua/lsp/usercmds/workspace_diagnostics.lua:8` lib_notify

#### markdown.nvim

- `lua/markdown/util/notify.lua:15` lib_notify
- `lua/markdown/util/notify.lua:29` notify INFO (dynamic)

#### mdview.nvim

- `lua/mdview/adapter/inbound_poll.lua:15` lib_notify
- `lua/mdview/adapter/preview_tab.lua:16` lib_notify
- `lua/mdview/adapter/runner.lua:11` lib_notify
- `lua/mdview/adapter/server_args.lua:9` lib_notify
- `lua/mdview/adapter/ws_client.lua:147` echo `[mdview] server health-check impossible: `
- `lua/mdview/adapter/ws_client.lua:162` echo (dynamic)
- `lua/mdview/adapter/ws_client.lua:166` echo `[mdview] server health-check timed out after `
- `lua/mdview/adapter/ws_client.lua:334` echo `[mdview.ws_client] http_post stderr: `
- `lua/mdview/adapter/ws_client.lua:350` echo `[mdview.ws_client] failed to send markdown for `
- `lua/mdview/adapter/ws_client.lua:388` echo `[mdview.ws_client] immediate post stderr: `
- `lua/mdview/adapter/ws_client.lua:395` echo `[mdview.ws_client] immediate post failed for `
- `lua/mdview/bindings/usrcmds/blanklines.lua:14` lib_notify
- `lua/mdview/bindings/usrcmds/breadcrumbs.lua:8` lib_notify
- `lua/mdview/bindings/usrcmds/cursor.lua:28` lib_notify
- `lua/mdview/bindings/usrcmds/diagnose.lua:6` lib_notify
- `lua/mdview/bindings/usrcmds/file_log.lua:19` lib_notify
- `lua/mdview/bindings/usrcmds/log.lua:13` lib_notify
- `lua/mdview/bindings/usrcmds/overlay.lua:15` lib_notify
- `lua/mdview/bindings/usrcmds/pin.lua:26` lib_notify
- `lua/mdview/bindings/usrcmds/reveal.lua:11` lib_notify
- `lua/mdview/bindings/usrcmds/selection.lua:20` lib_notify
- `lua/mdview/bindings/usrcmds/standalone.lua:25` lib_notify
- `lua/mdview/bindings/usrcmds/start/init.lua:7` lib_notify
- `lua/mdview/bindings/usrcmds/start/server/launcher.lua:20` lib_notify
- `lua/mdview/bindings/usrcmds/stop.lua:17` lib_notify
- `lua/mdview/bindings/usrcmds/sync.lua:7` lib_notify
- `lua/mdview/bindings/usrcmds/theme.lua:13` lib_notify
- `lua/mdview/bindings/usrcmds/zoom.lua:14` lib_notify
- `lua/mdview/config/browser.lua:12` lib_notify
- `lua/mdview/config/init.lua:13` lib_notify
- `lua/mdview/init.lua:24` lib_notify
- `lua/mdview/test/diff_harness.lua:58` print (dynamic)
- `lua/mdview/test/diff_harness.lua:157` print (dynamic)
- `lua/mdview/test/runner.lua:12` bound

#### media.nvim

- `lua/media/bindings/keymaps.lua:53` notify WARN `no media file under the cursor`
- `lua/media/bindings/usrcmds.lua:86` notify INFO (dynamic)
- `lua/media/hub/dashboard.lua:373` notify INFO (dynamic)
- `lua/media/ui.lua:139` notify INFO (dynamic) (multiline)
- `lua/media/ui.lua:148` notify ERROR (dynamic)
- `lua/media/ui.lua:180` notify INFO (dynamic)

#### my.nvim

- `lua/my/bindings/keymaps.lua:23` lib_notify
- `lua/my/bindings/usrcmds/init.lua:23` lib_notify
- `lua/my/config/persist.lua:37` lib_notify
- `lua/my/declarative/clipboard.lua:177` notify ERROR `clipboard: win32yank -i failed to run`
- `lua/my/declarative/clipboard.lua:179` notify ERROR `clipboard: win32yank -i failed (exit `
- `lua/my/declarative/clipboard.lua:184` notify WARN (dynamic)
- `lua/my/diff_profile.lua:15` lib_notify
- `lua/my/health.lua:58` lib_notify
- `lua/my/hl_config/init.lua:58` lib_notify
- `lua/my/indent_per_ft/init.lua:19` lib_notify
- `lua/my/init.lua:33` lib_notify

#### open.nvim

- `lua/open/bindings/keymaps.lua:24` lib_notify
- `lua/open/bindings/usrcmds.lua:52` lib_notify
- `lua/open/bindings/usrcmds.lua:206` lib_notify
- `lua/open/config/init.lua:256` lib_notify
- `lua/open/context.lua:64` lib_notify
- `lua/open/handlers/browser.lua:9` lib_notify
- `lua/open/handlers/default.lua:13` lib_notify
- `lua/open/handlers/filemanager.lua:25` lib_notify
- `lua/open/handlers/image.lua:16` lib_notify
- `lua/open/handlers/notepad.lua:13` lib_notify
- `lua/open/handlers/nvim_internal.lua:8` lib_notify
- `lua/open/handlers/terminal.lua:10` lib_notify
- `lua/open/health.lua:34` lib_notify
- `lua/open/health.lua:35` lib_notify
- `lua/open/health.lua:37` lib_notify
- `lua/open/init.lua:70` lib_notify
- `lua/open/init.lua:98` lib_notify
- `lua/open/integrations/telescope.lua:18` lib_notify
- `lua/open/integrations/telescope.lua:82` lib_notify
- `lua/open/integrations/urlview.lua:14` lib_notify
- `lua/open/office_open.lua:17` lib_notify
- `lua/open/picker.lua:35` lib_notify
- `lua/open/registry.lua:8` lib_notify
- `lua/open/viewer/init.lua:25` lib_notify

#### pdfport.nvim

- `lua/pdfport/backends/docling.lua:52` print (dynamic)
- `lua/pdfport/backends/docling.lua:54` print (dynamic)
- `lua/pdfport/backends/pdfplumber.lua:68` print (multiline) `\n\n`
- `lua/pdfport/util/notify.lua:10` lib_notify
- `lua/pdfport/util/notify.lua:29` lib_notify

#### pickers.nvim

- `lua/pickers/actions/dir.lua:14` lib_notify
- `lua/pickers/actions/smart.lua:15` lib_notify
- `lua/pickers/bindings/usrcmds.lua:35` lib_notify
- `lua/pickers/browse/init.lua:20` lib_notify
- `lua/pickers/builtins/init.lua:25` lib_notify
- `lua/pickers/cheatsheet/init.lua:122` notify INFO (dynamic) (multiline)
- `lua/pickers/command/init.lua:31` lib_notify
- `lua/pickers/config/init.lua:6` lib_notify
- `lua/pickers/engines/fzf.lua:19` lib_notify
- `lua/pickers/engines/init.lua:10` lib_notify
- `lua/pickers/engines/snacks.lua:34` lib_notify
- `lua/pickers/engines/telescope.lua:21` lib_notify
- `lua/pickers/entry_actions/adapters/fzf.lua:38` lib_notify
- `lua/pickers/entry_actions/adapters/snacks.lua:24` lib_notify
- `lua/pickers/entry_actions/adapters/telescope.lua:11` lib_notify
- `lua/pickers/entry_actions/create_file.lua:11` lib_notify
- `lua/pickers/entry_actions/open_background.lua:15` lib_notify
- `lua/pickers/entry_actions/path_copy.lua:31` lib_notify
- `lua/pickers/git_status_filtered/init.lua:35` lib_notify
- `lua/pickers/health.lua:23` lib_notify
- `lua/pickers/history/init.lua:22` lib_notify
- `lua/pickers/last.lua:11` lib_notify
- `lua/pickers/mappings/init.lua:36` lib_notify
- `lua/pickers/sources/collection.lua:9` lib_notify
- `lua/pickers/sources/drives.lua:13` lib_notify
- `lua/pickers/sources/folder.lua:4` lib_notify
- `lua/pickers/sources/github.lua:17` lib_notify
- `lua/pickers/sources/repos.lua:7` lib_notify
- `lua/pickers/sources/system.lua:15` lib_notify
- `lua/pickers/tabs/init.lua:26` lib_notify

#### recommender.nvim

- `lua/recommender/health.lua:82` lib_notify
- `lua/recommender/util/lib.lua:30` lib_notify
- `lua/recommender/util/lib.lua:39` notify INFO (dynamic)
- `lua/recommender/util/lib.lua:87` lib_notify

#### replacer.nvim

- `lua/replacer/debug.lua:68` print (multiline) `\n=== Buffer Inspection ===`
- `lua/replacer/debug.lua:69` print (dynamic)
- `lua/replacer/debug.lua:72` print (multiline) `\n=== First 5 lines (with byte lengths) ===`
- `lua/replacer/debug.lua:75` print (dynamic)
- `lua/replacer/debug.lua:79` print
- `lua/replacer/debug.lua:117` print (dynamic)
- `lua/replacer/debug.lua:118` print (dynamic)
- `lua/replacer/debug.lua:119` print (dynamic)
- `lua/replacer/debug.lua:120` print (dynamic)
- `lua/replacer/debug.lua:121` print (dynamic)
- `lua/replacer/debug.lua:126` print (multiline) `\nOccurrences:`
- `lua/replacer/debug.lua:137` print (dynamic)
- `lua/replacer/debug.lua:154` print `  No occurrences found`
- `lua/replacer/debug.lua:156` print
- `lua/replacer/util/notify.lua:9` lib_notify

#### reposcope.nvim

- `lua/reposcope/bindings/usrcmds.lua:200` print (dynamic) (multiline)
- `lua/reposcope/bindings/usrcmds.lua:254` print INFO (dynamic) (multiline)
- `lua/reposcope/bindings/usrcmds.lua:268` print `Skipped readme fetches: `
- `lua/reposcope/bindings/usrcmds.lua:275` lib_notify
- `lua/reposcope/bindings/usrcmds.lua:292` print `dev_mode:`
- `lua/reposcope/utils/debug.lua:19` lib_notify
- `lua/reposcope/utils/debug.lua:23` notify (dynamic)
- `lua/reposcope/utils/debug.lua:94` print `State Buffers:`
- `lua/reposcope/utils/debug.lua:95` print `State Windows:`

#### rules.nvim

- `lua/rules/bindings/usrcmds.lua:78` notify ERROR `[rules.nvim] :Rules check needs --family=<PREFIX>, e.g. --family=DEP`
- `lua/rules/bindings/usrcmds.lua:83` print (dynamic)
- `lua/rules/bindings/usrcmds.lua:102` notify ERROR `[rules.nvim] :Rules gate needs a name, e.g. :Rules gate release`
- `lua/rules/bindings/usrcmds.lua:108` notify ERROR `[rules.nvim] `
- `lua/rules/bindings/usrcmds.lua:110` print (dynamic)
- `lua/rules/bindings/usrcmds.lua:124` notify ERROR (dynamic)
- `lua/rules/bindings/usrcmds.lua:134` notify ERROR (dynamic)
- `lua/rules/bindings/usrcmds.lua:140` notify WARN (dynamic)
- `lua/rules/bindings/usrcmds.lua:154` print (dynamic)
- `lua/rules/config/init.lua:61` notify WARN (dynamic) (multiline)
- `lua/rules/config/init.lua:73` notify WARN (dynamic)
- `lua/rules/config/init.lua:87` notify WARN `[rules.nvim] setup({ rulesets = ... }) must be a list of strings -- ig`
- `lua/rules/config/init.lua:107` notify WARN `[rules.nvim] setup({ gates = ... }) must be { name = {"PREFIX", ...}, `
- `lua/rules/init.lua:28` notify WARN `[rules.nvim] `
- `lua/rules/init.lua:39` notify WARN `[rules.nvim] `
- `lua/rules/init.lua:58` notify WARN (dynamic)
- `lua/rules/init.lua:84` notify (dynamic)
- `lua/rules/init.lua:143` notify ERROR `[rules.nvim] `

#### runtime-analysis.nvim

- `lua/runtime-analysis/bindings/usrcmds.lua:53` lib_notify
- `lua/runtime-analysis/env.lua:34` lib_notify
- `lua/runtime-analysis/health.lua:55` lib_notify
- `lua/runtime-analysis/history.lua:26` lib_notify
- `lua/runtime-analysis/init.lua:34` lib_notify
- `lua/runtime-analysis/startup/init.lua:61` lib_notify
- `lua/runtime-analysis/startup/init.lua:67` notify INFO `[runtime-analysis.startup] `
- `lua/runtime-analysis/telemetry/command.lua:132` lib_notify
- `lua/runtime-analysis/telemetry/init.lua:71` lib_notify
- `lua/runtime-analysis/telemetry/lazy.lua:62` lib_notify
- `lua/runtime-analysis/telemetry/toggle.lua:31` lib_notify
- `lua/runtime-analysis/ui/float.lua:108` lib_notify
- `lua/runtime-analysis/view.lua:12` lib_notify

#### sandbox.nvim

- `lua/sandbox/bindings/usrcmds/init.lua:85` bound
- `lua/sandbox/notify.lua:12` lib_notify
- `lua/sandbox/notify.lua:14` lib_notify INFO
- `lua/sandbox/notify.lua:17` notify INFO `[sandbox.nvim] `
- `lua/sandbox/notify.lua:20` notify WARN `[sandbox.nvim] `
- `lua/sandbox/notify.lua:23` notify ERROR `[sandbox.nvim] `

#### sessions.nvim

- `lua/sessions/bindings/autocmds/init.lua:28` lib_notify
- `lua/sessions/bindings/autocmds/init.lua:42` notify INFO `[sessions] `
- `lua/sessions/bindings/autocmds/init.lua:45` notify WARN `[sessions] `
- `lua/sessions/bindings/keymaps/init.lua:69` lib_notify
- `lua/sessions/bindings/keymaps/init.lua:75` notify INFO `[sessions.keymaps] `
- `lua/sessions/bindings/keymaps/init.lua:78` notify WARN `[sessions.keymaps] `
- `lua/sessions/bindings/keymaps/init.lua:81` notify ERROR `[sessions.keymaps] `
- `lua/sessions/bindings/usercmds/init.lua:27` lib_notify
- `lua/sessions/bindings/usercmds/init.lua:44` notify INFO `[sessions] `
- `lua/sessions/bindings/usercmds/init.lua:47` notify WARN `[sessions] `
- `lua/sessions/bindings/usercmds/init.lua:50` notify ERROR `[sessions] `
- `lua/sessions/health.lua:63` lib_notify
- `lua/sessions/health.lua:65` lib_notify
- `lua/sessions/health.lua:67` lib_notify
- `lua/sessions/marks/init.lua:43` lib_notify
- `lua/sessions/marks/init.lua:49` notify INFO `[sessions.marks] `
- `lua/sessions/marks/init.lua:52` notify WARN `[sessions.marks] `
- `lua/sessions/marks/init.lua:55` notify ERROR `[sessions.marks] `
- `lua/sessions/marks/menu.lua:36` lib_notify
- `lua/sessions/marks/menu.lua:42` notify INFO `[sessions.marks] `
- `lua/sessions/marks/menu.lua:45` notify WARN `[sessions.marks] `
- `lua/sessions/marks/menu.lua:48` notify ERROR `[sessions.marks] `
- `lua/sessions/marks/preview.lua:18` lib_notify
- `lua/sessions/marks/preview.lua:24` notify INFO `[sessions.marks] `
- `lua/sessions/marks/preview.lua:27` notify WARN `[sessions.marks] `
- `lua/sessions/picker.lua:75` lib_notify INFO
- `lua/sessions/picker.lua:76` lib_notify INFO
- `lua/sessions/picker.lua:79` notify INFO `[sessions] `
- `lua/sessions/picker.lua:82` notify WARN `[sessions] `
- `lua/sessions/picker.lua:278` notify INFO `[sessions] no sessions saved yet`
- `lua/sessions/picker.lua:287` notify ERROR `[sessions] :SessionLoad requires snacks.nvim (with picker) or telescop`

#### spotlight.nvim

- `lua/spotlight/health.lua:19` lib_notify
- `lua/spotlight/util/lib.lua:36` lib_notify
- `lua/spotlight/util/lib.lua:45` notify (dynamic)
- `lua/spotlight/util/lib.lua:104` notify DEBUG (dynamic)

