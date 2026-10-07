# terminal.nvim — Handover

Laufend aktuell halten (Regel aus `NEW_PROJECTS_PROMPT.md`). Stand: **2026-10-07: native, WezTerm- und tmux-Backend, Status-Export, Navigation, Pin/Adopt, Health, Property-Specs gebaut und live geprüft (334 Specs, 6 Live-Skripte, tmux live 34/34, nested 5/5); sechs ultracode-Review-Durchgänge sind durch und eingearbeitet (nur `696e631` und Configs `e599545` sind nicht gegengeprüft). Offen: `rules-nvim-sweep` (manuelle Regeln), Start-A/B mit UI, `integrate-*`, `lib-osc-detect-extraction`, `release-docs`. Live-Checks und Blocker: `docs/ROADMAP/Final_Checks/Checks-Blocker_0610.md` Abschnitt L.**

## Orte

| Was | Wo |
|---|---|
| Ursprungsnotiz | `nvim/docs/ROADMAP/IDEAS/IDEAS/TMUX_WEZTERM_USW.md` |
| Konzept | `nvim/docs/ROADMAP/IDEAS/IDEAS/terminal.nvim.md` |
| Öffentliches Repo | `github.com/StefanBartl/terminal.nvim` → `E:\repos\terminal.nvim` (STEVESPC: direkt unter `E:\repos`) |
| Plan (Ziel, Phasen, DoD) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/terminal.nvim/ROADMAP/plans/terminal-build.md` |
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

`nvim --headless -u NONE -l scripts/tasks.lua next terminal.nvim --vault=...` (aus `$REPOS_DIR/tasks.nvim`). Als Nächstes: `status-dataset` → `wezterm-backend-export` → `wezterm-config-counterpart`. Nach dem nächsten Neustart der Config: alte Tasten von Hand prüfen und Startzeit messen (Task `replace-terminal-lua`).

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
