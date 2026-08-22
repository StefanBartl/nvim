# Task: Startup-Blockaden reduzieren (~600–800 ms)

Ausgelagert aus [PERF-Startup-Analyse.md](./PERF-Startup-Analyse.md). Das ist
**nicht** der spürbare „zweite Hänger" (der ist lua_ls und dort behandelt),
sondern der Start selbst.

## Symptom

Der Main-Loop blockiert zwischen +0,1 s und +1,4 s in 4–5 Blöcken à 80–320 ms,
zusammen **600–800 ms**. Reproduzierbar in *jedem* gemessenen Lauf — auch mit
deaktiviertem LSP und deaktiviertem gopath. Es ist also die Config selbst.

Messen:

```powershell
nvim --cmd "luafile C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/perf-tools/stall.lua" C:/Users/bartl/AppData/Local/nvim/init.lua
```

## Benannte Verursacher (Stack-Sampling)

Aus `luaprof.log` — das sind gemessene Stacks, keine Vermutungen. Aggregiert
über 12 s, also nicht alles im frühen Cluster, aber alles echte Main-Loop-Last:

| ≈ ms | Stelle | Verdacht |
|---|---|---|
| ~1870 | `lazy/manage/git.lua:149/161/192` → `lazy/manage/process.lua` | lazy.nvim spawnt Git-Prozesse. **Läuft der Update-Checker beim Start?** Größter Posten — hier zuerst schauen. |
| ~506 | `which-key.nvim/lua/which-key/state.lua:158` | |
| ~280 | `vim/_core/system.lua:244` | Prozess-Spawns allgemein |
| ~214 | `lspsaga/codeaction/lightbulb.lua:134` | läuft auf Cursor-Bewegung — Dauerlast beim Editieren |
| ~134 | `lspsaga/symbol/winbar.lua:248` → `util.lua:252` → `vim/version.lua:512` | `vim.version` im Hot-Path |
| ~108 | `nvim-treesitter-context.lua:45` | |

## Kandidaten aus dem Startup-Log

Aus `nvim --startuptime` (Gesamtzeit bis erstes Screen-Update: ~828 ms):

| Kosten | Posten | Anmerkung |
|---|---|---|
| **~120 ms** | un-attribuiert in den VimEnter-Autocommands, direkt nach `require('insights.conflicts')` | VimEnter gesamt 131 ms — größter Einzelposten im ganzen Start, eigenes Plugin |
| **87 ms** | `require('filetree')` | lädt erst *nach* „before starting main loop" |
| **70 ms** | un-attribuiert im `LazyDone`-Block | |
| **61 ms** | `require('telescope')` | davon 23 ms allein `term_previewer` + `buffer_previewer` — beim Start vermutlich nicht gebraucht |
| **28 ms** | `provider/clipboard.vim` | Neovim probt Clipboard-Tools per Prozess-Spawn |
| **16 ms** | `require('options')` | |

## Vorgehen

1. **lazy.nvims Git-Aktivität prüfen** — mit Abstand größter Posten (~1,9 s
   Prozess-Spawns). Wenn `checker.enabled = true` gesetzt ist: abschalten oder
   auf ein Intervall legen, statt bei jedem Start zu fetchen.
2. **`vim.g.clipboard` explizit setzen** — 28 ms, keine Nebenwirkung, Einzeiler.
3. **which-key `state.lua:158`** (~506 ms) anschauen.
4. **lspsaga Lightbulb** (~214 ms) — läuft auf Cursor-Bewegung und ist damit
   auch beim Editieren dauerhaft spürbar. Abschalten oder debouncen.
5. **Die 120 ms bei `insights.conflicts` eingrenzen** — eigenes Plugin,
   erneut mit `luaprof.lua` und dann gezielt.
6. **Prüfen, ob telescopes Previewer beim Start geladen werden müssen** — 23 ms
   für zwei Module, die vor der ersten Suche niemand braucht.
7. **`filetree` und die VeryLazy-Kette** — 87 ms nach Start des Main-Loops.

Nach jedem Schritt gegenmessen:

```powershell
nvim --cmd "luafile C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/perf-tools/stall.lua" C:/Users/bartl/AppData/Local/nvim/init.lua
```

## Fertig, wenn

Der Blockade-Cluster vor +1,5 s unter **~300 ms** Gesamtblockade liegt,
gemessen mit `stall.lua`.

## Hinweis zur Messmethodik

`nvim --startuptime` endet beim ersten Screen-Update und sieht spätere
Blockaden nicht. `:profile` ist blind für libuv-Callbacks. Deshalb die
Werkzeuge in [`perf-tools/`](./perf-tools) benutzen — Details und
Fallstricke in [PERF-Startup-Analyse.md](./PERF-Startup-Analyse.md#methodik).
