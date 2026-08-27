# Testing debugging.nvim

How to manually test every implemented feature of `debugging.nvim`.
One-time setup, then one section per feature: what to do, what to expect,
and — where the code gives a concrete reason to suspect something — what to
watch for specifically. Checkbox syntax (`- [ ]`) is standard Markdown,
togglable directly in Neovim (e.g. with `cascade.nvim`'s `<leader>tc`).

Repo: `E:\repos\debugging.nvim`. Spec: `plugins/personal/init.lua` —
`event = "VeryLazy"` (commented-out `cmd = "Debug"` above it, so this
config chose eager-ish loading over command-lazy), `dependencies` on
`lib.nvim`, `opts = {}` (defaults apply — the spec's own comment notes
`features.neotree` is off by default in the plugin itself, so nothing extra
needed there).

**Telemetry gives a real, if indirect, signal.** 83 accumulated sessions,
3,764 total calls, but none of the instrumented functions match the
"trusted entry point" naming convention (`bindings.*`/`commands.*`/
`usrcmds`/`keymaps`/`handler.*`) — everything counted is inside
`views.display`/`views.utils`, support functions for rendering and
re-focusing the scratch windows. Still, the **scale** is the signal:
`views.display.get_window_tag` alone accounts for 2,723 of the 3,764
calls, and every other instrumented function is `views.*` too. The Messages/
Noice **views subsystem** is, by a wide margin, the most-exercised part of
this plugin in real use — everything else here has comparatively little
telemetry weight behind it, which is why it's ordered first below despite
not being a "handler"-style entry point itself.

## Setup

```vim
:checkhealth debugging
```

Expect: Neovim version, the `lib.nvim` modules each enabled feature
depends on, clipboard provider (needed for message capture), optional
Tree-sitter/Noice detection, write permissions for capture/keylog output
paths, and the opt-in Neo-tree bridge's resolvability (should report
"not configured" cleanly, since `features.neotree` is off).

```vim
:Debug
```

with no arguments renders a scrollable floating overview of every enabled
category — a quick sanity check that the command loaded and the feature
gates read as expected before testing anything below.

---

## 1. Messages / Noice views, and the capture-sink split

**Steps**

- [ ] `<lt>m` (the literal `<` key, then `m` — this plugin's default prefix)
      opens the Messages view: an auto-refreshing scratch window mirroring
      `:messages`. Generate a new message (`:echom "test"`) and confirm the
      window updates without re-triggering the keymap.
- [ ] If `noice.nvim` is installed: `<lt>n` opens the Noice-all view,
      `<lt>e` opens Noice-errors specifically — confirm the errors view
      really is filtered (produce a non-error message and confirm it does
      **not** show there).
- [ ] `<lt>c` captures the current view to **both** file and clipboard.
      Paste (`p`) somewhere to confirm the clipboard actually has content,
      and check `opts.views.output_dir` (defaults to
      `stdpath("config")/docs/debug_views`) for the written file.
- [ ] `<lt>f` captures to **file only** — paste afterward and confirm the
      clipboard was **not** touched (still holds whatever was there
      before).
- [ ] `<lt>y` captures to **clipboard only** — confirm no new file appears
      under `output_dir` for this one.
- [ ] `<lt>x` closes every debug window at once — open two or three views
      first, then confirm one `<lt>x` clears all of them, not just the most
      recent.
- [ ] `:Debug messages show|capture|clear` and `:Debug noice all|errors` —
      the `:Debug`-command equivalents of the above; try at least the
      `capture` one and confirm it matches `<lt>c`'s both-sinks default.

---

## 2. UI-freeze diagnosis (`:Debug proc`)

The most gotcha-dense feature in the docs — `WORKFLOW.md` spends a full
section on it, worth reading before testing.

**Steps**

- [ ] `:Debug proc start 200` (200ms threshold), then run something that
      shells out and is slow enough to cross it (a `vim.fn.system(...)`
      call taking >200ms, or lower the threshold to catch a fast one on
      purpose: `:Debug proc start 5`).
- [ ] `:Debug proc stop`, then `:Debug proc log` — expect an entry with a
      real duration and a **full Lua traceback** pointing at the call site,
      not just "something was slow."
- [ ] **The trap to actually try triggering**: `proc_trace` wraps
      `vim.fn.system`/`vim.fn.systemlist`/`vim.system`/`vim.fn.jobstart` in
      place. A plugin (or a scratch `:lua`) that captured
      `local system = vim.fn.system` **before** `proc start` ran holds the
      original, unwrapped function — confirm a call through such a
      pre-captured local does **not** show up in `proc log`, while an
      equivalent call through `vim.fn.system(...)` directly (after
      `proc start`) does. This is the one limitation the docs are most
      explicit should not be mistaken for a bug.
- [ ] Windows-only: `:Debug proc watch 60`, then trigger some external
      process spawn (anything that shells out, including one that bypasses
      `vim.fn.*`/`vim.system` entirely, e.g. an LSP server subprocess
      starting). `<C-c>` to stop early. Expect every child process of this
      Neovim instance listed, sorted by lifetime — this is the layer meant
      to catch what `proc_trace` structurally cannot see.
- [ ] `:Debug proc status` mid-trace — confirms whether tracing is
      currently active, without needing to remember whether you last
      called `start` or `stop`.

---

## 3. Autocmd inspection — the three views, and when to reach for which

**Steps**

- [ ] `:Debug autocmds runtime` — live dump via `nvim_get_autocmds()`.
      Should reflect exactly what's registered *right now* (try filtering
      with `runtime BufEnter` and confirm only matching entries show).
- [ ] `:Debug autocmds sources` — static scan of `nvim_create_autocmd` call
      sites in the project. Compare its count for a known event against
      `runtime`'s count for the same event — they can legitimately differ
      (a plugin registering dynamically has no static source).
- [ ] `:Debug autocmds sources qf=true` — same data, but sent to the
      quickfix list as real `path:line` entries instead of a scratch
      report. Confirm `:cnext`/`<CR>` actually jumps to the
      `nvim_create_autocmd(...)` call, not just somewhere in the file.
- [ ] **Cache staleness check**: run `sources` once, then edit a file that
      adds a new `nvim_create_autocmd` call, save, and re-run
      `sources` **without** `refresh=true` — per the docs, results are
      cached per project root for a few seconds via `lib.nvim.cache.memory`,
      so the new entry may not appear yet. Re-run with `refresh=true` and
      confirm it does.
- [ ] `:Debug autocmds all` — the fused view. Look specifically for an
      event flagged as registered-at-runtime-with-no-source (this is
      `sources`'s documented blind spot made visible — a genuinely
      plugin-internal, dynamically-registered autocmd should show up
      flagged here even though `sources` alone would silently omit it).

---

## 4. Reports vs. inspect

**Steps**

- [ ] `:Debug report buf` — prints straight to `:messages`, no window.
      `:Debug report win 1000` / `:Debug report tab 2` with an explicit id
      — confirm it reports that window/tab, not the current one (use
      `:messages` afterward to check, since the point of `report` is that
      it doesn't open anything to look at).
- [ ] `:Debug inspect buffer` (no id) — opens a scoped view of the current
      buffer's options/state, distinct from the plain-message `report`.
      `:Debug inspect window 1000` with an explicit id likewise.
- [ ] Confirm omitting the id on either command falls back to "the current
      one" consistently across `buf`/`win`/`tab`.

---

## 5. Module reload

**Steps**

- [ ] Open a Lua file belonging to a loaded plugin (debugging.nvim's own
      source is the safest target — e.g. open
      `lua/debugging/actions/module_reload.lua` itself). `:Debug module
      reload` — expect a notification confirming the module was evicted
      from `package.loaded` and re-required.
- [ ] Make a trivial, visible change to a **leaf** function (one nothing
      else holds a closure over), save, reload again — confirm the new
      behavior is live without restarting Neovim.
- [ ] **Structurally verified, worth knowing rather than being surprised
      by**: this does *not* cascade to modules that already `require`'d
      the old table and kept a local reference — a change spanning several
      interdependent modules will not fully take effect via repeated
      `module reload` calls alone. Not something to "fix" by reloading
      harder; a restart is the correct answer for that case, per the docs.

---

## 6. Terminal keylogger

**Steps**

- [ ] Open a terminal buffer, `:Debug keylogger start` (no path) — type a
      few keys, confirm each is notified as pressed and **nothing is
      written to disk** (no `logfile` configured by default in this
      config).
- [ ] `:Debug keylogger start ~/keys.log` (or another writable path) — type
      a few more keys, `:Debug keylogger stop`, then check the file
      actually contains them.
- [ ] Confirm the per-session path argument does **not** persist — start
      again with no argument afterward and check it's back to notify-only.

---

## 7. Indent diagnostics

**Steps**

- [ ] `:Debug indent show` in a buffer with known indent settings — confirm
      the printed values (`shiftwidth`, `expandtab`, etc.) match `:set
      sw?` / `:set et?` for that buffer.
- [ ] `:Debug indent treesitter true` — forces Tree-sitter-driven indent on;
      `:Debug indent treesitter false` restores `cindent`/`smartindent`.
      Confirm indenting a new line (`o`, type, `<CR>`) actually behaves
      differently between the two states in a language with a Tree-sitter
      indent query available.

---

## 8. Markdown inline-highlight debug

**Steps**

- [ ] In a Markdown buffer with some inline styling rendered (bold,
      italic, etc. — depends on `markdown.nvim` being active), `:Debug
      markdown inline` — expect a gathered debug dump of the extmarks/
      syntax state behind the rendering, not an empty report.
- [ ] `:Debug markdown log` — opens the most recent debug log from the
      command above. Confirm it opens the log that was *just* generated,
      not a stale one from a previous session.

---

## 9. Startup benchmark

**Steps**

- [ ] `:Debug performance startup` (no argument) — runs `--startuptime`
      once, reports total time and the slowest sourced scripts.
- [ ] `:Debug performance startup 5` — averages over 5 headless launches.
      **Worth actually comparing the two**: per `WORKFLOW.md`, a single run
      is a weak signal given normal run-to-run jitter — confirm the
      averaged number differs somewhat from a single bare run, which is
      the whole reason the averaged form exists.

---

## 10. Neo-tree safety bridge (opt-in, off by default)

Lowest priority here on purpose — `features.neotree` defaults to `false`
in both the plugin and this config, and the bridge targets config that
lives outside this plugin entirely.

**Steps**

- [ ] With the feature left off (current config): confirm `neotree` does
      **not** appear in `:Debug <Tab>` completion — this is the documented
      behavior (§ "Tab completion reflects the active config"), not a bug
      to chase.
- [ ] If you want to actually exercise it: temporarily set
      `features.neotree = true` in a scratch config (without the private
      `config.neotree.*` layout present). `:Debug neotree status` should
      degrade to a clear warning notification ("not configured") rather
      than erroring — confirming the pcall-guard works, since "ran with no
      error" and "did something" are explicitly documented as different
      things here.

---

## 11. Tab completion reflects the active config, and `:checkhealth debugging`

**Steps**

- [ ] `:Debug <Tab>` — should list exactly the categories enabled in
      `opts.features` (everything except `neotree` in this config's
      default state).
- [ ] `:Debug autocmds sources <Tab>` — completes its own keyword args
      (`event=`, `sort=`, `impl=`, `summary=`, `freq=`, `root=`,
      `refresh=`, `qf=`); `:Debug autocmds sources event=Buf<Tab>` should
      further complete against real event names (`BufAdd`, `BufEnter`, …).
- [ ] `:checkhealth debugging` (also reachable as `:Debug health`) — run it
      clean once, confirm all sections report sensibly.
