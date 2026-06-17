# custom.markdown

Focused Markdown folding, heading navigation, selection wrapping, TOC generation, and highlight customization for Neovim.
Single source of truth for keymaps lives in `ui/keymaps.lua`. A lightweight shim (`mappings.markdown`) can wire the module into your config but does **not** define its own maps.

---

## Table of content

- [custom.markdown](#custommarkdown)
  - [Features](#features)
  - [Install](#install)
  - [Options](#options)
  - [Blockquote highlighting](#blockquote-highlighting)
    - [Module layout](#module-layout)
  - [Keymaps (default)](#keymaps-default)
  - [Folding integration](#folding-integration)
  - [Health](#health)
  - [Notes / Limitations](#notes-limitations)

---

## Features

- **Folding**
  - Fast `foldexpr` for ATX (`#…######`) and Setext H2 (`---`).
  - Helpers: toggle under cursor, unfold-all, fold previous heading, fold H2+ (keep H1 open).
- **Headings**
  - Jump to previous/next heading (H2+), shift ATX levels with `protect_h1`.
- **Selection wrap**
  - Visual `**` wrapper with optional inner reselect.
- **TOC**
  - Markerless TOC inserted after first H1 (or after front-matter).
    Skips fenced code, GitHub-like anchors with optional de-duplication.
- **Highlight customization**
  - VS Code–style blockquote highlighting (green `>` sign + colored text).
  - Theme-independent: re-applies after `:colorscheme` changes.
  - Extensible architecture: `hl_options/hl_groups/` stubs for headings, code, and links.

---

## Install

Lazy example:

```lua
{
  "your/repo",
  ft = "markdown", -- optional but recommended
  config = function()
    require("custom.markdown").setup({
      map_double_asterisk   = true,
      keep_inner_selection  = true,
      protect_h1            = true,
      enable_keymaps        = true,  -- install keymaps
      ft_only               = true,  -- keymaps only in Markdown buffers
      use_zf_override       = false, -- keep native 'zf'; set true to override
      enable_autocmds       = false, -- only for your own UI/filetype hooks
      blockquote_hl = {
        fg     = "#6A9955",          -- green foreground (VS Code default)
        italic = true,
      },
    })
  end,
}
```

Prefer a FileType-oriented entrypoint? The shim is fine:

```lua
require("mappings.markdown").setup({
  enable_keymaps = true,
  ft_only = true,
})
```

> The shim simply calls `require("custom.markdown").setup(...)`. It does not add extra mappings.

---

## Options

```lua
---@class Custom.MD.Config
---@field map_double_asterisk boolean     Visual "**" mapping (default: true)
---@field keep_inner_selection boolean    Reselect inner text after wrapping (default: true)
---@field protect_h1 boolean              Never demote below H1 (default: true)
---@field enable_keymaps boolean          Install unified keymaps (default: true)
---@field ft_only boolean                 Buffer-local keymaps on FileType=markdown (default: false)
---@field use_zf_override boolean         Map 'zf' to fold toggle (default: false)
---@field enable_autocmds boolean         For your own UI/FileType hooks (default: false)
---@field blockquote_hl table|nil         Blockquote highlight options (see below)
```

Defaults:

```lua
{
  map_double_asterisk   = true,
  keep_inner_selection  = true,
  protect_h1            = true,
  enable_keymaps        = true,
  ft_only               = false,
  use_zf_override       = false,
  enable_autocmds       = false,
  blockquote_hl = {
    fg     = "#6A9955",
    italic = true,
    bold   = false,
  },
}
```

**Keymaps logic (independent of `enable_autocmds`):**

* `enable_keymaps=true, ft_only=false` → install **once globally**.
* `enable_keymaps=true, ft_only=true`  → install **buffer-local** in `FileType=markdown`.
* `enable_keymaps=false`               → no mappings.

---

## Blockquote highlighting

Lines beginning with `>` are highlighted using the dedicated `MarkdownBlockquote` group instead of theme defaults, giving consistent VS Code–style rendering across colorschemes.

```lua
require("custom.markdown").setup({
  blockquote_hl = {
    fg     = "#6A9955",  -- hex foreground color
    bg     = nil,        -- hex background color (optional)
    italic = true,
    bold   = false,
    -- link = "Comment", -- alternatively, link to an existing group
  },
})
```

The group is applied to:
- Tree-sitter: `@markup.quote` and `@markup.quote.markdown`
- Legacy Vim Markdown syntax: `markdownBlockquote`

It is automatically re-applied after `:colorscheme` changes.

### Module layout

```
custom/
└─ markdown/
   ├─ hl_options/
   │  ├─ init.lua              ← orchestrator; sets up ColorScheme autocmd
   │  └─ hl_groups/
   │     ├─ blockquote.lua     ← MarkdownBlockquote + TS/syntax links
   │     ├─ headings.lua       ← stub (future per-level heading colors)
   │     ├─ code.lua           ← stub (future code-block highlights)
   │     └─ links.lua          ← stub (future link highlights)
   ├─ config.lua
   └─ init.lua
```

---

## Keymaps (default)

> All mappings are defined in `ui/keymaps.lua`. Disable with `enable_keymaps=false` to roll your own.

| Mode    | LHS              | Action                              |
| ------- | ---------------- | ----------------------------------- |
| `x`     | `**`             | Toggle `**` around visual selection |
| `n`     | `<localleader>f` | Toggle fold under cursor & center   |
| `n`     | `zu`             | Unfold all & center                 |
| `n`     | `zi`             | Fold previous heading & center      |
| `n`     | `zk`             | Fold H2+ (keep H1 open)             |
| `n`/`v` | `mk`             | Previous heading (H2+)              |
| `n`/`v` | `mj`             | Next heading (H2+)                  |
| `n`     | `<leader>toc`    | Insert/refresh markerless TOC       |

If you insist on overriding native `zf`:

```lua
require("custom.markdown").setup({ use_zf_override = true })
```

---

## Folding integration

In your Markdown buffers, use this module's `foldexpr`:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx", "mdx" },
  callback = function()
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr   = "v:lua.require'custom.markdown.core.fold'.foldexpr(v:lnum)"
    vim.opt_local.foldenable = true
    vim.opt_local.foldlevel  = 99
    vim.opt_local.foldlevelstart = 99
  end,
})
```

Optional editor niceties:

```lua
vim.opt.foldnestmax = 6
vim.opt.foldcolumn  = "1"
```

---

## Health

```vim
:lua require("custom.markdown.ui.health").check()
```

Reports whether config and core modules load.

---

## Notes / Limitations

* Heading **shift** affects **ATX** headings only (Setext remains unchanged).
* TOC skips fenced code blocks (``` or ~~~, language optional).
* Anchors are GitHub-like; duplicates are disambiguated (`foo`, `foo-2`, …).
* `enable_autocmds` is reserved for your own UI/FileType hooks (e.g., `conceallevel`, `textwidth`, statusline toggles). It does **not** control keymap installation.
* `blockquote_hl.link` takes precedence over `fg`/`bg`/`italic`/`bold` when set.

---
