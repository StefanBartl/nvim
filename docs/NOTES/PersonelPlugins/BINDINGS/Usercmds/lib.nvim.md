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

## Module control commands (separate from the `:Lib` verb)

Two modules ship their own flat control command. Neither goes through the
composer — they predate/sit outside the verb and are about *runtime state of
that module*, not about lib.nvim as a plugin.

| Command | Registered when | Effect |
| --- | --- | --- |
| `:LibLogger [show\|on\|off\|level <l>\|dump\|clear\|tags]` | automatically, on the first `logger.new()` | Flip logging on/off, change level, inspect/dump/clear the ring buffer |
| `:LibTelemetry [report\|start\|stop\|reset\|coverage\|export]` | **only** after `require("lib.nvim.telemetry.command").setup()` | Read/steer call-counting across every live telemetry instance |
| `:KitPreview` | `require("lib.nvim.ui.kit")` dev-tool | Live theme playground (see the Keymaps cheatsheet for its in-buffer keys) |

### `:LibTelemetry`

`lib.nvim.telemetry` counts how often functions are called, persists the
counts across restarts, and — with argument profiling on — tells you when one
argument dominates. Bare `:LibTelemetry` reports across every live instance in
a kit float; a bare namespace argument narrows it to one.

| Form | Effect |
| --- | --- |
| `:LibTelemetry` | Report across all instances |
| `:LibTelemetry lsp.nvim` | Report for that namespace only |
| `:LibTelemetry start` / `stop` | Install / restore the wrappers on every instance |
| `:LibTelemetry reset` | Drop collected data (memory **and** disk) |
| `:LibTelemetry coverage` | Which wrapped functions were called **zero** times |
| `:LibTelemetry export [path]` | JSON snapshot (defaults under `stdpath("cache")`) |

Opt-in registration is deliberate — the module itself never claims a
user-command name on its own; a library that did would collide with someone's
own mapping. **This config does opt in**: `lua/config/telemetry.lua`, called
from `init.lua` before `lazy.setup()`, registers `:LibTelemetry` and starts an
instance for `lib.nvim` itself plus one for every personal plugin, generically,
right after each one loads (namespace = the plugin's lazy.nvim name — see that
file's own doc-comment for why it must run that early and how it avoids
hardcoding a module name per plugin). Counting only, no argument profiling.

Manual setup, for a plugin not covered by that generic pass (or to add
argument profiling/timing on top of what's already running):

```lua
require("lib.nvim.telemetry.command").setup()  -- idempotent; already done above

local t = require("lib.nvim.telemetry").new({ namespace = "my-thing" })
t.wrap(require("my-thing"))
t.start()   -- counting only; nothing is wrapped until this runs
```

Nothing is installed before `start()` — until then the shipped functions *are*
the original functions, so leaving the module required costs nothing. Details:
`lua/lib/nvim/telemetry/README.md` in the lib.nvim repo.

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
