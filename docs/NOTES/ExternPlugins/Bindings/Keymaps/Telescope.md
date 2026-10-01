# Telescope — Keymaps

Betrifft `nvim-telescope/telescope.nvim`. Registriert/konfiguriert in:

- [lua/bindings/mappings/telescope.lua](../../../../../lua/bindings/mappings/telescope.lua)
  (aufgerufen aus `bindings.mappings.init`) — die Leader-Keymaps.
- [lua/config/telescope/init.lua](../../../../../lua/config/telescope/init.lua) —
  `telescope.setup()`, inkl. Merge der In-Picker-`mappings`.
- [lua/config/telescope/file_browser/keymaps.lua](../../../../../lua/config/telescope/file_browser/keymaps.lua) —
  die einzige lokale Ergänzung zu den In-Picker-Mappings (reines
  `telescope.actions.which_key`, seit 2026-10-01 **nicht** mehr von
  `telescope-file-browser.nvim` abhängig — der Modulpfad ist historisch).
- [lua/plugins/telescope.lua](../../../../../lua/plugins/telescope.lua) — Lazy-Specs
  für `telescope.nvim`, `telescope-fzf-native.nvim`
  (search.nvim seit 2026-10-01 abgelöst durch `pickers.tabs`; `telescope-github.nvim`
  und `telescope-file-browser.nvim` am selben Tag entfernt, beide ungenutzt — externe-plugins-report §9.2/§9.3;
  kein `keys = {...}` in den Specs — alle Keymaps kommen aus `bindings.mappings.telescope`).

**Wichtig:** Hier ist die Lage gemischt. Telescope ist zu großen Teilen
**Plugin-Standard** — insbesondere fast alle In-Picker-Tasten (Insert-/
Normal-Mode-Mappings innerhalb eines offenen Pickers) sind unverändertes
`telescope.nvim`-Werkseinstellung.
Die wenigen Leader-Keymaps, die überhaupt existieren, sind dagegen zwangsläufig
**eigene**, denn `telescope.nvim` selbst liefert von Haus aus **keine**
Leader-Keymaps (nur `:Telescope ...`-Commands).

Zusätzliche Komplikation: **`pickers.nvim`** (StefanBartl/pickers.nvim, separates
Plugin, lokal aus `$REPOS_DIR/pickers.nvim`) patcht global einen Teil von
Telescopes `defaults.mappings` nach — unabhängig davon, ob der Picker über
`config.telescope` oder direkt über `:Telescope ...`/`pickers.nvim` selbst
geöffnet wurde. Das passiert **nicht** in den hier gelisteten Dateien, sondern
in `pickers.nvim`s eigenem `lua/pickers/keys/adapters/telescope.lua`
(`M.patch()`, per `vim.schedule`), konfiguriert über `pickers.setup({ keys =
{...} })` in [lua/plugins/personal/init.lua](../../../../../lua/plugins/personal/init.lua).
Siehe auch die ausführliche Doku dort: pickers.nvim's eigene
[docs/BINDINGS.md](https://github.com/StefanBartl/pickers.nvim/blob/main/docs/BINDINGS.md)
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
| `<leader>tg` | Grep mit eigenem Prompt (`lib.nvim.ui.kit.input`), danach `pickers.nvim`-Live-Grep im CWD mit dem getippten Text vorbelegt (`pickers.command.handle({ "cwd", "grep" })`, Engine wählt pickers.nvim); nur ohne pickers.nvim Fallback auf `telescope.builtin.grep_string` | Lua-Funktion | [custom] |

**`<leader>ts`** (Telescope-Picker-Übersicht, `:Telescope`) und **`<leader>,`**
(File-Browser-Extension am CWD) sind seit 2026-10-01 entfernt — nie benutzt,
keine `pickers.nvim`-Entsprechung nötig gewesen (externe-plugins-report §9.2
Follow-up). `<leader>.` (`pickers.nvim`s eigenes, engine-agnostisches
`explorer`-Builtin, "am aktuellen Buffer") war bereits vorher der
Ersatz für `<leader>,` und bleibt unverändert.

**`<leader>fa` ist seit 2026-10-01 kein direkter Telescope-Call mehr**
(externe-plugins-report §9.2): engine-agnostisch über `pickers.nvim`s
eigenes opt-in `keymaps.cwd_find_all` (`plugins/personal/specs/navigate.lua`),
Ziel `:Pickers cwd files all` — gleiche drei Flags (`hidden`/`no_ignore`/
`follow`), aber nicht mehr telescope-only.

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
Blätter besitzen (Astro-Buffer, LSP-Tools); geprüft werden sie dort, wo sie
registriert werden, nicht hier.

| Mapping | Aktion | Quelle |
|---|---|---|
| `gC` / `gL` / `gP` (Astro-Buffer) | Astro-Komponenten/-Layouts/-Pages finden (`telescope.builtin.find_files`) | `lsp/languages/webdev/astro/keymaps.lua` |
| (LSP-Tool, kein festes Leader-Mapping) | Workspace-Symbol-Picker (eigener Telescope-Picker über `telescope.pickers`/`finders`/`previewers`) | `lsp/tools/ts_type_lookup/ts_telescope_picker.lua` |
| (Neotest-Command, kein festes Leader-Mapping) | Neotest-Actions-Picker | `config/neotest/telescope/init.lua`, `config/neotest/commands/init.lua` |
| `<leader>s` | `:Pickers tabs default` — Tab-Gruppe Files / All Files / Grep / Buffers über pickers.nvim (löste `search.nvim` am 2026-10-01 ab; `<Tab>`/`<S-Tab>` wechseln, Query wandert mit) | `bindings/mappings/telescope.lua`, `pickers.tabs` in `specs/navigate.lua` |

Diese nutzen Telescope nur als Backend/Picker-Engine für eine fremde Domäne
(Astro, LSP-Tooling, Neotest) — sie sind keine "Telescope-Bindings" im
engeren Sinn und daher hier nur verlinkt, nicht ausgeführt. Harpoons
Telescope-Liste (`<leader>ht`) fiel mit dem Plugin selbst weg (2026-09-19,
externe-plugins-report 7.4) — sessions.nvim's `:Session marks` wählt seine
Picker-UI automatisch (`auto`, snacks → telescope → fzf → edit), ohne eine
separate Telescope-only-Taste.

---

## 2. Lokale Zusatz-Mappings (`config.telescope.file_browser.keymaps.lua`)

Trotz des Modulpfads **nicht** von `telescope-file-browser.nvim` abhängig —
reines `telescope.actions.which_key` (Core-Telescope). Gemerged in
`config.telescope.defaults().mappings`, gilt daher **global** für jeden
Telescope-Picker, nicht nur einen einzelnen (`telescope.setup()`s
`defaults.mappings` ist nicht picker-scoped):

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
| `<C-a>` | `create_file` (pickers.nvim `entry_actions`, von pickers.nvim in `defaults.mappings` gepatcht) | **[custom]** — kein Telescope-Default auf dieser Taste. |
| `<S-CR>` | `open_background` (pickers.nvim `entry_actions`) | **[custom]** |
| `<C-o>` | `open_background` (pickers.nvim `entry_actions`) | **[custom]** — kollidierte bis 2026-10-01 mit `telescope-file-browser.nvim`s eigenem `open` innerhalb des `file_browser`-Pickers; mit der Extension entfernt, siehe §5. |
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

## 5. Entfernt: `telescope-file-browser.nvim`

Die Extension (eigene Default-Mappings, `M.extensions()`'s `file_browser`-Opts
in `config.telescope.init.lua`) ist seit 2026-10-01 deinstalliert — ihr
einziger Aufrufer (`<leader>,`, §1) wurde nie benutzt. `pickers.builtins`'
`explorer`-Eintrag auf der Telescope-Engine fängt das Fehlen bereits per
`pcall` ab (`notify.error`, kein Crash). Die früheren Abschnitte 5
(file_browser-eigene Tasten) und 6 (Extension-Konfiguration) samt ihrer
Kollisions-Hinweise (`<S-CR>`/`<C-o>`/`<C-s>` gegen `pickers.nvim`s globale
`entry_actions`) sind damit gegenstandslos und entfallen.

---

## Autocmds / Usercmds

Für `telescope.nvim` wurden **keine** eigenen Autocmds oder User-Commands in
diesem Config-Repo gefunden (nur die von `telescope.nvim` selbst intern
registrierten, z. B. `:Telescope` als Plugin-Command — kein zusätzlicher
Wrapper wie bei `:Session`). Es gibt daher keine `Autocmds/Telescope.md`/
`Usercmds/Telescope.md` in diesem Ordner.
