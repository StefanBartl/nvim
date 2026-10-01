# Übrige externe Plugins — Feature-Abdeckung durch die eigenen Plugins

Stand 2026-10-01. Zweiter Teil des Roadmap-Punkts „noice.nvim & übrige externe Plugins auf Feature-Abdeckung
prüfen — was ist durch eigene Plugins schon abgedeckt, was fehlt noch? **Nur dokumentieren, keine
Ersatz-Entscheidung**" (`00_ROADMAP.md`, Konkurrenzanalyse; Aufgabe in `TASKS.md`). Der erste Teil ist
`noice-feature-abdeckung-2026-10-01.md` (dort auch die Pipeline-Befunde zu `nvim-notify`/`nui.nvim` unter noice).

Dieser Report entscheidet **nichts**. Nichts wurde entfernt, ersetzt oder umkonfiguriert.
Er ist die umgekehrte Richtung des Roadmap-Punkts „Feature-Scan" (Zeile 95: fremde Konkurrenz *zu meinen* Plugins):
hier geht es um das, was **in meiner Config läuft**, und wie viel davon ein eigenes Plugin schon abdeckt.

## Kurzfassung

- **31 externe Plugins** stehen in `lua/plugins/*.lua` (ohne noice, ohne die schon abgelösten window-picker/bqf/zen/minty).
  Einordnung:
  - **11 bleiben Engine/Host**, eigene Plugins sitzen *drauf*: telescope, fzf-lua, snacks, neo-tree, gitsigns, blink.cmp,
    mason, neogit, diffview, nvim-treesitter, treesitter-textobjects.
  - **5 sind (teilweise) durch Eigenes abgedeckt:** search.nvim, telescope-github, nvim-notify, telescope-file-browser,
    nvim-web-devicons.
  - **5 sind reine Zulieferer** eines anderen externen Plugins: nui.nvim, plenary.nvim, telescope-fzf-native,
    neo-tree-diagnostics, neo-tree-tests-source.
  - **9 haben kein eigenes Pendant**: tokyonight, which-key (Popup), vim-matchup, mini.ai, targets.vim, nvim-autopairs,
    nvim-ts-autotag, vim-visual-multi, neotest (dort ist `test.nvim` als Konzept da, aber nicht gebaut).
  - **1 ist gar nicht installiert:** nvim-cmp (nur der Alternativ-Pfad in lsp.nvim und der Config).
- **Das Muster der eigenen Plugins ist durchgängig „aufsetzen", nicht „ersetzen":** pickers.nvim abstrahiert über drei
  Engines, filetree.nvim über fünf Tree-Plugins, gitsuite.nvim über gitsigns/neogit/diffview, lsp.nvim über blink/mason/conform/trouble,
  dap.nvim über nvim-dap. Das Ziel „weniger externe Plugins" erreicht das nur dort, wo ein Adapter *wegfällt*
  (fugitive, git-conflict, lazygit.nvim, window-picker, bqf, zen-mode, minty/volt sind so gegangen).
- **Die größten echten Lücken** (Funktionen, die du täglich nutzt und die nur ein externes Plugin liefert): Git-Signs/Hunk-Engine
  (gitsigns), Tree-Rendering samt Sources (neo-tree), Completion-Engine (blink), Treesitter-Parser, die Editing-Primitive
  (autopairs, autotag, matchup, visual-multi, Textobjekte) und die Testlauf-Oberfläche (neotest). → §5.
- **Wartungsrisiken in der Rest-Liste** (belegt per GitHub-API, siehe §1): `plenary.nvim` (README: „no longer actively maintained,
  will be officially archived soon"; alle seine Abnehmer sind extern), `diffview.nvim` (letzter Push 2024-08), `search.nvim`
  (2024-05), `vim-visual-multi` (2024-09), `targets.vim` (2024-07), `neo-tree-diagnostics` (2024-02). → §6.
- **Doku-Abweichung gefunden:** gitsuites `scope.md`/`around-it.md` behaupten eine native Hunk-Implementierung; im Code gibt es für
  stage/reset **keine** (nur `preview` fällt zurück). → §7.

## 1. Grundlage und Methode

| Quelle | Was daraus kam |
|---|---|
| `lua/plugins/*.lua`, `lua/config/{telescope,search,fzf,snacks,neotree,neotest}`, `lua/bindings/**` | wozu das Plugin hier dient, was konfiguriert/gebunden ist |
| `nvim-data/lazy/*` (57 Verzeichnisse), `git log -1` je Plugin | was wirklich installiert ist und auf welchem Stand (= der Lock-Stand) |
| `gh api repos/<owner>/<repo>` (am 2026-10-01) | Sterne, letzter Push, `archived`-Flag je Plugin |
| `docs/NOTES/ExternPlugins/Bindings/*` | welche Maps tatsächlich gesetzt sind |
| Quelltext + `docs/` der eigenen Repos in `E:\repos` (pickers, filetree, gitsuite, diff, lsp, ui, lib, cascade, dap, debugging) | Abdeckung je Feature, `around-it.md`/`scope.md` als Zusage, Code als Beleg |
| `Grep` über `E:\repos` | welche eigenen Plugins das externe Plugin berühren (Zähltabelle in §2) |

Alles beruht auf **Lektüre und Zählung**, nichts wurde ausgeführt außer `gh api` und `git log`. Wo Doku und Code sich widersprechen, gilt der
Code (siehe §7). **Nicht geprüft** steht in §8.

Legende: ✅ abgedeckt · 🟡 teilweise / nur als Adapter · ❌ nicht abgedeckt · ➖ liegt außerhalb dessen, was ein eigenes Plugin abdecken soll.
Beziehung: **Engine** (extern bleibt Backend) · **aufgesetzt** (Eigenes sitzt auf dem Externen) · **ersetzbar** (Eigenes deckt die Funktion, Umstellung wäre eine Entscheidung) · **Zulieferer** · **kein Pendant**.

### Gesamtübersicht

Reichweite = GitHub-Sterne, „Push" = letzter Push upstream, „Pin" = Commit-Datum des installierten Stands.

| Plugin | ★ | Push | Pin | Wozu hier | Eigenes Pendant | Beziehung |
|---|---:|---|---|---|---|---|
| telescope.nvim | 19 807 | 2026-08-17 | 2026-08-17 | Picker-Backend, 3 direkte Maps, ~11 eigene Plugins mit Telescope-UI | pickers.nvim (abstrahiert) | Engine |
| telescope-fzf-native | 1 758 | 2026-05-06 | – | Sorter für telescope | – | Zulieferer |
| telescope-file-browser | 1 942 | 2025-08-05 | – | `<leader>,` (CWD), `explorer`-Builtin auf telescope | `pickers.browse` | ersetzbar (🟡) |
| telescope-github | 234 | 2026-01-20 | – | nur als Abhängigkeit deklariert, **keine Nutzung gefunden** | `pickers.sources.github` (`gh`-CLI) | ersetzbar |
| fzf-lua | 4 454 | 2026-09-30 | 2026-09-21 | Backend, 10 direkte `<leader>f*`-Maps, replacer/cmdlog/lsp | pickers.nvim | Engine |
| snacks.nvim | 8 112 | 2026-05-25 | 2026-05-25 | **aktive Engine** (`engine = "snacks"`), `debug`, `quickfile`, `explorer` | pickers.nvim (nur Picker) | Engine |
| search.nvim | 189 | 2024-05-21 | 2024-05-21 | `<leader>s` Tab-UI über telescope | `pickers.tabs` | ersetzbar |
| neo-tree.nvim | 5 616 | 2026-09-27 | 2026-09-01 | Tree-Rendering, 6 Sources | filetree.nvim (Features drüber) | Engine |
| neo-tree-diagnostics | 100 | 2024-02-28 | – | Source „diagnostics" | trouble (lsp-Pack), filetree `lsp_diagnostics` (nur Marken) | Zulieferer |
| neo-tree-tests-source | 8 | 2026-09-03 | – | Source „tests" (neotest-Konsument) | – | Zulieferer |
| gitsigns.nvim | 7 128 | 2026-09-22 | 2026-09-22 | Signs, Hunk-Engine, Blame-on-Hold | gitsuite (Adapter) | Engine |
| diffview.nvim | 5 833 | **2024-08-02** | 2024-06-13 | `:Git ui diffview` | diff.nvim (Fallback) | Engine |
| neogit | 5 640 | 2026-09-30 | 2026-08-21 | `<leader>gg`, Staging-UI | – (gitsuite startet es nur) | Engine |
| mason.nvim | 10 499 | 2026-06-19 | 2026-06-11 | Installer für LSP/DAP/Tools | lsp.nvim `ensure_install` | Engine |
| blink.cmp | 6 603 | 2026-10-01 | 2026-04-04 | Completion-Engine | lsp.nvim: Sources, Ranking, Keymap-Anbindung | Engine |
| nvim-cmp | 9 487 | 2026-07-09 | – (nicht installiert) | nur Alternativ-Pfad | wie blink | – |
| nvim-treesitter | 14 434 | 2026-09-30 | f873ec29 (2026-03-12, **bewusst gepinnt**) | Parser, Highlight, Indent | ➖ (Neovim-Kern) | Engine |
| treesitter-textobjects | 2 813 | 2026-09-03 | 2026-09-03 | nur `move` für `[u`/`]u` | ❌ | Engine |
| mini.ai | 633 | 2026-09-21 | 2026-06-18 | `a`/`i`-Textobjekte | ❌ | kein Pendant |
| targets.vim | 2 642 | **2024-07-10** | 2024-07-10 | `a`/`i`/`n`/`l`-Textobjekte | ❌ | kein Pendant |
| vim-matchup | 1 930 | 2026-09-05 | 2026-09-05 | `%`, Offscreen-Match | ui.nvim liest es nur | kein Pendant |
| nvim-autopairs | 4 101 | 2026-08-23 | 2026-08-23 | Klammern/Quotes schließen | ❌ | kein Pendant |
| nvim-ts-autotag | 2 120 | 2026-04-15 | 2026-04-15 | HTML/TSX-Tags schließen/umbenennen | ❌ | kein Pendant |
| vim-visual-multi | 4 887 | **2024-09-01** | 2024-09-01 | Multi-Cursor, nur `<C-n>` | ❌ | kein Pendant |
| neotest | 3 116 | 2026-08-16 | 2026-08-16 | Testlauf, 1 593 Zeilen eigene Config („parked") | ❌ (`test.nvim` nur Konzept) | kein Pendant |
| which-key.nvim | 7 320 | 2025-10-28 | 2025-10-28 | `<leader>`-Popup, Gruppenlabels | ❌ Popup; 152 eigene Dateien labeln optional | kein Pendant |
| tokyonight.nvim | 8 208 | 2026-03-24 | 2026-03-24 | das Colorscheme (`storm`) | ➖ ui.nvim liefert Palette/Transparenz, kein Schema | kein Pendant |
| nvim-web-devicons | 2 724 | 2026-09-21 | – | Datei-Icons | `lib.nvim.ui.icons` (Tabelle, ~150 Endungen) | ersetzbar (🟡) |
| nvim-notify | 3 572 | 2025-09-06 | 2025-08-27 | **ungenutzt** (noice routet auf `mini`) | `lib.nvim.notify` + `ui.kit.toast` | ersetzt |
| nui.nvim | 2 127 | 2026-08-22 | – | nur noice + neo-tree | `ui.kit` ist nui-frei | Zulieferer |
| plenary.nvim | 3 499 | 2026-04-10 | 2026-04-10 | nur externe Abnehmer | ❌ (kein eigenes Plugin braucht es) | Zulieferer |

Auf die Pin-Differenz achten: **blink.cmp** (Pin 2026-04-04, Push 2026-10-01) und **neogit** (Pin 2026-08-21) liegen hinter dem Upstream; bei
**nvim-treesitter** ist das gewollt (Kommentar in `plugins/treesitter.lua`: Pin wegen `vim.list.unique`, „unpin once this Neovim is on 0.12"). Neovim ist
inzwischen 0.12.2 → der Kommentar ist **veraltet**, das Entpinnen wurde aber **nicht** getestet (§6).

## 2. Welche eigenen Plugins berühren welches externe

Aus `Grep` über `E:\repos` (Dateien mit `require(…)` bzw. Erwähnung; ohne WKDBooks, `.test-plugins`, plenary-Klon, Tests):

| Extern | Eigene Plugins mit direktem Bezug |
|---|---|
| telescope | pickers, cmdlog, sessions, sandbox, insights, open, pdfport, buffer-ctx, color_my_ascii, filetree (refs_picker, find_files), gitsuite (pickers_nvim-Integration), lsp (Astro) |
| fzf-lua | pickers, lsp (Code-Action-Liste, Finder), replacer, cmdlog, pdfport |
| snacks | pickers (nur dort) |
| neo-tree | filetree (Adapter, 14 Dateien), fileops |
| gitsigns | gitsuite (Adapter), diff (`gitsigns_peek`), lsp (Code-Actions), Config (`blame_on_hold`, `gitsigns_refresh`) |
| diffview / neogit | gitsuite (je ein Adapter) |
| blink / nvim-cmp / mason / conform / trouble / lazydev / lensline / inc-rename | lsp (Pack + `integrations/*`) |
| neotest | debugging (`:Debug neotest …`) |
| nvim-ts-autotag | lsp (Astro-Modul) |
| vim-matchup | ui (Statusline-Modul `matchup_offscreen`) |
| nvim-web-devicons | lib (`ui.icons`), ui (Statusline/Tabline), lsp (Winbar) |
| which-key | **152 Dateien** in `E:\repos` erwähnen es (je `which_key`-Option/Integration) — u. a. cmdlog, buffer-ctx, cascade, dap, diff, ai, casedesk, debugging, gopath, replacer |
| plenary | nur `documentation.nvim` (Tests); kein Laufzeit-Plugin |

## 3. Cluster im Detail

### 3.1 Git — gitsigns · diffview · neogit ↔ gitsuite.nvim · diff.nvim

Beziehung nach gitsuites eigener Aussage (`docs/around-it.md`): *gitsigns, diffview, neogit werden nicht ersetzt, sondern angebunden.* Ersetzt wurden
fugitive, rhubarb, git-conflict.nvim, lazygit.nvim (in `plugins/git.lua` als entfernt kommentiert).

| Feature | Extern | Eigenes | Stand |
|---|---|---|---|
| Signs in der Signcolumn | gitsigns | – | ❌ |
| Hunk stage/reset/preview | gitsigns | `:Git hunk *` — **nur über gitsigns** (`features/hunk/init.lua:4`: keine native Alternative); `preview` fällt auf `:Git diff head` zurück | 🟡 |
| Blame (Zeile/Datei) | gitsigns | gitsuite `:Git blame *` (`git blame --porcelain`) | ✅ — aber die Config ruft beim `CursorHold` weiter `gitsigns.blame_line` (`bindings/autocmds/git/blame_on_hold.lua`) |
| Hunk-Navigation `]c`/`[c`, Textobjekt `ih`, Hunks → Quickfix | gitsigns | – (in der Config nicht einmal gebunden, kein `on_attach`) | ❌ |
| Inline-Diff / Wortdiff | gitsigns | `<leader>di` = `:Git hunk inline` (ruft gitsigns) | 🟡 |
| Seiten-an-Seiten-Diff, Dateipanel | diffview | diff.nvim (Split, Verzeichnisse, URLs, Revisionen); **kein** Dateipanel mit Staging | 🟡 |
| Datei-Historie | diffview | `:Git diff history` = diff.nvim `:DiffHistory` (laut Doku bewusst ersetzt) | ✅ |
| 3-Wege-Merge-Layout | diffview | gitsuite `conflict` (eigener Parser, Inline-Auflösung) — anderes Bedienkonzept | 🟡 |
| Staging-UI, Commit-Editor, Push/Pull-Popups, Rebase | neogit | – (gitsuite `scope.md`: bewusst nicht; `:Git ui lazygit` als TUI) | ❌ |
| Merge-Konflikte | (git-conflict.nvim, entfernt) | gitsuite `conflict` | ✅ |
| Multi-Repo-Statuspanel | – | gitsuite `dashboard` | ✅ (Mehrwert, kein externes Gegenstück) |

Einschätzung: **gitsigns bleibt unverzichtbar**, solange nichts die Signs und die Index-Schreibzugriffe übernimmt; das ist laut gitsuite-Architektur
bewusste Entscheidung. **diffview** ist upstream seit 2024-08 ohne Push, die Config nutzt nur das Öffnen/Schließen — der Ausfallpfad (diff.nvim-Split)
existiert schon.

### 3.2 Picker — telescope (+3 Extensions) · fzf-lua · snacks · search.nvim ↔ pickers.nvim

pickers.nvim ist ausdrücklich **keine Ablösung**, sondern eine Schicht: dieselbe Grammatik (`:Pickers cwd files`) läuft auf allen drei Backends
(`docs/FEATURES/ENGINES.md`). Aktuell `engine = "snacks"` (`specs/navigate.lua:548`). Die Backends bleiben nötig, solange nicht jeder Aufrufer über
pickers.nvim geht.

| Feature | Extern | Eigenes | Stand |
|---|---|---|---|
| Fuzzy-Picker, Previewer | alle drei | pickers.nvim wählt/patcht, besitzt keinen | 🟡 (Engine nötig) |
| Datei-/Grep-Scopes (cwd, config, folder, repos, system, drives, dir `<nav>`) | – | pickers.nvim | ✅ (Mehrwert) |
| 53 native Picker (`:Pickers builtin …`) | je Engine | pickers `builtins/` (Tabelle in `docs/builtins.md`) | ✅ — alle Ziele der 10 direkten `<leader>f*`-Maps stehen dort drin (colorschemes, keymaps, git_status, quickfix, man, treesitter, lines/grep_buffers, grep_word) |
| Tab-Gruppen (search.nvim) | search.nvim | `pickers.tabs` — gleiche Struktur, `[2/3 cwd grep]` im Titel statt Tab-Leiste; telescope + snacks, **nicht fzf-lua**; `tab_next`/`tab_prev` standardmäßig aus | 🟡 — in der Config **nicht aktiviert** (`tabs`-Block auskommentiert, `specs/navigate.lua:858`) |
| File-Browser | telescope-file-browser | `pickers.browse` (engine-neutral); `explorer`-Builtin nutzt die Extension nur auf telescope | 🟡 (Umfang der Dateiaktionen im Picker nicht verglichen) |
| GitHub-Issues/PRs | telescope-github | `gh_issue`, `gh_pr`, `*_all` über `gh`-CLI (`pickers.sources.github`) | ✅ — und `telescope-github` wird in der Config **nirgends benutzt** (nur `dependencies`-Eintrag in `plugins/telescope.lua:18`) |
| Native Sorter | telescope-fzf-native | – (Zulieferer für telescope; wird per `load_extension("fzf")` geladen) | ➖ |
| Snacks: Explorer (`<leader>F`) | snacks | filetree hat **keinen** snacks-Adapter (Adapter: neotree, nvim-tree, oil, mini.files, netrw) | ❌ |
| Snacks: `debug`-Inspector (`<leader>ud`/`uD`) | snacks | `debugging.nvim` ist ein Befehlsverzeichnis, ein Inspector-Gegenstück nicht verglichen | nicht geprüft |
| Snacks: `quickfile` | snacks | – | ❌ (klein) |

Die *direkt* an Telescope/fzf-lua gebundenen Maps (3 Telescope: `<leader>ts`, `<leader>fa`, `<leader>,` — `<leader>tg` geht über pickers und nutzt Telescope nur als Fallback; 10 fzf-lua in
`bindings/mappings/fzf.lua`) sind in der Config verblieben, obwohl pickers.nvim den Weg anbietet — das ist eine Lücke der *Verdrahtung*, nicht der
Funktion.

### 3.3 Tree — neo-tree (+ diagnostics, tests) ↔ filetree.nvim

filetree.nvim hat **keinen eigenen Baum-Renderer**. Es hängt Features über fünf Adapter (`neotree`, `nvimtree`, `oil`, `mini_files`, `netrw`).
neo-tree liefert weiter: das gezeichnete Fenster, die Sources, die Navigation.

| Neo-tree-Funktion | Eigenes | Stand |
|---|---|---|
| Baum-Rendering, Fensterverhalten | – | ❌ |
| Source „filesystem" | filetree-Features (Marks, Preview, smart rename, Trash, Pfad-Kopie, Find/Grep-in-Dir) drüber | 🟡 aufgesetzt |
| Source-Umschalter, Toggle-Tasten | filetree `source_switcher`, `tree_toggle` (aus der neo-tree-Config *entfernt*, 2026-09-19) | ✅ |
| Git-Status-Anzeige, Diagnostik-Marken, Copy/Move-Markierung | filetree `git_status`, `lsp_diagnostics`, `copy_move` (eigene Extmarks; neo-tree-Varianten abgeschaltet) | ✅ |
| Source „buffers" | `pickers builtin buffers` ist ein Picker, kein Baum | 🟡 |
| Source „git_status" (Baum der Änderungen) | `pickers git_status_filtered`, gitsuite `:Git status` (Quickfix) | 🟡 |
| Source „document_symbols" | my.nvim/lsp.nvim Winbar-Pfad; `builtin treesitter` | 🟡 |
| Source „diagnostics" (neo-tree-diagnostics) | trouble (lsp-Pack) | 🟡 |
| Source „tests" (neo-tree-tests-source) | `test.nvim` als Konzept (`docs/ROADMAP/LONG_RUN/IDEAS/testing.md`, Teil B/D), nicht gebaut | ❌ |

Abhängigkeitskette: neo-tree zieht laut `plugins/neotree.lua` neotest, die Adapter (Kommentar: acht), nvim-treesitter, devicons, nui, plenary, vim-test und FixCursorHold nach
(Messung im Kommentar: 44 statt 29 geladene Plugins bei Eager-Load). Fällt die „tests"-Source weg, entfällt der Grund für die neotest-Abhängigkeit
von neo-tree (laut Kommentar braucht sie den neotest-Consumer).

### 3.4 Completion und LSP-Werkzeug — blink · nvim-cmp · mason ↔ lsp.nvim

| Funktion | Eigenes | Stand |
|---|---|---|
| Completion-Engine | – (lsp.nvim wählt per `pack.completion`, Default `blink`) | ❌ Engine |
| Eigene Quellen (Personal-Plugin-Namen, Markdown-Wörter), Nutzungs-Ranking über Neustarts | `lsp.completion.*` (engine-neutral) | ✅ Mehrwert |
| Keymap `<CR>`/`<C-y>`/`<C-x>`/`Tab` | `plugins/completion.lua` (beide Engines gepflegt) | ✅ |
| nvim-cmp | **nicht installiert**; der cmp-Zweig ist laut Datei-Kommentar „never exercised" | 🟡 toter Alternativpfad |
| Server-/Tool-Installation | lsp.nvim `mason.ensure_install` orchestriert, `hard = false`; mason selbst ist das Register | ❌ Engine |

Zusätzlich vom lsp-Pack **installierte** externe Plugins (nicht in `lua/plugins/*.lua`, daher nicht in der 31er-Liste): conform, trouble, lazydev,
lensline, inc-rename, workspace-diagnostics — alle „aufgesetzt" (Optional-Tabelle in `lsp.nvim/docs/requirements.md`).

### 3.5 Syntax und Editing — treesitter(+textobjects) · mini.ai · targets · matchup · autopairs · autotag · visual-multi

| Plugin | Genutzt für | Eigenes | Anmerkung |
|---|---|---|---|
| nvim-treesitter | Parser-Installation, Highlight-Start, Indent | – (viele eigene Plugins nutzen `vim.treesitter` direkt) | Pin mit veralteter Begründung (s. o.) |
| treesitter-textobjects | **nur** `move` für `[u`/`]u` (`bindings/mappings/treesitter_structure.lua`); `select`/`swap` ungenutzt; eigene Queries in `after/queries/*/textobjects.scm` | – | schaltbar über `plugins.modes` |
| mini.ai | `a`/`i`-Objekte, Default-Setup ohne eigene Objekte | – | **überschneidet sich mit targets.vim** (beide: Quotes, Klammern, Argumente, next/last) — gleichzeitiges Verhalten nicht geprüft |
| targets.vim | s. o. | – | upstream seit 2024-07 ohne Push |
| vim-matchup | `%`-Erweiterung, Offscreen-Match → `status_manual` | ui.nvim `matchup_offscreen` konsumiert es | ❌ Pendant |
| nvim-autopairs | Schließen von `()[]{}` und Quotes | – (cascade deckt Listen/Zyklen/Sequenzen/Strings/Transpose, **nicht** Klammern) | ❌; Config-Kommentar: blink-`<CR>` fällt auf autopairs zurück |
| nvim-ts-autotag | Tags schließen/umbenennen | lsp.nvim Astro-Modul braucht es | ❌ |
| vim-visual-multi | Multi-Cursor, nur `<C-n>` (alle Default-Maps abgeschaltet) | – | ❌; upstream seit 2024-09 ohne Push |

Eigene Surround-Maps (visuell, `bindings/mappings/surrounding.lua`) gibt es; ein Surround-*Plugin* ist nicht installiert.

### 3.6 UI-Infrastruktur — which-key · tokyonight · devicons · nvim-notify · nui · plenary

| Plugin | Befund |
|---|---|
| which-key | Popup und Gruppenlabels: kein Pendant. Gleichzeitig ist es der **Host für optionale Labels** von vielen eigenen Plugins (152 Dateien erwähnen `which_key`); das lsp.nvim-Roadmap hält ausdrücklich fest, nur `<leader>x` zu labeln. Eigene In-Buffer-Cheatsheets (`?` in filetree, pickers) decken *ihre eigenen* Maps, nicht die globalen. Pin 2025-10-28. |
| tokyonight | Das Colorscheme selbst; ui.nvim hat Palette, Transparenz und `theme_toggle = { "default", "tokyonight" }`, liefert aber kein Schema. Außerhalb dessen, was ein UI-Plugin ersetzt (➖). |
| nvim-web-devicons | `lib.nvim.ui.icons` ist ein eigener Daten-Fallback (~150 Endungen, ~90 Dateinamen); mit `prefer_plugin = true` (Default) gewinnt das Plugin (500 Endungen). Konsumenten: ui.nvim, lsp-Winbar, neo-tree, telescope. |
| nvim-notify | `lib.nvim.notify` + `ui.kit.toast` decken Benachrichtigungen; noice routet `notify` auf `mini`. Einziger Restbezug: noice ruft `require("notify")` in `util.notify` für **eigene** Fehlermeldungen auf, wenn das Modul existiert (`noice/util/init.lua:275`), und im `notify`-View (nicht benutzt). Eine Abhängigkeit, die nichts Sichtbares mehr tut. |
| nui.nvim | Nur noice und neo-tree brauchen es (Hard-Dependencies). Die eigene `ui.kit` ist nui-frei. In der Config steht es zusätzlich *allein* in `plugins/ui.lua`. |
| plenary | **Kein eigenes Laufzeit-Plugin** nutzt es (nur `documentation.nvim`-Tests). Alle Abnehmer sind extern: telescope, neo-tree, diffview, neogit, neotest samt Adapter. Upstream-README: „This repository is no longer actively maintained and will be officially archived soon" (`archived: false` laut API am 2026-10-01). |

### 3.7 Tests, Debugging und sonstige installierte Plugins

- **neotest** (+ go/jest/plenary/python/rust/vim-test/vitest-Adapter, nvim-nio, vim-test, FixCursorHold): Testlauf-Oberfläche. Kein eigenes Pendant; das Konzept
  `test.nvim` (IDEAS/testing.md B/D) hebt die bestehende Config in ein Plugin, ersetzt neotest aber nicht. `debugging.nvim` hat nur Diagnose-Befehle
  (`:Debug neotest adapters|state|file|root|framework|discover`). In `plugins/neotest.lua` stehen nur drei Adapter fest; die Config-Datei markiert
  das als „parked" (Adapter-Split-Brain mit `config.neotest.adapters.factory`).
- **nvim-dap, nvim-dap-ui, nvim-dap-view, nvim-dap-virtual-text, one-small-step-for-vimkind:** `dap.nvim` ist laut README ausdrücklich „a config layer on
  top of nvim-dap". Aufgesetzt, keine Ablösung.
- **wezterm-types:** reines Typ-Stub-Paket für LuaLS (Dev).

## 4. Abdeckung in Zahlen (nur die 31)

| Beziehung | Anzahl | Plugins |
|---|---:|---|
| Engine/Host (Eigenes sitzt drauf) | 11 | telescope, fzf-lua, snacks, neo-tree, gitsigns, blink.cmp, mason, neogit, diffview, nvim-treesitter, treesitter-textobjects |
| (teilweise) ersetzbar durch Eigenes | 5 | search.nvim, telescope-github, nvim-notify, telescope-file-browser, nvim-web-devicons |
| Zulieferer eines anderen externen Plugins | 5 | nui, plenary, telescope-fzf-native, neo-tree-diagnostics, neo-tree-tests-source |
| kein eigenes Pendant | 9 | tokyonight, which-key, vim-matchup, mini.ai, targets.vim, nvim-autopairs, nvim-ts-autotag, vim-visual-multi, neotest |
| nicht installiert | 1 | nvim-cmp |

## 5. Lückenliste — was nur ein externes Plugin liefert und täglich genutzt wird

Nach Relevanz in dieser Config, nicht nach Aufwand:

1. **Git-Signs und Hunk-Engine** (gitsigns): Signs, Index-Schreibzugriffe, Hunk-Navigation, `ih`. gitsuite adaptiert das bewusst.
2. **Tree-Rendering und -Sources** (neo-tree): filetree ist Feature-Schicht ohne Renderer; vier der sechs Sources (`buffers`, `git_status`,
   `document_symbols`, `diagnostics`) haben nur Picker/Quickfix-Äquivalente, `tests` gar keins.
3. **Completion-Engine und Installer** (blink, mason): beides „hard=false" in lsp.nvim, aber ohne sie läuft nichts.
4. **Parser** (nvim-treesitter): kein Pendant, durch den Pin außerdem ein Update-Risiko.
5. **Editing-Primitive** (autopairs, autotag, matchup, visual-multi, mini.ai/targets): kein Pendant, auch kein Roadmap-Eintrag (Roadmaps durchsucht,
   keine Fundstelle). cascade deckt andere Dinge.
6. **Staging-UI/Commit/Rebase** (neogit) und **Diffview-Panel**: gitsuite lehnt das ausdrücklich ab; lazygit-Float als Ersatz-Bedienung.
7. **Testlauf-Oberfläche** (neotest): `test.nvim` nur Konzept.
8. **Key-Popup** (which-key): kein Pendant; eigene Plugins labeln nur optional dort hinein.
9. **`quickfile`** (snacks): kleiner Nebeneffekt, kein Pendant.

### Kein eigenes Pendant und keins geplant (nach Roadmap-Suche)

tokyonight (➖ Schema), which-key-Popup, vim-matchup, mini.ai, targets.vim, nvim-autopairs, nvim-ts-autotag, vim-visual-multi. Für neotest existiert ein
Konzept (`test.nvim`), für den Rest keine Roadmap-Fundstelle in `WKDBooks/…/ROADMAP*.md` oder `00_ROADMAP.md`.

## 6. Abhängigkeiten und Wartungsbefunde (nur beschrieben)

| Befund | Beleg | Wirkung |
|---|---|---|
| `plenary.nvim`: Upstream kündigt Archivierung an; alle Abnehmer extern | README des installierten Stands; Zähltabelle §2 | telescope, neo-tree, diffview, neogit und neotest hängen daran |
| `nvim-notify`: benutzt nichts Sichtbares | noice routet auf `mini`; nur `noice.util.notify` (Fehlerfall) | Entfernen würde nur noices *eigene* Fehlermeldungen anders anzeigen |
| `telescope-github`: keine Nutzung gefunden | kein Treffer in `lua/`, `after/`; nur `dependencies`-Eintrag | `pickers.sources.github` deckt Issues/PRs |
| `nvim-cmp`-Spec ohne installiertes Plugin | `plugins/completion.lua`, lsp.nvim `pack.completion` (Default `blink`) | toter, ungetesteter Zweig |
| `search.nvim` (189★, 2024-05) ↔ `pickers.tabs`, **nicht aktiviert** | `specs/navigate.lua:858` auskommentiert | Funktion vorhanden, Config nutzt sie nicht |
| mini.ai + targets.vim gleichzeitig | beide `event = "VeryLazy"` | überlappende Objekte; Zusammenspiel nicht geprüft |
| `nvim-treesitter`-Pin: Kommentar „unpin once … 0.12" | `plugins/treesitter.lua`; Neovim ist 0.12.2 | Begründung gilt nicht mehr; Entpinnen nicht getestet |
| `diffview` (2024-08), `vim-visual-multi` (2024-09), `targets.vim` (2024-07), `neo-tree-diagnostics` (2024-02) ohne Upstream-Push | `gh api` | Wartungsrisiko, bei diffview existiert ein Ausfallpfad (diff.nvim) |
| `blink.cmp`-Pin 2026-04-04, Upstream 2026-10-01; `neogit` Pin 2026-08-21 | `git log` im Plugin-Verzeichnis | nur Hinweis auf den Abstand |
| Direkte Telescope/fzf-lua-Maps, obwohl pickers.nvim denselben Picker bietet | `bindings/mappings/{telescope,fzf}.lua` | hält zwei Engines dauerhaft nötig |
| `snacks` in den noice-Dependencies, aber ohnehin Engine | `plugins/ui.lua` | kein Handlungsbedarf |

Nach der Analyse bleiben als **Abhängigkeitskette** übrig: neo-tree → nui, plenary, devicons, neotest (+ Adapter, nio, vim-test, FixCursorHold),
diagnostics- und tests-Source; telescope → plenary, treesitter, telescope-github (ungenutzt), file-browser, fzf-native; noice → nui, nvim-notify (ungenutzt),
snacks; diffview/neogit → plenary. `nui.nvim` fiele nur weg, wenn *beide* neo-tree und noice gingen.

## 7. Abweichung zwischen Doku und Code

- **gitsuite `docs/scope.md` und `docs/around-it.md`** sagen, `:Git hunk *` nutze „gitsigns' engine when available, a native `git`-only
  implementation otherwise". Der Code sagt etwas anderes: `lua/gitsuite/features/hunk/init.lua:4` — *„There is no native fallback for
  stage/reset/toggle-deleted"*; `stage`, `reset`, `stage_buffer`, `reset_buffer`, `toggle_deleted` und `inline` rufen bei fehlendem gitsigns `unavailable(...)`.
  Nur `preview` fällt auf `:Git diff head` zurück. **Nicht korrigiert** (Plugin-Doku; Entscheidung, ob die Doku oder der Code angepasst wird, liegt bei dir).
- **Config-Kommentar `plugins/treesitter.lua`:** „Unpin once this Neovim is on 0.12" — Neovim ist 0.12.2 (siehe §3.5/§6).

## 8. Nicht geprüft

- **Laufzeitverhalten**: nichts wurde ausgeführt; alle Abdeckungsaussagen beruhen auf Quelltext, Doku und Zählung. Insbesondere nicht getestet: ob die
  pickers-Builtins das Verhalten der direkt gebundenen `<leader>f*`-Maps 1:1 wiedergeben; wie mini.ai und targets.vim zusammen reagieren; ob nvim-treesitter
  mit entferntem Pin läuft; ob `pickers.tabs` auf snacks das search.nvim-Tabverhalten (Query wandert mit) wirklich wie dokumentiert erreicht.
- **Feature-Tiefe je Plugin**: die Matrizen führen Funktionsgruppen, keine vollständigen Optionslisten der Upstream-Plugins.
- **Snacks `debug`** gegenüber `debugging.nvim`: kein Vergleich durchgeführt.
- **Telescope-spezifischer Code in den ~11 eigenen Plugins**: gezählt, aber nicht je Plugin auf einen Fallback ohne telescope geprüft.
- **GitHub-Zahlen** sind Momentwerte vom 2026-10-01 (`gh api`); Sterne sind nur ein grobes Reichweitenmaß.
- Die Roadmap-Regel „bei mittlerer Ähnlichkeit nur die reichweitenstärksten" wurde hier nicht angewandt: es gibt keine Ähnlichkeitsstufe, weil es um
  *eingesetzte* Plugins geht, nicht um fremde Konkurrenz.
- Plugins, die **nicht** in `lua/plugins/*.lua` stehen, aber installiert sind (conform, trouble, lazydev, lensline, inc-rename, workspace-diagnostics, dap-Stack,
  neotest-Adapter): in §3.4/§3.7 nur einzeilig eingeordnet.

## 9. Vorschläge für Entscheidungen (keine Empfehlung zum Ersetzen)

Nur Hinweise, welche Entscheidungen *anstehen*, falls du den Bestand ausdünnen willst:

1. Soll `pickers.tabs` aktiviert werden (damit `search.nvim` überflüssig wird)? Voraussetzung wäre eine Entscheidung zu `<Tab>` (telescope-Mehrfachauswahl).
2. Sollen die 13 direkten Telescope/fzf-lua-Maps auf `:Pickers builtin …` umgestellt werden (macht eine Engine entbehrlich)?
3. `telescope-github` und `nvim-notify` aus den Abhängigkeiten nehmen? (Beides ohne sichtbaren Nutzen.)
4. gitsuite-Doku oder -Code angleichen (§7).
5. `plenary.nvim`-Risiko: beobachten, solange telescope/neo-tree/diffview/neogit/neotest es brauchen.
6. nvim-treesitter-Pin und -Kommentar neu bewerten.
7. Für die Editing-Primitive (autopairs, autotag, matchup, visual-multi, Textobjekte) bewusst entscheiden, ob sie dauerhaft extern bleiben.
