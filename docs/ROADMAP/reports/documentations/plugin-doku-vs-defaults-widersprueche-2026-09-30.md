# Widersprüche zwischen Doku, Typen und Defaults in den eigenen Plugins

Stand 2026-09-30. Gefunden beim Vervollständigen der Install-Specs
(`lua/plugins/personal/specs/*.lua`, Rezept: WKDBooks `TOOLS/spec-full-options.md`).
Nichts davon wurde in den Plugins geändert; die Specs verwenden jeweils den Wert
aus dem **Code/DEFAULTS.lua**.

## hover.nvim

- `video.play_scale`: DEFAULTS.lua sagt 2.5, `@types/init.lua` sagt "Default 1.75".
- `@types/init.lua`: `Hover.VideoConfig` trägt `timeout_ms` und `cache_days`, die zu
  `Hover.OfficeConfig` gehören (verrutschter Kommentar).
- `docs/configuration.md`: `dir_keys` fehlt in der Beispiel-Tabelle, steht nur in der Key-Tabelle.

## filetree.nvim

- `tree_traverse.sync_cwd`: Code-Default `false`, `@types/config.lua` sagt "default true".
- `smart_create.auto_init_lua`, `auto_types_template`, `ask_clipboard`: Code-Default `false`,
  Typen sagen "default true". `auto_module_annot`/`notify_level` stehen nur in den Typen.
- `features.source_switcher`, `tree_toggle`, `path_copy`, `trash`, `watcher_quarantine`,
  `handle_guard`, `window_style` fehlen in `config/DEFAULTS.lua` (Defaults stecken nur in den
  Feature-Modulen).
- `docs/configuration.md` zeigt nur eine Auswahl der Feature-Optionen.

## emojis.nvim

- `checkbox.default_set` ist wirkungslos: `config.checkbox_sets(nil)` durchsucht immer alle Sets,
  obwohl DEFAULTS, Typen und Doku "Set für `:Emojis toggle` ohne Argument" beschreiben.
- Top-Level-`picks` werden index-weise gemerged (kürzere Liste behält den Default-Schwanz), nur
  `overlay.picks`, `checkbox.sets.*`, `checkbox.order` werden ersetzt.

## mdview.nvim

- `experimental.click_navigate`: Kommentar in DEFAULTS sagt "Opt in", der Wert ist `true`.
- `experimental.any_file` ist deprecated (Top-Level-`any_file` ersetzt es).

## markdown.nvim

- `fenced_scope.operations.fold`: Typ `Mkdn.FencedScopeOps` sagt "stretch; default off",
  DEFAULTS hat `true`.
- `hover.*` ist laut Typ Alias auf `Hover.Config`, DEFAULTS kennt nur einen Teil;
  `bare_paths`, `enabled`, `url` sind dort Legacy.

## gopath.nvim

- `docs/configuration.md`: `excluded_dirs` ohne `.github`/`venv`, `commands` ohne
  `to_repos_dir`/`to_nvim_dir`, `cache_roots` als nil beschrieben, `watch_patterns` fehlt
  (Default `{ "*.lua", "*.vim" }` nur in `bindings/autocmds.lua`).

## sessions.nvim

- `blacklist.paths`: Doku `{ "/tmp/", "/private/tmp/" }`, DEFAULTS `{}` (füllt erst `setup()`).
- `Sessions.Opts`-Typen kennen `chip.dock`, `track_mode`, `row_offset`, `col_offset`,
  `min_width` nicht; `keymaps.chip_toggle` fehlt in der Doku.
- Mögliche Nebenwirkung: `chip.col_offset = -1` mit `shape = "dock_left"` fällt laut Doku auf
  `rounded_chip` zurück (ungeprüft).

## casedesk.nvim

- `keymaps` steht in DEFAULTS und Doku, fehlt aber in `Casedesk.Config(.Opts)`.
- `blueprints`: Doku sagt name-keyed gemerged, Kommentar an `M.setup` sagt ersetzende Liste.
- `Casedesk.BlueprintNode` wird referenziert, ist nicht deklariert.

## ui.nvim

- Typen nennen `"rounded_chip"`/`"chip"` (`Ui.Tabline.Config.style`, `Ui.Context.ChipsOpts.shape`),
  `docs/configuration.md` und `config/tabline.lua` noch die alten Namen `rounded`/`square`/`rect`.

## Kleinere Funde

- **replacer.nvim**: `engine` typisiert als `"fzf"|"telescope"|"auto"`, Validator akzeptiert auch
  `fzf-lua`/`fzf_lua`; `history_max_entries = 0` (aus) steht nicht in DEFAULTS.
- **ai.nvim**: `ui.progress_style` im Schema ohne `"kit"` (replacer hat es); `enable` als Pflichtfeld
  typisiert; `completion.provider/model = false` als "unset"-Sentinel, Typ `string?`.
- **data.nvim**: `keymaps.preset` ist "reserved", ohne Wirkung.
- **open.nvim**: `filemanager.command` fehlt im Defaults-Block der Doku.
- **pickers.nvim**: `keys.tab_next/tab_prev` nur in `config/init.lua` und Doku, nicht in DEFAULTS.
- **color_my_ascii.nvim**: `custom_groups` in den Typen, im Code nie gelesen (tot).
- **lsp.nvim**: `diagnostics` in DEFAULTS kennt nur `ui`/`debounce_ms`, PRESETS setzt mehr;
  `lspdoctor.formatter_priority` nennt das inerte `null-ls`.
- **my.nvim**: `highlight.breadcrumbs_ctx.lua_table_root` ohne Verbraucher; `use_container_chain`
  wirkt nur in der Debug-Probe; Typ `My.BreadcrumbsCtx.prefer_lsp_function` veraltet
  (`prefer_lsp_symbols`).
- **github_stats.nvim**: `digest_dir`, `token_file` nur in den Typen; `theme` "reserved".
- **dap.nvim**: `ui.dap_view`/`ui.dap_ui` nur im Kommentar, nicht als Schlüssel.
- **documentation.nvim**: `watch`, `watch_ms`, `callhierarchy`, `diagnostics`, `mdview` sind laut
  Typ "install() only"; Wirkung über `opts` hängt an `registry.install(cfg)`.
- **recommender.nvim**: `keymaps`/`float_keymaps` Default `true`, Typen erlauben auch Tabellen.
- **insights.nvim**: `todos.keywords.PERF` ohne `color`.
- **pdfport.nvim**: Spec-`ollama_model = "qwen2.5-coder:7b"` (Coding-Modell) vs. Default `llava`
  (Vision) – gewollt?
