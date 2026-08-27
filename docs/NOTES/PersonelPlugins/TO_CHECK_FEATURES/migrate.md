# Testing migrate.nvim

How to manually test migrate.nvim's real feature surface. **No telemetry
data exists for this plugin at all** (`TelemetryReport.md`'s "Ohne Daten"
section lists it explicitly — no telemetry file in either dataset), so
priority here comes entirely from reading `docs/features.md`,
`docs/WORKFLOW.md`, and the source, not from usage counts.

Repo: `E:\repos\migrate.nvim`. Spec: `lua/plugins/personal/init.lua`
(`cmd = { "MigrateOpt", "MigrateNotify", "MigrateHl", "MigrateLsp" }`,
`dependencies = { "StefanBartl/lib.nvim" }`, `opts = {}` — opt + notify +
hl + lsp all enabled by this config, nothing overridden from the plugin's
own defaults). `keymaps` stays at its default `false` in this config, so
no `<leader>m*` bindings exist unless you add them for a test (§6).

## Setup

```vim
:checkhealth migrate
```

**Expect**: core module and all four registered migration modules load OK,
`lib.nvim` and `telescope.nvim` found (hard deps), `rg` reported
present/missing (needed only for `cwd` scans), the active per-module config,
and which-key detection. Open Neovim from a real Lua tree with old-API calls
to migrate — this nvim config repo itself has plenty of `vim.notify(...)`
call sites, or use a scratch copy so a botched migration costs nothing.

---

## 1. `-n`/`--dry-run` on `:MigrateNotify` — fixed 2026-08-28, confirm it actually works now

**Was a real bug, now fixed — this section is a regression check, not an open question.**
`docs/commands.md` and `docs/features.md` claimed `-n`/`--dry-run` worked on
all four `:Migrate*` commands. It didn't: `:MigrateOpt`/`:MigrateHl`/
`:MigrateLsp` go through `migrate.common.command`'s shared `M.register()`
(`lua/migrate/common/command.lua`), which declares the flag and checks it;
`:MigrateNotify` hand-rolled its own `composer.verb` registration in
`lua/migrate/notify/init.lua` with no `flags` table and a `dispatch()` that
never read a dry-run flag at all.

Fixed by adding the same `{ name = "dry-run", short = "n", bool = true }`
flag to `:MigrateNotify`'s route, plus its own `report_dry_run()` (mirroring
`common/command.lua`'s, since `:MigrateNotify` isn't built on that shared
factory) threaded through `dispatch()`'s line and range branches. Docs now
match the code.

**Steps**

```vim
:MigrateOpt -n
```
on a line with a real `nvim_buf_get_option(...)` call — confirm this one
genuinely reports without applying (matches the docs).

```vim
:MigrateNotify -n
```
on a line with a real `vim.notify(...)` call.

- [ ] `:MigrateNotify -n` reports the before/after and applies nothing — same
  shape as `:MigrateOpt -n`'s output.
- [ ] `:'<,'>MigrateNotify -n` (range mode) also reports instead of applying.
- [ ] `:MigrateNotify % -n` and `:MigrateNotify cwd -n` still open their
  normal picker (the flag is accepted but has no effect there, same as the
  other three commands — `%`/`cwd` already preview through the picker).

---

## 2. `:MigrateNotify` end to end — the most elaborate single migration

**Steps**

Pick or write a real Lua file with `local notify, levels = vim.notify, vim.log.levels`
near the top and a few `notify(msg, levels.WARN)`-style calls below, then:

```vim
:MigrateNotify
```
on one call site (current line).

**Expect**: the call becomes `notify.warn(msg)`-shaped (level-method form),
and — since this is the *first* migrated call in the buffer — a
`local notify = require("lib.nvim.notify").create("[name]")` line is
injected above the first code line, with `[name]` auto-detected from the
buffer's path (`lib.nvim.lua_ls.get_module_path`).

- [ ] `:MigrateNotify % my.custom.name` — buffer-wide via the picker; the
  injected import uses `my.custom.name` verbatim, not the auto-detected path.
- [ ] Once every call in the buffer is migrated, confirm the original
  `local notify, levels = vim.notify, vim.log.levels` alias line is deleted
  (§ "Removes stale aliases" in features.md) — not left dangling as dead code.
- [ ] **The range-mode argument trap** (WORKFLOW.md's own warning): select a
  range with a `vim.notify(...)` call, then
  `:'<,'>MigrateNotify my.plugin.ui` (no placeholder). Confirm this
  **silently** falls back to auto-detecting the module name instead of using
  `my.plugin.ui` — the injected `require(...)` line should **not** say
  `my.plugin.ui`. Then retry correctly as
  `:'<,'>MigrateNotify - my.plugin.ui` and confirm *that* one does use the
  real name. No error either way — the whole point is this fails silently.
- [ ] A multiline `vim.notify("...", vim.log.levels.ERROR)` call spanning
  several lines (balanced-paren tracked) — after migration, confirm it
  collapsed onto **one** line, not preserved as multiline.
- [ ] Put a `vim.notify(...)` example inside a `[[ ]]` long-bracket string
  (e.g. documenting usage in a doc comment written as a long string) and run
  `:MigrateNotify %` — confirm that line is **not** touched by the picker
  (parser skips lines starting inside a long-bracket string).
- [ ] Run `:MigrateNotify` again on an already-migrated file with a couple of
  calls fixed by hand and some left as raw `vim.notify(...)` — confirm only
  the untouched ones show up, no double-wrapping and no duplicate
  `require(...)` injected (re-run safety, per WORKFLOW.md).

---

## 3. `cwd` scope — auto-write, and self-exclusion

**The one genuinely risky feature**: unlike `%`, a `cwd` scan writes touched
files back to disk the moment you apply a match in the picker — no confirm
step beyond the picker's own apply action.

**Steps**

Do this in a scratch copy of a small repo (or commit/stash first, per
WORKFLOW.md's own advice), with a few files containing migratable calls.

```vim
:MigrateOpt cwd
```

**Expect**: Telescope picker opens with matches gathered via `rg`. Apply one
selection (`<CR>`) — confirm the source file on disk actually changed
(reopen it, or check outside Neovim), not just the in-memory buffer.

- [ ] `:MigrateNotify cwd` specifically — since this module's `cwd` scan
  doesn't use `rg` at all (`migrate.common.buffer.find_lua_files`, a
  Lua-native walk, per features.md) — confirm it still finds matches even if
  `rg` is missing from `$PATH` (temporarily rename it if you want to prove
  this), unlike `:MigrateOpt cwd`/`:MigrateHl cwd`/`:MigrateLsp cwd`, which
  do depend on `rg` and should show "ripgrep (rg) not found" instead.
- [ ] Run any `cwd` scan from inside `E:\repos\migrate.nvim` itself — confirm
  the picker never lists a match from `lua/migrate/**` (self-exclusion,
  checked against the plugin's own source root) even though those files
  contain real `vim.notify`/option-API calls.
- [ ] `:MigrateNotify cwd` apply — confirm the notify messages at the end
  report both "Applied N migration(s)" and "✅ Written N file(s) (async)" —
  two separate confirmations, not one conflated message.

---

## 4. `:MigrateHl` and `:MigrateLsp` — the simpler two

**Steps**

```vim
:MigrateHl
```
on a line using `vim.highlight.range(...)` or `vim.highlight.on_yank(...)`.

**Expect**: blanket `vim.highlight.` → `vim.hl.` prefix rewrite, member name
untouched.

```vim
:MigrateLsp
```
on a line with `vim.lsp.buf_get_clients(bufnr)` and one with
`vim.lsp.buf_get_clients()` (no argument).

**Expect**: `get_clients({ bufnr = bufnr })` and `get_clients({ bufnr = 0 })`
respectively (the no-argument case defaults to buffer `0`, not left blank).
Also try `vim.lsp.get_active_clients(filter)` — should become
`vim.lsp.get_clients(filter)`, argument list untouched (name-only rename).

- [ ] A line with `vim.lsp.buf_request(...)` or `vim.lsp.buf_notify(...)` —
  confirm these are **left alone** (not deprecated, deliberately excluded per
  features.md — only `buf_get_clients`/`get_active_clients` are migrated).

---

## 5. Telescope picker — batch apply and preview

**Steps**

```vim
:MigrateOpt %
```
in a buffer with 3+ matches.

**Expect**: multi-select with `<Tab>`, a before/after preview per entry.
Select two, `<CR>` — only those two applied. Reopen, this time
`<C-a>` — every remaining match applied at once regardless of selection.
Try `<S-A>`, `<M-a>`, `<C-y>` on separate runs too — all four should be
equivalent (kept for muscle-memory compatibility, per features.md).

---

## 6. Optional per-module keymaps and the count-as-range behavior

**Prerequisites**: this config leaves `keymaps = false` (the plugin
default), so bind one for the session to test:

```vim
:lua require("migrate").setup({ keymaps = { opt = "<leader>mo" } })
```

**Steps**

`<leader>mo` on a single migratable line — should behave identically to
bare `:MigrateOpt` (current line, applied immediately).

- [ ] `3<leader>mo` — should migrate the cursor line **and the two below
  it**, issued as an explicit `:{line1},{line2}MigrateOpt` range — confirm
  it is *not* interpreted as "go to line 3" (`:3MigrateOpt` would mean
  that; the count-as-range path is deliberately different, per
  `bindings/keymaps.lua`'s own comment).
- [ ] A count that overruns the buffer (e.g. `50<leader>mo` near the last
  line) — should clamp to the last line, not error.

---

## 7. Pluggable migration registry — a third-party module gets a command for free

**Steps**

```lua
require("migrate.registry").register("mytest", {
  module = "some.module",
  command = "MigrateMyTest",
  desc = "test migration",
})
require("migrate").setup({ mytest = true })
```
(before this, `some.module` need not exist for the registration step itself
— only for actually running the command, so this can be tested purely for
wiring.)

**Expect**: `:checkhealth migrate` now lists `mytest` as a registered
module, and `require("migrate").setup({ mytest = true })` attempts to load
`some.module` — reporting a warning if it fails to load (`bindings/usrcmds.lua`),
not a hard error that aborts the rest of setup.

- [ ] Per WORKFLOW.md: registering alone gets you the config key and health
  entry, but **not** a keymap — confirm `keymaps = { mytest = "<leader>mt" }`
  is required separately before that binding exists.

---

## What this checklist does not cover in depth

Debug tracing (`debug = true`) — a no-op path check only, nothing visibly
interactive beyond confirming trace lines appear via `lib.nvim.notify`'s
`.debug()` level once enabled. `enable_all()`/`disable_all()` (convenience
wrappers over the same registry loop `setup()` already exercises above).
The `WRITE_STRATEGY` constant (`"async"` vs `"sync"`) — hardcoded, not
exposed through `setup()` in this version, so there's nothing to configure
and test differently.
