# Startup-Zeit und Config-Optimierung: Analyse und Konzept

Stand: 2026-09-26 · Rechner `OHANA` (Windows, Rolle `default`) · Neovim 0.11.4 ·
Status: **Analyse und Konzept, keine Änderung an der Config.** Neu angelegt wurde
nur das Messwerkzeug [`scripts/startup-probe/`](../../../scripts/startup-probe/README.md).

Diese Fassung ersetzt die erste, die ich im Chat ausgegeben hatte. Sie ist nach
einer Prüfung von `lua/startup/`, der Startup-Policy
([`docs/NOTES/ARCHITECTURE/startup.md`](../../NOTES/ARCHITECTURE/startup.md)) und
einer zweiten Messrunde **nach `VimEnter`** grundlegend überarbeitet. Was
korrigiert wurde, steht in Abschnitt 2.

---

## 1. Kurzfassung

Zwei Aussagen, die vorher gefehlt haben:

1. **Bis `UIReady` vergehen etwa 1,05 s** (plus rund 120 ms Neovim-Kern vor
   `init.lua`). Die `lsp`-Phase allein ist mit **390 ms** die größte Einzelphase.
2. **Danach steht die Event-Loop weitere ~1,4 s still**, in fünf Stößen von bis
   zu 0,5 s in den ersten drei Sekunden. Das sieht keine der bisherigen Metriken:
   „Config loaded in … ms" endet vor `UIReady`, `:StartupReport` misst nur die
   Phasen-Bodies.

Die Zeit steckt nicht im Lua-Code, sondern in **wenigen C-Aufrufen**, die in Summe
teuer sind:

| # | Ursache | Kosten (gemessen) | Wo es zuschlägt |
| --- | --- | --- | --- |
| F1 | **PATH-Suchen** (`exepath`/`executable`): 15 Programme ohne Treffer, je 36–54 ms | **≈ 690 ms** von 790 ms in 24 Aufrufen | `lsp`-Phase (≈ 350 ms), Menü-Prewarm von `wkddap` (≈ 370 ms) |
| F2 | **`vim.loader` berechnet die `runtimepath`-Liste bei jeder Änderung neu**, ≈ 16–20 ms pro Plugin-Load bei ~60 Einträgen | **≈ 560 ms** in 92 Aufrufen | über den ganzen Start, nach `VimEnter` ≈ 420 ms |
| F3 | **Menü-Prewarm** in `ui.nvim` lädt die Plugins der Menü-Integrationen hintereinander | Stöße von 486, 423, 335, 84, 71 ms | direkt nach dem ersten Frame |
| F4 | `lsp`-Phase synchron, zu ~90 % F1 | 390 ms von 488 ms Phasenzeit | vor `VimEnter` |
| F5 | `my`-Phase lädt Telemetrie-Registry und which-key, prüft `powershell`/`win32yank` | 85 ms (am 2026-09-08: 50 ms) | vor `VimEnter` |
| F6 | eager geladene eigene Plugins registrieren ihre Usercmds mit schweren `require`s | ≈ 50–100 ms von ≈ 390 ms `lazy.setup` | vor `VimEnter` |
| F7 | Kleinigkeiten: NvChad-Probe, `gitsigns`-`require` im Autocmd | ≈ 30 ms | verteilt |

**Erwartung** (Schätzung, siehe Abschnitt 7): `UIReady` von ≈ 1,05 s auf
**600–700 ms**, die Stöße nach dem ersten Frame von ≈ 1,4 s auf **< 0,4 s**,
mit F2 auf **< 0,15 s**.

**Empfehlung:** Phase 0 (Messbasis und Leitplanke) und Phase 1 (F1, F4, F5): etwa
die Hälfte des Gewinns bei geringem Risiko, alles in eigenen Repos.

---

## 2. Korrekturen gegenüber der ersten Fassung

| Erste Fassung | Richtig |
| --- | --- |
| Start ≈ 945 ms | Das war „Config loaded" (`defer_fn(0)`, beim ersten Idle, um `VimEnter`). `UIReady` kommt bei **≈ 1,05 s**, die zweite Ladewelle danach noch nicht eingerechnet. |
| „738 Module, 397 ms `require`" | Gemessen **vor** `VimEnter`: `-c "… vim.wait(…)"` läuft vor `VimEnter`, die `UIReady`-Phasen und alles Spätere fehlten. Bis 3,5 s nach dem Start sind es **1619 Module**. Beide Zahlen sind außerdem nicht mit den „449 Modulen vor der ersten Phase" vom 2026-09-08 vergleichbar (anderes Fenster). |
| „`docs/ARCHITECTURE/startup.md` existiert nicht" | Falsch. Die Datei liegt unter `docs/NOTES/ARCHITECTURE/startup.md`. **Die Verweise im Code** (`lua/startup/init.lua` Z. 11 und 122, `lua/startup/report.lua`) zeigen auf den alten Pfad. |
| „`pwsh`-Spawn bis 150 ms" | Übernommen aus einem Code-Kommentar, nicht geprüft. Gemessen: **35–43 ms** Spawn, kein blockierendes `wait`. Niedrige Priorität. |
| Phase 2: persönliche Plugins auf Lazy-Trigger umstellen | Hinfällig: die Policy begründet jedes `lazy = false` an der Spec (Sessions-Autoload, Cmdlog-Tracker, Insights-Autocmds, Casedesk-Statusline, Telemetrie). Richtig ist: **eager lassen, aber beim Laden billig machen** (F6). |
| `startup` = vollständige Zeitachse | `:StartupReport` zeigt nur die **Phasen-Bodies**. `lazy.setup()` (≈ 390 ms) und alles nach `UIReady` sind unsichtbar, ebenso die Stöße. |
| F2 (`runtimepath`-Neuberechnung) und F3 (Prewarm) | In der ersten Fassung gar nicht gefunden. |

---

## 3. Methode und Grenzen

Werkzeug: [`scripts/startup-probe/probe.lua`](../../../scripts/startup-probe/README.md)
(Sonden `req`, `exe`, `rtp`, `stall`, `spawn`, `fs`, `marks`, `report`), läuft per
`--cmd` vor `init.lua` und schreibt den Bericht erst nach `VimEnter`.

- **Headless**, Windows, warmer Cache, ein Rechner. Ein Lauf schwankt um ±40 ms.
  Angegeben sind Werte aus mehreren Läufen; Bereiche, wo sie streuen.
- **Überlappung.** Die Ladezeit eines Plugins enthält seine `require`s und
  `exepath`-Aufrufe. Die Tabellen sind Belege für Ursachen, keine addierbaren
  Anteile.
- **Wrapper-Overhead.** Mit allen Sonden sind Summen 5–10 % höher; die Einzelläufe
  sind die Referenz.
- **Kein UI.** Kein `UIEnter`, kein Paint. `UIReady` feuert trotzdem
  (`VimEnter` + `vim.schedule`).
- **`vim.loader` bleibt an:** ohne ihn 2,0–4,2 s statt ≈ 0,94 s (A/B, je 4 Läufe).

---

## 4. Zeitachse

Millisekunden seit Beginn von `init.lua` (`vim.g.start_time`); davor liegen ≈ 120 ms
Neovim-Kern.

| ms | Ereignis |
| ---: | --- |
| 0 | `init.lua` beginnt, `vim.loader` an, `lazy.setup` |
| ≈ 390 | `LazyDone`: Specs importiert, 18 Start-Plugins geladen |
| 393 | Phase `system`, `ui_open` (je < 1 ms) |
| 394 | Phase `my`: **85 ms** |
| 480 | Phase `autocmds`: 8 ms |
| 487 → 877 | Phase `lsp`: **390 ms** |
| 890 | `VimEnter` |
| ≈ 945 | „Config loaded in … ms" (`defer_fn(0)`) |
| 1049 / 1059 / 1076 | `UIReady`-Phasen `usrcmds` (10 ms), `mappings` (17 ms), `ui_statusline` (27 ms) |
| ≈ 1100 | `pwsh`-Spawn (35–43 ms) |
| ≈ 1370 → 1860 | **Stoß 1**: `wkddap.integrations.menu`, 486 ms |
| ≈ 2073 → 2500 | **Stoß 2**: `filetree.integrations.menu`, 423 ms |
| ≈ 2577 → 2910 | **Stoß 3**: `gitsuite`, `emojis`, `fzf-lua`, `trouble`, `color_my_ascii`, 335 ms |

Fünf Stöße > 60 ms, zusammen **1399 ms** (mit allen Sonden 1480 ms).

---

## 5. Befunde

### F1: PATH-Suchen kosten ein Drittel des Starts

**Beleg.** 24 `exepath`/`executable`-Aufrufe, **790 ms**. 15 davon ohne Treffer, je
36–54 ms, zusammen **686 ms**. Programme mit Treffer sind billig (8–19 ms).
`PATH` hat 72 Einträge, `PATHEXT` 11: eine fehlgeschlagene Suche stellt ≈ 790
`stat`-Aufrufe.

| Aufrufer (Datei:Zeile) | Namen | Fehlversuche |
| --- | --- | --- |
| `lsp.nvim/lua/lsp/formatter/conform.lua:37` (`resolve`, aufgerufen aus Z. 167–187) | `prettierd`, `prettier`, `shfmt`, `shellharden` (+ `mdformat` gefunden, 19 ms) | 4 ≈ 175 ms |
| `lsp.nvim/lua/lsp/servers/webdev/html.lua:32` | `vscode-html-language-server`, `html-languageserver`, `html-lsp` | 3 ≈ 125–145 ms |
| `wkddap/config/init.lua:328` und `wkddap/languages/bash.lua:60-61` | `js-debug-adapter`, `codelldb`, `dlv`, `debugpy-adapter`, `gdb`, `bash-debug-adapter`, `netcoredbg`, `bashdb` | 8 ≈ 360 ms |
| `my.nvim/lua/my/declarative/shell.lua:33`, `clipboard.lua:62` | `powershell` (9–11 ms), `win32yank` (8 ms) | 0 |
| `gitsuite/features/ui/lazygit/init.lua:146` | `nvr` (18 ms) | 0 |

Der erste Block läuft in der synchronen `lsp`-Phase (≈ 350 ms von 390 ms), der
`wkddap`-Block im Menü-Prewarm (369 ms von 500 ms in `wkddap.integrations.menu`).
Dazu kommt bei jedem Start die Meldung `[dap.nvim.adapters] 12/13 adapter(s)
unavailable`: dieselbe Prüfung, deren Ergebnis niemand sofort braucht.

**Es ist dieselbe Lehre wie in der Startup-Policy** („ein Feld sieht billig aus,
eine PATH-Suche ist es nicht"), an drei weiteren Stellen.

**Gemessene Gegenmittel** (im `--clean`-Lauf, absolute Werte höher als im Start):

| Variante | fehlender Name | Bemerkung |
| --- | ---: | --- |
| `exepath`, `PATHEXT` mit 11 Endungen | 85–94 ms | Ist-Zustand |
| `exepath`, `PATHEXT` mit `.COM;.EXE;.BAT;.CMD` | 34–37 ms | −60 %, aber ein Eingriff in die Umgebung |
| einmaliger PATH-Index per `fs_scandir` (7265 Einträge) | 65 ms **einmal**, danach 0 ms | robust, Cache muss invalidierbar sein |
| gar nicht beim Start auflösen | 0 ms | erste Nutzung zahlt |

**Maßnahme.** Auflösung dorthin verschieben, wo das Ergebnis gebraucht wird:
`conform` erlaubt `command` als Funktion (vor dem Umbau gegen die installierte
Version prüfen), der HTML-Server löst `cmd` bei `FileType` auf, die DAP-Adapter
beim ersten `:Dap`/Debug-Start. Als zweite Verteidigungslinie ein **PATH-Index in
`lib.nvim.cross.executable`** (Windows, dedupliziert, invalidierbar), damit
künftige Aufrufer nicht wieder 40 ms pro Fehlversuch zahlen. Den Index dem
`PATHEXT`-Kürzen vorziehen: kein Eingriff in die Umgebung.

### F2: `vim.loader` berechnet die `runtimepath`-Liste bei jeder Änderung neu

**Beleg.** `nvim_get_runtime_file("", true)` (das ist `vim.loader`s `get_rtp()`,
neu berechnet, sobald sich `vim.go.rtp` ändert): **92 Aufrufe, 558 ms** über den
Start, 40 davon (≈ 140 ms) vor `VimEnter`, 52 (≈ 417 ms) danach. Ein Aufruf kostet
4–22 ms und wächst mit der Liste (6 Einträge zu Beginn, 64 zuletzt). Im
sauberen Neovim mit 29 Einträgen: 0,0 ms.

In `filetree.integrations.menu` (472 ms Wall) sind **204 ms** davon: 18 Aufrufe,
weil das Modul viele Plugins nachlädt und jeder Load den `runtimepath` ändert
(18 Neuberechnungen). Dazu 99 ms für 678 `fs_stat`.

Über den ganzen Start sind `fs_stat` (2543 Aufrufe, 348 ms), `fs_open`/`fs_read`
(1663 Aufrufe, 191 ms) und `nvim_exec2` (233 Aufrufe, 156 ms) die nächsten
Posten.

**Maßnahme, teils Hypothese.** Weniger Plugin-Loads in der zweiten Welle (F3);
die Ursache des Preises pro Aufruf klären (Dateisystem-Scan durch Defender/EDR? Die
Config vermerkt einen EDR nur für die Workstation, siehe `config/lazy.lua`; hier ist
die Rolle `default`); prüfen, ob eine neuere Neovim-Version `get_rtp()` billiger macht (die
Startup-Policy zeigt `nvim 0.12.2`, hier läuft 0.11.4).

### F3: Der Menü-Prewarm erzeugt die Stöße

**Beleg.** Traceback: `ui.nvim/lua/ui/menu/contributors.lua:314` (`prewarm`), über
`vim.defer_fn(step, 20)` nach 300 ms Vorlauf. Der Kommentar dort:
*„Requiring a lazy plugin's menu module loads the whole plugin (up to ~400 ms …),
which is a stall on the first right click; spread over idle ticks after startup it
is not."*

Das Verteilen auf Ticks verhindert **den Stoß beim ersten Rechtsklick**, aber
nicht den einzelnen Stoß: jeder Schritt ist ein einziges `require` von bis zu
500 ms am Stück. Gemessen im Innern der Schritte:

| Schritt | Wall | Davon |
| --- | ---: | --- |
| `wkddap.integrations.menu` | 500 ms | 369 ms `exepath` (9 Aufrufe), 72 ms `runtimepath` (8) |
| `filetree.integrations.menu` | 472 ms | 204 ms `runtimepath` (18), 99 ms `fs_stat` |
| `gopath.integrations.menu` | 90 ms | 14 ms `runtimepath` (2) |

**Nebenbefund zur Policy.** Die Startup-Policy verbietet Wall-Clock-Timer als
Phasen-Trigger („eine Zahl wie `10` beschreibt keine Bedingung, sie rät"). Der
Prewarm ist derselbe Fehlertyp (`delay = 300`, `defer_fn(step, 20)`), nur im
Plugin statt im Config-Kern, also außerhalb der geschriebenen Regel.

**Maßnahme, in dieser Reihenfolge.** (a) F1 und F2 nehmen den Schritten den
Großteil der Zeit. (b) Menü-Integrationsmodule **statisch** machen: beim `require`
nur Beschreibungen (Label, Kommando), schwere `require`s erst im Handler. Dann
kostet der Prewarm nichts und kann entfallen. (c) Bis dahin nur bei echtem Idle
prewarmen (z. B. über `vim.on_key`-Zeitstempel), nicht per fester Verzögerung.

### F4: Die `lsp`-Phase

390 ms von 488 ms Phasenzeit, synchron (`startup.now("lsp")`). Die Begründung der
Policy (Capabilities global vor dem ersten Attach, Configs registrieren) bleibt
gültig: verschoben werden muss nur die **Auflösung der Executables** (F1), nicht
die Registrierung. Erwartung nach F1: ≈ 40–50 ms.

### F5: Die `my`-Phase

85 ms (2026-09-08: 50 ms). Aus dem Traceback: `my/init.lua:173` →
`my/bindings/keymaps.lua:64` → `runtime-analysis/telemetry/registry.lua:203` →
`lib/nvim/bindings/keymap/registry.lua:346` → `which_key.lua:63` lädt **which-key**
(9–17 ms), die Registry ruft außerdem `exepath git` (`run_argv`, Z. 117). Dazu
`powershell`/`win32yank`-Prüfungen (17–20 ms). Maßnahme: which-key nur anfassen,
wenn schon geladen (`package.loaded`, nicht `require`), die Executable-Prüfungen
über den Cache aus F1.

### F6: Eager Plugins, billig statt lazy

Ladezeiten der 18 Start-Plugins: `runtime-analysis` 74 ms (am 2026-09-08 ≈ 45 ms,
Zunahme prüfen), `casedesk` 34, `nvim-treesitter` 27, `pickers.nvim` 24, `lib.nvim`
22, `sessions` 22, `tokyonight` 21, `mason` 17, `cmdlog` 17, `insights` 16, `hover` 15.

Die Gründe für `lazy = false` sind an den Specs dokumentiert und tragen (Sessions
registriert `VimEnter`/`VimLeavePre`, Cmdlog startet den `CmdlineLeave`-Tracker,
Insights registriert Autocmds, Casedesk speist die Statusline). **Also nicht lazy
machen, sondern das Laden verschlanken:** der auffällige Teil ist wiederholt
`<plugin>.bindings.usrcmds` (gemessen: Casedesk 17–26 ms, Hover 4 ms; die
übrigen Plugins sind noch zu prüfen): die Registrierung der Usercmds zieht schwere
Untermodule hoch. Registrieren
(`vim.api.nvim_create_user_command`) darf nichts laden; das `require` gehört in den
Handler. Erwartung: 50–100 ms.

`runtime-analysis` steht außerdem nach `VimEnter` im Lua-Sampler ganz oben
(`telemetry/registry.lua` Z. 203–270, `fingerprint.lua:91`). Die Telemetrie ist
laut Policy „eine bewusste Entscheidung", aber ihr Preis ist gewachsen und
gehört in Phase 0 gemessen.

### F7: Kleinigkeiten

- **NvChad-Probe.** `lsp.nvim/lua/lsp/integrations/nvchad.lua:31` macht
  `pcall(require, "nvchad.configs.lspconfig")`; NvChad ist nicht installiert. Ein
  fehlgeschlagenes `require` durchsucht den ganzen `runtimepath`: **12–14 ms**, 2×.
  Statt `require` gegen `lazy.core.config.plugins` prüfen.
- **`gitsigns` im Autocmd.** `bindings/autocmds/git/gitsigns_refresh.lua:19` ruft
  im `BufEnter`/`FocusGained`-Handler `pcall(require, "gitsigns")` und lädt das
  Plugin damit beim ersten Buffer (15–19 ms), statt nur zu aktualisieren, wenn es
  ohnehin geladen ist: `package.loaded["gitsigns"]` prüfen (LUA-92).
- **`pwsh`-Spawn** (`shell.lua:68`): 35–43 ms, schon geschoben. Niedrige Priorität.

---

## 6. Konzept

### Phase 0: Messbasis und Leitplanke

1. **`startup` sieht die ganze Zeitachse.** Marken für `init.lua`-Beginn,
   `LazyDone`, `VimEnter`, `UIReady`; ein **Stall-Detektor** (10-ms-Herzschlag,
   Lücken > 60 ms) für die ersten ~5 s; `:StartupReport` zeigt beides. Aktuell
   sieht es 5 Phasen-Bodies und lässt 60–80 % der Zeit aus.
2. **Die Metrik korrigieren.** „Config loaded in … ms" per `defer_fn(0)` durch die
   `UIReady`-Marke ersetzen; sie ist die Antwort auf „wann ist es benutzbar".
3. **Budget im `:StartupCheck`.** Grenzwerte für `UIReady` und für den längsten
   Stoß; als Schranke, nicht als Gefühl.
4. **Benchmark-Lauf.** 10 Starts, Median und Streuung mit `startup-probe`
   (`PROBE=marks,stall,report`), damit „schneller" gemessen ist.
5. **Verweise reparieren.** `docs/ARCHITECTURE/startup.md` →
   `docs/NOTES/ARCHITECTURE/startup.md` in `lua/startup/init.lua` (Z. 11, 122) und
   `lua/startup/report.lua`.

### Phase 1: PATH-Suchen (F1, F4, F5), Erwartung −340 ms bis `UIReady`

Reihenfolge: (1) `lsp.nvim`: Formatter-`command` und HTML-`cmd` lazy;
(2) `wkddap`: Adapter-Verfügbarkeit erst bei Debug-Start, die Meldung
`12/13 adapters unavailable` nur noch dann; (3) `lib.nvim.cross.executable` als
zentraler, invalidierbarer PATH-Index; (4) `my.nvim`: which-key nur bei
vorhandenem Plugin, Executable-Prüfungen aus dem Cache.

### Phase 2: Menü-Prewarm (F3), Erwartung Stöße −0,6 s

Menü-Integrationen statisch (nur Beschreibungen beim `require`), Prewarm
anschließend abschaffen oder auf echtes Idle umstellen. Danach die Policy um die
Regel erweitern: **kein Plugin lädt beim Startup weitere Plugins per
Wall-Clock-Timer**.

### Phase 3: `runtimepath`-Neuberechnung (F2), Erwartung −100 bis −300 ms

Erst Ursache klären (Experimente: Defender-Ausnahme für `nvim-data` und
`B:\repos`, Neovim 0.12 gegenprüfen, Anzahl der Plugin-Loads in der zweiten
Welle), dann entscheiden. Kein Umbau auf Verdacht.

### Phase 4: Eager Plugins verschlanken (F6, F7), Erwartung −80 bis −130 ms

Usercmd-Registrierung ohne schwere `require`s, in den betroffenen Plugin-Repos;
NvChad-Probe und `gitsigns`-Autocmd; `runtime-analysis`-Kosten messen.

### Phase 5: Config-Optimierung (nicht Startzeit)

- **C1 Wirkungsprüfung.** Diese Session hat mehrere Einstellungen gefunden, die nie
  wirkten (fzf-`actions`, `entry_maker`, `preview`-Funktion, telescope
  `preview.wrap`, fzf-`rg_opts` neben eigenem `cmd`). Vorschlag: headless-Assertions
  „effektiver Wert ist X" pro Engine, als Smoke-Test unter `docs/TESTING`.
- **C2 Policy fortschreiben.** `docs/NOTES/ARCHITECTURE/startup.md` beschreibt
  NvChad als Basis, „29 auf 16 Plugins" und eine Messung vom 2026-09-08; nach Phase 1
  aktualisieren. Neue Regeln: keine PATH-Suche auf dem synchronen oder `UIReady`-Pfad;
  Usercmd-Registrierung lädt nichts; kein Plugin-Prewarm per Timer.
- **C3 Checklisten.** F1 und F2 in `wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`
  als Regeln festhalten (PATH-Suche kostet pro Fehlversuch ≈ 40 ms; jede
  `runtimepath`-Änderung kostet `vim.loader` eine Neuberechnung).
- **C4 `plugins/personal/init.lua`** hat über 1200 Zeilen; nach Zuständigkeit
  aufteilen, wenn die Phasen 1–4 durch sind.
- **C5 Plugin-Inventur.** 93 Specs: welche laden in echten Sessions nie
  (`runtime-analysis`/lazy-Daten über eine Woche)? Kandidaten zum Entfernen.
- **C6 NvChad-Reste.** Nur Kommentare in der Config; die Probe in `lsp.nvim`
  (F7) und Doku-Bezüge bereinigen.

---

## 7. Erwartung

Schätzungen, keine Summen (die Ursachen überlappen). Ist-Werte aus Abschnitt 4.

| Größe | Ist | nach Phase 1 | nach Phasen 1–2 | nach Phasen 1–4 |
| --- | ---: | ---: | ---: | ---: |
| `lsp`-Phase | 390 ms | 40–50 ms | 40–50 ms | 40–50 ms |
| `my`-Phase | 85 ms | ≈ 45 ms | ≈ 45 ms | ≈ 45 ms |
| `UIReady` | ≈ 1050 ms | ≈ 650–700 ms | ≈ 650–700 ms | **≈ 600 ms** (Stretch 550) |
| Event-Loop-Stöße nach `VimEnter` | 1,4 s | ≈ 1,0 s | **< 0,4 s** | **< 0,15 s** |
| `exepath`-Fehlversuche beim Start | 15 (686 ms) | 0 | 0 | 0 |

---

## 8. Risiken und Nebenwirkungen

- **Verfügbarkeit erst bei Bedarf.** `:checkhealth`, Statusmeldungen und Health-Zeilen
  müssen dann selbst auflösen. Die erste Formatierung eines fehlenden Tools kostet
  einmalig ≈ 40 ms statt bei jedem Start.
- **PATH-Index veraltet**, wenn ein Tool nachinstalliert wird (mason). `clear()`
  existiert in `lib.nvim.cross.executable`; Invalidierung an Mason-Installationen
  und `FocusGained` hängen.
- **`PATHEXT` kürzen** wäre der billigste Eingriff (−60 %), verändert aber die
  Prozessumgebung für alle Kindprozesse. Deshalb Index statt Kürzung.
- **Statische Menü-Integrationen** ändern die Struktur der Integrationsmodule in
  mehreren Repos (`wkddap`, `filetree`, `gitsuite`, `gopath` …). Schrittweise, pro
  Repo ein Commit.
- **Schätzungen hängen an dieser Maschine.** Kalt gegen warm ändert Faktor 2–3;
  nach jeder Phase neu messen, nicht die Erwartung abhaken.

---

## 9. Offene Entscheidungen

1. **Ziel.** `UIReady` (< 700 ms) oder „keine Stöße > 100 ms in den ersten 3 s"?
   Phase 1 bringt das erste, Phasen 2–3 das zweite.
2. **Repos.** Änderungen in `lsp.nvim`, `lib.nvim`, `my.nvim`, `ui.nvim`,
   `wkddap`, `filetree`, `gitsuite` (alle eigene Repos), jeweils Commit und Push
   im `main`?
3. **Semantik.** Ist „Verfügbarkeit von Executables wird beim ersten Bedarf
   geprüft" für dich in Ordnung, inklusive der `dap.nvim`-Meldung beim Start?
4. **Menü-Prewarm.** Statische Integrationsmodule (aufwendiger, sauber) oder
   Prewarm nur bei Idle (schnell, bleibt ein Timer)?
5. **Experimente, die nur du auslösen kannst:** Defender-/EDR-Ausnahme für
   `%LOCALAPPDATA%\nvim-data` und `B:\repos` (Systemeinstellung), Neovim 0.12 als
   Gegenprobe zu F2.

---

## 10. Anhang

### Reproduktion

```bash
# alle Sonden, Bericht nach $TEMP/startup-probe.txt
nvim --headless --cmd "luafile scripts/startup-probe/probe.lua"

# gezielt, mit anderem Ausgabeort
PROBE=exe,rtp PROBE_OUT=/tmp/exe.txt nvim --headless --cmd "luafile scripts/startup-probe/probe.lua"
```

### Rohwerte (Auszug)

| Messung | Wert |
| --- | --- |
| `vim.loader` an / aus (je 4 Läufe „Config loaded") | 914–977 ms / 1880–4180 ms |
| `LazyDone` / `VimEnter` | ≈ 390 ms / ≈ 890 ms |
| `exepath`, 15 Fehlversuche | 36–54 ms je |
| Phasen | `my` 85, `autocmds` 8, `lsp` 390, `usrcmds` 10, `mappings` 17, `ui_statusline` 27 ms |
| Stöße > 60 ms | 486, 423, 335, 84, 71 ms (Σ 1399) |
| `nvim_get_runtime_file("")` | 91 Aufrufe, 573 ms (alle Sonden) / 92 Aufrufe, 558 ms (allein) |
| Module bis 3,5 s | 1619 (exklusive `require`-Zeit 1,9 s, überlappend) |
| Prozesse | 2 (`pwsh` 35–43 ms Spawn, `git status` 9–10 ms) |
| `PATH` / `PATHEXT` | 72 Einträge / 11 Endungen |

### Nicht gemessen

Kalter Start, echtes UI (Paint, `UIEnter`), die andere Maschine (Rolle
`workstation`, dort bremst laut `config/lazy.lua` der EDR jeden `git.exe`-Spawn),
Tipp-Latenz während der Stöße (die Tasten werden vermutlich gepuffert, nicht
verworfen: ungeprüft).
