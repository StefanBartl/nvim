# Testing dap.nvim

How to manually test every implemented feature of `dap.nvim`. One-time
setup, then one section per feature: what to do, what to expect, and —
where the code gives a concrete reason to suspect something — what to watch
for specifically. Checkbox syntax (`- [ ]`) is standard Markdown, togglable
directly in Neovim (e.g. with `cascade.nvim`'s `<leader>tc`).

Repo: `E:\repos\dap.nvim`. Lua module name is `wkddap`, not `dap` (that name
is nvim-dap's own `lua/dap.lua`). Spec: `plugins/personal/init.lua` —
`cmd = "Dap"` plus a generated `keys` table (so both the first keypress and
`:Dap` load it), `dependencies` on `lib.nvim`, `nvim-dap`,
`nvim-dap-view`/`nvim-dap-ui`/`nvim-dap-virtual-text`/`nvim-nio`/
`one-small-step-for-vimkind`. This config overrides two defaults:
`keymaps.prefix = "<leader>da"` (not the plugin's own `<leader>d`, which
collides with existing git/fzf mappings) and `ui.provider = "dap-view"`.

**Telemetry gave essentially no signal here** — 24 accumulated sessions, 6
total instrumented calls (`config.get` ×2, `integrations.menu.items` ×2,
`integrations.menu.submenu` ×2). That's too little to order anything by;
priority below comes entirely from reading `docs/WORKFLOW.md` and
`docs/FEATURES/*.md`, which is where most of the concrete "here's what
could go wrong" material already lives.

## Setup

```vim
:checkhealth wkddap
```

Run this **before** anything below, per the plugin's own `WORKFLOW.md`:
"chasing 'why didn't my breakpoint fire' without checking this first usually
means chasing the wrong thing." Expect: Neovim version, nvim-dap presence,
`lib.nvim` availability, configured-vs-active panel UI provider (should read
`dap-view` on both sides in this config — a mismatch means the preference
silently fell back), per-language adapter availability, enabled languages,
registry stats, and any `registry.validate()` errors.

You need something to actually debug. A small standalone Lua file works for
the Lua/OSV target with zero extra setup; for other languages you need the
matching adapter binary (see §5) — Go (`dlv`) and Python (`debugpy`) are the
easiest to have on hand already.

---

## 1. The core debugging loop — continue, step, breakpoints

**Steps**

- [ ] Open a small debuggable file (Lua is the zero-dependency option —
      `one-small-step-for-vimkind` needs nothing external). `<leader>dab`
      toggles a plain breakpoint on the current line (sign appears in the
      gutter — see §3's sign check). `<leader>dac` (`:Dap continue`) starts
      the session.
- [ ] `<leader>das`/`<leader>dai`/`<leader>dao` step over/into/out once each
      — confirm the stopped line and sign move correctly.
- [ ] Stop at a breakpoint, then press `5<leader>das` (count-prefixed step
      over). **This is the one worth watching closely**: per
      `FEATURES/CONTROLS.md`, a naive count loop would desync from the
      adapter (DAP forbids firing a new step request while the previous one
      is still in flight) — the real implementation waits for
      `event_stopped` between each of the 5 steps. Confirm it actually lands
      5 lines further (not fewer, not erroring partway), and that a plain
      `<leader>das` with no count still feels instant (no listener installed
      for the no-count path).
- [ ] `<leader>dat` terminates, `<leader>dar` restarts a stopped session.
- [ ] Every one of the above has a `:Dap <subcommand>` equivalent
      (`:Dap continue`, `:Dap step-over`, …) — try at least two from the
      command line instead of the keymap and confirm identical behavior.

---

## 2. Conditional breakpoints & log points — the pre-fill behavior

**Steps**

- [ ] `<leader>daB` on a line with **no** existing breakpoint — prompt
      should open empty. Submit a condition (e.g. `i > 10`).
- [ ] `<leader>daB` again on that **same line** — the prompt should now
      **pre-fill with the condition already on that breakpoint**, not open
      empty. This is the specific fix `CONTROLS.md` documents (added
      2026-08-24): edit-in-place instead of retype-from-scratch.
- [ ] `<leader>daB` on a **different** line with no breakpoint of its own —
      should pre-fill with the **last value submitted this session**
      (session-level fallback), not the first line's value silently
      reapplied without you seeing it, and not empty.
- [ ] Submit an **empty** line on a line that already has a condition —
      confirm it clears the condition (turns it back into a plain
      breakpoint) rather than being treated as a cancel. `<Esc>` on the
      prompt, separately, should change nothing.
- [ ] `<leader>daL` (log point) — same pre-fill behavior, but check it does
      **not** offer the condition prompt's text or vice versa (tracked
      separately).
- [ ] `:Dap conditional-breakpoint i > 5` (value given inline) — should skip
      the prompt entirely and set the breakpoint directly.

---

## 3. UI provider — `dap-view` in this config, and the gotcha that goes with it

**Steps**

- [ ] With a session running, `<leader>dau` (`:Dap toggle-ui`) opens the
      panel. Confirm it's `nvim-dap-view`'s single-window layout (this
      config's configured provider), not `nvim-dap-ui`'s multi-panel one.
- [ ] `<leader>dae` (`:Dap eval`) on an expression under the cursor (normal
      mode) — with `dap-view` active, this should **add the expression to
      the watch list**, not open a floating window (that's `dap-ui`'s
      behavior only). Confirm the docs' claimed difference actually holds.
- [ ] Visual-select an expression, `<leader>dae` in visual mode — same
      watch-list behavior on the selection.
- [ ] **Gotcha to specifically confirm**: `WORKFLOW.md` states the
      cursorline-toggle autocmd (`DapUIWindowOpen`/`DapUIWindowClose`) is a
      registered no-op with `dap-view`, because only `nvim-dap-ui` ever
      fires those `User` events. Open/close the panel a few times and
      confirm `cursorline` does **not** toggle in the process — if it does,
      something changed and the docs are stale; if it doesn't, that's the
      documented (if slightly surprising) correct behavior, not a bug.

---

## 4. Adapter detection, Mason fallback, and the health check's real job

**Steps**

- [ ] Pick a language whose adapter you do **not** have installed yet (or
      temporarily rename a Mason package directory). `:checkhealth wkddap`
      should report it as missing with a specific remediation (the Mason
      package name to install, or "install manually" for GDB, which has
      none) — not a generic failure.
- [ ] `opts.auto_install = true` (temporarily, in a scratch config) with
      `mason.nvim` present — `:Dap continue` (or restart) on that language
      should trigger a single `:MasonInstall` covering whatever's missing.
- [ ] **If you have Rust and rustc on PATH**: start a Rust debug session and
      inspect a struct value. `WORKFLOW.md` flags that the pretty-printer
      bootstrap (`rustc --print sysroot` + reading
      `lib/rustlib/etc/lldb_commands`) fails **silently** if either step
      doesn't resolve — no error, just raw memory instead of a readable
      struct. Worth confirming pretty-printed output actually appears, since
      a silent failure here looks identical to "it's just not implemented."
- [ ] **If you have Zig**: try the "Launch (build first)" config and confirm
      Neovim genuinely blocks (no spinner, no responsiveness) until
      `zig build` finishes — `vim.system(...):wait()` is synchronous by
      design, per the docs; this isn't a bug to report, just a behavior to
      have actually seen once.

---

## 5. `:Dap` user command surface

**Steps**

- [ ] `:Dap <Tab>` — lists all twelve subcommands
      (`continue`/`step-over`/`step-into`/`step-out`/`terminate`/`restart`/
      `toggle-breakpoint`/`conditional-breakpoint`/`log-point`/
      `list-breakpoints`/`toggle-ui`/`eval`/`repl`).
- [ ] `:Dap list-breakpoints` — quickfix-style list of every breakpoint set
      so far in this session, including the conditional one from §2.
- [ ] `:Dap repl` — opens nvim-dap's own REPL buffer.
- [ ] Disable keymaps (`opts.keymaps.enable = false` in a scratch config)
      and confirm `:Dap continue` etc. still work — the command surface is
      registered independently of `keymaps.enable`.

---

## 6. Menu integration (`nvzone/menu`)

The one area telemetry actually shows *some* activity (`menu.items`/
`menu.submenu`, 2 calls each) — worth a look even without a host menu
plugin wired up.

**Steps**

- [ ] `:lua vim.print(require("wkddap.integrations.menu").items())` —
      should return a real table of entries (Continue/Step Over/Step
      Into/Step Out/Terminate/Restart, breakpoint actions, panel-UI
      actions), not an empty list, given nvim-dap is installed.
- [ ] If `nvzone/menu` (or an equivalent right-click dispatcher) is
      actually wired into this config, right-click in a buffer and confirm
      the DAP entries appear and each one fires the same action its keymap
      equivalent does.
- [ ] Structurally-only if no menu host is configured: confirm
      `M.items()`/`M.submenu()` degrade to an empty list rather than
      erroring when nvim-dap is unavailable (temporarily rename
      `nvim-dap`'s plugin dir, or check this by reading
      `lua/wkddap/integrations/menu.lua` if you'd rather not disturb a
      working install).

---

## 7. which-key group label

**Steps**

- [ ] With which-key installed, press `<leader>da` and wait — should show a
      "DAP" group label over the individual keymap descriptions, not a
      blank/unlabeled popup.

---

## 8. Windows-specific: Mason binary resolution

Only worth a deliberate look on this machine (Windows), not general-purpose.

**Steps**

- [ ] For a Mason-installed adapter (e.g. Go's `dlv`), confirm
      `:checkhealth wkddap` reports it found — the resolution path appends
      `.cmd` to the binary name before checking `mason/bin/` on Windows,
      per `WORKFLOW.md`. If you want to see the raw mechanism: the real
      file on disk is `dlv.cmd`, not `dlv` — a manual
      `stdpath("data")/mason/bin/dlv` check without the suffix would
      (correctly) come up empty, which is not itself a bug.
