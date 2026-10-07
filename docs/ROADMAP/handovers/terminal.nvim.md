# terminal.nvim — Handover

Laufend aktuell halten (Regel aus `NEW_PROJECTS_PROMPT.md`). Stand: **2026-10-07, Repo gebaut und live (native Backend), `terminal.lua` der Config ersetzt. Nächste Schritte: WezTerm-Export (Phase `export`).**

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
- Bares `:Terminal` schaltet um (kein Menü); `3<A-h>` = Terminal "3".

## Offen / nächster Schritt

`nvim --headless -u NONE -l scripts/tasks.lua next terminal.nvim --vault=...` (aus `$REPOS_DIR/tasks.nvim`). Als Nächstes: `status-dataset` → `wezterm-backend-export` → `wezterm-config-counterpart`. Nach dem nächsten Neustart der Config: alte Tasten von Hand prüfen und Startzeit messen (Task `replace-terminal-lua`).

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
