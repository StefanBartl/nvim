# Testing lsp.nvim

How to manually test every implemented feature of `lsp.nvim`. One-time setup,
then one section per feature: prerequisites, steps, what to expect. Checkbox
syntax (`- [ ]`) throughout.

Repo: `E:\repos\lsp.nvim`. Spec: `plugins/personal/init.lua` — `lazy = false`,
`priority = 900`, no `opts`/`config` on the spec itself. `require("lsp").setup()`
is instead called explicitly from this config's own `init.lua`
(`startup.now("lsp", function() ... end)`), **before** `apply_capabilities()`,
because capabilities must be global before the first client attaches — a lazy
`opts` block would hand that ordering to lazy.nvim. The real config passed:

```lua
require("lsp").setup({
  mason = { ensure_install = false },
  completion = { personal_names = { labels = function() return require("plugins.personal.list").read() end } },
})
```

Everything else — `servers`, `diagnostics`, `formatter`, `keymaps` (preset =
`"default"`, all 42 entries), `usrcmds`, `which_key`, `menu` — is this
plugin's own default. `init.lua` also pins `dir = lsppath` and adds
`import = "lsp.pack"` early (before the main spec table) so the ecosystem
(conform, lazydev, trouble, etc.) installs.

**Telemetry note**: 128 accumulated sessions, 23,004 calls, but almost all of
it is the `completion.blink.*`/`completion.register.*` hot path (fires once
per keystroke in insert mode) — not a feature signal by itself. What *is* a
real entry-point signal, thin but genuine: `status` fired once (`:Lsp status`
actually run), `bindings.keymaps.rebind_buffer_local` 8× (the `grn`/`grt`
LspAttach re-bind described in WORKFLOW.md, firing once per real attach),
`core.workspace_diagnostics.enabled`/`schedule_populate` (workspace
diagnostics genuinely toggled and populated a few times),
`languages.documentation.markdown.setup_reference_hl` 4× (markdown buffers
opened with the LSP QoL module active), and `completion.register.picked` /
`completion.usage.bump` each once (a personal-plugin-name completion was
actually accepted at least once). Ordering below leans on README/WORKFLOW's
own escalation-ladder framing, weighted toward what that thin signal
confirms is actually in use.

## Setup

```vim
:checkhealth lsp
```

**Expect**: five sections — environment, what `setup()` registered (including
every warning the config normalizer worked around), servers configured vs.
set up vs. attached, the ecosystem around the plugin (conform, lazydev,
trouble, mason, ...), and a pointer to `:LspDoctor`. Open a real Lua file in
this config (or `lsp.nvim`'s own repo) first so at least one server has a
chance to attach before reading the "attached" column.

---

## 1. `:Lsp status` vs `:Lsp doctor` vs `:checkhealth lsp` — the escalation ladder

Per WORKFLOW.md this is the intended first move whenever something seems off,
so worth confirming the three genuinely answer different questions rather
than being three views of the same data.

**Steps**

```vim
:Lsp status
:Lsp doctor
:Lsp doctor deep
```

**Expect**: `:Lsp status` is about the *plugin* — what `setup()` registered,
which keymaps got bound, every warning the config normalizer worked around
(deliberately misconfigure something, e.g. an invalid `diagnostics.ui` value,
and confirm it shows up here as a degraded-to-default warning rather than an
error at startup). `:Lsp doctor` (= `health` mode) is about the *buffer*:
expected servers vs. running vs. executable-on-PATH. `:Lsp doctor deep` adds
capabilities and provider-overlap detail — try it in a buffer with two
providers that could plausibly conflict (e.g. both `conform` and an LSP
formatter registered) and confirm it actually names the overlap rather than
just relisting servers.

---

## 2. Server registry and attach — the foundation everything else needs

**Steps**

1. Open a real `.lua` file in this config or `lsp.nvim`'s own repo.
2. `:Lsp servers`, `:Lsp info`.

**Expect**: `lua_ls` (and whatever else is in the configured `servers` list)
shows attached, with real capabilities. Deliberately reference an
undefined global or a bad `require(...)` path and confirm diagnostics appear
(proves the attach → capabilities → diagnostics chain end-to-end, not just
that a client process is running).

**Also check the shadowing trap** (WORKFLOW.md's own warning): confirm this
config has **no** `lua/lsp/**` directory of its own —
`Get-ChildItem <config>/lua/lsp` should not exist — since a config-local one
would silently shadow this entire plugin and nothing above would actually be
running the plugin's code.

---

## 3. Completion — personal plugin-name source

**Prerequisites**: the completion engine is `blink.cmp` (`vim.g.lsp_nvim.pack.completion`,
config default) per this config's pack settings.

**Steps**

1. In any Lua buffer, type `require("` and start typing a personal plugin
   name, e.g. `markd`.
2. Accept a completion (`<CR>` per `completion_accept = "cr"`).

**Expect**: `markdown` (or the matching personal plugin) appears as one atomic
candidate, sourced from `plugins.personal.list.read()` — i.e. the real list
this config's `plugins/personal/init.lua` declares, not a hardcoded list.
Accept it a few times across a session and confirm ranking shifts toward
recently/frequently picked names (disk-persisted use counter, per
FEATURES.md) — compare candidate order before and after several accepts of
the same name.

---

## 4. Keymap catalogue — `grn`/`grt` re-bind on attach, and the `ls*` prefixless family

**Steps**

1. In an attached buffer, `:map grn` and `:map grt` **before** any LSP
   activity this session (fresh buffer) vs. **after** `LspAttach` has fired.
2. Try `lsd` (goto definition), `lss` (document symbols), `<leader>rn` and
   `grn` (rename — both should resolve to the same `rename.provider`-selected
   backend).

**Expect**: `grn`/`grt` are Neovim 0.11's own buffer-local `gr*` maps before
attach; **after** attach, `:map grn` shows this plugin's catalogue entry has
overridden them (confirmed live by the telemetry: `bindings.keymaps.rebind_buffer_local`
fires once per real attach). `lsd`/`lss`/etc. work immediately after typing
`l` — confirm there's a brief `timeoutlen` pause after a bare `l` in Normal
mode before any `ls*` key resolves (this is documented, expected, not a bug).
`grn` and `<leader>rn` should behave **identically** (same backend, not two
different renames) — this is called out as a fixed bug (roadmap finding B9),
worth confirming it stays fixed.

**Also check** `keymaps.map` overrides: `require("lsp").setup({ keymaps = { map
= { goto_definition = false } } })` in a scratch `:lua` block — `lsd` should
stop working, and `:Lsp status`'s keymap section should list it as disabled
rather than silently absent.

---

## 5. Formatter — `:Lsp format`, `<leader>ft`/`<leader>tft`/`<leader>fl`

**Steps**

```vim
:Lsp format which
```
then, on a deliberately misformatted line:
```vim
:Lsp format
<leader>ft
```

**Expect**: `format which` names the actual tool that would run (conform vs.
LSP fallback) — cross-check by looking at what actually happened to the
buffer after `<leader>ft`. `<leader>tft` toggles format-on-save for the
session (`formatter.on_save` starts `false` in this config); after toggling
on, save a deliberately misformatted buffer and confirm it auto-formats;
toggle off, confirm it stops. `<leader>fl` forces the LSP formatter
specifically, bypassing conform — compare its output against `<leader>ft`'s
on a file where the two tools would format differently (e.g. quote style).

**Also check the timeout symptom**: `formatter.timeout_ms` defaults to 1500 —
on a large file with a genuinely slow formatter, confirm the failure mode is
silence ("nothing happened"), not an error, matching the documented caveat.

---

## 6. Diagnostics navigation — `]d`/`[d` vs `]w`/`[w`, and `diagnostics.ui`

**Steps**

1. In a buffer with at least two diagnostics, `]d`, `[d`.
2. `<leader>xt` (Trouble toggle) if Trouble is installed, then `]w`/`[w`.
3. Close the Trouble list entirely, `]w` again.

**Expect**: `]d`/`[d` move through buffer diagnostics, landing in Trouble's
list (focused) if `diagnostics.ui = "auto"` and Trouble is installed,
otherwise via plain `vim.diagnostic.jump`. `]w`/`[w` only move within an
**already open** Trouble list — with no list open, confirm they do nothing
(not an error, not a fallback to `]d`'s behavior) — this is the deliberately
different question WORKFLOW.md calls out. Try `3]d` (count-prefixed) — should
jump three diagnostics at once.

**Also check** `<leader>wq` (diagnostics → quickfix, workspace, with an open)
vs `<leader>tq` (`vim.diagnostic.setqflist`, plain, no open, no workspace
walk) — confirm these two visibly differ (one opens the list and walks the
workspace, the other populates silently and buffer-local only).

---

## 7. Workspace diagnostics — `:Lsp workspace`, the `max_files` gate

**Steps**

```vim
:Lsp workspace status
:Lsp workspace now
```
Then on a large repo (if one is on hand):
```vim
:Lsp workspace toggle
```

**Expect**: `status` reports whether the on-attach population is currently
on/off (default on, `attach.use_workspace_diagnostics = true`). `now` does a
one-shot populate for the current buffer's clients without touching the
on-attach setting — confirm diagnostics actually populate workspace-wide, not
just for the current buffer, right after running it. On a repo above the
`max_files = 800` gate, confirm it **refuses and says so explicitly**, rather
than silently producing nothing or freezing the editor — this is the concrete
claim WORKFLOW.md makes ("the gate held" vs. "the feature is broken").

---

## 8. Root scope — `<leader>lsp` / `:Lsp root`

**Steps** (ideally from inside a monorepo-shaped nested-`.git` structure, or
just any real git repo)

```vim
:Lsp root show
```
then `<leader>lsp` (or `:Lsp root pick`), switch scope, `:Lsp root show`
again.

**Expect**: `show` names the current scope (cwd / git root / file path).
`pick` opens a picker to switch between the three; after switching, re-run
`show` and confirm it changed, then check that references/definitions
resolve differently depending on the scope on a file whose relevant code sits
outside the current scope (e.g. cross-package in a monorepo) — the concrete
case WORKFLOW.md calls out as the reason this is a picker rather than a fixed
setting.

---

## 9. Restart ladder — `restart` / `force-restart` / `recover`

**Steps**

```vim
:Lsp restart lua_ls
:Lsp force-restart lua_ls
:Lsp recover
```

**Expect**: `restart` is the ordinary case — client goes down and back up,
attach fires again (check `bindings.keymaps.rebind_buffer_local` logic runs
again, i.e. `grn`/`grt` still resolve correctly post-restart). `force-restart`
additionally does a forced cleanup + wait + retry — harder to see the
difference without an actually-wedged client, but at minimum confirm it
completes without error and the server re-attaches. `recover`: stop a server
manually (`:Lsp stop lua_ls`), then in a **different** buffer that needs it,
`:Lsp recover` — should start exactly the servers configured-but-not-running
for buffers that need them, and running `restart` in the recover scenario
(no client to restart) should visibly do nothing, per WORKFLOW.md's own
"restart does nothing for a server that never came up" note.

---

## 10. `:LspDoctor` — six reports

**Steps**

```vim
:LspDoctor startup
:LspDoctor resolve
:LspDoctor buffer
:LspDoctor capabilities
:LspDoctor probe
:LspDoctor all
```

**Expect**: each report's own answer — `startup` (= `:Lsp doctor` default):
configured/running/executable; `resolve`: where the filetype → server chain
breaks; `buffer`: clients, diagnostic counts, provider conflicts, lists capped;
`capabilities`: the same uncapped, plus root_dir/workspace and the full
capability set (§1); `probe`: whether diagnostics actually come back — the only
one that provokes, and the only one *not* in `all`; `all`: the four observing
ones combined. Confirm they are visibly different, not the same report six
times.

The names were `health`, `quick`, `debug` and `deep` until 2026-08-29 and kept
working unlisted until 2026-09-02 (lsp.nvim `d6f0378`); they are refused now,
with the six valid names in the message.

---

## 11. Markdown-language QoL (`languages/documentation/markdown.lua`)

Directly evidenced by telemetry (`setup_reference_hl` fired 4× — real
markdown buffers opened this session range).

**Steps**

1. Open a `.md` file.
2. `<leader>fm` (buffer-local format keymap, distinct from the global
   `<leader>ft`).
3. `:MdFormat`, `:MdFormatPrettier`.

**Expect**: opening the buffer sets `fileencoding=utf-8`, `bomb=false`,
`textwidth=0`, `formatoptions=jnql` (`:set fileencoding? bomb? textwidth?
formatoptions?` to confirm), and the three `LspReference*` highlight groups
are defined (`:hi LspReferenceText` should show real fg/bg, not "cleared").
`<leader>fm` prefers `conform` (`lsp_fallback = false`) if available, else
falls back to `vim.lsp.buf.format`. `:MdFormat` prefers `mdformat` specifically
for `.md` (vs. `prettierd`/`prettier` for other filetypes) — check which
formatter actually ran if more than one is installed. `:MdFormatPrettier`
always uses prettier regardless of filetype.

---

## 12. Right-click context menu

**Prerequisites**: `nvzone/menu` installed (soft dependency; if not, this
section is not testable — confirm `:checkhealth lsp` reports it as an
optional, missing ecosystem piece rather than an error).

**Steps**

`<RightMouse>` in an attached buffer.

**Expect**: a context menu with fly-out groups (Navigation, Rename, Formatter,
Diagnostics, Trouble, Picker) built straight from `require("lsp").status().keymaps`
— i.e. the same resolved catalogue §4 exercises, with the active
`keymaps.preset`/`keymaps.map` overrides already applied. If you disabled an
entry via `keymaps.map` in §4's test, confirm it's also absent from this menu
(same source of truth, not a separately maintained list). Entries requiring
an uninstalled plugin (e.g. Trouble-only entries if Trouble isn't installed)
should be silently skipped, not shown as broken/greyed.

---

## 13. Tools — eslint/prettier, signature help, type lookup, deprecated help

All four are `enable = true` by this config's (plugin) defaults.

**Steps**

1. Open a `.ts`/`.js` file with a real ESLint-flaggable issue — check
   diagnostics appear from ESLint specifically (not just the TS server).
2. In an active insert-mode function call, confirm signature help
   (`<M-s>`) shows a floating parameter hint.
3. In a `.ts` file, use `:TypeDef*` on a typed symbol.
4. Trigger `:LuaLsReloadLibrary`-adjacent deprecated-API help — write a call
   using a known-deprecated Neovim API (e.g. `vim.lsp.buf_get_clients()`) and
   check whether `deprecated_help` flags it.

**Expect**: each tool visibly contributes independent of the others — turn
one off via `tools.<name>.enable = false` in a scratch `setup()` call and
confirm only that one stops (e.g. disabling `lsp_signature` alone should not
touch ESLint diagnostics or type lookup).

---

## What cannot be checked here, and why

- **The `:Lsp` verb taking `nvim-lspconfig`'s plugin file out.** WORKFLOW.md
  documents this as verified *headless* (lspconfig loads, its five commands
  never register because `:Lsp` already exists, case-insensitively).
  Re-verifying it interactively means deliberately renaming the verb and
  checking `:LspStart` reappears from lspconfig — disruptive to do in a real
  session, and the headless proof already covers the mechanism; worth knowing
  about rather than re-testing.
- **`vim.g.lsp_nvim.pack` vs. `opts`** — the two-channel install/configure
  split can only really be seen by editing `init.lua` before `lazy.setup()`
  runs and restarting, which is disruptive to a real session; the failure
  mode (`pack` inside `opts` silently installs nothing, reported as "missing"
  in `:checkhealth lsp`) is worth remembering rather than reproducing live.
