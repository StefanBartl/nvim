# Testing lib.nvim

`lib.nvim` is not a feature plugin — it is a Neovim adapter library ~30 of
this config's other personal plugins declare as a hard dependency (`lib.lua.*`
editor-independent helpers, `lib.nvim.*` the Neovim adapter layer). It has no
end-user feature surface in the usual sense: no `:DocMap`-style command tree
to click through. What it *does* expose directly to a human sitting in
Neovim is a handful of commands it registers itself, plus one interactive UI
toolkit (`lib.nvim.ui.kit`) that other plugins build their own popups on top
of. This checklist is about **that** surface — "does what lib.nvim itself
puts in front of a user work" — not "does every one of its ~50 helper
modules work", which is what `TESTS/` (12+ headless suites) already covers.

Repo: `$REPOS_DIR\lib.nvim`. Spec: `plugins/personal/init.lua` — `lazy = false`,
`priority = 1000` (loads before everything else; ~30 other plugin specs
declare it as `dependencies`). Its own commands are registered eagerly at
startup, not lazy-loaded on anything:

- `require("lib.nvim_usrcmds").setup({ helptags = true, cwd_here = true,
  powershell_profile = true })` runs in `plugins/personal/init.lua`'s
  `config()` — registers `:Lib`, `:CwdHere`, `:PowershellProfile` (`deps` and
  `lib_verb` aren't passed, so they fall back to their own `true` defaults,
  meaning `:Lib deps ...` should also be there).
- `require("lib.nvim.system").setup({ publish_globals = true, rpc_pipe =
  true, info_usercmd = true })` runs in this config's own `init.lua:134` —
  registers `:SystemInfo`.
- `:KitPreview` and `:LibLogger` register themselves lazily, the moment
  `lib.nvim.ui.kit` / `lib.nvim.logger.new()` is first touched by *any*
  plugin — since dozens of plugins use both on startup, both should already
  exist in a fresh session without you doing anything.

## Setup

```vim
:checkhealth lib
```

**Expect** five sections, all green on a healthy install: Neovim version
(>= 0.10) + libuv bridge, the aggregator strategy (`require("lib.config").get().strategy`),
module resolution (a probe list of ~14 representative modules across both
namespaces — `lib.nvim.ui.kit` and `lib.nvim.bindings.usercmd.composer` are
on it), the `require("lib")` aggregator resolving `notify`/`map`/`is_windows`,
and a list of every plugin that has created a `lib.nvim.logger` instance this
session (empty on a fresh start — a plugin only shows up once it calls
`logger.new()`).

---

## 1. The `:Verb sub` composer pattern (`lib.nvim.bindings.usercmd.composer`)

**This is the single most depended-on piece of this whole library** — the
README calls it out explicitly, and it's what every sibling plugin's own
`:Markdown sub`, `:Lsp sub`, `:DocMap sub` grammar is built on. If this is
broken, it isn't just lib.nvim that's broken — every personal plugin's
command surface is. `:Lib` itself dogfoods it, so testing `:Lib` **is**
testing the composer.

**Steps**

```vim
:Lib <Tab>
```

**Expect**: completes `helptags | cwd-here | ps-profile | deps` (no
`ps-profile` on non-Windows, since `powershell_profile` gates that route).

```vim
:Lib helptags
```

**Expect**: regenerates helptags, notifies when done.

```vim
:Lib cwd-here
```

**Expect**: `:lcd` to the current buffer's directory. Try it from an
**unnamed buffer** too — should no-op rather than error (README says so
explicitly).

```vim
:Lib deps show
:Lib deps show mdview.nvim
```

**Expect**: the first lists every plugin that ships a `docs/install.json`/
`docs/INSTALL.md` spec; the second reports mdview.nvim's declared tools
(`curl`), present/missing, and why they matter — mdview.nvim's own README
calls out this exact command as the repeat-path for its first-run popup.
`<Tab>` after `deps show ` should complete plugin names that actually ship a
spec, not every plugin.

```vim
:Lib deps install mdview.nvim
```

(Only if something is actually missing — otherwise skip.) **Expect**: composes
an install command for the host's package manager, asks for confirmation,
then opens a terminal with the command **typed but not submitted** — you
press Enter yourself. If it runs anything without that confirmation step,
that's a real bug (the deps README is explicit that this module "touches
nothing" on its own).

**Also check a route with declared args and flags**, since `:Lib` itself has
none — any sibling plugin's verb will do, e.g. `:Markdown table format
<Tab>` or `:Replace --dry <Tab>` (whichever of markdown.nvim/replacer.nvim
you have handy) — confirm flag completion (`--<Tab>`) and enum-value
completion both work, since that's composer's code path being exercised
through a different verb.

---

## 2. `lib.nvim.ui.kit` — the popup/form/select toolkit

**Steps**

```vim
:KitPreview
```

**Expect**: a live theme playground opens — this is the one command the
`ui.kit` README points you at first, specifically so you don't have to wire
up a throwaway `:lua` call just to see what a themed popup looks like. Cycle
through what it offers (themes/presets, component types) if the playground
exposes that interactively.

**Steps** — exercise a few component types directly, since `:KitPreview`'s
own coverage of the *interactive* ones (form, live filtering) may be
limited:

```lua
local kit = require("lib.nvim.ui.kit")
kit.popup({ type = "note", title = "Test", message = "hello", timeout = 1500 })
kit.popup({ type = "select", message = "Pick one", selection = { "a", "b", "c" },
  on_select = function(choice, idx) vim.notify(("picked %s (%d)"):format(choice, idx)) end })
kit.popup({ type = "input", prompt = "Name", default = "x",
  on_submit = function(v) vim.notify("got: " .. v) end })
kit.confirm({ question = "Delete 3 files?", on_answer = function(yes) vim.notify(tostring(yes)) end })
```

**Expect**: `note` auto-dismisses after 1.5s. `select` responds to `j`/`k`
+ `<CR>`. `input` submits on `<CR>`, cancels on `<Esc>` (try both). `confirm`
responds to `h`/`l`/`<Tab>` to move focus and `<CR>` to confirm — **and** a
left click directly on a button (needs `:set mouse=a`) should focus *and*
confirm in one click, per the README's specific claim about single-click
behavior here.

**A form, since it's the multi-field composition several sibling plugins
reuse (sandbox.nvim's Image/Name/Ports/Volumes/Env chain is named in the
README as the motivating case):**

```lua
require("lib.nvim.ui.kit").form({
  fields = {
    { name = "a", label = "Required field", required = true },
    { name = "b", label = "Optional field" },
  },
  on_submit = function(values) vim.notify(vim.inspect(values)) end,
  on_cancel = function() vim.notify("cancelled") end,
})
```

**Expect**: `<Esc>` on the **optional** field just skips it (form continues);
`<Esc>` on the **required** field aborts the whole form and fires
`on_cancel` — this distinction is called out explicitly in the docs as the
form's actual behavior, worth confirming it's really that and not "any
`<Esc>` aborts".

---

## 3. `:SystemInfo`

**Steps**

```vim
:SystemInfo
```

**Expect**: a system-info float (OS/shell/paths snapshot) — this used to be
inline in `bindings/mappings/general.lua` in this config and now comes from
`lib.nvim.system.info`. Should render real values for this machine, not
placeholders.

---

## 4. `:LibLogger`

**Steps** (needs at least one plugin to have created a logger already —
true for a real session, since `runtime-analysis.nvim`/`documentation.nvim`
and others use `lib.nvim.logger`):

```vim
:LibLogger show
:LibLogger level debug
:LibLogger off
:LibLogger on
```

**Expect**: `show` lists recent records across every registered logger,
newest last. `off` disables logging globally (README: "zero-cost" — check
the notify message says that). `level` changes the global level. Nothing
here should require a restart to take effect.

---

## 5. Flat legacy commands

**Steps**

```vim
:CwdHere
:PowershellProfile
```

(Windows-only for the second, which matches this machine.) **Expect**:
identical behavior to their `:Lib` verb equivalents — the README is explicit
both surfaces dispatch into the exact same action functions, so they cannot
drift. If `:PowershellProfile` errors instead of opening `$PROFILE`, check
whether `powershell` is actually on `PATH` first (documented failure mode).

---

## What this checklist deliberately does not cover

Everything under `lua/lib/lua/*` and the ~50 other `lib.nvim.*` helper
modules (fs, cross-platform run/env, notify/logger internals, progress,
selection, treesitter helpers, …) — those have no interactive surface of
their own; they're building blocks other plugins call from code, and their
correctness is what `TESTS/` (12+ suites, `cargo`/`node`-test-shaped for
this repo's own Lua) exists to verify, not a manual click-through. If one of
those is actually broken, it'll show up as a failure in whichever *consuming*
plugin's own checklist exercises the path that uses it.
