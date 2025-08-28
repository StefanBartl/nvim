# ui bootstrap folder – purpose and rationale

This folder centralizes small UI bootstraps that make theme switching and indentation guides robust, especially when cycling themes via pickers (e.g. `:FzfLua colorschemes`). The goal is to avoid `ColorScheme`-related races and missing highlight groups.

```
ui/
  base46_boot.lua   -- early Base46 bootstrap (cache path + core caches)
  ibl_shim.lua      -- pre-ColorScheme shim creating safe default IBL groups
  ibl.lua           -- canonical ibl (indent-blankline) setup with hooks
  README.md         -- this file
```

## Why this exists

1. Live theme switching triggers `ColorScheme` many times. Some plugins expect certain highlight groups to already exist when that autocommand fires.
2. `ibl` (the successor of indent-blankline) uses groups like `IblIndent`, `IblWhitespace`, `IblScope`. Older configs or third-party snippets sometimes still reference `IblChar`. Without a guarded alias, one can hit `E411: Highlight group not found: IblChar`.
3. When using Base46 (NvChad), compiled highlight caches should be available early so dependent plugins don’t see “half-applied” themes.

## What each file does

### base46_boot.lua

Sets `vim.g.base46_cache` and eagerly loads core Base46 caches (`syntax`, `defaults`, `statusline`) via `dofile`. This makes baseline highlight groups available before lazy plugin configs run.

### ibl_shim.lua

Registers a `ColorScheme` autocommand that defines safe default highlight links and a backward-compat alias:

* Ensures `IblIndent`, `IblWhitespace`, `IblScope` exist with non-intrusive defaults (`default = true` so themes can override).
* Creates `IblChar` as a link to `IblIndent` to keep legacy references working.

### ibl.lua

Configures `ibl` itself and, if available, its hooks. The hook re-applies the preferred highlight links on every colorscheme, making the result deterministic across theme changes.

## Load order

1. Load `ui/base46_boot.lua` as early as possible (before plugin init), especially if Base46 is used.
2. Require `ui/ibl_shim.lua` early so its `ColorScheme` shim runs before other handlers.
3. Load/require `ui/ibl.lua` in your plugin layer (lazy-loaded is fine).

Minimal example:

```lua
-- init.lua (very early)
require("ui.base46_boot")
require("ui.ibl_shim")

-- later in your plugin config (e.g. after lazy.nvim has started)
require("ui.ibl")
```

## Notes

* If not using Base46, keep `ibl_shim.lua` and `ibl.lua`; skip `base46_boot.lua`.
* To fully drop the legacy alias, replace every `IblChar` occurrence in your config with `IblIndent`, then remove the alias from the shim.
* Verification:

  * `:hi IblIndent` and `:hi IblScope` should exist.
  * `:hi IblChar` should not error (until you remove the alias).
  * Cycling themes via `:FzfLua colorschemes` should no longer throw highlight errors.

## Troubleshooting

* If highlights look off after big theme changes, recompile Base46 once:

  ```lua
  pcall(function()
    require("base46").load_all_highlights()
  end)
  ```
* Check who last set a group:

  ```
  :verbose hi IblIndent
  ```
* Ensure no legacy `vim.g.indent_blankline_*` variables remain; migrate to `ibl` options.

