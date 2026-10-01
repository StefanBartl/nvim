# Startup-Zeit und Config-Optimierung: Analyse und Konzept

## Table of content

  - [Intro](#intro)
  - [1. Kurzfassung](#1-kurzfassung)
  - [2. Korrekturen gegenüber der ersten Fassung](#2-korrekturen-gegenber-der-ersten-fassung)
  - [3. Methode und Grenzen](#3-methode-und-grenzen)
  - [4. Zeitachse](#4-zeitachse)
  - [5. Befunde](#5-befunde)
    - [F1: PATH-Suchen kosten ein Drittel des Starts](#f1-path-suchen-kosten-ein-drittel-des-starts)
    - [F2: `vim.loader` berechnet die `runtimepath`-Liste bei jeder Änderung neu](#f2-vimloader-berechnet-die-runtimepath-liste-bei-jeder-nderung-neu)
    - [F3: Der Menü-Prewarm erzeugt die Stöße](#f3-der-men-prewarm-erzeugt-die-ste)
    - [F4: Die `lsp`-Phase](#f4-die-lsp-phase)
    - [F5: Die `my`-Phase](#f5-die-my-phase)
    - [F6: Eager Plugins, billig statt lazy](#f6-eager-plugins-billig-statt-lazy)
    - [F7: Kleinigkeiten](#f7-kleinigkeiten)
  - [6. Konzept](#6-konzept)
    - [Phase 0: Messbasis und Leitplanke](#phase-0-messbasis-und-leitplanke)
    - [Phase 1: PATH-Suchen (F1, F4, F5), Erwartung −340 ms bis `UIReady`](#phase-1-path-suchen-f1-f4-f5-erwartung-340-ms-bis-uiready)
    - [Phase 2: Menü-Prewarm (F3), Erwartung Stöße −0,6 s](#phase-2-men-prewarm-f3-erwartung-ste-06-s)
    - [Phase 3: `runtimepath`-Neuberechnung (F2), Erwartung −100 bis −300 ms](#phase-3-runtimepath-neuberechnung-f2-erwartung-100-bis-300-ms)
    - [Phase 4: Eager Plugins verschlanken (F6, F7), Erwartung −80 bis −130 ms](#phase-4-eager-plugins-verschlanken-f6-f7-erwartung-80-bis-130-ms)
    - [Phase 5: Config-Optimierung (nicht Startzeit)](#phase-5-config-optimierung-nicht-startzeit)
  - [7. Erwartung](#7-erwartung)
  - [8. Risiken und Nebenwirkungen](#8-risiken-und-nebenwirkungen)
  - [9. Offene Entscheidungen](#9-offene-entscheidungen)
  - [10. Anhang](#10-anhang)
    - [Reproduktion](#reproduktion)
    - [Rohwerte (Auszug)](#rohwerte-auszug)
    - [Nicht gemessen](#nicht-gemessen)
  - [11. Entscheidungen (2026-09-26)](#11-entscheidungen-2026-09-26)
  - [12. Umsetzungsstand (2026-09-26)](#12-umsetzungsstand-2026-09-26)
    - [Gemessenes Ergebnis](#gemessenes-ergebnis)
    - [Was in welchem Repo passiert ist](#was-in-welchem-repo-passiert-ist)
    - [Abweichungen vom Konzept, und warum](#abweichungen-vom-konzept-und-warum)
    - [Tests](#tests)
    - [Offen](#offen)
  - [13. Fortsetzung (2026-09-26, zweite Runde)](#13-fortsetzung-2026-09-26-zweite-runde)
    - [Review der Commits aus Abschnitt 12](#review-der-commits-aus-abschnitt-12)
    - [Erklärung der 76-ms-Lücke aus Abschnitt 12](#erklrung-der-76-ms-lcke-aus-abschnitt-12)
    - [Abgeschlossen: Rest von Phase 1](#abgeschlossen-rest-von-phase-1)
    - [Korrektur: Phase 2 wie geplant funktioniert nicht](#korrektur-phase-2-wie-geplant-funktioniert-nicht)
    - [Umgesetzt: Phase 2 (Option A)](#umgesetzt-phase-2-option-a)
    - [Phase 3](#phase-3)
    - [Zweiter Review-Durchgang (alle Code-Commits dieser Runde, per Agent)](#zweiter-review-durchgang-alle-code-commits-dieser-runde-per-agent)
  - [14. Nachprüfung der Analyse (2026-10-01)](#14-nachprfung-der-analyse-2026-10-01)
    - [Kurzfassung der Nachprüfung](#kurzfassung-der-nachprfung)
    - [Methodenfehler: headless kennt kein `VeryLazy`](#methodenfehler-headless-kennt-kein-verylazy)
    - [Andere Maschine, anderes Neovim](#andere-maschine-anderes-neovim)
    - [Was von den Schlussfolgerungen hält](#was-von-den-schlussfolgerungen-hlt)
    - [Neue Befunde](#neue-befunde)
    - [Umgesetzt in dieser Runde](#umgesetzt-in-dieser-runde)
    - [Zweiter Schritt: die `VeryLazy`-Welle](#zweiter-schritt-die-verylazy-welle)
    - [Messwerkzeug erweitert](#messwerkzeug-erweitert)
    - [Neue Reihenfolge](#neue-reihenfolge)
    - [Offen für dich](#offen-fr-dich)

---

## Intro
Stand: 2026-09-26 · Rechner `OHANA` (Windows, Rolle `default`) · Neovim 0.11.4 ·
Status: **Analyse und Konzept, keine Änderung an der Config.** Neu angelegt wurde
nur das Messwerkzeug [`scripts/startup-probe/`](../../../scripts/startup-probe/README.md).

**Umsetzungsstand (2026-09-26): Phasen 1 und 2 abgeschlossen. `UIReady` ≈ 0,68 s
(Phase 1), Event-Loop-Stöße nach `VimEnter` von Σ 1209 ms auf Σ ≈ 868 ms (Phase 2).
Phase 3 blockiert weiter auf Gegenproben nur des Nutzers. Siehe Abschnitt 12
(erste Runde) und Abschnitt 13 (Review + Phase-1-Rest + Phase 2).** Die
Abschnitte 1 bis 9 sind die Analyse vor der Umsetzung und bleiben als
Ausgangslage stehen.

**Nachprüfung (2026-10-01, Abschnitt 14): Alle Messungen der Abschnitte 1 bis 13
sind headless entstanden und haben deshalb die Arbeit nach dem ersten Frame zu
zwei Dritteln nicht gesehen (lazy.nvim feuert `VeryLazy` nur mit UI). Mit UI
gemessen lagen die größten Posten woanders: `language.nvim` (1,2 s pro Start)
und lazys Checker (101 git-Prozesse pro Start), beide behoben. Wer nur den
aktuellen Stand braucht, liest Abschnitt 14.**

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

---

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

---

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

---

### F4: Die `lsp`-Phase

390 ms von 488 ms Phasenzeit, synchron (`startup.now("lsp")`). Die Begründung der
Policy (Capabilities global vor dem ersten Attach, Configs registrieren) bleibt
gültig: verschoben werden muss nur die **Auflösung der Executables** (F1), nicht
die Registrierung. Erwartung nach F1: ≈ 40–50 ms.

---

### F5: Die `my`-Phase

85 ms (2026-09-08: 50 ms). Aus dem Traceback: `my/init.lua:173` →
`my/bindings/keymaps.lua:64` → `runtime-analysis/telemetry/registry.lua:203` →
`lib/nvim/bindings/keymap/registry.lua:346` → `which_key.lua:63` lädt **which-key**
(9–17 ms), die Registry ruft außerdem `exepath git` (`run_argv`, Z. 117). Dazu
`powershell`/`win32yank`-Prüfungen (17–20 ms). Maßnahme: which-key nur anfassen,
wenn schon geladen (`package.loaded`, nicht `require`), die Executable-Prüfungen
über den Cache aus F1.

---

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

---

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

---

### Phase 1: PATH-Suchen (F1, F4, F5), Erwartung −340 ms bis `UIReady`

Reihenfolge: (1) `lsp.nvim`: Formatter-`command` und HTML-`cmd` lazy;
(2) `wkddap`: Adapter-Verfügbarkeit erst bei Debug-Start, die Meldung
`12/13 adapters unavailable` nur noch dann; (3) `lib.nvim.cross.executable` als
zentraler, invalidierbarer PATH-Index; (4) `my.nvim`: which-key nur bei
vorhandenem Plugin, Executable-Prüfungen aus dem Cache.

---

### Phase 2: Menü-Prewarm (F3), Erwartung Stöße −0,6 s

Menü-Integrationen statisch (nur Beschreibungen beim `require`), Prewarm
anschließend abschaffen oder auf echtes Idle umstellen. Danach die Policy um die
Regel erweitern: **kein Plugin lädt beim Startup weitere Plugins per
Wall-Clock-Timer**.

---

### Phase 3: `runtimepath`-Neuberechnung (F2), Erwartung −100 bis −300 ms

Erst Ursache klären (Experimente: Defender-Ausnahme für `nvim-data` und
`B:\repos`, Neovim 0.12 gegenprüfen, Anzahl der Plugin-Loads in der zweiten
Welle), dann entscheiden. Kein Umbau auf Verdacht.

---

### Phase 4: Eager Plugins verschlanken (F6, F7), Erwartung −80 bis −130 ms

Usercmd-Registrierung ohne schwere `require`s, in den betroffenen Plugin-Repos;
NvChad-Probe und `gitsigns`-Autocmd; `runtime-analysis`-Kosten messen.

---

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

---

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

---

### Nicht gemessen

Kalter Start, echtes UI (Paint, `UIEnter`), die andere Maschine (Rolle
`workstation`, dort bremst laut `config/lazy.lua` der EDR jeden `git.exe`-Spawn),
Tipp-Latenz während der Stöße (die Tasten werden vermutlich gepuffert, nicht
verworfen: ungeprüft).

---

## 11. Entscheidungen (2026-09-26)

Die fünf offenen Punkte aus Abschnitt 9, einzeln besprochen und entschieden:

| # | Frage | Entscheidung |
| --- | --- | --- |
| 1 | Ziel | **Beides, gestuft:** erst Phase 0 und 1, dann neu messen und über Phase 2 und 3 entscheiden |
| 2 | Repos | **Alle fünf** für Phase 0 und 1: `nvim-config`, `lib.nvim`, `lsp.nvim`, `wkddap`, `my.nvim`; jeweils eigener Commit und Push im `main`, ohne Co-Author; Reihenfolge `lib.nvim` → `lsp.nvim`/`wkddap`/`my.nvim` → `nvim-config`, Messung nach jedem Schritt |
| 3 | Executables | **Lazy plus Index als Absicherung:** Auflösung beim ersten Bedarf, zusätzlich zentraler PATH-Index in `lib.nvim.cross.executable` mit `clear()` bei Mason-Installationen; die `dap.nvim`-Meldung erscheint nur noch bei `:checkhealth` oder beim Debug-Start |
| 4 | Menü-Prewarm | **D:** vorerst unverändert; nach Phase 1 neu messen, dann B (Prewarm nur bei Idle) oder A (statische Menü-Integrationen) |
| 5 | Gegenproben zu F2 | **Beide:** Neovim 0.12 parallel testen und Defender/EDR-Ausnahme testweise; beides löst der Nutzer aus, gemessen wird mit `startup-probe` (`PROBE=rtp,fs,marks`) |

Offen bleibt Phase 3 (F2), bis die Gegenproben vorliegen. Umsetzungsstand:
siehe die Commits in den genannten Repos.

---

## 12. Umsetzungsstand (2026-09-26)

Nach den Entscheidungen aus Abschnitt 11 umgesetzt: Phase 1 in `lib.nvim`, `lsp.nvim`
und `dap.nvim`, dazu die which-key-Kette. **Nicht angefasst:** Phase 0 in
`nvim-config` (Marken, Stall-Detektor, Budget, Metrik, Doku-Verweise), der Rest von F5
in `my.nvim` (`powershell`/`win32yank`), F6, F7 (`gitsigns`), Phasen 2 und 3.

---

### Gemessenes Ergebnis

Median aus 5 Läufen, mit `startup-probe` (Sonden `exe,stall,report,marks,rtp`,
Overhead inklusive), Zeiten in ms seit Beginn von `init.lua`. Ausgangswerte aus
Abschnitt 4 und 5.

| Größe | vorher | jetzt | Änderung |
| --- | ---: | ---: | ---: |
| `lsp`-Phase | 390 | **76** | −314 |
| `my`-Phase | 85 | **57** | −28 |
| `LazyDone` | ≈ 390 | 396 | unverändert |
| `VimEnter` | ≈ 890 | **583** | −307 |
| `UIReady` (`usrcmds` / `mappings` / `ui_statusline`) | 1049 / 1059 / 1076 | **677 / 688 / 703** | ≈ −370 |
| `exepath`/`executable` | 790 ms in 24 Aufrufen, 15 ohne Treffer | **166 ms in 9 Aufrufen, 2 ohne Treffer** | −624 ms |
| Event-Loop-Stöße > 60 ms nach `VimEnter` | 5, Σ 1399, größter 486 | 5, Σ 1209, größter 461 | −190 ms |
| `nvim_get_runtime_file("")` | 91 Aufrufe, ≈ 560 ms | 91 Aufrufe, 545 ms | unverändert |

**Das Ziel für `UIReady` (< 700 ms) ist erreicht, knapp.** Die Stöße nach dem ersten
Frame sind kaum kleiner geworden: `wkddap.integrations.menu` schrumpfte von ≈ 486 auf
≈ 235 ms, aber `filetree` (≈ 400–450 ms, `runtimepath`-Neuberechnung) und der dritte
Stoß (≈ 320 ms) blieben. Das bestätigt Entscheidung 4 (Prewarm nach Phase 1 neu
bewerten) und rückt Phase 2 und 3 nach vorn: die Stöße hängen jetzt fast nur noch an
F2 und an den Menü-Modulen.

---

### Was in welchem Repo passiert ist

| Repo | Commit | Inhalt |
| --- | --- | --- |
| `lib.nvim` | `c35c8ca`, `78d2c9b`, `4845fbf` | `cross.executable.index`: `$PATH`-Index für native Windows; `clear(name)` umgeht ihn, `warm()` baut ihn vorab |
| `lib.nvim` | `644d732`, `8a557de` | which-key-Labels laden which-key nicht mehr (`require`), sie werden bis zum Laden gepuffert; `when_loaded(fn)` für Aufrufer mit eigenem Weg |
| `lsp.nvim` | `8246a37` | Formatter-`command` als Funktion, HTML-`cmd` als Funktion, NvChad-Probe nur einmal |
| `lsp.nvim` | `f043bd5` | which-key-Labels über `when_loaded` statt `require` |
| `dap.nvim` | `4bbc963` | keine Startmeldung mehr für nicht installierte Adapter; `adapters.unavailable` und `:checkhealth wkddap` |
| `nvim-config` | `90823a5f`, `3023b4d4` | `startup-probe`, dieser Bericht |

---

### Abweichungen vom Konzept, und warum

1. **Index-Strategie geändert.** Geplant war ein Hintergrund-Index ab dem dritten
   nativen Lookup. Beim Lesen von `wkddap` fiel auf, dass `register_all` **synchron**
   über alle Sprachen läuft: ein Hintergrundaufbau braucht Event-Loop-Ticks und kann
   in so einer Schleife nie fertig werden. Jetzt wird die Zeit in nativen Lookups
   aufsummiert, und bei **60 ms** (etwa der Preis des Index, 27–65 ms) wird er
   **synchron** gebaut. Damit zahlen native Lookups nie viel mehr als der Index
   gekostet hätte. `warm()` bleibt für den Hintergrundaufbau.
2. **Index gegen `vim.fn` geprüft.** 379 von 380 Namen einer echten `$PATH`
   stimmen überein. Nötig war die Regel, dass ein **exakter Dateiname** (auch ohne
   `.exe`, z. B. das Shell-Skript `npm` neben `npm.cmd`) als ausführbar zählt und die
   `$PATHEXT`-Erweiterung im selben Verzeichnis schlägt. Die eine Abweichung geht
   zugunsten des Index: Windows-Store-App-Aliase (`pwsh` aus dem Store) kann
   `vim.fn` wegen EACCES nicht sehen, der Index findet sie.
3. **Neuer Fund bei `conform`.** `conform` ruft bei **jedem** Format-Aufruf
   `vim.fn.executable(command)` auf. Bei einem fehlenden Formatter mit bloßem Namen
   (`prettierd` steht in fünf Ketten vor `prettier`) ist das jedes Mal die volle
   PATH-Suche, ≈ 40 ms pro Speichern. Ein nicht installiertes Tool antwortet jetzt mit
   dem **absoluten Mason-Pfad**: eine `stat`-Abfrage, und eine spätere
   Mason-Installation wird dort gefunden.
4. **`dap.nvim` nur teilweise lazy.** Entscheidung 3 verlangte Auflösung beim ersten
   Bedarf. Umgesetzt ist: keine Startmeldung, und die Auflösung selbst kostet dank
   Index ≈ 80 ms statt ≈ 360 ms. Die **Registrierung** der Sprachen bleibt beim
   Laden des Plugins, weil sie an jedem der zehn Sprachmodule hängt (`setup()` und
   `load()` lesen den Adapterpfad). Ein vollständiges Lazy-Registrieren wäre ein
   Umbau von `dap.nvim` und bringt nach der Neumessung noch ≈ 100 ms; ich habe ihn
   **nicht** gemacht.
5. **Ein Fehlgriff, korrigiert.** Ein Commit in `lib.nvim` (`78d2c9b`) ist mit einem
   zeitabhängigen Test gepusht worden, der im Ganzlauf scheiterte; die Prüfung des
   Exit-Codes war maskiert. `4845fbf` ersetzt ihn durch eine kontrollierte Uhr.
   Seitdem laufen die Suiten mit Exit-Code-Prüfung, bevor committet wird.

---

### Tests

| Repo | Suite | Ergebnis |
| --- | --- | --- |
| `lib.nvim` | `TESTS/run.lua` (58 Specs, neu: `cross_executable_spec`, `which_key_spec`) | `LIB_TESTS_OK` |
| `lsp.nvim` | plenary-Verzeichnislauf | 1123 Erfolge (vorher 1111), derselbe einzige Fehler wie vor den Änderungen (`usercmds stop force-stops a server that never answers shutdown`, unabhängig) |
| `dap.nvim` | plenary-Verzeichnislauf | 283 Erfolge (vorher 280), keine Fehler |

---

### Offen

| Punkt | Stand |
| --- | --- |
| Phase 0 in `nvim-config` | nicht begonnen |
| F5-Rest in `my.nvim` | `powershell`-, `win32yank`-Prüfung noch direkt über `vim.fn` (17–20 ms) |
| which-key wird noch geladen | zwei Auslöser behoben (`lib.nvim`, `lsp.nvim`). Ein dritter liegt in der Config: `lua/config/neotest/whichkey/init.lua:8` lädt which-key, sobald neotest lädt (über den Menü-Prewarm). Gleiches Muster, gleiche Lösung (`when_loaded`) |
| F6, F7 | unberührt (`usrcmds`-Registrierungen, `gitsigns`-`require` im Autocmd) |
| Phase 2 und 3 | jetzt der größte verbleibende Hebel: Stöße Σ ≈ 1,2 s, `runtimepath`-Neuberechnung ≈ 545 ms |
| Gegenproben zu F2 | Neovim 0.12 und Defender-Ausnahme: warten auf dich |
| Dokumentation `startup.md` | noch nicht nachgezogen (Regeln zu PATH-Suchen und Menü-Prewarm) |

---

## 13. Fortsetzung (2026-09-26, zweite Runde)

### Review der Commits aus Abschnitt 12

Vor der Weiterarbeit alle in Abschnitt 12 gelisteten Commits auf Bugs, Sicherheit
und Performance geprüft. Zwei echte Bugs gefunden, beide behoben:

- **`lib.nvim`** (`TESTS/cross_executable_spec.lua`, `TESTS/which_key_spec.lua`,
  neu in `c35c8ca`/`644d732`): beide Spezifikationen sind flache Skripte (kein
  `describe`/`it`), die globalen Zustand patchen (`PATH`/`PATHEXT`,
  `vim.fn.executable`/`exepath`, `vim.uv.hrtime`,
  `package.loaded`/`preload["which-key"]`) und ihn erst am Dateiende
  wiederherstellen. Ein fehlschlagender Assert irgendwo dazwischen hätte die
  Wiederherstellung übersprungen und den kaputten Zustand in **alle 58 Specs
  des gemeinsamen Laufs** durchgereicht — exakt die Falle, vor der
  `H.with_patched`s eigener Kommentar warnt, hier aber nicht angewendet. Fix:
  beide Testkörper laufen jetzt in einem `pcall`, die Wiederherstellung läuft
  garantiert, ein echter Fehler wird weitergereicht. Commit `2caec3c`.
- **`lsp.nvim`** (`TESTS/lsp/bindings_actions_spec.lua`, neu in `f043bd5`):
  derselbe Fehlertyp, kleiner — `package.preload["which-key"]` wurde nur am
  Ende des einzelnen `it()`-Blocks zurückgesetzt statt im ohnehin vorhandenen
  `after_each`. Verschoben. Commit `0512e6d`.

Keine Sicherheitsbefunde. Der synchrone Index-Build bei 60 ms Breakeven
(`78d2c9b`, Abweichung 1 in Abschnitt 12) wurde geprüft, aber nicht verändert —
das ist eine begründete, dokumentierte Abwägung, kein Defekt. Beide Fixes
lint- und testgrün (`lib.nvim`: `LIB_TESTS_OK`; `lsp.nvim`: 1123 Erfolge, nur
der bekannte unabhängige Fehler).

---

### Erklärung der 76-ms-Lücke aus Abschnitt 12

Die `lsp`-Phase landete bei 76 ms statt der in Abschnitt 7 geschätzten 40–50 ms.
Ursache: `executable.warm()` wird **nirgends** aufgerufen (geprüft in
`lsp.nvim`, `dap.nvim`, `my.nvim`, der Config) — der einmalige synchrone
Index-Build (~60–65 ms) fällt also zwangsläufig in die `lsp`-Phase, weil deren
Formatter-/HTML-Lookups die ersten sind, die die 60-ms-Schwelle reißen.

Geprüft, ob ein früher `warm()`-Aufruf das verschieben könnte: **nein.** `my`,
`autocmds` und `lsp` laufen alle synchron innerhalb eines einzigen
`init.lua`-Durchlaufs vor `VimEnter`, ohne dass die Event-Loop dazwischen
`vim.schedule()`-Callbacks abarbeitet — exakt der Grund, warum `78d2c9b` den
Index synchron statt im Hintergrund baut. Ein `warm()`-Aufruf am Anfang von
`init.lua` hätte keine Gelegenheit, seine Ticks vor der `lsp`-Phase
abzuarbeiten. Die 76 ms sind also kein Fehler und keine Regression, sondern
reine Buchhaltung: welche Phase die Indexkosten trägt, ändert `UIReady` nicht.
Kein Handlungsbedarf.

---

### Abgeschlossen: Rest von Phase 1

- **Dritter which-key-Auslöser** (`lua/config/neotest/whichkey/init.lua`):
  behoben, aber anders als angenommen. Neun der zehn `wk.add()`-Einträge waren
  reine Duplikate der Keymaps aus `config/neotest/keymaps/init.lua` (dort
  bereits über den einfachen `vim.keymap.set`-Wrapper gesetzt, ohne
  which-key-Anbindung); die Datei hatte nur einen eigenständigen Zweck, das
  Gruppenlabel `<leader>nt`. Auf `lib.nvim`s `add_group()` reduziert — fixt den
  eager-Load und entfernt die Redundanz in einem Schritt. Commit `92a618b0`
  (nvim-config).
- **Stale Doku-Pfade**: die drei aus Abschnitt 6 bekannten
  (`lua/startup/init.lua:11,122`, `lua/startup/report.lua`) plus ein vierter,
  bisher nicht erfasster (`init.lua:96`, Kommentar über den Startup-Phasen).
  Alle vier auf `docs/NOTES/ARCHITECTURE/startup.md` korrigiert. Commit
  `92a618b0`.
- **F5-Rest in `my.nvim`**: `shell.lua`/`clipboard.lua` nutzen jetzt
  `lib.nvim.cross.executable` statt rohem `vim.fn.executable`. Commit `8683320`
  (my.nvim). Nebeneffekt: der Neovim-<0.10-Fallback für `pwsh` findet jetzt
  auch eine Windows-Store-Installation, die `vim.fn` wegen EACCES nicht sehen
  kann. **Erwarteter Laufzeitgewinn in diesem Umlauf gering bis null:** alle
  fünf betroffenen Namen (`powershell`, `pwsh`, `zsh`, `wl-copy`/`wl-paste`,
  `win32yank`) sind laut Abschnitt 5 bereits Treffer (0 Fehlversuche), und jeder
  wird nur einmal pro Session geprüft — der Index hilft vor allem bei
  Wiederholung (z. B. `:checkhealth`), nicht beim einzigen Aufruf einer
  Session. Der Wert liegt in Konsistenz, nicht in gemessener Zeit.

---

### Korrektur: Phase 2 wie geplant funktioniert nicht

Vor der Umsetzung von Phase 2 wurde die Architektur von `ui.nvim`s
Menü-Prewarm und der vier betroffenen Module geprüft
(`wkddap`/`dap.nvim`, `filetree.nvim`, `gitsuite.nvim`, `gopath.nvim`).
Ergebnis: **die im Konzept (Abschnitt 6, Phase 2b) angenommene Ursache stimmt
nicht.**

Alle vier `integrations/menu.lua`-Module sind bereits "statisch" im gewünschten
Sinn: kein schweres `require` am Dateikopf, Label und Aktion sauber getrennt,
das eigentliche Plugin wird erst in der Klick-Closure requiret. Der
tatsächliche Mechanismus ist ein anderer: **lazy.nvims globaler
`package.loaders`-Hook** (`lazy/core/loader.lua:531–568`) lädt beim `require()`
JEDER Datei unterhalb eines noch nicht geladenen Plugin-Verzeichnisses
automatisch das GANZE Plugin samt `dependencies` — unabhängig vom Inhalt der
konkret angeforderten Datei. `ui.nvim`s eigenes README dokumentiert das exakt
so ("requiring it loads the whole plugin"), und der Prewarm existiert genau
deswegen.

Konkret: `wkddap.integrations.menu` hat **keinen** `event`-Trigger in der
Plugin-Spec (nur `cmd = "Dap"` + `keys`), ist also im Prewarm-Slot
(~`VimEnter`+320 ms) so gut wie nie schon geladen — der Prewarm-`require`
zwingt lazy.nvim, `dap.nvim` und alle sechs `dependencies` vollständig zu
laden. Das ist mit hoher Sicherheit der Hauptverursacher des 400–500-ms-Stoßes.
`gitsuite.nvim` ist ein sekundärer, startup-abhängiger Kandidat (nur wenn kein
Datei-Argument übergeben wird, sonst lädt `BufReadPost` es vorher).
`filetree.nvim`/`gopath.nvim` haben `event = "VeryLazy"` und sind vermutlich
meist schon geladen, bevor der Prewarm sie anfasst (Annahme, nicht mit
Zeitstempeln verifiziert).

**Nebenbefund.** Der Kommentar in `plugins/personal/init.lua:1151–1152`
("lazy.nvim has no 'load on require()' trigger") ist nach Prüfung des
lazy.nvim-Quellcodes nicht korrekt — der Hook existiert und greift bei jedem
Plugin ohne `module = false`. Sollte richtiggestellt werden, damit künftige
Analysen nicht wieder in dieselbe falsche Richtung laufen.

**Konsequenz.** "Menü-Integrationsmodule statisch machen" bringt nichts, weil
das Problem nicht im Dateiinhalt liegt. Es bleiben drei Optionen:

- **A.** Menü-Metadaten (Label, Icon, Kommando-Referenz) für `wkddap` und
  `gitsuite` nicht mehr per `require()` aus dem jeweiligen Plugin holen,
  sondern direkt in `ui.nvim`s `contributors.lua` hinterlegen — dort gibt es
  mit den `filetree`/`gitsuite`-Sonderfällen bereits Präzedenz für
  plugin-spezifisches Wissen. Der schwere `require` bleibt exakt dort, wo er
  schon ist: in der Klick-Closure. Prewarm bräuchte für diese Einträge dann gar
  kein `require()` mehr.
- **B.** `wkddap`/`gitsuite` aus dem Prewarm-Kandidatenset ausschließen (z. B.
  über `applies`/`ft` in `prewarm_modules()`). Kleinster Eingriff, ein Repo
  (`ui.nvim`), aber das DAP-Untermenü fehlt dann bis zum ersten echten
  `dap.nvim`-Gebrauch.
- **C.** `event = "VeryLazy"` ergänzen — **keine gute Option**: das würde die
  schweren Dependencies wieder bei jedem Start eager laden, das Gegenteil vom
  Zweck des `cmd`/`keys`-Gatings.

Das entscheidet über `ui.nvim`s Kopplung an andere Plugins und über das
Verhalten des DAP-Menüs — mehr, als Entscheidung 4 (Abschnitt 11) ursprünglich
abgedeckt hat. **Entscheidung: A** (Metadaten in `ui.nvim` hinterlegen, siehe
unten).

---

### Umgesetzt: Phase 2 (Option A)

`ui.nvim`s `Ui.Menu.ContributorSpec` bekommt ein neues optionales Feld `lazy =
{ label, plugin? }`. Ein so markierter Contributor wird nicht mehr prewarmt und
nicht mehr eager per `require(module)` + `submenu()` aufgebaut: er erscheint
als ein einziger Eintrag mit dem statischen `label`, dessen Anwesenheit über
lazy.nvims eigene Registry geprüft wird (`require("lazy.core.config").plugins[plugin]`,
ohne zu laden) — erst beim Anklicken wird das echte Plugin requiret und die
echte `submenu()` in einem frischen Popup an der Mausposition geöffnet, statt
inline als Fly-out. Genau dasselbe Muster für `gitsuite`s "Git Actions"-Zeile
in `ui.menu.sections` (dort bisher ungetestet gewesen). Beide aus
`prewarm_modules()` entfernt — nichts mehr, was dort vorzuladen wäre. Commit
`5102712` (ui.nvim), inklusive vier neuer Tests für den `lazy`-Mechanismus und
Korrektur der beiden bestehenden Prewarm-Assertions. Volle Suite: 63/63 in
`menu_spec.lua`, gesamte `ui.nvim`-Suite grün.

**UX-Änderung, bewusst in Kauf genommen:** `ui.kit.menu` kennt kein
Hover-Fly-out für nachträglich geladene Einträge (`items` muss beim Öffnen
schon eine fertige Liste sein, keine Funktion) — ein Klick auf "Debug"/"Git
Actions" öffnet deshalb ein zweites, eigenständiges Popup an der Mausposition,
statt dass sich das bestehende Menü seitlich erweitert. Nicht live mit der Maus
geprüft (nur die Datenseite über die Testsuite); bei Bedarf gegenprüfen.

**Gemessene Wirkung** (`startup-probe`, `PROBE=exe,stall,report,marks,rtp`, 3
Läufe; Lauf 1 verworfen als Kaltstart-Ausreißer nach dem Commit, 5770 ms
Gesamt-Stall gegenüber ~870 ms in Lauf 2/3 — siehe Abschnitt 8 zu
kalt/warm-Streuung):

| Größe | vorher (Abschnitt 12) | jetzt (Median Lauf 2/3) |
| --- | ---: | ---: |
| Event-Loop-Stöße > 60 ms | 5, Σ 1209 ms, größter 461 ms | **4, Σ ≈ 868 ms, größter ≈ 384 ms** |
| `nvim_get_runtime_file("")` | 91 Aufrufe, 545 ms | 81 Aufrufe, ≈ 411 ms |

Der größte verbleibende Stoß (≈ 384 ms) passt zur `filetree`-Neuberechnung
(F2/Phase 3, unverändert); ein zweiter (≈ 331–337 ms) zur dritten Gruppe
(`gitsuite`-Restplugins/`emojis`/`fzf-lua`/`trouble`/`color_my_ascii`, die
weiterhin regulär prewarmt werden). Der `wkddap`-Stoß aus Abschnitt 12
(≈ 235 ms nach Phase 1) taucht in keinem der drei Läufe mehr auf. Die
`nvim_get_runtime_file`-Kosten sind trotz unveränderter Ursache mitgesunken,
vermutlich weil insgesamt weniger Plugins beim Prewarm laden (jede
Laderunde ändert `runtimepath` und damit die zu invalidierende Liste).

---

### Phase 3

Unverändert blockiert auf die beiden Gegenproben, die nur der Nutzer auslösen
kann (Neovim 0.12, Defender-Ausnahme für `%LOCALAPPDATA%\nvim-data` und
`B:\repos`). Kein Umbau auf Verdacht (Abschnitt 6).

---

### Zweiter Review-Durchgang (alle Code-Commits dieser Runde, per Agent)

Jeder Code-Commit aus Phase 1 und 2 einzeln von einem eigenen Review-Agenten
geprüft (sequenziell, nie parallel). Drei weitere, kleinere Funde, alle sofort
behoben:

- **`lib.nvim` (`5683bfe`):** `registry.forget()` räumt laut eigener Doku nur
  direkte `set()`-Records auf, nicht `registry.register()`-Einträge — der
  Testabschluss in `which_key_spec.lua` verließ sich fälschlich darauf, ließ
  `"wk_queue_probe"` in `registry.registered()` zurück. Über die dokumentierte
  Methode (`register()` erneut, leer) korrigiert.
- **`lsp.nvim` (`117b121`):** dieselbe Bugklasse wie in Abschnitt 13 oben,
  in derselben Datei, aber unabhängig vom which-key-Fix: `capture_notify()`s
  `restore()` lief in einem anderen Test erst NACH einer Schleife mit
  Asserts — ein fehlschlagender Assert hätte den Notify-Capture-Stub in den
  Rest des gemeinsamen Laufs durchgereicht. Gleiches `pcall`-Muster angewendet.
- **`ui.nvim` (`19087e5`):** zwei Funde im Phase-2-Commit selbst. (1) Ein
  `lazy`-Eintrag ("Debug"/"Git Actions") erschien unabhängig davon, ob das
  Plugin sich selbst per `enabled() == false` abgeschaltet hatte — brach den
  dokumentierten Opt-out-Vertrag, ein Klick tat dann still nichts. Das lässt
  sich nicht vorab prüfen, ohne genau den `require` zu bezahlen, den `lazy`
  vermeiden soll; ein Klick, der ins Leere läuft, sagt das jetzt (`notify.warn`)
  statt zu schweigen. (2) Das nachträglich geöffnete Popup öffnete immer mit
  `mouse = true`, unabhängig davon, ob das Menü selbst per Maus oder per
  `key`-Bindung am Cursor geöffnet wurde — bei reiner Tastaturnutzung konnte
  das Popup an einer veralteten Mausposition erscheinen. `mouse` wird jetzt von
  `M.open()`/`M.warm()` durch `M.items()` bis zur Klick-Closure gereicht.
  Zwei neue Tests, volle Suite weiterhin grün (65/65 in `menu_spec.lua`).

`nvim-config` (`92a618b0`) und `my.nvim` (`8683320`) ohne Befund.

---

## 14. Nachprüfung der Analyse (2026-10-01)

Rechner `STEVESPC` (Windows, Rolle `default`) · Neovim 0.12.2 · Auftrag: prüfen,
ob die Schlussfolgerungen der Abschnitte 1 bis 13 tragen, und ob etwas übersehen
wurde.

---

### Kurzfassung der Nachprüfung

1. **Die Messmethode hatte ein Loch.** Alle bisherigen Läufe waren headless. Ein
   Headless-Neovim bekommt kein `UIEnter`, lazy.nvim feuert `VeryLazy` deshalb
   nie: 15 Plugins laden nicht, lazys Checker startet nicht. Der Report hat
   damit **zwei Drittel der Arbeit nach dem ersten Frame nicht gesehen**
   (Stöße mit UI: Σ 2538 ms, headless: Σ 562 ms).
2. **Die beiden größten Posten standen nicht im Report.** `language.nvim`
   fror die UI bei jedem Start 1,2 s ein (ein `:spellgood!` pro Wort), und lazys
   Checker startete bei jedem Start 101 git-Prozesse (1,4 s Hauptthread). Beide
   behoben.
3. **Eine Schlussfolgerung war ein Artefakt.** Der „`filetree`-Stoß durch den
   Menü-Prewarm" (Abschnitte 4, 12, 13) existiert nur headless. Mit UI ist
   `filetree` zu dem Zeitpunkt längst per `VeryLazy` geladen.
4. **Der Rest hält.** F1 (PATH-Suchen), F2 (Mechanismus), F4, F5, die
   Telemetrie-Einschätzung und Phase 1 sind bestätigt.
5. **Die Zahlen sind nicht vergleichbar.** Abschnitte 1 bis 13 stammen von
   `OHANA` mit Neovim 0.11.4, diese Runde von `STEVESPC` mit 0.12.2.

| Größe (Median aus 5 Läufen, mit UI) | vor dieser Runde | nach `language.nvim` | plus Checker nur bei Fälligkeit |
| --- | ---: | ---: | ---: |
| Stöße > 60 ms, Summe | 2538 ms | 1522 ms | **1086 ms** |
| längster Stoß | 1131 ms | 560 ms | 662 ms |
| Event-Loop belegt in den ersten 6 s | 2993 ms | 2012 ms | **1309 ms** |
| gestartete Prozesse | 106 | 106 | **5** |
| `UIEnter` / letzte `UIReady`-Phase fertig | 413 / 503 ms | 431 / 517 ms | 434 / 521 ms |

„Benutzbar" (Ende des letzten großen Stoßes) war der Editor vorher nach etwa
2,5 s, jetzt nach etwa 1,15 s. Die Marke `UIReady` (≈ 0,5 s) sagt darüber nichts.

---

### Methodenfehler: headless kennt kein `VeryLazy`

`lazy/core/util.lua`, `very_lazy()`: nach `LazyDone` wartet lazy auf `UIEnter`
und feuert `User VeryLazy` erst dann. Ohne UI kommt `UIEnter` nie.

Die Startup-Policy wusste das im Ergebnis („in Headless-Runs feuerte es messbar
gar nicht") und hat deshalb `VeryLazy` aus dem Config-Kern verbannt. Die
Konsequenz für die *Messung* hat niemand gezogen: Abschnitt 3 nennt „kein
`UIEnter`, kein Paint" als Grenze, nicht aber, dass damit die ganze
`VeryLazy`-Ladewelle und alles, was diese Plugins nach dem Laden tun, fehlt.

| | mit UI | headless |
| --- | ---: | ---: |
| geladene Plugins (davon per Event) | 60 (15) | 50 (1) |
| `VeryLazy` | bei ≈ 510 ms | nie |
| Stöße > 60 ms: Anzahl, Summe, längster | 6, 2538 ms, 1131 ms | 4, 562 ms, 229 ms |
| Event-Loop belegt (6 s) | 2993 ms | 873 ms |
| gestartete Prozesse | 106 | 5 |

Gemessen wird jetzt über `scripts/startup-probe/tui.lua`: der geprüfte Neovim
läuft in einem Pseudo-Terminal mit angehängtem TUI, `UIEnter` und `VeryLazy`
feuern wie in einer echten Session.

**Zwei Kommentare im Code beruhten auf demselben Fehler** und sind korrigiert:
`lua/plugins/neotree.lua` („on demand: 29 statt 44 Plugins, ~1050 statt
~1300 ms") und `lua/plugins/personal/specs/edit.lua` („ein paar hundert
`:spellgood!` abseits des Hot-Paths lohnen kein Gating").

---

### Andere Maschine, anderes Neovim

Der Report nennt `OHANA`, Neovim 0.11.4, `B:\repos`. Hier: `STEVESPC`, 0.12.2,
`E:\repos`, 83 `PATH`-Einträge, 16 `PATHEXT`-Endungen. Headless gegen headless:

| Größe | `OHANA` (Abschnitt 13) | `STEVESPC` |
| --- | ---: | ---: |
| `LazyDone` / `VimEnter` | 396 / 583 ms | 224 / 362 ms |
| letzte `UIReady`-Phase fertig | ≈ 703 ms | 469 ms |
| Stöße > 60 ms, Summe | ≈ 868 ms | 562 ms |
| `nvim_get_runtime_file("")` | 81 Aufrufe, ≈ 411 ms | 81 Aufrufe, 197 ms |

Die „Gegenprobe Neovim 0.12" zu F2 (Abschnitt 9, Punkt 5) ist damit **nicht**
erbracht: Version und Maschine haben sich gleichzeitig geändert. Ein Aufruf
kostet hier 2,4 bis 3,1 ms statt ≈ 5 ms; woran das liegt, ist offen. Die
`OHANA`-Zahlen müssen mit `tui.lua` neu gemessen werden, bevor dort über Phase 3
entschieden wird.

---

### Was von den Schlussfolgerungen hält

| Aussage im Report | Befund der Nachprüfung |
| --- | --- |
| F1: PATH-Suchen sind teuer, Fehlversuche am teuersten | **Hält.** Rest hier, mit UI: 12 Aufrufe, ≈ 220–240 ms. Davon `cygpath` ×2 ohne Treffer (≈ 55–60 ms, gitsigns prüft das beim Laden, fremder Code), `git` ×7 mit Treffer (≈ 75–80 ms, `exepath` ×4 und `executable` ×3 von verschiedenen Aufrufern), `nerdctl` ohne Treffer plus `podman`/`docker`/`wsl` (≈ 60–75 ms, `sandbox.nvim` beim Laden). Die Sandbox-Aufrufe waren headless unsichtbar. |
| F2: `vim.loader` berechnet die `runtimepath`-Liste bei jeder Änderung neu | **Mechanismus bestätigt** (Traceback `vim/loader.lua:101 get_rtp` ← `find`). Mit UI 96 Aufrufe, 270–300 ms, verteilt über die `VeryLazy`-Welle. Kosten pro Aufruf hier halb so hoch wie auf `OHANA`. |
| F3 und Abschnitt 13: Stöße kommen vom Menü-Prewarm, der größte ist `filetree` (≈ 400–450 ms) | **Artefakt.** Headless lädt `filetree` nie per `VeryLazy`, also zahlt dort der Prewarm den vollen Plugin-Load. Mit UI ist `filetree` vorher geladen, der Prewarm-`require` kostet nichts. Abschnitt 13 enthielt beide Aussagen nebeneinander (die Annahme „`VeryLazy`-Plugins sind meist schon geladen" und die Messung, die ihr widerspricht), ohne den Widerspruch aufzulösen. Was mit UI vom Prewarm bleibt: der Load von `gitsuite`, `color_my_ascii`, `fzf-lua` u. a. (≈ 100–150 ms) und `M.warm()`, das einmal wirklich ein Float öffnet (≈ 130–250 ms). |
| Phase 2 (Option A) hat den `wkddap`-Stoß beseitigt | **Hält**, unabhängig vom UI: der Prewarm requiret das Modul nicht mehr. |
| „Phase 3 ist der größte verbleibende Hebel" (Abschnitt 12, Offen) | **Hält nicht.** F2 ist ein Teil der `VeryLazy`-Welle, nicht ihr Hauptposten. Größer waren `language.nvim` und der Checker, größer ist jetzt die Zahl der Plugins in der Welle. |
| „`UIReady` < 700 ms: Ziel erreicht" | **Zahl stimmt, Aussage trägt nicht.** Nach `UIReady` kam mit UI ein Stoß von 0,6 s und direkt danach einer von 1,1 bis 2,2 s. Die Metrik, die Abschnitt 6 (Phase 0, Punkt 2) als „wann ist es benutzbar" einführen wollte, beantwortet diese Frage nicht. |
| F4 `lsp`-Phase, F5 `my`-Phase | **Hält.** Hier 54–64 ms bzw. 35–44 ms. |
| F6: `runtime-analysis` ist teuer, „Preis der Telemetrie messen" | **Gemessen, hält als bewusste Entscheidung.** A/B mit abgeschalteter Telemetrie (je 5 Läufe): `LazyDone` −32 ms, nach dem Start kein Unterschied außerhalb des Rauschens. In den Stoß-Stichproben erscheint die Telemetrie mit 170–280 ms, das überschätzt sie: ihre Wrapper liegen oft als innerster Frame auf fremder Arbeit. Das A/B ist die belastbare Zahl. |
| F7: NvChad-Probe, `gitsigns` im Autocmd | **Beides noch offen.** `nvchad.configs.lspconfig` kostet weiter 6–7 ms (ein fehlgeschlagenes `require`), `gitsigns` lädt per `require` bei ≈ 330–380 ms, also vor `VimEnter`. |
| Abschnitt 13: „lazy lädt bei `require` das ganze Plugin" | **Hält**, in der `lazy`-Sonde direkt sichtbar (`require gitsigns`, `require fzf-lua`, `require open.integrations.menu` …). |

---

### Neue Befunde

**N1: `language.nvim` fror die UI bei jedem Start 1,2 s ein.** `programming_dict`
und `extra_wordlists` riefen für jedes Wort ein `:spellgood!` auf, alle in einem
`vim.schedule`-Callback. `:spellgood!` hängt das Wort an Neovims interne Wortliste
(eine Temp-Datei) und **kompiliert danach die ganze Liste neu**. 310 Wörter (187
mitgelieferte, 123 aus `casedesk.spell_wordlists`) sind 310 Kompilierläufe:
gemessen 1193 ms isoliert, 1282 ms im Start. Dieselben Wörter in einem Lauf:
3,9 ms. Der Kommentar an der Spec hielt das für billig.

**N2: lazys Checker startete bei jedem Start 101 Prozesse.** `frequency` bremst
nur den `fetch`. Ist der nicht fällig, ruft `checker.start()` trotzdem
`Manage.log({ check = true })`: ein `git log` pro Remote-Plugin, hier 92, dazu 9×
`git show-ref` aus `fast_check()`. Ein `uv.spawn` kostet unter Windows ≈ 14 ms
Hauptthread: **1375 ms** allein fürs Spawnen, ab etwa 3 s nach dem Start. Keiner
davon ist für sich ein Stoß > 60 ms, zusammen machen sie den Editor über eine
Sekunde zäh. Die Notiz `lazynvim-checker-git-fetch-storm.md` kennt den
Fetch-Sturm, nicht diesen täglichen Teil. Gelesen wird die Liste zwischen zwei
Checks von niemandem (`notify = false`, keine Statusline-Komponente).

**N3: Die `VeryLazy`-Welle ist ein Stoß von ≈ 600 ms.** Alle Plugins auf
`VeryLazy` laden in einem Callback direkt nach dem ersten Frame. Ladezeiten
(inklusive Dependencies, überlappend):

| Plugin | ms | Bemerkung |
| --- | ---: | --- |
| `filetree.nvim` | 281–294 | enthält `neo-tree` (166–173) und darin `neotest` (146–151) als Dependency |
| `sandbox.nvim` | 109–130 | lädt die Docker-Adapter, prüft vier Engines im `PATH`, registriert Hover |
| `gopath.nvim` | 70–77 | |
| `language.nvim` | 31–38 | davon `trouble.nvim` als Dependency 23–33 |
| `spotlight`, `cascade`, `media`, `noice` | je 11–22 | |
| `debugging`, `fileops` | je 12–14 | |

`neo-tree` steht auf `cmd = "Neotree"`, damit es eben nicht bei jedem Start lädt.
`filetree.nvim` führt es als Dependency und steht auf `VeryLazy`: die Kette
`neo-tree` → `neotest` → Adapter lädt trotzdem bei jedem Start.

**N4: Der Menü-Warmup öffnet einmal wirklich ein Fenster.** `ui.menu` `M.warm()`
öffnet und schließt das Kontextmenü unsichtbar, damit der erste Rechtsklick nicht
zahlt: 130–250 ms an einem Stück (`nvim_open_win` samt der Autocmds, die das
erste Float auslöst; `ui.kit.theme.materialize` einmal 125 ms). Bewusste
Abwägung des Plugins, kein Fehler, aber sichtbar.

**N5: Stoß und Belegung sind zweierlei.** Die bisherige Stoß-Metrik (Lücken
> 60 ms) hat N2 systematisch übersehen. Die Sonde zählt jetzt zusätzlich alle
Lücken über dem Timer-Rauschen, summiert pro Sekunde.

**N6: Die Keymap-Reihenfolge stand falsch herum im Code.** Der Kommentar in
`lua/bindings/mappings/init.lua` behauptete, die `mappings`-Phase (`UIReady`)
laufe *nach* den Plugins auf `VeryLazy`, ein dort gemapptes Key gewinne also.
Mit UI ist es umgekehrt: `UIReady` ist `VimEnter` + `vim.schedule`, `VeryLazy`
ist `UIEnter` + `vim.schedule`, und `UIEnter` kommt nach `VimEnter`. Gemessen:
`mappings` bei ≈ 505 ms, `VeryLazy` bei ≈ 550 ms. **Ein Plugin auf `VeryLazy`
überschreibt also ein gleichnamiges Config-Mapping, nicht umgekehrt.** Headless
gab es nie ein `VeryLazy`, das dem widersprochen hätte. Kommentar korrigiert;
`Keymaps-Collisions.md` in den WKDBooks sollte gegen diese Reihenfolge geprüft
werden.

---

### Umgesetzt in dieser Runde

| Repo | Commit | Inhalt |
| --- | --- | --- |
| `language.nvim` | `ad355be` | neues `spell/session_words.lua`: erstes Wort per `:spellgood!` (legt die Listendatei an), die mittleren direkt in die Datei, letztes Wort per `:spellgood!` (kompiliert alles in einem Zug). Die Datei wird an dem erkannt, was der erste Befehl hinterlassen haben muss, und an dem bestätigt, was der letzte hinterlassen haben muss; schlägt eine Prüfung fehl, gehen die Wörter einzeln durch, in 8-ms-Scheiben statt in einem Callback. Semantik unverändert (wie `zG`). Tests: 300 Wörter kosten ≤ 2 Befehle, Fallback, falsche Datei, ungültige Einträge. Suite grün (`LANGUAGE_TESTS_OK`). |
| `nvim-config` | `a6d0f455` | `lua/config/lazy/init.lua`: Checker nur in der Session, in der der wöchentliche Check fällig ist (aus lazys `state.json` gelesen). `scripts/startup-probe/`: siehe unten. Kommentare in `neotree.lua` und `specs/edit.lua` korrigiert. `docs/NOTES/ARCHITECTURE/startup.md`: `VeryLazy`-Erklärung richtiggestellt, Regeln „`VeryLazy` ist ein Stapel" und „Headless ist kein Start". |

Wirkung: Tabelle in der Kurzfassung oben.

**Nebenwirkung der Checker-Änderung:** In den Sessions zwischen zwei Checks
zeigt `:Lazy` keine anstehenden Updates, bis dort `C` gedrückt wird. In der
Session, in der der Check fällig ist, läuft alles wie bisher.

---

### Zweiter Schritt: die `VeryLazy`-Welle

Nach den beiden großen Posten war die Welle (N3) der längste Stoß. Zwei
Plugins sind aus ihr heraus, ohne dass sich an ihrer Bedienung etwas ändert:

| Änderung (`nvim-config`) | Vorher | Jetzt |
| --- | --- | --- |
| `neotest` | Dependency von `neo-tree`, lud mit `filetree.nvim` bei jedem Start (≈ 150 ms mit Adaptern, `vim-test`, `nio`) | eigene Auslöser: die 12 `:Neotest*`-Kommandos, die `<leader>nt*`-Tasten als lazy-Stubs (aus derselben Liste wie die echten Mappings), Testdateien (`*_spec.lua`, `*.test.ts` …, die Muster aus `config.neotest.core`), und die `tests`-Quelle von neo-tree |
| `sandbox.nvim` | `event = "VeryLazy"` (≈ 110 ms: sechs Engine-Adapter, PATH-Suche nach `nerdctl`/`podman`/`docker`/`wsl`) | `cmd = "Sandbox"` und `ft = dockerfile / yaml` (dort lebt seine Hover-Vorschau); es registriert keine globalen Tasten oder Autocmds |

Zu `neotest`: der Kommentar an der neo-tree-Spec hatte recht, dass das bloße
Streichen der Dependency `:Neotree tests` bricht (die Quelle holt ihre Einträge
über einen neotest-Consumer, der erst nach `neotest.setup()` einen Client hat).
Deshalb lädt `config.neotest.neotree.load_with_tests_source()` neotest
unmittelbar, bevor diese Quelle zum ersten Mal rendert: jeder Weg in die Quelle
endet in deren `navigate`. Das `<leader>nt`-Gruppenlabel registriert jetzt die
`mappings`-Phase, weil es vor dem ersten Tastendruck da sein muss.

Geprüft mit UI, gegen den Worktree als Config: `:Neotree tests` rendert und
lädt neotest; `<leader>nts` lädt neotest und öffnet die Summary; eine
`*_spec.lua` lädt neotest per Event, eine normale Lua-Datei nicht;
`:Sandbox engine get` und ein `Dockerfile` laden `sandbox.nvim`.

| Größe (Median aus 5 Läufen, mit UI) | Beginn der Runde | nach Schritt 1 (N1, N2) | nach Schritt 2 |
| --- | ---: | ---: | ---: |
| Stöße > 60 ms, Summe | 2538 ms | 912 ms | **595 ms** |
| längster Stoß | 1131 ms | 585 ms | **348 ms** |
| Event-Loop belegt in den ersten 6 s | 2993 ms | 1203 ms | **938 ms** |
| geladene Plugins | 60 | 60 | 47 |

(„Nach Schritt 1" ist hier die reale Config nach dem Pull gemessen und liegt
deshalb etwas unter der Tabelle in der Kurzfassung, die den Checker per
`--cmd` eingeschleust hatte.) Benutzbar ist der Editor damit nach etwa 0,9 s
(`VeryLazy` bei ≈ 525 ms plus der Stoß), zu Beginn der Runde waren es ≈ 2,5 s.

Was in der Welle bleibt (≈ 350 ms): `filetree.nvim` mit `neo-tree` (≈ 130–165 ms),
`gopath.nvim` (20–90 ms, schwankt mit der Ladereihenfolge; darin
`truncated/cache.lua` `load_from_disk` ≈ 30 ms), `language.nvim` mit
`trouble.nvim` (≈ 35–45 ms), lazys eigene Arbeit pro Plugin
(`source_runtime`, `runtimepath`-Neuberechnung: F2).

---

### Messwerkzeug erweitert

`scripts/startup-probe/` (Details im dortigen README):

- **`tui.lua`**: startet den geprüften Neovim mit UI.
- **`bench.lua`**: n Läufe, Median / Min / Max; weitere Argumente gehen an den
  geprüften Neovim (A/B ohne Config-Änderung, so ist die Telemetrie-Messung
  entstanden). Das ist Phase 0, Punkt 4.
- **Sonde `where`**: ordnet jeden Stoß einem Besitzer und einem Stack zu
  (zeitgewichtete Stichproben per Zähl-Hook). So wurden N1 und N2 gefunden,
  die keine `require`-, `exepath`- oder `rtp`-Sonde zeigt.
- **Sonde `lazy`**: welches Plugin wodurch geladen wurde und wie lange.
- **Sonde `spawn`**: zählt jetzt jeden Prozess (`uv.spawn`), nicht nur
  `vim.system`. lazys git-Prozesse waren vorher unsichtbar.
- **Sonde `stall`**: zusätzlich „Event-Loop belegt pro Sekunde".
- `<Bericht>.json` mit den Vergleichszahlen.

---

### Neue Reihenfolge

Ersetzt die Prioritäten aus Abschnitt 12 („Offen"). Erwartungen sind Schätzungen
für `STEVESPC`.

1. **`VeryLazy`-Welle verkleinern (N3).** `neotest` und `sandbox.nvim` sind
   erledigt (siehe „Zweiter Schritt"), der Stoß ist von 585 auf 348 ms gefallen.
   Offen: (a) `filetree.nvim` so umbauen, dass es `neo-tree` nicht beim eigenen
   Laden braucht (Erwartung −50 bis −70 ms; der Adapter hängt sich mit
   Reihenfolge-Annahmen in neo-tree-Interna, das ist kein Nebenbei-Umbau).
   (b) `gopath.nvim`: `load_from_disk` aus `setup()` nehmen. (c) Die Welle in
   Scheiben laden statt in einem Callback, falls (a) und (b) nicht reichen.
2. **F1-Rest:** die sieben `git`-Suchen über den Index aus `lib.nvim` führen;
   `sandbox.nvim` ebenso (`lib.nvim.core.has_exec` umgeht ihn).
3. **Phase 0 nachziehen:** `:StartupReport` zeigt weiter nur Phasen-Bodies. Mit
   dem, was die Sonde jetzt kann, wäre „Stöße und Belegung der ersten Sekunden"
   dort die ehrlichere Zeile als „Config loaded in … ms".
4. **F7** (NvChad-Probe, `gitsigns`-`require`): unverändert klein, unverändert offen.
5. **F2 / Phase 3:** auf `STEVESPC` kein eigener Hebel mehr. Für `OHANA` erst neu
   messen (mit `tui.lua`).
6. **Regeln festhalten (C3):** „Ein Befehl pro Element, wenn der Befehl das
   Ganze neu aufbaut" (N1) und „Prozess-Spawns zählen, auch wenn keiner
   blockiert" (N2) gehören in `PERFORMANCE.md`.

---

### Offen für dich

1. **`OHANA` neu messen:** `nvim --headless -l scripts/startup-probe/bench.lua 5 tui`
   nach dem Pull.
2. **Checker:** Reicht `C` in `:Lazy` für die Tage zwischen zwei Checks, oder
   soll die Update-Liste beim Öffnen von `:Lazy` automatisch berechnet werden
   (kostet dann dort ≈ 0,1 s)?
3. **`neotest` im Alltag gegenprüfen:** die Auslöser sind automatisiert
   geprüft, nicht von Hand bedient. Auffallen würde es an einem `<leader>nt*`,
   das beim ersten Druck nichts tut, oder an Statuszeichen, die in einer
   Testdatei fehlen, deren Name auf keines der Muster passt.
4. **`filetree.nvim` ohne `neo-tree` beim Laden** (Punkt 1a): lohnt sich das
   für ≈ 60 ms, oder bleibt es so?

---

