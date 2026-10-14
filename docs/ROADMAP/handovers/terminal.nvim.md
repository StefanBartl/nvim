# terminal.nvim — Handover

Laufend aktuell halten (Regel aus `NEW_PROJECTS_PROMPT.md`). Stand: **2026-10-14 (abends): gebaut, CI grün (8 Jobs: ubuntu/windows/macos stable, ubuntu Neovim 0.11.0, Module-Map mit Schichtregeln, luacheck, stylua, echtes tmux), 543 Specs lokal (Windows, 0.12), LuaLS bei 0.** Nicht erledigt: die Handprüfung (`live-check`), das Tag (wartet auf deine Zustimmung), die `integrate-*`-Tasks und ein paar kleine `ruleset-*`/Feature-Tasks (Liste unten). **Review-Stand:** ein Teil der Code-Commits dieser Sitzung hat noch keinen `ultracode`-Review (siehe Abschnitt "Review-Stand").

## Orte

| Was | Wo |
|---|---|
| Ursprungsnotiz | `nvim/docs/ROADMAP/IDEAS/IDEAS/TMUX_WEZTERM_USW.md` |
| Konzept | `$REPOS_DIR/tasks-vault/terminal.nvim/Backlog/FEATURES/2026-10-07_terminal-nvim-konzept.md` (alter Pfad `nvim/docs/ROADMAP/IDEAS/IDEAS/terminal.nvim.md` ist ein Symlink) |
| Öffentliches Repo | `github.com/StefanBartl/terminal.nvim` → `E:\repos\terminal.nvim` (STEVESPC: direkt unter `E:\repos`) |
| Plan (Ziel, Phasen, DoD) | `$REPOS_DIR/tasks-vault/terminal.nvim/ROADMAP/plans/terminal-build.md` |
| Tasks | `.../terminal.nvim/ROADMAP/tasks/`, Übersicht `ROADMAP/TASKS.md` (generiert) |
| Notizen/Messungen | `.../terminal.nvim/NOTES/` (`spike-uservars.md`, `nvim-windows-terminal-findings.md`) |
| Installations-Spec | `nvim/lua/plugins/personal/specs/project.lua` (Eintrag `StefanBartl/terminal.nvim`, alle Optionen auskommentiert, deutsch kommentiert) |
| Gegenstücke | `$REPOS_DIR/Configs/terminals/{wezterm,tmux}` (noch nicht angefasst) |
| Regelwerk | `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/gates/NEW_PROJECT.md` (+ `regeln/PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) |

## Was es kann (gebaut)

- `native`-Backend: benannte Terminals pro Projekt-Root (float/split/vsplit/tab), toggle/open/hide/close/list, `send` (tippen, Enter nur mit `newline`/`--exec`), `run` (String wie getippt, argv-Liste gequotet, `--direct` mit Exit-Code).
- `:Terminal` (Composer), Keymaps als benannte Aktionen (`<A-h>` toggle, `<Esc>/<C-c>`, `<C-hjkl>`, `<A-l>`), Autocmds (Fensteroptionen, Kitty-Padding, Auto-Insert), `:checkhealth terminal`.
- 104 Specs auf `testing.nvim` (Windows lokal + CI ubuntu/windows/macos grün), `TESTS/live/smoke.lua` für den echten UI-Pfad.

## Entscheidungen

- Name `terminal.nvim` (ursprünglich Arbeitstitel `mux.nvim`); Modul `terminal`, Command `:Terminal`; UserVar-Protokoll behält `MUX_*`.
- Phase 1 = native + WezTerm-Export; tmux danach; kein Snacks-Fallback; Pin/Adopt bleibt im Plan (Phase `pin`).
- `<C-l>` bleibt das Clear der Shell: `clear` und `window_right` sind per Default aus (opt-in).
- Terminal-Backend (wo Terminals leben) und Status-Exporter (was an WezTerm/tmux gemeldet wird) sind getrennt; `backend = auto` heißt native.
- Bares `:Terminal` schaltet um (kein Menü); `3<A-h>` = Terminal "3".

## Offen / nächster Schritt

Abfrage: `nvim --headless -u NONE -l $REPOS_DIR/tasks.nvim/scripts/tasks.lua next terminal.nvim --actor=cdx --n=5 --vault=$REPOS_DIR/tasks-vault`.

| Task (`terminal.nvim/<id>`) | Stand |
|---|---|
| `release-docs` | `doing`: alles fertig außer **Tag/Release** (nach außen sichtbar, braucht Zustimmung; Vorschlag `v0.1.0`, README sagt "Beta") |
| `live-check` | `open`, **bei dir**: Handprüfung in WezTerm (Windows) und tmux (Linux/WSL); Skripte `TESTS/live/*`, Schritte kann ich liefern |
| `ruleset-nested-nvim-failopen` | `decision`, **bei dir**: tmux-Exporter bei verschachteltem Neovim fail-open oder fail-closed (heute fail-closed) |
| `repo-scaffold` | steht noch auf `doing`; Rest ist durch `ruleset-*`-Arbeit erledigt, prüfen und schließen |
| `ruleset-types-per-level` | `@types` je Ebene, einheitliche Datei-Tags (S) |
| `ruleset-release-media` | Demo-GIF und Logo (S) |
| `wezterm-status-veraltete-uservars-in-wrapper-panes-wsl-tmux` | Status eines abgestürzten Neovim bleibt hinter `wsl.exe`/tmux/ssh stehen; Ansatz offen (M) |
| `shell-cheatsheet` | Cheatsheet im offenen Terminal (L) |
| `integrate-pickers-ui`, `integrate-sessions`, `integrate-run-hooks` | Familien-Integrationen (M, M, L) |

Andere Areas mit Bezug: `images.nvim/bilder-in-tmux-osc-1337-sequenz-in-die-passthrough-huelle-pa` (Zeichenweg ohne tmux-Hülle, braucht Live-Prüfung), `nvim-config/insert-ctrl-hjkl-moves` (`<C-j>/<C-k>` im Insert-Modus, nur in laufender Sitzung klärbar), `gitsuite.nvim/eigene-git-engine-fallback-tui-float-ueber-terminal-nvim-sta`.

## Review-Stand (Haken-Regel: `ultracode`-Review oder reine Doku)

- Ohne `ultracode`-Review (Code): keine mehr offen.
- Gelb (mit hohem Reasoning geprüft, kein `ultracode`): `lib.nvim` `f9bba25`; `terminal.nvim` `bafb80c`, `5ba815e`, `33a1b81`, `623cd88`, `d226a95`, `670a409`. Seit 2026-10-14 (spät): `terminal.nvim` `296bd2c`, `b45f65f`, `96fd516`, `be0f99c`, `23f77e6`, `05564a2` und `lib.nvim` `e411923`.
- Der letzte volle `ultracode`-Durchgang (56 Agenten) lief über `d204e89`, `6918c14`, `68a7f57`, `32db127`, `9f0c114`, `c3a1f7c`, `0e3f081`; Befunde behoben.
- Befunde der gelben Prüfung (alle drei behoben): `terminal.nvim` `54ce3b4` (Hinweis nur aus der ersten Zeile, gekürzte Einzelzeile ins Debug-Log, synchroner `publish`/`clear` des tmux-Exporters nennt den Timeout) und `lib.nvim` `a7a0417` (Fall "leeres `$TMUX`" wieder in `terminal_host_osc_spec`). Diese beiden Fix-Commits haben noch keinen Review (nur eigene Prüfung + Specs); Vorschlag: ein `ultracode`-Review bei Gelegenheit, dann ✅ für alle gelben.

## API für andere Plugins

`require("terminal").run(argv, { direct = true, name, title, cwd, float, close, env, on_open, on_exit })` startet ein TUI/Programm als Job in einem Terminal-Fenster (gedacht u. a. für den lazygit-Fallback von gitsuite.nvim; Task im gitsuite-Bereich).

## Fallen (gemessen)

- Headless Windows: stdin von Terminal-Jobs ist zu; `nvim_chan_send` hängt; Absturz 0xC0000005 beim schnellen Schließen (siehe `NOTES/nvim-windows-terminal-findings.md`). Specs: `TESTS/support/jobs.lua`.
- `--remote-expr` nur mit `nvim --headless --server ...` (70 ms statt 1,15 s), UserVars nur per `nvim_ui_send`, unter tmux DCS-umhüllt + `allow-passthrough on` (`NOTES/spike-uservars.md`).
- Heredoc-Falle: große Spec-Dateien nie per Shell-Heredoc schreiben (Anführungszeichen), das Write-Tool nutzen.

## Arbeitsregeln

- `lib.nvim` verwenden; Wiederverwendbares nach `lib.nvim` heben. Deutsch im Chat, Englisch im Code. Kein Co-Author. `luacheck` + `stylua` grün, committen, pullen, auf `main` pushen (keine PRs).
- Commits werden mit `ultracode`-Review abgehakt; Doku-Commits gelten auch ohne.

## Log

- 2026-10-07: Konzept, Plan mit 30 Tasks, Spikes (UserVars, Pipe, tmux-Passthrough).
- 2026-10-07: Repo angelegt und gepusht; native Backend, `:Terminal`, Bindings, Specs, Docs; Config umgestellt (Spec in `project.lua`, `terminal.lua` und `autocmds/terminals` entfernt).
- 2026-10-07: Review-Fixes (18), `<C-l>`-Entscheidung, `run --direct`-Optionen, Status-Datensatz + WezTerm-Exporter + `Configs/.../nvim_status.lua` (Tab-Titel, Right-Status), live geprüft.
- 2026-10-07: `wezterm`-Pane-Backend (`backends/wezterm.lua`, Fake-CLI-Specs + `TESTS/live/wezterm.lua` gegen echtes WezTerm).
- 2026-10-07: `navigate-core`: `terminal.navigate(dir, count)`, Hand-off an WezTerm/tmux am Neovim-Rand, Terminal-Modus-Tasten, opt-in `nav_*` (Spec in `specs/project.lua`), `TESTS/live/navigate.lua`.
- 2026-10-07: tmux-Backend (+ Exporter, CI-Job), Konformitäts-Suite, Pin/Adopt, Health, Property-Specs, Perf-Messung (Branch-Cache), Neovim 0.11 als Minimum, `tmux.conf`-Ladefehler behoben; Final-Checks Abschnitt L.
- 2026-10-07: Review-Runde 2 (52 Agenten): 42 Befunde behoben (`383380a`, Configs `d620fc1`): tmux-`;`-Escaping (`backends.tmux.word`), `pin`-Reihenfolge, „list fehlgeschlagen = unbekannt, nicht weg“, Status-Besitz in tmux (`$NVIM`, UI, `owned`), `^V`/`^S`, Tab-Titel aus `PaneInformation`, Property-Generator (xorshift32), hermetische Specs. Verifikations-Review: 11 weitere (`f51df0f`, `8322761`): `pin` beendet das alte Terminal vor dem Pane (+ `preflight`, Restore), `alive()` für `$NVIM`; dritter Durchgang: 3 kleine (`e3056e4`: TCP-Adresse, ehrliche Restore-Meldung, Kommentare).
- 2026-10-08: Abschluss-Check aller 56 bestätigten Befunde auf `HEAD` (10 Agenten): 46 zu, 10 nachgebessert (`de58d89`, Configs `39fae23`): `UIEnter` setzt die Änderungssperre zurück, `$NVIM` zählt nur, wenn der äußere Neovim läuft **und** ein Vorfahre ist (`TESTS/live/nested.lua`, in der CI), `pin` fragt den Multiplexer vor dem Beenden (`backend.ping`), `run --direct` startet kein zweites Pane bei fehlgeschlagenem Close, WezTerm teilt `shell`-Strings, Check-Skripte für `tmux.conf` und Tasten. Vierter Durchgang (14 Agenten): 10 weitere (`b6102ef`, Configs `a4a196f`): `NVIM_APPNAME`, `/proc`-Parser, PATH-Scan, theme-feste Statuszeile (`@terminal_status_segment` + `run-shell` nach TPM), `tmux_conf_check.sh` prüft Ladefehler jetzt über `source-file`.
- 2026-10-08: Fünfter Durchgang (10 Agenten): 6 weitere (`696e631`, Configs `e599545`): die Pid des äußeren Neovim wird vom Server erfragt (`nvim --headless --server … --remote-expr getpid()`, Timeout, nie ein RPC im eigenen Prozess) statt aus dem Namen gelesen; `tmux_conf_check.sh` wartet auf die Panes, hinterlässt keine Server/Sockets mehr, prüft „genau einmal“, „vor dem Theme“ und Neuladen.
- 2026-10-08: rules.nvim-Durchlauf (432 Regeln; 393 manuell beurteilt, 110 Befunde, 106 von einer zweiten Prüfung bestätigt): Block 1 `d7499d3` (Quoting: TAB, `cmd.exe`-Backslashes, fish, tmux-Ein-Wort-argv), Block 2 `3ea7a66` (Fehlervertrag der Fassade, Config-Wertebereiche und der `{}`-Fehler von `deep_merge`, Health nach Konfiguration, `pin`/`adopt` als eigene Module, `Terminal.Options`), Block 3 `108c763` + `1230db4` (native Fenster mit Float, Fremd-JSON von WezTerm, Branch-Cache nach `.git/HEAD`-mtime, Namens-Completion, zeichenweise Auswahl, lazy Exporter), Block 4 `5c10db9` + `257492f` + `67fef6d` (begrenzte Eingaben, ein Prozess-Runner `core/exec.lua`, `pin` in Prüfen/Tauschen, LuaLS 0, Spec-Köpfe mit Begründung, Doku). Ultracode-Review der Fixes (81 Agenten, 38 Kandidaten, 30 bestätigt): `78e4675` + `4910675` (u. a. `pin` mit falschem Layout beendete das native Terminal, tmux-`-c` mit `#`, PowerShell-Quoting unter 5.1, `exec.run` bei kurzem Timeout, veraltete Visual-Marken). Zweite und dritte Runde (4 Finder, 25 und 27 Befunde): `9afe591`, `239d75c`, `a68f885` und danach `630e7be` (die Umstellung "Fenster zuerst" ließ Neovim unter Windows mit `0xC0000005` abstürzen, wenn ein laufendes Terminal in zwei Fenstern sichtbar war, 10 von 10, eine Pause half nicht: zurück zur alten Reihenfolge mit Vorprüfung per Wegwerf-Buffer), `e92ae34` (blockweise Auswahl im Visual-Modus lesen, `curswant == v:maxcol` für `$`; Regression aus `239d75c`), `6982a79` (argv mit Lücke wurde still gekürzt; reservierte Programmwörter; cmd.exe/portable), `86c1d9c` (Rahmen `bold` erst ab 0.12, Test-Limits 30 s/180 s in `.testing.lua`). Ergebnisliste und 13 Rest-Tasks im Wkdbook (`terminal.nvim/NOTES/rules-sweep-ergebnisse.md`, `ROADMAP/tasks/ruleset-*`). Lehren: Memory `parallel-session-same-checkout` (eine zweite Sitzung im selben Checkout hat Hunks verloren); der Runner wertet Überspringen nie als grün, plattformabhängige Fälle werden nur dort registriert, wo sie laufen.
- 2026-10-14: `lib-osc-detect-extraction`, `ruleset-async-publish` und `ruleset-lib-nvim-module` erledigt. lib.nvim: `terminal.host`, `terminal.osc` (`d204e89`), `cross.shell_quote` (`6918c14`, aus `core/quote.lua`; die Kern-Spec zog mit, Property-/Echt-PowerShell-Specs bleiben hier). terminal.nvim: `68a7f57`, `32db127` (tmux-Statuspublish und adopt-Refresh ohne Blockieren: ein Prozess in flight, neuester Datensatz gewinnt, `clear()` wartet), `9f0c114` (Autocmds über `lib.nvim.bindings.autocmd`, `is_windows` aus der lib). **Modulabgleich gegen `lib.nvim/docs/modules.md`:** umgestellt autocmd, platform, shell_quote, terminal.osc/host; verworfen mit Messung/Grund: `cross.run_argv` für `core/exec` (Timeout-Baumkill mit Gnadenfrist: 300 ms Limit brauchten 1,2 s, `run` blockiert den Editor), `cache.memory` für den Branch-Cache (negatives Caching und zwei gekoppelte Tabellen), `fs.project_key` für `core/context` (gecachter `find_root` statt frischem `vim.fs.root`, cwd-Schreibweise und Schlüssel getrennt). Der Zeichenweg von images.nvim ist Folge-Task (`images.nvim/bilder-in-tmux-...`).
- 2026-10-14: Release-Vorbereitung (`release-docs`): README, Docs, `doc/terminal.txt` gegen den Code geprüft (Agent, nur lesen), `FEATURES.md` und `ROADMAP.md` im Wkdbook, Konzept nach `Backlog/FEATURES/`, Eintrag in der wkd-Registry (`wkd@923b288`). CI-Matrix um Neovim 0.11.0 ergänzt; dort zwei echte Fehler gefunden und behoben (Schließen-Vorabprüfung nutzte die leere `:echo`-Ausgabe von 0.11; Modifier-Spec nur ab 0.12). Windows + 0.11.0 stürzt in den Teardown-Specs ab (0xC0000005), dokumentiert. Kein Tag gesetzt.
- 2026-10-14 (Tag): erledigt `wezterm-config-counterpart`, `perf-pass`, `lib-osc-detect-extraction`, `ruleset-async-publish`, `ruleset-lib-nvim-module`, `ruleset-os-matrix`, `float-title-informative` (Entscheidung: Titel bleibt der Name), `ruleset-tooling-measure`, `ruleset-central-cleanup`, `ruleset-config-knobs`, `ruleset-error-types`, `ruleset-module-coupling`, `ruleset-startup-measure-ui`; `release-docs` bis aufs Tag. Gebaut: `terminal.teardown()`, nicht blockierender tmux-Statuspublish und adopt-Refresh, Zeitgrenzen als Config-Schlüssel (`multiplexer.timeout_ms`, `navigate.timeout_ms`, `status.timeout_ms`, `adopt.refresh_ms`, `pin.layout`), `core/errors.lua` (Fehlertext: erste Zeile + Hinweis, Rest ins Debug-Log; Fehler bleiben Anzeige-Strings, Entscheidung in `docs/architecture.md`), `core/env.lua`, `status/nested.lua`, `core/tmux_word.lua`, `scripts/luals-check.sh`, `scripts/gen_map.lua` + `.docmap.json` (Schichtregeln, CI-Job `map`), `docs/development.md`. Nach `lib.nvim` gehoben: `terminal.host`, `terminal.osc`, `cross.shell_quote`. Fund durch den neuen 0.11-CI-Lauf: Schließen-Vorabprüfung nutzte die leere `:echo`-Ausgabe von 0.11 (behoben). Unter Windows + Neovim 0.11.0 stürzt der Editor in den Teardown-Specs ab (0xC0000005, dokumentiert in `docs/requirements.md`). Messungen: Start mit UI ohne messbaren Beitrag, auch mit WezTerm-Export (`Messungen/startup-*.md`).
- Lehren: Live-Skripte (`TESTS/live/*`, gegen echtes tmux in WSL) vor dem Push laufen lassen, wenn eine Funktion verschoben wird (die CI fand `nested.lua` erst nachträglich); kein `git stash` (geteilter Stash, ein Hintergrundlauf hat Änderungen kurz weggenommen); Python unter Windows schreibt CRLF, `stylua --check` meldet das lokal, Git normalisiert beim Commit; lib.nvim-Checkout ist von einer anderen Sitzung belegt (Contract-Arbeit), dort nur über eigenen Worktree und `git push origin HEAD:main`.
