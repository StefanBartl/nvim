# mux.nvim — Handover

Laufend aktuell halten (Regel aus `NEW_PROJECTS_PROMPT.md`). Stand: **2026-10-07, Planung abgeschlossen, noch kein Repo, kein Code.**

## Orte

| Was | Wo |
|---|---|
| Ursprungsnotiz | `nvim/docs/ROADMAP/IDEAS/IDEAS/TMUX_WEZTERM_USW.md` |
| Konzept | `nvim/docs/ROADMAP/IDEAS/IDEAS/mux.nvim.md` |
| Plan (Quelle der Wahrheit für Ziel, Phasen, DoD) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/mux.nvim/ROADMAP/plans/mux-build.md` |
| Tasks (30) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/mux.nvim/ROADMAP/tasks/`, Übersicht `ROADMAP/TASKS.md` (generiert) |
| Öffentliches Repo (noch anzulegen) | `github.com/StefanBartl/mux.nvim` → `$REPOS_DIR/mux.nvim` |
| Privat (Roadmap/Notes) | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/mux.nvim/{ROADMAP,NOTES,Backlog}` |
| Gegenstücke | `$REPOS_DIR/Configs/terminals/{wezterm,tmux}` |
| Regelwerk | `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/gates/NEW_PROJECT.md` (+ `regeln/PRINCIPLES.md`, `LUA_NVIM.md`, `PERFORMANCE.md`) |
| Tools | `.../wkdbook-myplugins/TOOLS/{TOOL-PLACEMENT,lua-plugin-tools}.md`, `.../HEREDOC.md` |

## Wie weiterarbeiten

```sh
nvim --headless -u NONE -l scripts/tasks.lua next mux.nvim --vault=$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins
nvim --headless -u NONE -l scripts/tasks.lua plan mux.nvim --vault=...
```

Erste startbare Tasks: `spike-uservars-osc1337`, `spike-pipe-roundtrip`. Die Entscheidung `decide-scope-name` (Name, Phase-1-Umfang, Repo-Form, Snacks-Fallback, Pin/Adopt) gehört dem Nutzer und blockiert `repo-scaffold`.

## Arbeitsregeln (aus dem Prompt)

- `lib.nvim` verwenden; Wiederverwendbares nach `lib.nvim` heben.
- Max. 1 Agent gleichzeitig; Antworten deutsch, Code/Kommentare englisch; ausgeben, was gerade passiert.
- Kein Co-Author; nach jeder Aufgabe `luacheck` + `stylua` grün, committen, pullen, auf `main` pushen.
- Doku/README des Plugins mitpflegen; große/escape-haltige Literale nicht durch die Shell.
- Performance-, Security-Regeln früh mitdenken (Architektur/Struktur zuerst richtig, `rules.nvim`-Sweep am Ende).

## Log

- 2026-10-07: Konzept geschrieben, Plan `mux-build` mit 30 Tasks im Vault angelegt (Phasen: spike, fundament, native, export, navigate, tmux, pin, family, abnahme).
