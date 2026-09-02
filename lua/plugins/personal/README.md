# plugins.personal

The personal `StefanBartl/*.nvim` plugins: which ones exist, whether each loads
from a local checkout or from GitHub, and where its checkout is on this
machine.

Five files, and the split between them is the point:

| Module | Role |
| --- | --- |
| [`plugins.personal`](init.lua) | **Spec implementation.** The `lazy` specs themselves, and nothing else. |
| [`plugins.personal.source`](source.lua) | **Policy.** Which repo loads how (`dir` / `remote` / `disabled`), the global `OVERRIDE` switch, machine-role handling. |
| [`plugins.personal.list`](list.lua) | **The repo list**, derived from the resolved spec. |
| [`plugins.personal.export`](export.lua) | **The repo list plus each local checkout path.** |
| [`plugins.personal.utils`](utils.lua) | **Where `repos` is on this machine**, and whether a given plugin is cloned there. |

To turn a repo off, or move it between local and remote, edit
[`source.lua`](source.lua) — never `init.lua`, and never a single spec.

`plugins/control/` holds the generic mode-control core the policy file builds
on; it is shared with the other spec files under `lua/plugins/` and is
documented at the bottom of this file.

---

## API

Everything below is side-effect free to call. `require("plugins.personal")`
builds and returns the spec table; the individual plugins' `config()`
functions are lazy.nvim's business and do not run.

### `plugins.personal` → `LazyPluginSpec[]`

```lua
local specs = require("plugins.personal")
#specs                --> 33   (every declared repo, disabled ones included)
specs[1][1]           --> "StefanBartl/lib.nvim"
specs[1].dir          --> "E:/repos/lib.nvim"   (mode "dir", checkout present)
                      --> nil                   (mode "remote", or not cloned)
specs[n].enabled      --> false                 (mode "disabled")
```

The raw, resolved spec list, as handed to lazy. Read it when you need a spec
field (`lazy`, `priority`, `dependencies`, …). For "which repos are there" and
"where are they", prefer `list` and `export` below — they answer that question
without making the caller re-derive it.

### `plugins.personal.list.read()` → `entries|nil, err`

```lua
local entries, err = require("plugins.personal.list").read()
-- entries[i] = { repo = "StefanBartl/markdown.nvim", name = "markdown.nvim" }
```

Every repo that is **meant to be on disk**: one entry per repo, deduplicated,
with `disabled` repos (currently only `learn-cli.nvim`) filtered out — those
are "neither local nor remote" by explicit choice, so a cloner should not fetch
them and a remover should not offer them.

`name` is the basename, and it is the same string in three places: the folder
under the repos root, `source.lua`'s mode-table key, and
runtime-analysis.nvim's telemetry namespace. That is why it is returned rather
than left to the caller to compute.

Returns `nil, err` when the spec itself could not be read, or when it yielded
no enabled repos. Never returns an empty list with no error.

### `plugins.personal.export.projects()` → `projects, err`

```lua
local projects, err = require("plugins.personal.export").projects()
-- projects[i] = {
--   name = "markdown.nvim",
--   repo = "StefanBartl/markdown.nvim",
--   dir  = "E:/repos/markdown.nvim",
-- }
```

`list.read()` plus a resolved absolute `dir`, filtered to the plugins that
**actually have a checkout on this machine**. A remote-mode entry has no tree
to point a tool at, so it is dropped here rather than returned with a `dir` the
caller would have to remember to nil-check. Sorted by `name`, so two calls in
one session agree on order.

`err` is set only when the underlying entry list failed. *No local checkouts at
all* is `{}, nil` — an answer, not a failure.

This is the interface to build tools against: it is what
`:DocMapAll`, docmap-desktop's spec import, and `:Bindings check repo`'s
checkout axis all read.

### `plugins.personal.utils`

```lua
local u = require("plugins.personal.utils")

u.repos_path            --> "E:\\repos"  (or "" when there is no local root)
u.local_dev("lib.nvim") --> "E:/repos/lib.nvim"   (directory exists)
                        --> nil                   (no root, or not cloned)
```

`repos_path` is resolved **once, at module load**: `$REPOS_DIR` if it names a
directory, otherwise the first hit among `E:\repos`, `E:/repos`, `D:\…`,
`C:\…`, `/repos`. A fallback warns; no root at all notifies and switches
everything to remote.

Note the separators: `repos_path` is whichever candidate matched, verbatim —
on this machine the backslash form — while `local_dev` runs it through
`vim.fs.joinpath` and comes back with forward slashes. So `repos_path` is a
string to *hand onward* (pickers.nvim takes it as `repos_dir` and concatenates
collection paths onto it), and `local_dev`'s result is the one to compare
against other resolved paths. Do not expect the two to match textually.

`local_dev(name)` returning `nil` is the mechanism behind "flagged `dir` but
not cloned falls back to its remote spec" — it is a normal outcome, not an
error.

> This module must not `require` lib.nvim, not even `lib.nvim.notify`:
> `init.lua` calls `local_dev("lib.nvim")` to locate lib.nvim itself, before it
> is on the runtime path. Hence the plain `vim.notify` calls inside.

### `plugins.personal.source` → `Plugins.Control.ModeApi`

The configured mode-control instance, with the personal resolver already
injected. `init.lua` uses exactly three calls:

```lua
local plugins = require("plugins.personal.source")
plugins.add({ ...specs... })   -- register; chainable; idempotent per repo
return plugins.export()        -- apply the modes, return the list for lazy
```

| Call | Effect |
| --- | --- |
| `.modes(t)` | Merge `basename -> mode` pairs into the mode table. Chainable, callable more than once. |
| `.add(list)` | Register specs. **Idempotent per repo** — re-registering the same repo replaces in place. |
| `.export()` | Run the resolver over every registered spec and return the list. This is the file's `return`. |

`.add`'s idempotence is load-bearing rather than tidiness: the spec file is
evaluated more than once per session (lazy's importer and a later
`require("plugins.personal")` are separate cache keys), and without it the list
grew by a full set each time — measured at 84 entries for 28 plugins.

#### The three modes

| Mode | Effect on the spec |
| --- | --- |
| `"dir"` | `spec.dir = local_dev(name)` — local checkout, **falling back to remote** when the folder is missing. The default for anything not listed. |
| `"remote"` | `dir` stays `nil`, so lazy uses `repo[1]` and manages it as a GitHub remote. |
| `"disabled"` | `spec.enabled = false`. Loaded neither way. |

#### Precedence

```
repo's own "disabled"  >  global OVERRIDE / SOURCE  >  repo's own dir|remote  >  "dir"
```

A repo's own `disabled` wins over everything, `OVERRIDE` included: a repo you
do not need should load neither locally nor remotely.

#### `OVERRIDE`

One line near the top of [`source.lua`](source.lua), currently `"dir"`. It
forces a single source for *all* personal plugins.

| Value | Meaning |
| --- | --- |
| `"auto"` | Force nothing — machine role and the mode table decide. |
| `"dir"` | All local. |
| `"remote"` | All from GitHub. |
| `"disabled"` | All off. |

`:MyPlugins mode <value>` rewrites that exact line. A restart is required —
`require()` caches the file.

With `OVERRIDE = "auto"`, the machine role decides: `machine.is("workstation")`
never has local checkouts, so it goes `remote` unconditionally rather than
paying ~25 `isdirectory` probes. (Remote on the workstation is also why lazy's
update checker is off there — otherwise it fetches ~116 repos on every start
and freezes the UI for 60–90 s. See `lua/config/lazy/init.lua`.)

---

## Commands

`:MyPlugins <route>` (`lua/bindings/usrcmds/plugin_repos/`) is the interactive
surface over the same data. Every route takes an optional `dir` argument that
overrides `repos_path`/`$REPOS_DIR`; most take `--only=<name>`.

| Route | What it does |
| --- | --- |
| `list` | Every plugin in `list.read()`, and whether it is present on disk. Scratch buffer, no git. |
| `clone` | Clone what is missing. `--dry-run` previews. |
| `remove` | Remove *clean* checkouts (no uncommitted or unpushed work), after confirmation. |
| `fetch` / `pull` / `update` | `git fetch --all --prune` / `git pull --ff-only` / both. |
| `reclone` | Delete (if clean) and re-clone, after confirmation. `--dry-run` shows the safe/unsafe/missing split. |
| `picker` | Multi-select: assign an action per plugin, then run them together. |
| `dashboard` | reposcope.nvim's git-status dashboard for the repos root. |
| `mode [value]` | Show, or persistently switch, `source.lua`'s `OVERRIDE`. |

---

## Who reads what

Worth knowing before changing a return shape — these are the callers a change
here reaches:

| Consumer | Reads |
| --- | --- |
| `bindings.usrcmds.plugin_repos` (`:MyPlugins`) | `list.read()` |
| `bindings.usrcmds.plugin_repos.picker` | `list.read()` |
| `wkdnvchad.ui.statusline` — `plugin_summary`'s own/external badge | `list.read()` |
| `config.telemetry` | `list.read()` |
| `bindings.usrcmds.bindings_explorer.config` — `:Bindings check repo` | `export.projects()` |
| documentation.nvim (`:DocMapAll`, via `opts.generate_all`), docmap-desktop | `export.projects()` |
| pickers.nvim's `repos_dir` and its collection paths | `utils.repos_path` |

---

## The mode-control core

[`plugins.control.mode`](../control/mode.lua) is the generic half, shared by
every spec file under `lua/plugins/`. `M.new(opts)` returns one instance;
`opts.resolve(spec, mode, name)` decides what a mode *does*.

The core only knows the shape (`basename -> mode string`). The default
resolver honours `"disabled"` and ignores everything else, which is all a
third-party spec file needs — lazy manages those remotely regardless.
`plugins.personal.source` injects the resolver that adds `dir`/`remote` and the
`OVERRIDE` switch.

`plugins/control/` deliberately has **no** `init.lua`: lazy's
`{ import = "plugins" }` picks up every `plugins/<dir>/init.lua` one level deep
and normalizes the return value as a plugin spec. A folder without one is
skipped entirely, which is exactly right for a helper module.

The same rule is why `source.lua`, `list.lua`, `export.lua` and `utils.lua` can
live next to `personal/init.lua` without lazy trying to read them as specs —
the importer only ever looks at the `init.lua`.
