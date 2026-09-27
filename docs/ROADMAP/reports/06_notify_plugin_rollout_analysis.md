# Plugin-Rollout-Analyse: wer braucht ein Update auf `lib.nvim.notify` (Stand nach P0)

Stand: 2026-09-27 · Grundlage: [05_notify_implementation_plan.md](./05_notify_implementation_plan.md)
(P0 umgesetzt, lib.nvim-Commit `80bdc3d`), Neuscan mit `lib.nvim.dev.notify_scan`
gegen `E:\repos` (**nicht** `$REPOS_DIR\repos` — die Plugins liegen bei dir direkt
unter `$REPOS_DIR`, der Unterordner `repos` existiert auf dieser Maschine nicht;
Report 02 hatte denselben Bestand am 2026-09-25 bereits korrekt erfasst, nur der
Pfad in der ursprünglichen Aufgabenstellung war ungenau).

Geprüft: exakt deine 38 gelistete Einträge (36 `.nvim`-Plugins + `lib.nvim` +
`ui.nvim`) plus die 2 nativen Apps. Alle 36 Konsumenten-Plugins decken sich 1:1
mit den 37 in Report 02 gescannten Repos (Report 02 zählte zusätzlich
`reposcope.nvim` mit, das in deiner Liste diesmal ebenfalls enthalten ist — die
Mengen sind identisch).

**Status P4:** `sessions.nvim` (Rang 1) ist erledigt — sessions.nvim-Commit
`6bda06f`. Beim Umsetzen zeigte sich, dass die 6 Wrapper-Dateien schon
`lib.nvim.notify.create()` mit einem korrekten Fallback aufriefen (kein reiner
`vim.notify`-Direktaufruf, wie unten in Kategorie B ursprünglich vermutet) —
das eigentliche Problem war 7-fache Code-Duplikation, nicht fehlende
lib.nvim-Anbindung, plus zwei wirklich unangebundene `vim.notify`-Aufrufe in
`picker.lua`s `M.pick()`. Siehe die Korrektur in Kategorie B unten.

## Kurzfassung

Nach P0 (konfigurierbare Kappung, `toast_min_level`, globaler
`notify.setup({popup=true})`-Default, `expand_last`, `:Lib notify …`) ändert
sich an der **Holschuld** nichts: kein Plugin muss etwas tun, damit P0 wirkt —
das passiert erst mit **P3** (Aktivierung in deiner Installations-Spec) und
betrifft dann automatisch jeden Konsumenten von `lib.nvim.notify`. Diese
Analyse beantwortet die andere Frage: **welche Plugins braucht es überhaupt
noch Code-Änderungen an**, damit ihre Meldungen über `lib.nvim.notify.popup`
laufen statt weiter direkt über `vim.notify`/`nvim_echo`/`print`.

- **20 von 36** Plugins sind bereits vollständig (oder praktisch vollständig)
  auf `lib.nvim.notify` migriert — **keine Code-Änderung nötig**, Toast kommt
  mit P3 automatisch.
- **11 von 36** haben einen eigenen Wrapper oder Direktaufrufe ohne
  lib.nvim-Bezug — das ist die eigentliche P4-Arbeitsliste.
- **2** haben eine Load-Time-Bindung, die vor jeder Änderung erst auf Absicht
  geprüft werden muss (P5).
- **1** (`reposcope.nvim`) ist die Referenzumsetzung aus Report 00 und praktisch
  fertig — nur eine Rest-Stelle.
- `lib.nvim` selbst und `ui.nvim` sind keine Konsumenten im Migrationssinn.
- `docmap-desktop` und `loomAI` sind keine Neovim-Plugins — nicht anwendbar.

## Kategorie A — bereits migriert, keine Code-Änderung nötig

Diese Plugins rufen ausschließlich `lib.nvim.notify.create(...)` auf (direkt
oder über einen eigenen "lib-first"-Wrapper mit ungenutztem Fallback-Zweig für
den Fall, dass `lib.nvim` fehlt — der Zweig feuert in deiner Umgebung nie, weil
`lib.nvim` immer da ist). Sobald P3 `notify.setup({ popup = true })` setzt,
zeigen alle diese Plugins Toasts, ohne dass hier irgendetwas angefasst wird.

| Repo | Befund | Hinweis |
|---|---|---|
| ai.nvim | 14 lib_notify, sonst nichts | rein |
| casedesk.nvim | 29 lib_notify, sonst nichts | rein |
| cmdlog.nvim | 14 lib_notify, sonst nichts | rein |
| open.nvim | 24 lib_notify, sonst nichts | rein |
| language.nvim | 22 lib_notify, sonst nichts | rein |
| images.nvim | 11 lib_notify, sonst nichts | rein |
| documentation.nvim | 4 lib_notify, sonst nichts | rein |
| hover.nvim | 3 lib_notify, sonst nichts | rein |
| github_stats.nvim | 1 lib_notify, sonst nichts | rein |
| gitsuite.nvim | 1 lib_notify, sonst nichts | rein |
| lsp.nvim | 64 lib_notify, 1 echo, 1 print | die 63+1 `lib_notify`-Stellen profitieren automatisch; mit `toast_min_level` (P0/P3) wird das größte Chatty-Risiko (viele INFO-Aufrufe) sogar automatisch gedämpft, ohne dass hier etwas geändert wird. Der eine `echo` (`htmx/filter_logs.lua:59`) und `print` (`lspdoctor/init.lua:202`) sind P6-Kandidaten, kein P4 |
| debugging.nvim | 23 lib_notify, 1 notify, 2 print | der 1 raw `notify` (`debug_helper.lua:260`, `"Test message 1"`) ist laut Report 02 ein Selbsttest — **nicht anfassen**; die 2 `print` sind P6-Kandidaten |
| data.nvim | 2 lib_notify, 1 print | der `print` (`bindings/usrcmds.lua:119`) ist ein P6-Kandidat, kein P4 |
| runtime-analysis.nvim | 12 lib_notify, 1 notify | 1 statischer `vim.notify(INFO, "[runtime-analysis.startup] …")` neben einem `lib_notify`-Aufruf im selben File — wirkt wie ein Kopierrest; niedrige Priorität (kein WARN/ERROR), optional in P4 mit erledigen |
| emojis.nvim | 1 lib_notify + 4 dynamische Fallback-Calls | lib-first-Wrapper, Fallback-Zweig unverändert lassen |
| gopath.nvim | 2 lib_notify + 4 dynamische Fallback-Calls | lib-first; DEBUG-lastig — mit `toast_min_level=INFO` (Default) werden die DEBUG-Meldungen automatisch leiser, das ist gewünscht, kein Bug |
| recommender.nvim | 3 lib_notify + 1 dynamischer Fallback-Call | lib-first |
| spotlight.nvim | 2 lib_notify + 2 dynamische Calls | lib-first |
| cascade.nvim | 8 lib_notify + 2 dynamische Calls | lib-first |
| fileops.nvim | 3 lib_notify (davon 2 health.lua) + 4 dynamische Fallback-Calls, 1 print | lib-first; `bindings/usrcmds.lua:660` (`print`) ist ein P6-Kandidat |

## Kategorie B — eigener Wrapper/Direktaufrufe ohne lib.nvim-Bezug (P4-Liste)

Das ist die eigentliche Arbeitsliste. Reihenfolge nach Hebelwirkung (meiste
Aufrufer bzw. größter Blast-Radius zuerst) — deckt sich mit Plan 05 §6, dort
fehlten `buffer-ctx.nvim` und `markdown.nvim` versehentlich in der
Reihenfolge; hier nachgezogen.

| Rang | Repo | Fundstelle | Befund (frisch) | Empfehlung |
|---|---|---|---|---|
| 1 | ~~sessions.nvim~~ **erledigt** (`6bda06f`) | 7 Dateien (`bindings/{autocmds,keymaps,usercmds}/init.lua`, `marks/{init,menu,preview}.lua`, `picker.lua`) | Korrektur beim Umsetzen: 6 der 7 Stellen riefen `lib.nvim.notify.create()` bereits korrekt mit Fallback auf — der Scanner zählte deren fallback-Zweig als "raw `vim.notify`" mit. Das eigentliche Problem war 7-fache Duplikation derselben ~30-Zeilen-Closure, plus zwei echte, unangebundene `vim.notify`-Aufrufe in `picker.lua`s `M.pick()` | `sessions/util/notify.lua` eingeführt (`create`/`create_titled`), alle 7 Stellen darauf umgestellt, `M.pick()`s zwei Rohaufrufe mitmigriert |
| 2 | ~~rules.nvim~~ **erledigt** (`f4e4fea`) | `bindings/usrcmds.lua`, `config/init.lua`, `init.lua` | 15 raw `vim.notify` (14 WARN/ERROR!), 3 `print`, **null** `lib_notify` — komplett unmigriert | `rules/util/notify.lua` eingeführt (harte lib.nvim-Abhängigkeit, kein Fallback nötig — lib.nvim ist hier schon Pflicht), alle 15 Stellen umgestellt, `:Rules messages` ergänzt. Die 3 `print(json)`-Stellen sind bewusstes `--format=json`-CI-Output, keine Debug-Reste — unangetastet gelassen |
| 3 | mdview.nvim | `adapter/ws_client.lua` (7 Stellen) | 7 raw `nvim_echo` (Server-Health-Check-Fehler, stderr, oft lang); 24 andere Stellen sind bereits `lib_notify` | nur `ws_client.lua` umstellen — der Rest des Plugins ist schon migriert; `test/runner.lua`s Load-Time-Bindung ignorieren (Test-Runner) |
| 4 | media.nvim | `ui.lua`, `hub/dashboard.lua`, `bindings/*` | 6 raw `notify` (2 WARN/ERROR), **kein** `lib_notify` — kein Wrapper vorhanden | Wrapper neu einführen |
| 5 | my.nvim (privat) | `declarative/clipboard.lua:178,180,185` | 3 raw `notify` (ERROR/WARN, win32yank-Fehler); der Rest (8 Stellen) ist `lib_notify` | nur diese eine Datei migrieren |
| 6 | dap.nvim | `languages/rust.lua:138`, `languages/zig.lua:109,119` | 3 raw `notify` WARN (`zig build`-Ausgabe kann lang sein); der Rest (8) ist `lib_notify` | nur diese zwei Dateien migrieren |
| 7 | sandbox.nvim | `notify.lua:17-23` | 3 raw `notify` (INFO/WARN/ERROR), ohne lib-Bezug an dieser Stelle | Wrapper auf `create(..., {popup=true})`; die Load-Time-Bindung in `bindings/usrcmds/init.lua:85` separat behandeln (Kategorie C) |
| 8 | buffer-ctx.nvim | `util/notify.lua:29-56` | 4 raw `notify` (INFO/WARN/ERROR/DEBUG), 2 davon WARN/ERROR | Wrapper → `create(..., {popup=true})`; `health.lua:51,53` (checkhealth) unangetastet lassen |
| 9 | markdown.nvim | `util/notify.lua:29` | 1 raw `notify` INFO | wie buffer-ctx, kleinster Fall in dieser Liste |
| 10 | insights.nvim | `config/init.lua:158` | 1 raw `notify` WARN, mehrzeilig (`"config issue(s) in setup(): …"`) | klassischer Popup-Kandidat, kleiner Umfang |
| 11 | diff.nvim | `core/directory.lua:281` (mehrzeilig), `core/render.lua:755` | 2 raw `nvim_echo` | Wrapper existiert schon (`util/notify.lua`) für andere Stellen — diese zwei nachziehen |
| 12 | pickers.nvim | `cheatsheet/init.lua:122` | 1 raw `notify` INFO, mehrzeilig | **Einzelfall prüfen, nicht pauschal migrieren**: das ist Cheatsheet-Inhalt, keine Ereignismeldung — eher ein P6-Viewer-Kandidat (`output.viewer.show_lines`, sobald P1 steht) als ein P4-Popup |

## Kategorie C — Load-Time-Bindungen (P5, erst Absicht prüfen)

| Repo | Fundstelle | Befund | Hinweis |
|---|---|---|---|
| color_my_ascii.nvim | `commands/fence_check.lua:15`, `commands/format.lua:8`, `config/init.lua:10`, `highlighter.lua:15` | 4× `local notify = vim.notify` bei Modulload | die eindeutige reposcope-Fehlerklasse aus Report 00 — zuerst dran, klar ein Bug (später gesetzte Hooks werden umgangen) |
| filetree.nvim | `features/infra/watcher_quarantine/init.lua:85` | `S.original_notify = vim.notify` | **erst Absicht prüfen** — sieht nach bewusster Sicherung fürs temporäre Unterdrücken aus, nicht blind ändern |
| sandbox.nvim | `bindings/usrcmds/init.lua:85` | `local saved_notify = vim.notify` | **erst Absicht prüfen** — vermutlich Sicherung rund um einen Sandbox-Lauf, siehe auch Kategorie B Rang 7 für dasselbe Repo |
| mdview.nvim | `test/runner.lua:12` | Test-Runner | ignorieren |

`filetree.nvim`s eigener Notify-Wrapper (`util/notify.lua:13`) ist bereits
sauber `lib_notify` — nur die Load-Time-Bindung und die unten genannten
`print`-Dumps brauchen hier noch etwas.

## Weitere print-/echo-Dumps (P6-Kandidaten, separat von B/C)

Aus der Kategorie-A/B-Zuordnung oben bereits vermerkt, hier gebündelt für den
Überblick — jede Stelle einzeln prüfen, ob Migration auf
`output.viewer.show_lines` (ab P1 verfügbar) sinnvoll ist oder ob es
vergessener Debug-Code ist, der einfach gelöscht gehört:

- **Größere Dumps:** color_my_ascii (`debug/commands.lua`, 35 Zeilen),
  replacer (`debug.lua`, 14 Zeilen), reposcope (`utils/debug.lua`,
  `bindings/usrcmds.lua`, mehrere Provider-/Query-Dumps), lsp
  (`lspdoctor/init.lua:202`), pdfport (`backends/docling.lua`,
  `backends/pdfplumber.lua`).
- **Einzeiler, vermutlich Debug-Reste (einzeln prüfen, nicht pauschal
  migrieren):** filetree (`features/nav/source_switcher/init.lua:410` und neu
  `features/infra/who_locks/init.lua:139,145,169` — letzteres existierte in
  Report 02 noch nicht, ist seit dem 2026-09-25 neu dazugekommen), fileops
  (`bindings/usrcmds.lua:660`), data (`bindings/usrcmds.lua:119`), debugging
  (`commands.lua:149`, `tools/cursor/state.lua:15`), lsp
  (`htmx/filter_logs.lua:59`, ein `echo`).

## Sonderfälle

- **reposcope.nvim** — die Referenzumsetzung aus Report 00 (`:Reposcope
  messages` existiert schon, `utils/debug.lua` leitet an `popup.deliver`
  weiter). Nur eine Rest-Stelle offen: `utils/debug.lua:23`, ein dynamischer
  raw `vim.notify`-Aufruf neben dem bereits migrierten `lib_notify` in
  derselben Datei. Die übrigen Treffer sind Debug-Dumps (siehe oben).
- **my.nvim ist privat** — technisch keine Sonderbehandlung nötig (Kategorie B,
  Rang 5), nur als Hinweis: bei einer eventuellen `ultracode`-Review oder
  einem geteilten Report ist das zu beachten.
- **lib.nvim** — kein Konsument; ist die Quelle des Moduls selbst.
- **ui.nvim** — kein Konsument im Migrationssinn; liefert den `ui.kit.toast`,
  den `popup.lua` als weiche Abhängigkeit nutzt, und `ui.notify`, das
  `popup.deliver` bereits erkennt (`ui_notify_active()`).
- **docmap-desktop, loomAI** — keine Neovim-Plugins, nicht anwendbar.

## Empfohlene Reihenfolge (aktualisiert gegenüber Plan 05 §6)

```
P4  sessions → rules → mdview(ws_client) → media → my → dap → sandbox
    → buffer-ctx → markdown → insights → diff → pickers(Einzelfall, eher P6)
P5  color_my_ascii (klar) → filetree/sandbox (erst Absicht prüfen)
P6  print-/echo-Dumps, Repo für Repo, jede Stelle einzeln bewerten
```

Kategorie-A-Plugins (20 Stück, oben gelistet) brauchen in keiner Phase eine
Code-Änderung — sie sind mit P3 fertig.
