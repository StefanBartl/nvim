# `pickers.nvim`

**pickers.nvim** (~4000 Zeilen) hat ein sauberes, engine-agnostisches Modell:
- `scope × action` — 8 Scopes (`cwd`/`config`/`folder`/`repos`/`wkdbooks`/`system`/`drives`/`dir`) + user-definierte Collections, × 2 Actions (`files`/`grep`)
- Querschnitts-Features: `entry_actions` (3 Engines ✓), `history` (nur telescope+fzf), `selected_index` (nur telescope)
- Engine-Interface: `available/pick_files/live_grep/pick_item/pick_dir`

**config/snacks** (~2800 Zeilen) hat drei Dinge, die pickers.nvim gar nicht abbildet:
1. **In-Picker-Keymaps** ([keymaps.lua](../../C:/Users/bartl/AppData/Local/nvim/lua/config/snacks/picker/keymaps.lua)) — PageUp/Down Preview-Scroll, C-Left/Right H-Scroll, C-p/C-n History. Existiert **nur** für snacks.
2. **~32 native Picker-Keymaps** ([standard.lua](../../C:/Users/bartl/AppData/Local/nvim/lua/config/snacks/mappings/standard.lua)) — git, github, lsp, buffers, recent, projects, colorschemes, help… Alle hart auf `snacks.picker.*`.
3. **~40 `:Snacks …` Usercommands** — dieselbe Composer-Idee wie `:Pickers`, nur parallel implementiert.

## Zwei konkrete Bugs, die ich dabei gefunden habe

- **`get_input_keys()` wird nirgends aufgerufen.** [picker/init.lua:38-39](../../C:/Users/bartl/AppData/Local/nvim/lua/config/snacks/picker/init.lua#L38) nutzt nur `get_list_keys` und `get_preview_keys`. Heißt: im **Input-Fenster** (wo du beim Tippen bist) gibt es *kein* PageUp/PageDown und *keine* C-p/C-n History. Das ist vermutlich genau der Effekt, den du bei `<leader>ff` bemerkt hast.
- **Key-Inkonsistenz create_file**: [keymaps.lua:20](../../C:/Users/bartl/AppData/Local/nvim/lua/config/snacks/picker/keymaps.lua#L20) hardcodet `<M-a>`, [DEFAULTS.lua:100](lua/pickers/config/DEFAULTS.lua#L100) sagt `<C-a>`. Zwei Quellen der Wahrheit für dieselbe Aktion.

---

## Der Kern des Problems

Dein Ziel — „was ich implementiere, gilt für alle Picker" — scheitert aktuell an einer fehlenden Schicht. pickers.nvim kennt *Scopes*, aber keine **In-Picker-UX** und keine **nativen Picker** (git/lsp/…). Genau diese beiden Dinge liegen deshalb noch config-seitig und snacks-only.

Es braucht also zwei neue Layer in pickers.nvim:

```
pickers/keys/      ← engine-agnostische In-Picker-Keymaps   (Phase 1)
pickers/builtins/  ← native Picker (git/lsp/search/…)        (Phase 3)
```

---

## Schlachtplan

### Phase 1 — `pickers.keys`: In-Picker-Keymaps vereinheitlichen *(höchste Priorität)*

Neues Modul mit engine-agnostischem Vokabular an Aktionen:

```
preview_scroll_up/down/left/right, history_back/forward,
select_default, select_split/vsplit/tab, toggle_preview,
send_to_qflist, close, create_file, open_background
```

Config-Oberfläche in `DEFAULTS.lua`:
```lua
keys = {
  enable = true,
  preview_scroll_down = { "<PageDown>", mode = { "i", "n" } },
  preview_scroll_up   = { "<PageUp>",   mode = { "i", "n" } },
  preview_scroll_right= "<C-Right>",
  preview_scroll_left = "<C-Left>",
  history_back        = "<C-p>",
  history_forward     = "<C-n>",
},
```

Drei Adapter unter `pickers/keys/adapters/`:
- **snacks** → `win.input.keys` / `win.list.keys` / `win.preview.keys`. Direktes Mapping, alle Actions nativ da. **Behebt nebenbei den `get_input_keys`-Bug**, weil `input` diesmal wirklich befüllt wird.
- **telescope** → `defaults.mappings` (`i`/`n`), `actions.preview_scrolling_up/down/left/right`, `cycle_history_prev/next`. Volle Parität.
- **fzf-lua** → hier die **begründeten Ausnahmen**, die du erwähnst. `keymap.builtin` kann `preview-page-up/down` und `preview-page-left/right`; History ist aber `--history` im fzf-Prozess mit fixem `ctrl-p`/`ctrl-n` und **nicht** frei belegbar. Adapter mappt was geht, und meldet nicht-abbildbare Keys einmalig über `notify.debug` statt still zu schlucken.

`entry_actions` wird von diesem Layer **absorbiert** (create_file/open_background sind einfach zwei weitere Actions) — löst die `<M-a>`/`<C-a>`-Doppelung strukturell auf. `entry_actions.keys` bleibt als deprecated Alias erhalten.

Ergebnis dieser Phase allein: `<leader>ff` hat PageUp/PageDown — egal welche Engine.

### Phase 2 — Snacks-History nachrüsten

`pickers/history/` kennt telescope + fzf, aber nicht snacks. Snacks hat eigene History pro `source`. Ergänzen: `M.snacks_opts(cfg)` + Behandlung in `patch()`. Danach ist `history.enabled = true` über alle drei Engines hinweg ehrlich.

### Phase 3 — `pickers.builtins`: die nativen Picker migrieren

Registry `name → per-Engine-Implementierung`, z.B.:

```lua
git_branches = {
  snacks    = function(o) require("snacks").picker.git_branches(o) end,
  telescope = function(o) require("telescope.builtin").git_branches(o) end,
  fzf       = function(o) require("fzf-lua").git_branches(o) end,
},
```

Deckt die ~32 Keymaps aus `standard.lua` ab. Ehrlicher Realitäts-Check nach Kategorie:

| Kategorie | telescope | fzf-lua | Anmerkung |
|---|---|---|---|
| git (branches/log/status/stash/diff) | ✓ | ✓ | volle Parität |
| lsp (definitions/refs/symbols/calls) | ✓ | ✓ | volle Parität |
| search (help/keymaps/marks/jumps/registers/…) | ✓ | ✓ | Namen weichen ab, Mapping nötig |
| buffers/recent/colorschemes | ✓ | ✓ | telescope: `oldfiles` statt `recent` |
| **github** (gh_issue/gh_pr) | ✗ | ✗ | nur snacks nativ → Fallback dokumentieren |
| **projects** | ✗ | ✗ | snacks `recent_projects`; ließe sich aber gut als pickers-Collection über `repos_dir` nachbauen |
| **explorer / dashboard** | — | — | **kein Picker.** Bleibt config-seitig, migriert nicht. |

Dazu `:Pickers builtin <name>` mit Tab-Completion über den existierenden Composer — ersetzt `:Snacks …` und die ~40 Einzelbefehle.

### Phase 4 — Config abspecken

- `config/snacks/picker/` → entfällt komplett (ersetzt durch `pickers.keys`)
- `config/snacks/mappings/standard.lua` → wird zu einer Keymap-Tabelle in `pickers` config
- `config/snacks/usrcmds/` → entfällt (ersetzt durch `:Pickers builtin`)
- **bleibt**: `custom_dashboard/`, `mappings/extended.lua` (debug/profiler/scratch/dim — keine Picker), `plugins/snacks.lua`

Snacks-Setup schrumpft auf:
```lua
picker = require("pickers").snacks_opts()
```

### Phase 5 — Doku & Tests

`docs/KEYMAPS.md` bekommt eine **Engine-Parity-Matrix** (welche Action auf welcher Engine, mit Begründung bei Lücken). Tests für Key-Normalisierung und Builtin-Registry-Vollständigkeit in `docs/TESTS/`. `health.lua` meldet nicht abbildbare Keys der aktiven Engine.

---

## Reihenfolge & Aufwand

| Phase | Nutzen | Aufwand | |
|---|---|---|---|
| 1 — `pickers.keys` | **sehr hoch** — löst dein Kernproblem | mittel | zuerst |
| 2 — Snacks-History | mittel | klein | schneller Gewinn |
| 3 — `pickers.builtins` | hoch | **groß** | inkrementell: git → lsp → search |
| 4 — Config abspecken | Aufräumen | klein | folgt aus 1+3 |
| 5 — Doku/Tests | Absicherung | mittel | begleitend |

Phase 1+2 zusammen sind ein abgeschlossener, sofort spürbarer Schritt. Phase 3 kann kategorieweise nachziehen, ohne dass etwas kaputtgeht.

---

Zwei Punkte, bei denen ich deine Entscheidung bräuchte, bevor ich mit Phase 1 anfange:

1. **`entry_actions` absorbieren oder danebenstellen?** Ich empfehle absorbieren (eine Wahrheit für alle In-Picker-Keys), aber das ist ein Breaking Change an der Config-Oberfläche deines eigenen Plugins.
2. **Wie hart soll die fzf-Ausnahme sein?** Variante A: nicht-abbildbare Keys still weglassen. Variante B: einmalig warnen. Ich tendiere zu B mit `notify.debug`, damit Lücken sichtbar bleiben, ohne zu nerven.
---

