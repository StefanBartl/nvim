# nvim-config — Live-Checks (Stand 2026-10-29)

Offene Handarbeits-Tasks (`actor: me`) der Area `nvim-config`, die headless nicht (oder nur gegen Ersatz) prüfbar sind. Pro Abschnitt eine Task im `tasks-vault`; ist ein Abschnitt durch, die Task schließen (`tasks.lua done <id>`). Alles Auffällige **nicht hier sammeln**, sondern als Task anlegen (`kind: bug`), die Zeile hier mit der Task-Id schließen.

Konvention: `- [ ]` offen, `- [x]` verifiziert, darunter bei Bedarf eine Zeile `Notiz:`.

**Voraussetzungen (für alle Abschnitte):** nvim-config gepullt (Stand `main`), Neovim neu gestartet, `:checkhealth` ohne neue Fehler. Windows-Rechner mit echtem Terminal (nicht aus einer Claude-Sitzung: die Claude-App leitet AppData/HKCU um). Abschnitt 6 gilt für `OHANA`; Abschnitt 5 läuft auf `STEVESPC` oder `OHANA` (beide möglich). Auf der Workstation ist nichts vorzubereiten (dort nur händische Installationen/Checks der eigenen Apps, keine Claude-Sitzungen, also kein Hook nötig).

## Table of content

  - [1 — noice-Skip-Regeln und Start ohne Standalone-nui](#1--noice-skip-regeln-und-start-ohne-standalone-nui)
  - [2 — Large-files-Hook aus lazygit](#2--large-files-hook-aus-lazygit)
  - [3 — Struktur-Sprung `[u`/`]u` und `:Bindings check`](#3--struktur-sprung-uu-und-bindings-check)
  - [4 — `B` in `:MyPlugins machine`](#4--b-in-myplugins-machine)
  - [5 — `:MyNative install` und `uninstall`](#5--mynative-install-und-uninstall)
  - [6 — OHANA: Startup neu messen](#6--ohana-startup-neu-messen)
  - [7 — `context_open` (`M-o`) ausprobieren](#7--context_open-m-o-ausprobieren)

---

## 1 — noice-Skip-Regeln und Start ohne Standalone-nui

Task `nvim-config/live-check-noice-skip-regeln-und-start-ohne-standalone-nui`. Code: `nvim@42218a31c`, `22b131799` (notify-Skip-Regeln) und `nvim@5422af9f8`, `69f9e79fa` (redundanter `nui.nvim`-Eintrag entfernt). Headless durch Specs gedeckt, in einer echten UI nie angesehen.

Vorbereitung: Neovim frisch starten.

- [x] `:lua vim.notify('Buffer is not modifiable', vim.log.levels.WARN)` — erwartet: **keine** Mini-Meldung.
  Notiz: 2026-10-29 live: still, keine Meldung. OK.
- [ ] Signature-Help an einer Stelle ohne Signatur — erwartet: kein „No signature help“. **Taste ist `<M-s>` im Insert-Modus** (lsp.nvim, `LSP.signature_help`), nicht `<C-k>` (nicht belegt); in einer Lua-Datei mit lua_ls: `i` auf einer leeren Zeile, dann `<M-s>`. Alternativ `:lua vim.lsp.buf.signature_help()`.
  Notiz: 2026-10-29: `<C-k>` ohne Wirkung (Anleitungsfehler). `<M-s>` im **Normal**-Modus schaltete den Session-Chip um; der Chip liegt jetzt auf `<M-S>` (Alt+Shift+s), `<M-s>` ist im Normal-Modus frei. Insert-Modus-Test mit `<M-s>` noch offen.
- [x] `:lua vim.notify('hello')` — erwartet: erscheint weiterhin im mini-View.
  Notiz: 2026-10-29 live: ja. OK.
- [ ] Ein notify mit Text „Error detected while processing BufReadPost Autocommands for“ (z. B. `:lua vim.notify('Error detected while processing BufReadPost Autocommands for "x"', vim.log.levels.ERROR)`) — erwartet: jetzt **ebenfalls unterdrückt** (gewollt laut Feature-Abdeckungs-Report).
  Notiz:
- [x] Neustart, `:Lazy`: `nui.nvim` steht als Abhängigkeit von noice **und** neo-tree (kein eigener Top-Level-Eintrag mehr).
  Notiz: 2026-10-29 live: `:Lazy` zeigt `nui.nvim` geladen durch `neo-tree.nvim` (2,45 ms), kein eigener Eintrag; noice.nvim lädt bei VeryLazy. OK.
- [x] Noice-Cmdline (`:`) und Neo-tree öffnen ohne Fehlermeldung (`:messages` danach leer von Fehlern).
  Notiz: 2026-10-29 live: `:Noice` (Verlauf im Split) und Filetree öffnen ohne Problem. OK.

Falls rot: genaue Meldung und Auslöser notieren; Skip-Regel greift nicht = Task `kind: bug` (Bereich noice-Routing, Recherche-Task `noice-routing-and-nui-usage-recheck`); `nui` fehlt oder Ladefehler = Task `kind: bug` mit `:Lazy`-Ausschnitt.

Hinweis aus der Task: noice ist auf den Stand 2025-11 gepinnt und kennt die neuen 0.12-`kind`-Werte nicht (wird fehlerfrei ignoriert); ein Update-Test wäre eine eigene Task (S), nicht Teil dieses Checks.

Danach: Task `nvim-config/live-check-noice-skip-regeln-und-start-ohne-standalone-nui` mit `done` schließen.

---

## 2 — Large-files-Hook aus lazygit

Task `nvim-config/large-files-hook-live-test-lazygit`. Umsetzung: `nvim-config/large-files-hook-windows-no-tty` (Hook `scripts/git-hooks/pre-commit-large-files.sh`) und `terminal.nvim/nvim-ask-bridge` (`bin/nvim-ask` in lib.nvim, `lib.nvim.terminal.ask`, `$NVIM_ASK` in terminal.nvim). Offen: Fokuswechsel aus dem lazygit-Terminal in den Dialog und zurück; `lib.nvim.ui.dialog.ask` ignoriert vorgetippte Tasten.

Vorbereitung:
- [ ] `:Lazy update lib.nvim terminal.nvim` (die Lazy-Klone brauchen `bin/nvim-ask`), Neovim neu starten.
  Notiz:
- [ ] Im Ziel-Repo ist der pre-commit-Hook installiert (`bash scripts/git-hooks/install.sh <repo>` aus nvim-config, Marker `large-files-hook` in `.git/hooks/pre-commit`).
  Notiz:

Schritte:
- [ ] WKDBook-Tricentis: die zwei `.evtx` stagen, in lazygit (`:Git ui lazygit`) `c` — erwartet: Dialog „… larger than 5 MB“ erscheint **in Neovim** (Fokus wechselt aus dem Terminal in den Dialog).
  Notiz:
- [ ] „Compress to .zip“ wählen — erwartet: zweite Frage „Delete the originals?“; Antwort wirkt; der Commit enthält `*.evtx.zip`.
  Notiz:
- [ ] Nach dem Dialog: Fokus kehrt ins lazygit-Terminal zurück, Eingabe dort funktioniert normal.
  Notiz:
- [ ] Dasselbe aus einem terminal.nvim-Terminal (`git commit`).
  Notiz:
- [ ] `:checkhealth terminal` zeigt „Ask bridge: terminals get $NVIM_ASK …“.
  Notiz:
- [ ] Dialog wegklicken (`<Esc>`) — erwartet: Commit bricht mit Hinweis ab, nichts hängt.
  Notiz:

Alternative ohne Dialog fürs WKDBook: `git config largefiles.action compress` (ggf. `git config largefiles.deleteOriginals true`).

Falls rot: notieren, ob der Dialog gar nicht erscheint (`$NVIM_ASK` leer? `bin/nvim-ask` im Lazy-Klon vorhanden?), ob der Fokus nicht zurückkommt, oder ob vorgetippte Tasten Antworten auslösen; je ein Task `kind: bug` (Hook bzw. `terminal.nvim/nvim-ask-bridge`).

Danach: Task `nvim-config/large-files-hook-live-test-lazygit` mit `done` schließen.

---

## 3 — Struktur-Sprung `[u`/`]u` und `:Bindings check`

Task `nvim-config/live-check-structure-jump-and-bindings-check` (Tags `needs-live-test`, `bindings`, `treesitter`). Code: `lua/bindings/mappings/treesitter_structure.lua` (`up = "[u"`, `down = "]u"`; `[b`/`]b` ist ein Neovim-0.12-Default), Queries in `after/queries/{lua,json,python,rust,toml,yaml}/textobjects.scm`. Dieselben Kästchen stehen im Abschnitt „nvim-config“ (M5 und A) von `PLUGIN_ROADMAPS_TESTPLAN.md`; dort mit abhaken.

M5 — Sprung zur umschließenden Struktur:
- [ ] **lua:** in einer verschachtelten Funktion `[u` — erwartet: Cursor springt auf den Kopf der umschließenden Struktur; jedes weitere `[u` eine Ebene weiter raus (`for` → `if` → `function`). `]u` abwärts zum schließenden Ende.
  Notiz:
- [ ] **lua:** in einer Konfigurationstabelle — Tabellenkopf um Tabellenkopf.
  Notiz:
- [ ] **json:** in einem verschachtelten Objekt.
  Notiz:
- [ ] **python:** in einer Methode in einer Klasse (`if`/`for` in `def` in `class`).
  Notiz:
- [ ] **rust:** in einem `match`/`if` in einer `fn` in einem `impl`.
  Notiz:
- [ ] **toml:** in einer verschachtelten Tabelle (`[a.b]`).
  Notiz:
- [ ] **yaml:** tief verschachtelt (z. B. CI-Workflow).
  Notiz:
- [ ] `[b`/`]b` und `[s`/`]s` (Familie) arbeiten unverändert.
  Notiz:

A — Source-Achse von `:Bindings check`:
- [ ] `:Bindings check` läuft durch und meldet die verbliebenen Befunde. Erwartung: rund **51** (ursprünglich 150, nach zwei Werkzeugfixes 51). Kommt eine wesentlich größere Zahl, ist eher das Werkzeug verdächtig als die Config. Gemeldete Zahl:
  Notiz:
- [ ] Stichprobe gegen den Notizbaum: ein **gemeldeter** Keymap fehlt dort tatsächlich; ein **nicht gemeldeter** steht dort.
  Notiz:

Falls rot: Sprache, Cursorposition (Zeile/Spalte) und erwartetes vs. tatsächliches Ziel notieren; fehlende Query = Task `kind: bug` (Config). Jeder Fehler wird ein eigener Task (Regel R10), nicht Text im Testplan.

Danach: Haken im Testplan (M5, A) setzen, Task `nvim-config/live-check-structure-jump-and-bindings-check` mit `done` schließen.

---

## 4 — `B` in `:MyPlugins machine`

Task `nvim-config/machine-build-key-live-check`. Code: `nvim-config@b9b243e50` (Build des Repos unter dem Cursor in einem Float-Terminal über terminal.nvim: `build:<repo>`, `direct`, `cwd` = Repo). Headless geprüft: Lauf im Repo-Ordner, Float, Exit-Code. Offen: Bedienung in der echten Sitzung.

- [ ] `:MyPlugins machine`, Cursor auf eine Zeile mit `build stale`/`missing` und Befehl (mdview.nvim, ai-desktop), `B` — erwartet: Float öffnet sich, Build läuft im Repo-Ordner, Ausgabe bleibt stehen.
  Notiz:
- [ ] `<Esc>` (Normal-Modus), dann `q` schließt das Float; **erst danach** prüft der Bericht neu, und es ist keine Taste im Bericht gelandet.
  Notiz:
- [ ] Auf tasks-desktop / rules-desktop: `B` sagt „no build command - run its setup.exe“ und startet nichts.
  Notiz:
- [ ] Zweites `B` während eines laufenden Builds startet nichts; `:Terminal list` zeigt `build:<repo>`.
  Notiz:

Falls rot: Zeile/Repo, Fehlermeldung und Verhalten des Floats notieren; Task `kind: bug` (Bereich machine/terminal).

Danach: Task `nvim-config/machine-build-key-live-check` mit `done` schließen.

---

## 5 — `:MyNative install` und `uninstall`

Task `nvim-config/mynative-install-und-uninstall-einmal-live-durchspielen` (refs `nvim-config@0e1445477`, `docmap-desktop@74a6287`, `ai-desktop@5b03cb0`). Skripte `scripts\build-install.ps1` und `scripts\uninstall.ps1` sind gebaut und reviewed, aber Installieren/Entfernen verweigern sie in einer Claude-Sitzung (AppData/HKCU umgeleitet): nur ein normales nvim/PowerShell zählt. Werkzeuge und Pfade: `docs/NOTES/builds/toolchain.md`; Startbefehle: `docs/NOTES/builds/start.md`.

Vorbereitung: normales (nicht erhöhtes) nvim und PowerShell, Toolchain laut `toolchain.md` vorhanden (`:MyNative deps` zeigt es).

Schritte:
- [ ] `:MyNative install` — erwartet: alle vier Apps (tasks-desktop, rules-desktop, docmap-desktop, ai-desktop) installiert, Quickfix ohne `FAILED`.
  Notiz:
- [ ] Jede der vier Apps startet aus der Installation (Befehle in `docs/NOTES/builds/start.md`, z. B. `& "$env:LOCALAPPDATA\tasks-desktop\bin\tasks-hub.exe" start --open`).
  Notiz:
- [ ] `:MyNative uninstall docmap-desktop` — erwartet: fragt nach, der Deinstaller läuft, der Eintrag unter Einstellungen > Apps ist weg, und das Skript meldet `removed` erst **danach**.
  Notiz:
- [ ] `:MyNative uninstall ai-desktop` — erwartet: entfernt die Kopie der Skripte (`%LOCALAPPDATA%\ai-desktop`, PATH-Eintrag) und, falls vorhanden, die des Setups.
  Notiz:
- [ ] In einem **erhöhten** PowerShell verweigert `scripts\build-install.ps1` das Installieren (für alle vier Apps prüfen).
  Notiz:
- [ ] Optional (Probe aus der Task-Notiz, docmap-desktop): `src-tauri\resources\grammars` leeren, `scripts\build-install.ps1 -BuildOnly` — erwartet: der Ordner ist danach wieder voll (leerer Grammatik-Ordner zählt als nicht bereitgestellt und wird neu geladen). Wurde aus Claude-Sitzung nicht geprüft (Sicherheitsprüfung blockierte das Leeren).
  Notiz:

Bekannt: Auf der Workstation startet der Hub über `tasks-hub start` derzeit nicht (EDR beendet die Kette über wscript), siehe Task `appkit/start-ueber-wscript-von-edr-beendet`; dort sind App-Starts nicht aussagekräftig und gehören nicht in diesen Check.

Falls rot: was nicht klappt in die Notizen der Task, mit eigener Task (`kind: bug`), falls etwas zu ändern ist. Maschine: `STEVESPC` oder `OHANA`, beide möglich (nicht die Workstation).

Danach: Task `nvim-config/mynative-install-und-uninstall-einmal-live-durchspielen` mit `done` schließen.

---

## 6 — OHANA: Startup neu messen

Task `nvim-config/ohana-startup-remeasure` (Tags `startup`, `needs-user`, `machine-ohana`). Alle bisherigen Zahlen stammen von `STEVESPC` (Neovim 0.12.2). `OHANA` (Neovim 0.11.4 bei der ersten Analyse) ist mit UI nicht gemessen. Werkzeug: `scripts/startup-probe/README.md`; Report: `docs/ROADMAP/reports/startup/startup-und-config-optimierung-analyse-konzept-2026-09-26.md` (Abschnitt 2, Punkt 8).

Regeln: nur Läufe derselben Sitzung vergleichen, mindestens 5 Läufe, Median; die Zahlen schwanken mit der Last um 15 % und mehr.

Auf `OHANA`, im nvim-config-Ordner:
- [ ] `nvim --version` notieren. Version:
  Notiz:
- [ ] `nvim --headless -l scripts/startup-probe/bench.lua 5 tui` — Zahlen hier eintragen.
  Notiz:
- [ ] Für die Stoß-Zuordnung (PowerShell): `cmd /c "nvim --headless -l scripts/startup-probe/tui.lua > NUL < NUL"`.
  Notiz:
- [ ] Vergleich mit `STEVESPC`: Stöße über 60 ms Summe **612 ms**, längster Stoß **351 ms**, **47** Plugins. Liegt `OHANA` deutlich darüber: `PROBE=stall,where,lazy,marks` zeigt die Ursache.
  Notiz:
- [ ] Entscheidung über F2 (`runtimepath`-Neuberechnung von `vim.loader`) nur, falls die Messung sie nahelegt; sonst Task schließen.
  Notiz:

Falls rot (OHANA deutlich langsamer): Zahlen + Probe-Bericht notieren, Task für die Ursache anlegen; die F2-Entscheidung wird dann eine eigene Task.

Danach: Zahlen und Version in die Notizen der Task `nvim-config/ohana-startup-remeasure` eintragen und mit `done` schließen.

---

## 7 — `context_open` (`M-o`) ausprobieren

Task `nvim-config/context-open-review` (`kind: research`, Tags `context-open`, `needs-user`). `M-o` öffnet, was unter dem Cursor liegt, und verteilt an `gopath.nvim`, `markdown.nvim`, `images.nvim`, `pdfport.nvim` oder `open.nvim`. Code: `lua/bindings/usrcmds/context_open/` (`init.lua`, `providers.lua`, `scan.lua`, `util.lua`, `README.md`). Ziel: ausprobieren und klären, ob er erweitert werden soll.

Ausprobieren (`M-o`, alternativ `M-O`) an echten Zielen:
- [ ] URL in einer Tabellenzelle (Markdown).
  Notiz:
- [ ] Bildpfad.
  Notiz:
- [ ] PDF.
  Notiz:
- [ ] Markdown-Link.
  Notiz:
- [ ] Mediendatei (Video/Audio).
  Notiz:
- [ ] Pfad mit `:Zeile` (z. B. `lua/foo.lua:42`).
  Notiz:

Erweiterung prüfen — Kandidaten für neue Anbieter (nach dem Bau entstanden): `media.nvim`, `hover.nvim`, `mdview.nvim`, `filetree.nvim`-Knoten, `casedesk.nvim`-Cases, `buffer-ctx.nvim` (`:OpenInBrowser`, `:RevealInFm`).
- [ ] Liste der Plugins, die einen Anbieter verdienen, hier eintragen; je Fund ein Task (Config-Tasks, `context_open` ist Config-Code).
  Notiz:
- [ ] README der Funktion (Anbietertabelle) nach dem Ergebnis nachführen.
  Notiz:

Falls etwas nicht öffnet oder falsch verteilt: Ziel, Cursorposition und gewählten Anbieter notieren, Task `kind: bug`.

Danach: Ergebnis in die Notizen der Task `nvim-config/context-open-review` schreiben und mit `done` schließen.

