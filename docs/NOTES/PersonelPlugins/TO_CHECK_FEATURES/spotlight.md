# Testing spotlight.nvim

How to manually test every implemented feature of `spotlight.nvim`. One-time
setup, then one section per feature: prerequisites, steps, what to expect.
Checkbox syntax (`- [ ]`) throughout.

Repo: `E:\repos\spotlight.nvim`. Spec: `lua/plugins/personal/init.lua` —
`event = "VeryLazy"`, `dependencies = { "StefanBartl/lib.nvim" }`, `opts = {}`
(every default below is live as-is on this machine).

**Telemetry note**: 50 accumulated sessions, 28,746 calls, but every function
that actually shows meaningful counts is a per-window render hot path —
`core.match.reconcile_window`/`core.registry.all`/`core.registry.
apply_to_window` (8,182 each, one triple-fire per window-fill event),
`core.match.forget_window` (2,394), `core.registry.remove_for_buffer` (1,434).
None of these are entry points (no `bindings.`/`commands.`/`usrcmds`/
`keymaps`/`handler.`-shaped name in the whole table) — they fire from the
`WinNew`/`BufWinEnter`/`WinClosed` autocmds regardless of which feature a
human actually reached for, so per the "trust only entry points" rule this
plugin has **no real usage-priority signal**, the same situation as
`sessions.nvim`'s own checklist. `persist.flush`/`persist.save_now` (40 each)
at least confirm persistence ran for real, which is worth keeping in mind
while testing §11. Ordering below follows the README's own account instead:
the Features table and Quickstart both lead with toggle-and-see, so that's
first here too.

## Setup

```vim
:checkhealth spotlight
```

**Expect**: Neovim version OK, `'termguicolors'` reported (should be on —
without it the eight palette slots are approximated to the 256-color cube
and get harder to tell apart), each `lib.nvim` module's availability listed
**separately** (a missing `usercmd.composer` is a different problem than a
missing `debounce`), any config values that failed validation and what they
degraded to, the resolved match/cursor/keymap settings, and live state —
active spotlights with their slots, how many windows carry matches, the
resolved project root, and every per-file persistence override.

A good test target: this repo's own `CHANGELOG.md` or any real log file you
have lying around (`%USERPROFILE%\AppData\Local\nvim-data\log`, or any
server log) — something with request ids, timestamps, and repeated tokens.

---

## 1. Toggle every occurrence — the core loop

**Steps**

1. Open a log-shaped file. Put the cursor on a repeated token (a request id,
   a PID).
2. `<leader>sK`.
3. Move to a different occurrence of the *same* text, `<leader>sK` again.
4. Move to a different token entirely, `<leader>sK`.

- [ ] Step 2 lights up **every** occurrence of the token, in the current
      window, in colors from `Spotlight1`.
- [ ] Step 3 **removes** the spotlight — toggle keys on exact text, not
      position, so pressing it again anywhere the same text sits turns it
      off (not "adds a duplicate").
- [ ] Step 4 adds a second spotlight in `Spotlight2` — a different color
      from the first, not a reused one.
- [ ] `.` (dot-repeat) on a *different* token — re-resolves the cursor
      position fresh and toggles whatever's there now, not the original
      token from step 2.
- [ ] `3<leader>sK` — count prefix is deliberately meaningless here (unlike
      `3]k`); confirm it behaves exactly like a bare `<leader>sK`, not "toggle
      3 tokens".
- [ ] Visual mode: select an arbitrary substring (e.g. `err` inside a wall
      of `error`/`errors` text), `<leader>sK` — should light up `err`
      **literally**, including inside `error`, with no word-boundary
      wrapping — the opposite of what cursor-resolution on the same text
      would give.
- [ ] A multi-line or linewise (`V`) visual selection — should be refused
      (a newline can't live in a `matchadd()` pattern), not silently
      truncated to the first line.

---

## 2. Toggle only this occurrence (`<leader>sk`, lowercase)

The narrower sibling — useful for a common word (`error`, `null`) where
lighting up every instance would be noise.

**Steps**

1. On a common word, `<leader>sk` (lowercase).
2. Move to a *different* occurrence of the same word, `<leader>sk` again.
3. Press `<leader>sk` a third time, on the *original* spot.

- [ ] Step 1 lights up **only** that exact spot — other occurrences of the
      same word in the buffer stay dark.
- [ ] Step 2 adds an **independent** second spotlight (position-keyed, not
      text-keyed) rather than toggling the first one off.
- [ ] Step 3 removes only the original — confirm the step-2 spotlight is
      still lit.
- [ ] Restart Neovim (or just `:qa` and reopen) — a `<leader>sk` spotlight
      should be **gone**; it is session-only by design, excluded from the
      persisted snapshot (unlike §11's `<leader>sK` spotlights).
- [ ] Close the buffer it was created in (`:bwipeout`) while it's still
      active in another window — confirm it's dropped rather than erroring
      or lingering as a stale match.
- [ ] `<leader>sk` in visual mode on a selection — same "this exact spot
      only" semantics, position-pinned, not text-pinned.

---

## 3. Log-aware cursor resolver

The reason `<cword>` alone isn't enough — a UUID, IPv4:port, or ISO
timestamp is several `iskeyword`-words, not one.

**Steps**

Put the cursor at different points inside each of these (paste into a
scratch buffer):

```
550e8400-e29b-41d4-a716-446655440000
192.168.1.1:8080
2026-08-27T14:30:00Z
0x1f4a
user@host
a1b2c3d4e5f6
```

`<leader>sK` on each.

- [ ] Each resolves to the **whole** token, not a fragment split at a `.`,
      `-`, `:`, or `@` — confirm by checking what actually lit up.
- [ ] A plain identifier with no special shape falls back to `<cword>`.
- [ ] Paste (or construct) a single line longer than `cursor.max_line_len`
      (8192 bytes) — the pattern scan should be skipped entirely and
      `<cword>` should answer instead, not hang scanning a giant line.
- [ ] With `debug = true` (see §14), `<leader>sK` should log **which**
      resolver pattern won and its index in the list — confirm a UUID
      really does report the UUID pattern, not a fallback.

---

## 4. Applied in every window

**Steps**

1. `<leader>sK` on a token.
2. `:vsplit` the same buffer.
3. `:tabnew`, open the same file again.
4. Open a *different* buffer that also happens to contain the same literal
   text, in a new window.

- [ ] The spotlight appears in the split (step 2), the new tab (step 3),
      and the unrelated buffer (step 4) — `matchadd()`'s window-locality is
      fully hidden.
- [ ] `:Spotlight winopt on` in one window, then toggle a spotlight — that
      window's matches should be stripped **immediately** (not just gated
      for future fills). `:Spotlight winopt off` should re-fill it
      immediately the same way.
- [ ] `:Spotlight winopt status` reports the current window's state.
- [ ] The opt-out flag is window-sticky: with `winopt on`, switch that
      *same window* to a different buffer (`:bnext`) — it should stay
      excluded, since the flag lives on the window, not the buffer.

---

## 5. Auto-color palette + slot locking

**Steps**

1. Toggle 3–4 spotlights, note the colors used.
2. `:Spotlight clear`, toggle one again — check it starts back at slot 1.
3. `:Spotlight lock` on a spotlight's exact text (or cursor on it).
4. Toggle spotlights until slots would have to recycle.

- [ ] Round-robin skips a slot **already in use** while any slot is free —
      no two simultaneously active spotlights share a color.
- [ ] `:Spotlight clear` resets the round-robin cursor to slot 1 (step 2).
- [ ] A locked spotlight (step 3) keeps its slot even once every other slot
      is claimed and reuse becomes unavoidable — confirm via `:Spotlight
      list lock` or `:checkhealth spotlight`'s live-state section that it's
      shown as locked, and that a later spotlight never gets handed that
      same slot.
- [ ] `:colorscheme <something-else>` — `Spotlight1..8` should be redefined
      automatically (`ColorScheme` autocmd), not left stale/undefined.
- [ ] Toggle `'background'` (`:set background=light`) — the palette should
      switch to `palette.colors_light`, a genuinely different set of hex
      values, not just a dimmed version of the dark set.

---

## 6. Next / previous navigation

**Steps**

1. Spotlight a token that occurs several times, cursor on one occurrence.
2. `]k`, `]k`, `[k`.
3. Move the cursor **off** any spotlight match (a plain word), with two
   different spotlights active. `]k`.
4. `:Spotlight! next` from inside one spotlight's match.

- [ ] Step 2 walks *only* that token's occurrences (`nav.scope = "auto"`,
      standing inside a match) — confirm it never jumps to the *other*
      active spotlight's text.
- [ ] Step 3, standing off any match, walks **all** active spotlights in
      file order — the "auto" scope's other half.
- [ ] `3]k` — three one-step jumps, `unimpaired`-style (not "jump to the
      3rd occurrence" some other way).
- [ ] Step 4 (`:Spotlight!`, bang) ignores `nav.scope` for that one call
      and searches every spotlight even from inside a match — and the
      *next* plain `]k` narrows again (per-call override, not a mode you
      have to turn back off).
- [ ] `nav.wrap = true` (default) — jump past the last occurrence and
      confirm it wraps to the first rather than erroring "not found".

---

## 7. The spotlight list

**Steps**

```vim
:Spotlight list
```

with 2–3 spotlights active, on a buffer under `list.count_max_lines`
(200,000 lines).

- [ ] Shows one row per spotlight: color swatch, token text, live match
      count for the **current buffer only** (not project-wide — see
      `docs/WORKFLOW.md`'s explicit note that a "3" here means "3 here",
      not "3 total").
- [ ] `<CR>` on a row jumps to its first occurrence.
- [ ] `:Spotlight list remove` — selecting a row **removes** that spotlight
      instead of jumping.
- [ ] `:Spotlight list lock` / `:Spotlight list line` — selecting acts on
      the lock/line-mode flag instead (see §5/§9).
- [ ] Filter: `:Spotlight list jump <substring>` (or open the list then
      type) — narrows to spotlights whose slot, highlight group, origin
      path, or text matches. A **numeric** filter (e.g. `1`) should match
      **only** slot 1 exactly — not fall through to a substring match that
      would also catch `Spotlight10`.
- [ ] On a buffer bigger than `list.count_max_lines` — the count column
      shows `?` instead of a number, and the list still opens promptly
      (doesn't hang trying to count).
- [ ] `:lua require("spotlight.config").set("list.count_scope", "loaded")`
      then open the list with the same spotlight active in two loaded
      buffers — the count should now sum across both, shown as `N+` if one
      of those buffers itself exceeds `count_max_lines`.

---

## 8. Quickfix filter and yank

**Steps**

```vim
<leader>sK   " on a repeated token
<leader>sq
```

then, separately:

```vim
:Spotlight yank
```

- [ ] `<leader>sq` fills the quickfix list with every line matching any
      active spotlight (each line once, even if hit by two spotlights),
      auto-opens `:copen`, then returns focus to the **original buffer**
      (not the quickfix window).
- [ ] Press `<leader>sq` again from inside the quickfix window itself
      (deliberately move there first) — expect a refusal message ("run
      this from the buffer you want to filter..."), not a nested
      second-generation quickfix list.
- [ ] `:Spotlight qf all` — scans every loaded ordinary buffer, merges into
      one list; open two buffers with the same spotlighted text active and
      confirm both contribute entries.
- [ ] `:Spotlight yank` — matching lines land in the **unnamed register**
      (paste with `p` to check), raw text, no line-number prefix. Confirm
      it's independent of the quickfix list (doesn't also fill it).
- [ ] Trigger `quickfix.max_entries` (10000) on a genuinely huge repeated
      token if you have one, or lower the config value temporarily
      (`:lua require("spotlight.config").set("quickfix.max_entries", 5)`)
      — confirm scanning **stops** at the cap (not just truncates after
      scanning everything) and both the notify and the quickfix title say
      so.

---

## 9. Whole-line highlighting

**Steps**

```vim
<leader>sK   " on a token
<leader>sW
```

with a second, unrelated spotlight active on the same line somewhere.

- [ ] The token's spotlight now colors the **whole line** it sits on, not
      just the token — but only up to where the line's text ends (not the
      full window width — that's an inherent `matchadd()` limit, not a bug).
- [ ] The *other* spotlight sharing that line should still show its own
      token color somewhere visible — line-mode renders one priority below
      `match.priority`, specifically so it doesn't swallow other tokens'
      colors on the same line.
- [ ] `<leader>sq` / `:Spotlight yank` on this spotlight still report the
      token's own column, not "whole line" — confirm the underlying match
      identity didn't change, only the rendering.
- [ ] `:Spotlight list line` — reach whole-line toggling for a `<leader>sk`
      ("this occurrence only") spotlight this way, since it has no text
      identity for `:Spotlight line {text}` to target.
- [ ] Toggle it back off (`<leader>sW` again) — reverts to token-only
      coloring.

---

## 10. Occurrence density map (sign column)

**Steps**

```vim
:Spotlight map
```

on a buffer with an active spotlight whose occurrences cluster unevenly
(common early in the file, rare later, or vice versa).

- [ ] A sign appears in the sign column on every matching line, in that
      spotlight's own color — confirm it's a genuine density signal (you
      can see where occurrences cluster without scrolling).
- [ ] Edit the buffer afterward (add/remove lines) — the marks should
      **not** move to track the edit; this is explicitly one-shot, not
      live. Run `:Spotlight map` again to refresh.
- [ ] `:Spotlight map clear` removes the marks from the current buffer only
      — open a second buffer with its own map and confirm it's untouched.
- [ ] `:Spotlight map {text}` (one specific spotlight's text) vs. bare
      `:Spotlight map` (all active spotlights) — confirm the scoped version
      only marks that one token's lines.

---

## 11. Named sets

Documented in `docs/WORKFLOW.md` as the fix for juggling two unrelated
investigations in the same log without losing either setup — make sure this
gets covered, since it's easy to skip if you only skim the `:Spotlight`
table.

**Steps**

```vim
<leader>sK   " spotlight token A (today's investigation)
:Spotlight sets save today
:Spotlight clear
<leader>sK   " spotlight token B (yesterday's, reconstructed)
:Spotlight sets save yesterday
:Spotlight sets switch today
:Spotlight sets list
```

- [ ] `sets switch today` clears whatever's active and restores exactly the
      token-A spotlight — confirm token B's spotlight is gone, not layered
      underneath.
- [ ] `sets list` shows both `today` and `yesterday` with a real spotlight
      count each.
- [ ] `:Spotlight sets switch nonexistent-name` — refused as a no-op
      ("unknown set"), not a silent clear-and-nothing.
- [ ] `switch`/`delete` tab-complete from the real saved names.
- [ ] `:Spotlight sets delete yesterday`, then `sets list` — confirm it's
      gone, and confirm deleting it did **not** touch whatever set is
      currently active (`today` should still be lit).
- [ ] Restart Neovim entirely, `:Spotlight sets list` — saved sets persist
      across restarts (written synchronously on save/switch/delete, not
      debounced).

---

## 12. Per-file persistence opt-out

**Steps**

1. In a fresh scratch file, `<leader>sK` on some text.
2. `:qa`, reopen the same file.
3. `:Spotlight persist off`, `<leader>sK` on different text, `:qa`, reopen.
4. `:Spotlight persist status`.

- [ ] Step 2: the step-1 spotlight comes back (default `persist.default =
      true`, opt-out model).
- [ ] Step 3: the spotlight created *after* `persist off` does **not** come
      back on reopen — but confirm the `persist off` setting **itself**
      survives the restart (`:Spotlight persist status` afterward should
      still say "off" for this file).
- [ ] Origin, not appearance: spotlight the same literal text in a
      *different*, non-excluded file — confirm that one persists even
      though the excluded file also contains the string. The exception is
      about where a spotlight was created, not every file the text
      happens to appear in.
- [ ] `<leader>sk` ("this occurrence only") spotlights never persist
      regardless of this setting — already covered by §2's restart check,
      but worth re-confirming here specifically with `persist on`.
- [ ] `:Spotlight persist default` — drops the per-file override, back to
      following the global default.

---

## 13. `:Spotlight refresh`

**Steps**

```vim
:call clearmatches()
```

with a spotlight active in the current window, then:

```vim
:Spotlight refresh
```

- [ ] After `clearmatches()`, the spotlight should visibly disappear from
      that window (an external plugin action spotlight has no autocmd for
      — this is the documented gap `refresh` exists to patch).
- [ ] `:Spotlight refresh` restores it, across every window that had it,
      and redefines the `Spotlight1..8` groups from scratch.

---

## 14. `:checkhealth spotlight` and debug logging

**Steps**

```lua
require("spotlight").setup({ debug = true })
```

Then toggle a spotlight, navigate with `]k`, and restart Neovim.

- [ ] With `debug = true`, check `:LibLogger` (or `vim.notify` at DEBUG
      level if `lib.nvim.logger` isn't wired) for entries covering: which
      cursor-resolver pattern won, which windows the match ledger
      applied/skipped, what the persisted snapshot kept/dropped on load,
      and whether navigation narrowed to one spotlight or searched all.
- [ ] Feed a deliberately broken config value (`palette = { colors = {
      "not-a-color" } }`) into a scratch `setup()` call — `:checkhealth
      spotlight` should list it as rejected-and-defaulted, and the plugin
      should still load and work, not error out on `setup()`.
- [ ] Confirm `'termguicolors'` is flagged if it's off (temporarily `:set
      notermguicolors` and re-run `:checkhealth spotlight` to see the
      warning, then set it back on).

---

## What this checklist does not cover

The security-model claims in the README (bounded regex construction, no
shell-outs/network/file-writes outside the cache, snapshot re-validation on
load) are static code properties, not something a manual click-through can
falsify — worth a read if you're auditing the plugin, not a checklist item.
Deliberately unimplemented per the roadmap (regex mode, per-filetype
scoping, automatic error/warn rules, set export/import) is out of scope by
definition.
