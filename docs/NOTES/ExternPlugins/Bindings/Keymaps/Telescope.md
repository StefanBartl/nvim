# Telescope — Keymaps

Betrifft `nvim-telescope/telescope.nvim` und `nvim-telescope/telescope-file-browser.nvim`.
Registriert/konfiguriert in:

- [lua/bindings/mappings/telescope.lua](../../../../../lua/bindings/mappings/telescope.lua)
  (aufgerufen aus `bindings.mappings.init`) — die Leader-Keymaps.
- [lua/config/telescope/init.lua](../../../../../lua/config/telescope/init.lua) —
  `telescope.setup()`, inkl. Merge der In-Picker-`mappings`.
- [lua/config/telescope/file_browser/keymaps.lua](../../../../../lua/config/telescope/file_browser/keymaps.lua) —
  die einzige lokale Ergänzung zu den In-Picker-Mappings.
- [lua/plugins/telescope.lua](../../../../../lua/plugins/telescope.lua) — Lazy-Specs
  für `telescope.nvim`, `telescope-fzf-native.nvim`, `telescope-file-browser.nvim`
  und `search.nvim` (kein `keys = {...}` in den Specs — alle Keymaps kommen aus
  `bindings.mappings.telescope`).

**Wichtiger Unterschied zu Harpoon.md:** Hier ist die Lage gemischt. Anders als
Harpoon (komplett umgebaut) ist Telescope zu großen Teilen **Plugin-Standard** —
insbesondere fast alle In-Picker-Tasten (Insert-/Normal-Mode-Mappings innerhalb
eines offenen Pickers) sind unverändertes `telescope.nvim`-Werkseinstellung.
Die wenigen Leader-Keymaps, die überhaupt existieren, sind dagegen zwangsläufig
**eigene**, denn `telescope.nvim` selbst liefert von Haus aus **keine**
Leader-Keymaps (nur `:Telescope ...`-Commands).

Zusätzliche Komplikation: **`pickers.nvim`** (StefanBartl/pickers.nvim, separates
Plugin, lokal aus `E:/repos/pickers.nvim`) patcht global einen Teil von
Telescopes `defaults.mappings` nach — unabhängig davon, ob der Picker über
`config.telescope` oder direkt über `:Telescope ...`/`pickers.nvim` selbst
geöffnet wurde. Das passiert **nicht** in den hier gelisteten Dateien, sondern
in `pickers.nvim`s eigenem `lua/pickers/keys/adapters/telescope.lua`
(`M.patch()`, per `vim.schedule`), konfiguriert über `pickers.setup({ keys =
{...} })` in [lua/plugins/personal/init.lua](../../../../../lua/plugins/personal/init.lua).
Siehe auch die ausführliche Doku dort:
[pickers.nvim — Keymaps Cheatsheet](../../../PersonelPlugins/BINDINGS/Keymaps/pickers.nvim.md)
(§4 "Unified `keys`-Namespace"). Dieses Dokument fasst nur zusammen, **wie sich
das auf Telescope-Picker konkret auswirkt** — für alle anderen `pickers.nvim`-
Details siehe dort.

Markierung pro Zeile: **[default]** = unverändert Plugin-Werkseinstellung,
**[custom]** = in diesem Config-Repo gesetzt/überschrieben (egal ob aus
`config.telescope`, `bindings.mappings.telescope` oder `pickers.nvim`s Patch).

---

## 1. Leader-Keymaps (alle `[custom]`)

Aus `bindings.mappings.telescope.lua`. `telescope.nvim` selbst bindet nichts
davon — jede Zeile ist eine bewusste Config-Entscheidung.

| Mapping | Aktion | Ziel | Status |
|---|---|---|---|
| `<leader>ts` | Telescope-Picker-Übersicht öffnen | `:Telescope` | [custom] |
| `<leader>tg` | Grep mit eigenem Prompt (`lib.nvim.ui.kit.input`) über `telescope.builtin.grep_string` | Lua-Funktion | [custom] |
| `<leader>fa` | Find All Files (folgt Symlinks, `no_ignore`, `hidden`) | `:Telescope find_files follow=true no_ignore=true hidden=true` | [custom] |
| `<leader>,` | File-Browser-Extension am aktuellen **CWD** öffnen (lädt `file_browser` bei Bedarf nach) | Lua-Funktion → `telescope.extensions.file_browser.file_browser({ path = vim.uv.cwd() })` | [custom] |

Hinweis aus dem Quellcode: `<leader>.` gehört inzwischen `pickers.nvim`s
eigenem engine-agnostischem `explorer`-Builtin (File-Browser "am aktuellen
Buffer") — dieses Modul behält nur noch die CWD-Variante, weil
`pickers.builtins` keinen Pfad-Override mit engine-übergreifend stabiler
Opts-Form annimmt.

**Auskommentiert/inaktiv** (Zeilen 26–34 in der Quelldatei, bewusst
deaktiviert, kein Effekt): `<leader><leader>` (Live Grep), `<leader>fk`
(keymaps), `<leader>com` (commands), `<leader>col` (colorscheme), `<leader>ff`
(find_files), `<leader>help` (help_tags), `<leader>cb`
(current_buffer_fuzzy_find), `<leader>bu` (buffers), `<leader>old`
(oldfiles). Diese sind **nicht aktiv** und daher nicht Teil der "currently
active bindings" — hier nur der Vollständigkeit halber erwähnt, falls sie
später reaktiviert werden.

### Verwandte Keymaps außerhalb dieser Datei (Cross-Reference)

Diese öffnen ebenfalls Telescope-Picker, gehören aber zu anderen Plugins/
Features und werden dort dokumentiert, nicht hier:

**Nicht live:** eine Verweistabelle. Sie zeigt auf Maps, die **andere**
Blätter besitzen (Harpoon, Astro-Buffer, LSP-Tools); geprüft werden sie
dort, wo sie registriert werden, nicht hier.

| Mapping | Aktion | Quelle |
|---|---|---|
| `<leader>ht` | Harpoon-Liste als Telescope-Picker | [Harpoon.md](Harpoon.md), `config/harpoon/ui/menu_telescope.lua` |
| `gC` / `gL` / `gP` (Astro-Buffer) | Astro-Komponenten/-Layouts/-Pages finden (`telescope.builtin.find_files`) | `lsp/languages/webdev/astro/keymaps.lua` |
| (LSP-Tool, kein festes Leader-Mapping) | Workspace-Symbol-Picker (eigener Telescope-Picker über `telescope.pickers`/`finders`/`previewers`) | `lsp/tools/ts_type_lookup/ts_telescope_picker.lua` |
| (Neotest-Command, kein festes Leader-Mapping) | Neotest-Actions-Picker | `config/neotest/telescope/init.lua`, `config/neotest/commands/init.lua` |
| `<leader>s` | `search.nvim` — tabbed UI *um* Telescope herum (eigenes Plugin, `FabianWirth/search.nvim`) | `plugins/telescope.lua`, `config/search/init.lua` |

Diese nutzen Telescope nur als Backend/Picker-Engine für eine fremde Domäne
(Astro, LSP-Tooling, Neotest, Harpoon) — sie sind keine "Telescope-Bindings"
im engeren Sinn und daher hier nur verlinkt, nicht ausgeführt.

---

## 2. File-Browser-Extension: lokale Zusatz-Mappings

Aus `config.telescope.file_browser.keymaps.lua`, gemerged in
`config.telescope.defaults().mappings` (gilt **global** für jeden
Telescope-Picker, nicht nur `file_browser`, da `telescope.setup()`s
`defaults.mappings` nicht picker-scoped ist):

| Modus | Taste | Aktion | Status |
|---|---|---|---|
| Insert | `?` | `actions.which_key` (Mappings-Übersicht) | **[custom]** — Telescope bindet `which_key` im Insert-Mode nur auf `<C-/>`/`<C-_>`, nicht auf `?`. Diese Zeile fügt `?` zusätzlich hinzu. |
| Normal | `?` | `actions.which_key` | [default] (faktisch wirkungslos) — Telescope bindet `?` im Normal-Mode ohnehin schon standardmäßig auf `which_key`; diese Zeile reasserted nur denselben Wert. |

---

## 3. In-Picker-Mappings — effektiver Stand (Insert-Mode)

Basis: `telescope.nvim`s `mappings.default_mappings` (`lua/telescope/mappings.lua`),
überschrieben/ergänzt durch (a) den `km`-Merge in `config.telescope.init.lua`
(§2 oben + Entry-Actions) und (b) `pickers.nvim`s globalem Patch. Nur
abweichende/hinzugefügte Zeilen sind unten kommentiert — alles ohne Kommentar
ist unverändertes `telescope.nvim`-Werksverhalten.

| Taste | Aktion | Status |
|---|---|---|
| `<C-n>` | **überschrieben:** `history_forward` (`cycle_history_next`, pickers.nvim) | **[custom]** — Default wäre `move_selection_next`. |
| `<C-p>` | **überschrieben:** `history_back` (`cycle_history_prev`, pickers.nvim) | **[custom]** — Default wäre `move_selection_previous`. |
| `<PageUp>` | **überschrieben:** `preview_scroll_up` (`preview_scrolling_up`, pickers.nvim) | **[custom]** — Default wäre `results_scrolling_up`. |
| `<PageDown>` | **überschrieben:** `preview_scroll_down` (`preview_scrolling_down`, pickers.nvim) | **[custom]** — Default wäre `results_scrolling_down`. |
| `<M-Left>` | `preview_scrolling_left` (pickers.nvim, `keys.preview_scroll_left` explizit auf `<M-Left>` gesetzt statt Plugin-Default `<C-Left>`) | **[custom]** |
| `<M-Right>` | `preview_scrolling_right` (pickers.nvim, dito statt `<C-Right>`) | **[custom]** |
| `<C-a>` | `create_file` (pickers.nvim `entry_actions`, via `config.telescope`) | **[custom]** — kein Telescope-Default auf dieser Taste. |
| `<S-CR>` | `open_background` (pickers.nvim `entry_actions`) | **[custom]** |
| `<C-o>` | `open_background` (pickers.nvim `entry_actions`) | **[custom]** — siehe Kollisions-Hinweis unten (§5). |
| `<C-s>` | `split` (`select_horizontal`, pickers.nvim) | **[custom]**, aber wirkungsgleich zu `<C-x>` (Default, s. u.) — reine Zweit-Taste. |
| `<C-v>` | `select_vertical` | [default] — pickers.nvim bindet `vsplit` zusätzlich auf **dieselbe** Taste/Aktion, also keine funktionale Änderung. |
| `<C-t>` | `select_tab` | [default] — dito für `tab`, keine Änderung. |
| `?` | zusätzlich `which_key` | **[custom]**, s. §2 |
| `<C-x>` | `select_horizontal` | [default] |
| `<CR>` | `select_default` | [default] |
| `<Down>` / `<Up>` | `move_selection_next` / `_previous` | [default] |
| `<C-c>` | `close` | [default] |
| `<C-u>` / `<C-d>` | `preview_scrolling_up` / `_down` | [default] |
| `<C-f>` / `<C-k>` | `preview_scrolling_left` / `_right` | [default] — bleiben neben `<M-Left>`/`<M-Right>` als Zweit-Tasten aktiv. |
| `<M-f>` / `<M-k>` | `results_scrolling_left` / `_right` | [default] |
| `<Tab>` / `<S-Tab>` | Toggle-Selection + move worse/better | [default] |
| `<C-q>` / `<M-q>` | Send (selected) to quickfix | [default] |
| `<C-l>` | `complete_tag` | [default] |
| `<C-/>` / `<C-_>` | `which_key` | [default] |
| `<C-w>` | `<c-s-w>` (Wort löschen im Prompt) | [default] |
| `<C-r><C-w>` / `<C-a>` / `<C-f>` / `<C-l>` | Original word/WORD/file/line einfügen | [default] |
| `<C-j>` | `nop` (deaktiviert, verhindert Newline im Prompt) | [default] |
| `<LeftMouse>` / `<2-LeftMouse>` | Mouse-Click-Actions | [default] |

## 4. In-Picker-Mappings — effektiver Stand (Normal-Mode)

Nur Abweichungen vom Insert-Mode-Verhalten bzw. Normal-Mode-spezifische
Defaults sind unten aufgeführt.

| Taste | Aktion | Status |
|---|---|---|
| `<PageUp>` / `<PageDown>` | überschrieben auf `preview_scroll_up`/`_down` (pickers.nvim) | **[custom]** — Default wäre `results_scrolling_*`, s. o. |
| `<M-Left>` / `<M-Right>` | `preview_scrolling_left` / `_right` (pickers.nvim) | **[custom]** |
| `<C-a>` | `create_file` (pickers.nvim) | **[custom]** |
| `<S-CR>` / `<C-o>` | `open_background` (pickers.nvim) | **[custom]** |
| `<C-s>` | `split` (pickers.nvim, wirkungsgleich zu `<C-x>`) | **[custom]** |
| `<esc>` | `close` | [default] |
| `j` / `k` | move next/previous | [default] |
| `H` / `M` / `L` | move to top/middle/bottom | [default] |
| `gg` / `G` | move to top/bottom | [default] |
| `?` | `which_key` (Zeile in `config.telescope.file_browser.keymaps.lua` reasserted nur den Default, s. §2) | [default] |
| `<CR>`, `<C-x>`, `<C-v>`, `<C-t>`, `<Tab>`/`<S-Tab>`, `<C-q>`/`<M-q>`, `<Down>`/`<Up>`, `<C-u>`/`<C-d>`/`<C-f>`/`<C-k>`, `<M-f>`/`<M-k>`, Mouse | wie Insert-Mode, unverändert | [default] |

**Nicht aktiviert:** `preview_toggle` (pickers.nvim-Aktion, Default `false`/
unbelegt, in dieser Config nicht überschrieben) — es gibt daher **keine**
Taste zum Ein-/Ausklappen der Preview über `pickers.nvim`.

---

## 5. `telescope-file-browser.nvim` — eigene Default-Mappings

Ausschließlich innerhalb des `file_browser`-Pickers aktiv (`fb_actions`,
`lua/telescope/_extensions/file_browser/actions.lua`). In dieser Config
**keine einzige** dieser Tasten überschrieben — nur die zusätzliche `?`-Zeile
aus §2 kommt oben drauf. Alle Zeilen unten sind daher **[default]**.

| Insert/Normal | Aktion | Beschreibung |
|---|---|---|
| `<A-c>` / `c` | `create` | Datei/Ordner an aktuellem `path` erstellen (Pfadtrenner am Ende → Ordner) |
| `<S-CR>` | `create_from_prompt` | Aus dem Prompt-Text erstellen und öffnen |
| `<A-r>` / `r` | `rename` | (Multi-)Selektion umbenennen |
| `<A-m>` / `m` | `move` | (Multi-)Selektion an `path` verschieben |
| `<A-y>` / `y` | `copy` | (Multi-)Selektion an `path` kopieren |
| `<A-d>` / `d` | `remove` | (Multi-)Selektion löschen |
| `<C-o>` / `o` | `open` | Mit System-Standardanwendung öffnen |
| `<C-g>` / `g` | `goto_parent_dir` | Zum Parent-Verzeichnis |
| `<C-e>` / `e` | `goto_home_dir` | Zum Home-Verzeichnis |
| `<C-w>` / `w` | `goto_cwd` | Zum aktuellen `cwd` |
| `<C-t>` / `t` | `change_cwd` | `cwd` auf selektierten Ordner/Datei-Parent setzen |
| `<C-f>` / `f` | `toggle_browser` | Zwischen Datei- und Ordner-Browser wechseln |
| `<C-h>` / `h` | `toggle_hidden` | Versteckte Dateien/Ordner ein-/ausblenden |
| `<C-s>` / `s` | `toggle_all` | Alle Einträge (außer `./`, `../`) selektieren |
| `<Tab>` / `<S-Tab>` | siehe `telescope.nvim` | Selektion togglen + vor/zurück springen |
| `<bs>` | `backspace` | Bei leerem Prompt: zum Parent-Verzeichnis, sonst normal |

**Kollisions-Hinweis (offene Frage, nicht abschließend verifiziert):**
`<S-CR>` und `<C-o>` sind gleichzeitig (a) `file_browser`-eigene Defaults
(`create_from_prompt` bzw. `open`) **und** (b) global von `pickers.nvim`s
`entry_actions` auf `open_background` gelegt (§3/§4). `file_browser` bindet
seine eigenen Aktionen im Picker-eigenen `attach_mappings` **nach** den
globalen `defaults.mappings` — vermutlich gewinnt also innerhalb des
`file_browser`-Pickers die `file_browser`-eigene Aktion (`create_from_prompt`/
`open`), während `open_background` auf denselben Tasten in **allen anderen**
Telescope-Pickern (find_files, live_grep, etc.) aktiv bleibt. Das wurde hier
nur aus dem Quellcode abgeleitet, nicht zur Laufzeit getestet — im Zweifel
`:Telescope file_browser` öffnen und `<C-/>`/`?` (which_key) prüfen, welche
Aktion tatsächlich unter `<C-o>`/`<S-CR>` hängt.

`<C-s>` hat dieselbe Doppelbelegung wie oben (`toggle_all` in `file_browser`
vs. `split` global via pickers.nvim) — mit derselben Vermutung (picker-lokal
gewinnt `toggle_all` innerhalb `file_browser`).

---

## 6. Extension-Konfiguration (kein Keymap, aber verhaltensrelevant)

Aus `config.telescope.extensions()` — nicht Teil der Tastenbelegung, aber
bestimmt, *was* die obigen Aktionen sehen: `path = "%:p:h"`, `cwd_to_path =
true`, `select_buffer = true`, `hidden = true`, `respect_gitignore = false`,
`follow_symlinks = true`, `use_fd = true`, `git_status = true`, `prompt_path =
true`, `display_stat = { date = true, size = true, mode = false }`. Alles
**[custom]** gegenüber `telescope-file-browser.nvim`s eigenen Defaults (siehe
Kommentare in dessen README, z. B. Default `hidden = false`,
`respect_gitignore` je nach `fd`-Verfügbarkeit, `display_stat.mode = true`).

---

## Autocmds / Usercmds

Für `telescope.nvim`/`telescope-file-browser.nvim` wurden **keine** eigenen
Autocmds oder User-Commands in diesem Config-Repo gefunden (nur die von
`telescope.nvim` selbst intern registrierten, z. B. `:Telescope` als
Plugin-Command — kein zusätzlicher Wrapper wie bei Harpoon). Es gibt daher
keine `Autocmds/Telescope.md`/`Usercmds/Telescope.md` in diesem Ordner.
