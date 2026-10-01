# Startup-Zeit und Config-Optimierung: Stand und offene Punkte

Stand: 2026-10-01 · gemessen auf `STEVESPC` (Windows, Neovim 0.12.2), mit UI.

Der vollständige Verlauf (Analyse, Konzept, drei Umsetzungsrunden, Nachprüfung,
Review; die früheren Abschnitte 1 bis 14) liegt im Archiv:
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/nvim-config/Backlog/TASKS/startup-und-config-optimierung-2026-09-26.md`.
Verweise im Code auf „Abschnitt 14 dieses Reports" meinen den Abschnitt dort.
Hier steht nur, was für die weitere Arbeit zählt.

---

## Table of content

  - [1. Wo wir stehen](#1-wo-wir-stehen)
  - [2. So wird gemessen](#2-so-wird-gemessen)
  - [3. Was gilt](#3-was-gilt)
  - [4. Offene Punkte](#4-offene-punkte)
  - [5. Offene Entscheidungen](#5-offene-entscheidungen)
  - [6. Erledigt, zum Nachschlagen](#6-erledigt-zum-nachschlagen)

---

## 1. Wo wir stehen

Median aus 5 Läufen mit UI (`bench.lua 5 tui`), echte Config:

| Größe | Beginn (2026-10-01) | jetzt |
| --- | ---: | ---: |
| `UIEnter` / letzte `UIReady`-Phase fertig | 413 / 503 ms | 432 / 517 ms |
| Stöße > 60 ms, Summe | 2538 ms | **612 ms** |
| längster Stoß | 1131 ms | **351 ms** |
| Event-Loop belegt in den ersten 6 s | 2993 ms | **924 ms** |
| gestartete Prozesse | 106 | 5 |
| geladene Plugins | 60 | 47 |

Benutzbar ist der Editor nach etwa 0,9 s (`VeryLazy` bei ≈ 525 ms plus der
Stoß danach), zu Beginn waren es ≈ 2,5 s.

Eine spätere Messung am selben Tag, bei unruhigerer Maschine und nach den
Review-Fixes, ergab mit UI 699 ms Stöße, längster 407 ms, 47 Plugins (14 per
Event); headless 439 ms und 171 ms bei 39 Plugins. Die Plugin-Zahl ist stabil,
die Millisekunden schwanken mit der Last: nur Läufe derselben Sitzung
vergleichen.

Der längste verbleibende Stoß ist die `VeryLazy`-Welle: alle Plugins auf
diesem Event laden in einem Callback direkt nach dem ersten Frame.

| In der Welle | ms | Bemerkung |
| --- | ---: | --- |
| `filetree.nvim` mit `neo-tree` | 130–165 | `neo-tree` als Dependency ≈ 50–65 |
| lazys eigene Arbeit pro Plugin | ≈ 200 | `source_runtime`, `runtimepath`-Neuberechnung von `vim.loader` |
| `gopath.nvim` | 20–90 | schwankt mit der Ladereihenfolge; `load_from_disk` ≈ 30 |
| `language.nvim` mit `trouble.nvim` | 35–45 | `trouble` lädt auch über `lsp.nvim` |
| `spotlight`, `cascade`, `media`, `noice`, `debugging`, `fileops` | je 11–22 | |

Danach folgen zwei kleinere Stöße: der Load von `gitsuite` über den
Menü-Prewarm (≈ 65–100 ms) und `ui.menu` `M.warm()`, das einmal wirklich ein
Float öffnet (≈ 130 ms, bewusste Abwägung von `ui.nvim`).

---

## 2. So wird gemessen

```bash
# Vergleichszahlen: 5 Läufe mit UI, Median / Min / Max
nvim --headless -l scripts/startup-probe/bench.lua 5 tui

# Wem gehört jeder Stoß, was lud wodurch
PROBE=stall,where,lazy,marks nvim --headless -l scripts/startup-probe/tui.lua
```

**Nie headless** für Aussagen nach `VimEnter`: lazy.nvim feuert `VeryLazy` erst
nach `UIEnter`, ohne UI also nie. Headless sah von derselben Config 562 ms
Stöße statt 2538 ms. Werkzeug und Lesehilfe:
[`scripts/startup-probe/README.md`](../../../scripts/startup-probe/README.md).

Die Zahlen gelten pro Maschine. `OHANA` (Neovim 0.11.4 zum Zeitpunkt der
ersten Analyse) ist mit UI noch nicht gemessen.

---

## 3. Was gilt

- Startup-Policy mit den Regeln „`VeryLazy` ist ein Stapel", „Headless ist kein
  Start" und der Keymap-Reihenfolge (`UIReady` läuft **vor** `VeryLazy`):
  [`docs/NOTES/ARCHITECTURE/startup.md`](../../NOTES/ARCHITECTURE/startup.md).
- Allgemeine Regeln `PERF-94` bis `PERF-97`:
  `WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`.
- lazys Checker läuft nur in der Session, in der der wöchentliche Check fällig
  ist (`lua/config/lazy/init.lua`). Dazwischen zeigt `:Lazy` anstehende Updates
  erst nach `C`.
- `neotest` und `sandbox.nvim` laden über eigene Auslöser, nicht mehr bei jedem
  Start. Wer ein Plugin von „immer geladen" auf Bedarf umstellt, braucht
  **jedes** Kommando als Auslöser, das es oder seine Dependencies anlegen
  (`:Neotest` und die `:Test*` von vim-test fehlten zuerst, bei `sandbox.nvim`
  der Alias `:Sbx`) und muss prüfen, was der Auslöser **beim Start** tut: lazys
  `event` kennt kein „nach `VimEnter`", ein breiter `ft` (`yaml`) lädt bei der
  ersten beliebigen Datei dieser Art. `neotest` wartet für eine Testdatei als
  Argument deshalb auf `VeryLazy`, `sandbox.nvim` löst für Compose-Dateien über
  den Dateinamen aus.
- `:checkhealth <plugin>` findet ein per Auslöser geladenes Plugin erst nach dem
  Laden (bei `sandbox.nvim`: vorher `:Sandbox engine get`).

---

## 4. Offene Punkte

Nach erwartetem Gewinn, Schätzungen für `STEVESPC`.

| # | Punkt | Erwartung | Aufwand / Risiko |
| --- | --- | ---: | --- |
| 1 | `filetree.nvim` so umbauen, dass es `neo-tree` nicht beim eigenen Laden braucht, dann die Dependency streichen | −50 bis −70 ms am Stoß | hoch: der Adapter (`adapter/neotree.lua`, 1600+ Zeilen) hängt sich mit Reihenfolge-Annahmen in neo-tree-Interna |
| 2 | `gopath.nvim`: `load_from_disk` aus `setup()` nehmen. `search()` lädt schon selbst nach; `needs_refresh` braucht dann das Alter der Cache-Datei (mtime) statt `state.last_built` | −30 ms | klein, eigenes Repo, Cache-Semantik beachten |
| 3 | PATH-Suchen, Rest: `git` ×7 (≈ 75 ms, `gitsigns.lua:237`, `vim.system`, `lib.nvim`), `cygpath` ×2 ohne Treffer (≈ 57 ms, `gitsigns/git/repo.lua:575`, fremder Code) | bis −75 ms, verteilt | eigene Aufrufer über den Index aus `lib.nvim.cross.executable`; gitsigns nicht beeinflussbar |
| 4 | Die Welle in Scheiben laden statt in einem Callback, falls 1 und 2 nicht reichen | kein Gewinn an Summe, aber kein Stoß > 100 ms | Eingriff in die Lade-Events der Specs |
| 5 | `:StartupReport` zeigt weiter nur Phasen-Bodies; „Stöße und Belegung der ersten Sekunden" wäre die ehrlichere Zeile als „Config loaded in … ms" | Messbarkeit | mittel |
| 6 | `gitsigns` lädt per `require` schon vor `VimEnter` (≈ 30 ms, `bindings/autocmds/git/gitsigns_refresh.lua`); NvChad-Probe in `lsp.nvim` (ein fehlgeschlagenes `require`, 6–7 ms) | −35 ms | klein |
| 7 | `Keymaps-Collisions.md` (WKDBooks, `wkdbook-myplugins/ALL/`) gegen die richtige Reihenfolge prüfen: ein Plugin auf `VeryLazy` überschreibt ein Mapping der `mappings`-Phase | Korrektheit | klein |
| 8 | `OHANA` mit `bench.lua 5 tui` neu messen; erst danach dort über F2 (`runtimepath`-Neuberechnung) entscheiden | Vergleichbarkeit | nur du |

Der frühere Punkt 8 (Source-Switcher in `filetree.nvim` prüfte ein Modul, das
es nicht gibt) ist erledigt: `08708b0`, `30d338b`, `c445079` in `filetree.nvim`,
aus einer eigenen Session.

---

## 5. Offene Entscheidungen

1. **Checker:** Reicht `C` in `:Lazy` zwischen zwei Checks, oder soll die
   Update-Liste beim Öffnen von `:Lazy` automatisch berechnet werden (kostet
   dort ≈ 0,1 s)?
2. **Punkt 1** (`filetree` ohne `neo-tree` beim Laden): lohnt der Umbau für
   ≈ 60 ms, oder bleibt es so?
3. **`sandbox.nvim`:** die Hover-Vorschau für Image-Referenzen gibt es außerhalb
   von Dockerfiles und Compose-Dateien (k8s- und Workflow-YAML,
   `devcontainer.json`) erst, wenn das Plugin geladen ist. `yaml` als Auslöser
   kostet ≈ 110 ms bei der ersten beliebigen YAML-Datei und ist deshalb raus.
   So lassen oder weitere Dateinamen ergänzen (z. B. `devcontainer.json`)?
4. **`neotest` von Hand gegenprüfen:** die Auslöser sind automatisiert getestet,
   nicht bedient. Auffallen würde ein `<leader>nt*`, das beim ersten Druck
   nichts tut, oder fehlende Statuszeichen in einer Testdatei, deren Name auf
   keines der Muster in `lua/plugins/neotest.lua` passt.
5. **Erster langsamer `<leader>`-Druck:** which-key lädt erst auf seinen
   Tasten. Ist `<Space>` die erste Stub-Taste der Sitzung und kommt der Druck
   langsam, löst lazys Stub erst nach `timeoutlen` aus und es erscheint **kein
   Popup**; erst der zweite Druck zeigt es. Das war schon vor dieser Arbeit so
   (Review, Einheit „Lazy key stubs"). Option A: `event = "VeryLazy"` an der
   which-key-Spec (≈ 16–27 ms in der Welle, kehrt die dokumentierte
   lib.nvim-Entscheidung „lädt auf dem ersten `<leader>`" um). Option B: lassen
   und den Hänger an der Spec dokumentieren.
6. **neotests `localhost`-Listener:** Beim Start des Clients öffnet neotest
   selbst `serverstart("localhost:0")` ohne Zugangsschutz (ohne Option
   abschaltbar). Das Review hat gezeigt, dass sich ein zweiter nvim ohne
   Zugangsdaten verbindet und Lua in der Sitzung ausführt. Neotests Hilfsprozess
   startet hier nicht (`lib.nvim` `rpc_pipe` vererbt `NVIM_LISTEN_ADDRESS` an
   Kinder), der Listener bleibt also ungenutzt offen. Er war schon vorher offen
   (erster Besuch eines Test-Buffers). Schließen lässt er sich nur über
   `lib.nvim` (`rpc_pipe` darf die Variable nicht an Kinder exportieren), und
   dann startet neotests Hilfsprozess, was 110–140 ms am Start kostet und
   gemessen gehört. So lassen, `lib.nvim` ändern oder neotests Client-Start auf
   Abruf (`:Neotest …`) beschränken?

---

## 6. Erledigt, zum Nachschlagen

Details, Messreihen und Begründungen im Archiv (Pfad oben).

| Repo | Commit | Inhalt |
| --- | --- | --- |
| `lib.nvim`, `lsp.nvim`, `dap.nvim`, `my.nvim`, `ui.nvim` | siehe Archiv, Abschnitte 12 und 13 | Phase 1 (PATH-Index, lazy aufgelöste Executables, which-key ohne Zwangs-Load) und Phase 2 (Menü-Prewarm ohne `wkddap`/`gitsuite`) |
| `language.nvim` | `ad355be`, `f737371` | Session-Wortlisten in einem Zug kompilieren statt ein `:spellgood!` pro Wort (1,2 s pro Start); UTF-8-Prüfung |
| `nvim-config` | `a6d0f455` | `startup-probe` mit UI (`tui.lua`, `bench.lua`, Sonden `where`/`lazy`/`spawn`), lazy-Checker nur bei Fälligkeit (101 git-Prozesse pro Start) |
| `nvim-config` | `1e34a249`, `190a896e` | `neotest` und `sandbox.nvim` aus der `VeryLazy`-Welle; Review-Fixes (`:Neotest`, vim-test, Sonde) |
| `WKDBooks` | `cb22850` | `PERF-94..97`, Nachtrag zur Checker-Notiz, Tool-Index |
| `language.nvim` | `bba2adb` | Review-Fixes: Leer- und BOM-Einträge am Rand eines Stapels, kein Scan des Arbeitsverzeichnisses ohne Temp-Verzeichnis, Tests, die jetzt scheitern können |
| `nvim-config` | `627dff8e` | Review-Fixes `startup-probe`: `where`-Zuordnung, Belegung pro Sekunde, `fs`-Rückgabewerte, Pfade mit `%`/`#`, `bench.lua`-Argumente, Exit-Codes |
| `nvim-config` | `737a27b3` | Review-Fixes: `:Sbx`-Stub, `sandbox.nvim` ohne `yaml`-Auslöser, `neotest` für Testdatei als Argument erst nach `VeryLazy` |
| `nvim-config` | `e80d52f6` | Neotest-Doku in `docs/NOTES/ExternPlugins/Bindings` an Code und Lazy-Stubs angepasst |
| `language.nvim` | `7b8ee9a` | Zweiter Review: Testfallen je Art und Ende, Slash-Regel abgesichert, README-Zeile |
| `nvim-config` | `87a29e20` | Zweiter Review: `neotest` startet den Client auch für offene Test-Buffer (Session), Uhr-Härtung des Checkers zurückgenommen (sie schaltete den `git log`-Sturm ein) |
| `nvim-config` | `d1087b50` | Zweiter Review: `startup-probe` behält bei fehlenden Modulen den Aufrufer, Fehlergrund im Treiber, Umleitungsrat je Shell |

| `language.nvim` | `7b8ee9a` | (Review der zweiten Runde, ohne Fund) |
| `nvim-config` | `a28ce217` | Dritter Review: `neotest` normalisiert das Trennzeichen der auslösenden Datei (0 → 4 Signs bei `edit E:/…`), Kommentar zu Reichweite, Listener und „No tests found" |
| `nvim-config` | `e4849b68` | Dritter Review: `tui.lua` warnt bei offener stdin-Pipe und nennt die Ursachen eines Exit 2 |

Die Reviews dieser Fixes (erst 25 bestätigte Funde aus 45 Agenten, 7 widerlegt;
dann 8 aus 11 Agenten, 0 widerlegt; zuletzt 4 aus 8 Agenten, 1 widerlegt, keine
Regression mehr) stehen im Archiv. Nicht umgesetzt: Entscheidung 5 oben (erster
`<leader>`-Druck), der unauthentifizierte `localhost`-Listener, den neotests
Client-Start öffnet (Entscheidung 6), und der Auto-Attach, der auch ohne
laufenden Test „No tests found" bzw. „No running process found" meldet. Aus dem
Review des `neotest`-Auslösers bleibt ein Zielkonflikt stehen: die
Event-Muster entsprechen bewusst `core.is_test_file`.
