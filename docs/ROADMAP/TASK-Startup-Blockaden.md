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
nvim --cmd "luafile C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/perf-tools/stall.lua" C:/Users/StefanBartl/AppData/Local/nvim/init.lua
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

Stand 2026-08-22: 1, 2, 4, 5, 6, 7, 8 erledigt, 9 teilweise; 3 als nicht lokal
behebbar geklärt. Offen sind nur noch zwei notierte Einzelfragen (neo-tree
`lazy = false`, der `pwsh`-Lookup) — beide brauchen eine Entscheidung, keine
Analyse.

1. ~~**lazy.nvims Git-Aktivität prüfen**~~ — **erledigt.** Der Checker war hier
   tatsächlich an: `checker.enabled = not machine.is("workstation")` schaltet
   ihn nur auf der workstation ab, und diese Maschine ist es nicht. Fix in
   `config/lazy/init.lua`: `frequency = 3600 * 24 * 7` statt Default 1 h, plus
   `change_detection = { enabled = false }`. Der Checker bleibt damit als
   Drift-Erkennung erhalten (der Grund dafür steht im Kommentar dort), fetcht
   aber nicht mehr bei jedem Tagesstart.
2. ~~**`vim.g.clipboard` explizit setzen**~~ — **erledigt.** Expliziter
   win32yank-Provider für Windows in `options.lua`. Verifiziert:
   `provider/clipboard.vim` taucht im `--startuptime`-Log nicht mehr auf.
3. ~~**which-key `state.lua:158`**~~ — **nicht lokal behebbar.** Die Stelle ist
   kein Startup-Posten, sondern ein 50-ms-Repeat-Timer
   (`timer:start(0, 50, ...)`), den which-key als Workaround für ein
   `ModeChanged`-Problem laufen lässt (folke/which-key.nvim#787). Die ~506 ms
   sind also permanente Grundlast über die 12 s Sampling, kein Startanteil.
   Die installierte Version ist mit origin/main identisch (2025-10-28), der
   Workaround ist unverändert upstream. Nichts zu tun, außer bei einem
   künftigen Update erneut zu prüfen.
4. ~~**lspsaga Lightbulb**~~ — **erledigt, war ein Tippfehler.** Der Spec setzte
   `lightbulb = { enabled = false }`, lspsaga liest aber `enable`
   (`saga.config.lightbulb.enable`, `lspsaga/init.lua:204`). `tbl_deep_extend`
   hat `enabled` still als toten Extra-Key danebengelegt, die Lightbulb lief
   weiter. Ein Zeichen in `plugins/lsp.lua`.
5. ~~**Die 120 ms bei `insights.conflicts` eingrenzen**~~ — **erledigt, und es
   waren 244 ms.** `conflicts.run()` macht zwei git-Aufrufe mit
   `vim.system(..):wait()`, also blockierend, und hängt per Default an
   `VimEnter`. Gefixt in C:/repos/insights.nvim: `run_async()` macht dieselbe
   Arbeit über die Callback-Form, der Autocmd benutzt sie. Im selben Lauf
   gemessen: `run()` blockiert 248 ms, `run_async()` kehrt nach 10 ms zurück.
   `run()` bleibt blockierend für `:Insights conflicts` — dort wartet jemand
   auf die Antwort. Verifiziert gegen ein Repo mit echtem Merge-Konflikt:
   beide liefern dieselbe Quickfix-Liste.
6. ~~**Telescope beim Start**~~ — **erledigt.** Nicht die Previewer sind das
   Problem, sondern dass Telescope überhaupt geladen wird, obwohl es
   `cmd = "Telescope"` ist: ein Top-level-`require` hebelt lazy.nvims
   Lazy-Loading still aus. Zwei Auslöser, per `lazy.core.config.plugins[..]._.loaded`
   ermittelt:
   - `lsp/tools/ts_type_lookup/ts_telescope_picker.lua` hatte
     `require("telescope.pickers")` & Co. auf Modulebene, und das Modul wird
     beim LSP-Setup geladen. **Gefixt** — die requires liegen jetzt in `M.pick`.
   - `pickers.nvim` patchte telescopes Mappings (und, weil `history.enabled`
     hier an ist, auch die History) beim eigenen `setup()` (Kette:
     `pickers.setup` -> `bindings.setup` -> `keys.patch` -> Adapter ->
     `require("telescope").setup(..)`). **Gefixt in C:/repos/pickers.nvim.**
     Beide Stellen waren bereits `vim.schedule`-deferred, mit Kommentaren, die
     genau dieses Problem beschreiben -- nur hilft `vim.schedule` hier nicht:
     es verschiebt ans Ende des aktuellen Event-Loop-Durchlaufs, und der ist
     immer noch der Start. Neu: `pickers.engines.when_loaded` patcht erst, wenn
     die Engine wirklich geladen wird (lazy.nvims `User LazyLoad`), mit
     `vim.schedule`-Fallback ohne lazy.nvim.

   Verifiziert: telescope.nvim, telescope-github.nvim und pdfport.nvim tauchen
   beim Start nicht mehr in `lazy.core.config.plugins[..]._.loaded` auf; nach
   einem `:Telescope find_files` sind die `<M-Left>`/`<M-Right>`-Mappings und
   der History-Pfad trotzdem gesetzt.
7. ~~**`filetree` und die VeryLazy-Kette**~~ — **erledigt, und die Ursache war
   eine andere als vermutet.** filetree.nvim wurde gar nicht über seinen
   `event = "VeryLazy"` geladen, sondern durch das Statusline-Modul
   `wkdnvchad.ui.statusline.modules.filetree_cwd_mode` — gemessen 202 ms
   (`lazy.core.config.plugins["filetree.nvim"]._.loaded`).

   Der `require` dort stand bereits *innerhalb* der Render-Funktion, war also
   nicht der übliche Top-level-Fehler. Er greift trotzdem sofort: die
   Statusline wird beim allerersten Redraw ausgewertet, und damit zieht sie
   das Plugin **vor den ersten Paint** — für ein Badge, das in dem Moment noch
   niemand lesen kann. Jetzt liest das Modul `package.loaded["filetree"]`,
   statt das Laden zu erzwingen: bis VeryLazy das Plugin holt, bleibt das
   Segment leer, danach rendert cwd_mode es über sein eigenes `:redrawstatus`.

   Der Gewinn ist **Verlagerung, nicht Ersparnis** — die 202 ms fallen weiter
   an, nur eben nach dem ersten Paint statt davor. Headless sieht das
   übertrieben positiv (dort feuert mangels UIEnter nie ein VeryLazy, filetree
   lädt also gar nicht); interaktiv gegenmessen.

   **Dabei aufgefallen, noch offen:** `neo-tree.nvim` steht in
   `plugins/neotree.lua` auf `lazy = false` und kostet 155–179 ms beim Start.
   Ob das Absicht ist (netrw ist in `disabled_plugins`, neo-tree übernimmt
   also das Öffnen von Verzeichnissen), muss jemand entscheiden, der die
   Absicht kennt — deshalb hier nur notiert.
8. ~~**Die 70 ms im `LazyDone`-Block**~~ — **erledigt, und es waren 202 ms.**
   Es war `helptags ALL`, registriert von `lib.nvim_usrcmds` auf
   `User LazyDone` — also bei *jedem* Start. Der Befehl läuft über die
   doc/-Verzeichnisse aller ~116 Plugins und schreibt jede Tags-Datei neu;
   gemessen 229 ms, und ein zweiter Lauf in derselben Sitzung kostet genauso
   viel, weil nichts daran inkrementell ist. Hilfedateien ändern sich aber nur
   bei Install/Update. Gefixt in lib.nvim: der Autocmd hängt jetzt an
   `LazyInstall`/`LazyUpdate`/`LazySync`; `:Lib helptags` bleibt für den
   manuellen Fall.
9. ~~**`require('options')`, 77 ms**~~ — **teilweise erledigt.** Ein
   `vim.fn.executable()` auf einen Namen, der NICHT auf $PATH liegt, walkt
   jeden Eintrag und statet Kandidaten, bevor es aufgibt: gemessen ~40 ms,
   gegenüber ~3 ms wenn der Fund den Walk früh beendet. `options.lua` prüfte
   auf Windows `wl-copy` — 42 ms garantiert vergeblich, weil es dort kein
   Wayland gibt. Steht jetzt hinter einem POSIX-Guard, `options` liegt bei
   ~55 ms.

   **Offen bleibt der `pwsh`-Lookup:** auch der schlägt fehl (40 ms), obwohl
   `pwsh.exe` unter `WindowsApps` liegt — `vim.fn.executable("pwsh")` sieht
   den App-Execution-Alias nicht. Wer die Shell ohnehin kennt, kann `o.shell`
   direkt setzen statt zu proben; das wäre die letzten 40 ms wert, ist aber
   eine Maschinen-Entscheidung.

Nach jedem Schritt gegenmessen:

```powershell
nvim --cmd "luafile C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/perf-tools/stall.lua" C:/Users/StefanBartl/AppData/Local/nvim/init.lua
```

## Fertig, wenn

Der Blockade-Cluster vor +1,5 s unter **~300 ms** Gesamtblockade liegt,
gemessen mit `stall.lua`.

Stand 2026-08-22 nach den Fixes 1/2/4/6, interaktiv gemessen:

```
at +0.20 s   blocked   85 ms
at +0.59 s   blocked  105 ms
at +0.83 s   blocked  140 ms
at +1.59 s   blocked  192 ms
at +1.84 s   blocked  225 ms
---- 5 stall(s), 747 ms blocked in total
```

Vor +1,5 s sind das 330 ms — knapp über dem Ziel. Der späte Stall (+2,4…2,6 s)
ist verschwunden, subjektiv bleibt nur noch ein kurzer Ruckler (~0,1 s), der
beim Start nicht mehr auffällt. Es fehlen also die Posten 5 und 7.

## Hinweis zur Messmethodik

`nvim --startuptime` endet beim ersten Screen-Update und sieht spätere
Blockaden nicht. `:profile` ist blind für libuv-Callbacks. Deshalb die
Werkzeuge in [`perf-tools/`](./perf-tools) benutzen — Details und
Fallstricke in [PERF-Startup-Analyse.md](./PERF-Startup-Analyse.md#methodik).
