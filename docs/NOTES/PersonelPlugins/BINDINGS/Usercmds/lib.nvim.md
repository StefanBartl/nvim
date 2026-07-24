# lib.nvim — `:Lib <subcommand>` Cheatsheet

lib.nvim is the library itself — this is its **own dogfooding** use of
`lib.nvim.usercmd.composer` (`lua/lib/nvim_usrcmds/init.lua`), registered
**alongside** the pre-existing flat commands (kept for muscle memory — this
repo, unlike published standalone plugins, opted for alongside not replace).

| Command | Effect | Flat equivalent |
| --- | --- | --- |
| `:Lib cwd-here` | lcd to the current buffer's directory | `:CwdHere` (still works) |
| `:Lib ps-profile` | Open the active PowerShell profile | `:PowershellProfile` (still works, Windows only) |
| `:Lib helptags` | Regenerate all helptags now | (was autocmd-only before) |

Gated by `nvim_usrcmds.setup({ lib_verb = true })` (default: on). Set
`lib_verb = false` to disable the `:Lib` verb and keep only the flat commands.

## The composer module itself

`lua/lib/nvim/usercmd/composer/` — the actual reusable module every other
plugin's cheatsheet in this directory is built on.

- Design doc: `docs/ROADMAP/usrcmd_builder.md` (in the lib.nvim repo)
- API docs: `lua/lib/nvim/usercmd/composer/README.md`, `:h lib.nvim-composer`
- Access: `require("lib.nvim.usercmd.composer")`, `require("lib").composer`,
  or `require("lib").usercmd.composer`

### Route spec shape (quick reference)

```lua
local composer = require("lib.nvim.usercmd.composer")

composer.verb("Verb", {
  desc    = "…",
  default = function(ctx) end,        -- bare `:Verb` (zero tokens)
  bang    = true,                     -- or per-route
  routes  = {
    { path = { "sub" },
      args  = { { name = "x", type = "STRING", enum = {"a","b"}, optional = true } },
      flags = { { name = "dry", bool = true } },  -- Phase 6, opt-in per route
      desc  = "…",
      run   = function(ctx) end },    -- ctx.args, ctx.flags, ctx.rest, ctx.bang, ctx.range, ctx.raw
  },
})
```

`path = {}` = the verb's **root route** (matches even with zero literal
subcommand tokens — used for flat positional+flag grammars like
`replacer.nvim`'s `:Replace {old} {new} [--flags]`).

### Argument types

`STRING` (default) · `INT` · `FLOAT` · `BOOL` · `PATH` · `DIR` · `FILE` ·
`BUFFER` · `enum = {...}` on any arg (case-insensitive, closed set). Custom
types via `composer.register_type(name, { validate, complete })`.

### Docgen

`composer.document()` / `handle:document()` → `docs/BINDINGS/Usercmds.md` by
default (`composer.setup({ docs = { path, mode } })` to override; `mode =
"section"` updates a delimited block instead of overwriting the whole file).
