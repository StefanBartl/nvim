# terminal.nvim — Handover

Laufend aktuell halten (Regel aus `NEW_PROJECTS_PROMPT.md`). Stand: **2026-10-07, Spikes erledigt, Entscheidung gefallen, noch kein Repo, kein Code.** Nächster Task: `repo-scaffold`.

## Orte

| Was | Wo |
|---|---|
| Ursprungsnotiz | `nvim/docs/ROADMAP/IDEAS/IDEAS/TMUX_WEZTERM_USW.md` |
| Konzept | `nvim/docs/ROADMAP/IDEAS/IDEAS/terminal.nvim.md` |
| Plan (Quelle der Wahrheit für Ziel, Phasen, DoD) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/terminal.nvim/ROADMAP/plans/terminal-build.md` |
| Tasks (30) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/terminal.nvim/ROADMAP/tasks/`, Übersicht `ROADMAP/TASKS.md` (generiert) |
| Öffentliches Repo (noch anzulegen) | `github.com/StefanBartl/terminal.nvim` → `$REPOS_DIR/terminal.nvim` |
| Privat (Roadmap/Notes) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/terminal.nvim/{ROADMAP,NOTES,Backlog}` |
| Gegenstücke | `$REPOS_DIR/Configs/terminals/{wezterm,tmux}` |
| Regelwerk | `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/gates/NEW_PROJECT.md` (+ `regeln/PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) |
| Tools | `.../wkdbook-myplugins/TOOLS/{TOOL-PLACEMENT,lua-plugin-tools}.md`, `.../HEREDOC.md` |

## Wie weiterarbeiten

```sh
nvim --headless -u NONE -l scripts/tasks.lua next terminal.nvim --vault=$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins
nvim --headless -u NONE -l scripts/tasks.lua plan terminal.nvim --vault=...
```

Entscheidung (2026-10-07): Empfehlungen übernommen (Name `terminal.nvim`, native + WezTerm zuerst, eigenes Repo, kein Snacks-Fallback, Pin/Adopt bleibt als letzte Funktionsphase). Spikes erledigt, Befund: `.../terminal.nvim/NOTES/spike-uservars.md`. Offen aus den Spikes: tmux-Passthrough (braucht tmux in WSL, Freigabe nötig, Task `tmux-test-env`).

## Arbeitsregeln (aus dem Prompt)

- `lib.nvim` verwenden; Wiederverwendbares nach `lib.nvim` heben.
- Max. 1 Agent gleichzeitig; Antworten deutsch, Code/Kommentare englisch; ausgeben, was gerade passiert.
- Kein Co-Author; nach jeder Aufgabe `luacheck` + `stylua` grün, committen, pullen, auf `main` pushen.
- Doku/README des Plugins mitpflegen; große/escape-haltige Literale nicht durch die Shell.
- Performance-, Security-Regeln früh mitdenken (Architektur/Struktur zuerst richtig, `rules.nvim`-Sweep am Ende).

## Log

- 2026-10-07: Konzept geschrieben, Plan `terminal-build` mit 30 Tasks im Vault angelegt (Phasen: spike, fundament, native, export, navigate, tmux, pin, family, abnahme).
- 2026-10-07: Entscheidung `decide-scope-name` (alle Empfehlungen). Spikes UserVars + Pipe-Roundtrip gemessen (WezTerm 20240203, nvim 0.12.2): Kanal `nvim_ui_send`, kein Verlust bei 200 Updates, 64 KiB ok; Rückweg nur mit `nvim --headless --server` (~70 ms statt ~1,15 s); `update-status` sieht nur das aktive Pane. Harness unter `TOOLS/scripts/wezterm-uservar-spike/`.
