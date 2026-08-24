# recommender.nvim — User Commands Cheatsheet

One command tree, built via `lib.nvim.usercmd.composer` (migrated
2026-07-20). **The last plugin in the rollout — `usrcmd_composer.md` is now
26/26.** Second (after emojis.nvim) repo that had genuinely zero prior
`lib.nvim` dependency; now `:Recommender` fails to register without it.

Source: `lua/recommender/bindings/usrcmds.lua`
(module root renamed from `recommender_nvim` -> `recommender`, 2026-07 refactor)
Docs: `docs/commands.md`, `docs/BINDINGS.md`, `doc/recommender.txt` (renamed from
`doc/recommender.nvim.txt` in the 2026-08 checklist pass; `:h recommender` now resolves directly)

| Command | Args | Effect |
| --- | --- | --- |
| `:Recommender` | `[-r\|--replace] [-c\|--cwd] [regex\|treesitter\|javascript\|python\|perf] [threshold] [buffer\|path\|cwd\|cfile\|line]` | Toggle the suggestion float; flags/positionals in any order |

## Notes

- **2026-08-24: `perf` analyzer added — the plugin's core premise turned out
  false under LuaJIT.** Ran `:Recommender cwd` across all ~38 personal repos
  under `C:\repos` and got ~1000 alias suggestions, most of them junk
  (`local 9 = 0.9`, `local nvim = lib.nvim` — would crash, `lib.nvim` isn't a
  global — plus the scan silently truncated at `cwd_max_files=500`,
  covering only 11 of 38 repos alphabetically). Re-ran the *original*
  benchmark this plugin was built on
  (`C:\repos\WKDBooks\Development\wkdbook-Lua\Benchmarks\Tests\reference-lookup.lua`)
  under both a standalone Lua 5.4 interpreter and headless `nvim` (LuaJIT
  2.1): the benchmarked ~23% aliasing win **only reproduces without a JIT**
  — under LuaJIT (what Neovim actually runs), direct vs. aliased table
  lookup measured identically (`0.000ms` either way at 1e6 calls; a
  hoisting-safe follow-up measured the true per-lookup cost at ~0.02ns,
  i.e. noise). `vim.fn`/`vim.api` aliasing was already known from the same
  benchmark set to have no benefit either way (confirmed again: lookup is
  ~0.1% of a real `vim.api.*()` call's cost).
  - **User's own conclusion, verified rather than just accepted**: only 4 of
    the ~10 tracked benchmark results (`table.insert` vs. indexed
    assignment ~4-5x, `..` accumulator vs. `table.concat` ~4x+ at scale,
    `ipairs` vs. numeric `for` ~2x, `string.format` vs. `..` ~3x) hold up as
    *algorithmic* wins the JIT can't do for you — these became the new
    `analyzers/perf.lua`, everything alias-shaped was left alone (still
    works, just not recommended going forward per the benchmark evidence).
  - New analyzer is a **fixed-pattern detector, not a chain counter** — the
    four patterns above, each gated by a lightweight line-based block
    tracker (`classify_line` in `perf.lua`: for/while/repeat push a
    "loop" stack entry, if/function/do push non-loop, single-line blocks
    like `for i=1,3 do t end` are net-zero-depth special-cased) so a
    single `table.insert` outside any loop is correctly NOT flagged —
    confirmed in a dedicated unit test before wiring in.
  - `ipairs` is flagged on its own `for...in ipairs(...)` line regardless
    of enclosing loop nesting (the ~2x per-iteration cost doesn't depend on
    nesting); the other three require being inside a loop.
  - The `x = x .. y` accumulator check uses a genuine Lua pattern
    **backreference** (`%1`) — `([%w_%.]+)%s*=%s*%1%s*%.%.` — to require
    the *same* identifier on both sides, so it only flags the O(n²)
    self-concat case, not incidental `..` usage like
    `dir .. "/" .. name` (which is O(1) per call, not a real perf issue).
  - `Enter`/`A` insert a `-- perf: ...` advisory comment, not an automatic
    rewrite (per user's own explicit call when asked: new analyzer
    alongside existing ones, comment-only, not README repositioning, not
    auto-rewrite — all three were offered, this one chosen).
  - `config.threshold`'s meaning is genuinely different for `perf` than for
    the chain analyzers ("how many instances exist", not "worth aliasing
    at N+ repeats") — documented explicitly rather than silently reused,
    since e.g. a single `table.insert`-in-loop is still worth flagging.
  - Spot-checked against ~700 real files across 5 unrelated personal repos
    (cascade.nvim, documentation.nvim, cmdlog.nvim, lib.nvim,
    color_my_ascii.nvim) before shipping: every hand-inspected hit was a
    genuine in-loop occurrence, no crashes, no garbage chain names (unlike
    the old `:Recommender cwd` alias run above).
  - `project.supports_cwd(analyzer_name)` gate (added for scope work
    earlier the same day) already generalized cleanly to a 5th analyzer —
    just one line in `project.lua`'s `EXTENSIONS` table. The "unsupported"
    error message was hardcoded to name 3 analyzers though (`"use regex,
    javascript, or python"`) and had already silently drifted once (the
    scope work added it, this session immediately needed a 4th name) — now
    built from `project.supports_cwd()` at module-load time instead, so it
    can't drift again.

- **2026-08-24: `{scope}` positional added — `buffer` (default) / `path` /
  `cwd` / `cfile` / `line`**. Requested as "`:Recommender [scope?]` with
  default buffer scope, plus path/cwd/cfile/line" — `cwd` already existed as
  the `-c`/`--cwd` boolean flag; this generalizes it into a 5-way scope
  value and adds three new ones. Third optional positional slot (`a3`) added
  to the composer route (`a1`/`a2`/`a3`, all `STRING`, `values =
  COMPLETION_VALUES` — analyzer names ∪ scope names, for `<Tab>` hints in
  any of the 3 slots).
  - **Classification is by content, not slot position** — new
    `classify_pos_args(pos_args)` scans every leftover token once and
    buckets it as a scope match, else an analyzer match, else `tonumber`
    (first hit per category wins). This is a deliberate generalization of
    the pre-existing pos_args handling (which only ever checked
    `pos_args[1]` for the analyzer and `pos_args[2]`/`pos_args[1]` for the
    threshold): `:Recommender cwd javascript 5`, `:Recommender javascript
    cwd 5`, and `:Recommender 5 javascript cwd` all now resolve identically.
    Verified nothing in the documented pre-existing test matrix (`-r regex
    5` / `regex -r 5` / `regex 5 -r`, the `:Recommender 5` threshold-only
    edge case) changed behavior — the loop is a strict superset.
  - **`-c`/`--cwd` kept as a backward-compatible flag alias** for `scope =
    "cwd"`; an explicit `{scope}` positional always overrides it
    (`:Recommender -c path` → `path`, confirmed in headless testing).
  - **`path` scope**: identical scan to `cwd` (`project.find_files` +
    `project.read_lines`, same `cwd_ignore`/`cwd_max_files` config keys) but
    rooted at `vim.fn.fnamemodify(bufname, ":p:h")` — the *current buffer's
    own* directory — instead of `getcwd()`. Errors on an unnamed buffer
    (`api.nvim_buf_get_name(bufnr) == ""`).
  - **`cfile` scope**: new `resolve_cfile(cfile, bufnr)` helper resolves
    `vim.fn.expand("<cfile>")` to a readable absolute path in three steps —
    as typed, then relative to the source buffer's directory, then via
    `vim.fn.findfile(cfile, vim.o.path)` (mirrors `gf`'s resolution order,
    not reusing Neovim's actual `gf` internals since there's no public API
    for that). Single-file `project.read_lines({path})` call, isolated from
    both the buffer and any cwd/path aggregation (verified in testing: a
    file with its own count of 4 stayed isolated at 4 under `cfile`, not
    summed with the other file in the same directory's count of 7 under
    `cwd`/`path`).
  - **`line` scope**: passes `{ current_line_text }` as the explicit
    `lines` array. **Important interaction discovered via headless
    testing**: `analyzers/regex.lua`'s `extract_chains()` dedups matches
    *per line* before counting, so a 1-line `lines` array caps every
    chain's count at 1 — `config.threshold` (3 by default) would make
    `line` scope silently report "No suggestions" on every real invocation.
    Fixed by defaulting `threshold` to `1` specifically for `scope ==
    "line"` when the caller didn't pass an explicit `{threshold}` token
    (`pos_threshold or (scope == "line" and 1) or cfg.threshold`) — an
    explicit token still overrides it either direction.
  - **`cfile`/`cursor_line_text` captured at `execute()`-time**, before
    `vim.schedule(state.refresh)` — not inside `refresh()` itself — so the
    resolved scope reflects the cursor/file that was actually under it when
    `:Recommender` was invoked, consistent with how `source_bufnr` was
    already captured eagerly before scheduling.
  - **`project.supports_cwd(analyzer_name)` reused unchanged** as the gate
    for all four non-buffer scopes (renamed in doc comments only, not in
    code — it's really "does this analyzer accept an explicit `lines` array
    instead of a live buffer", which is what every non-buffer scope needs;
    treesitter never does, since it parses a live buffer via
    `vim.treesitter.get_parser`). Error message generalized from a
    cwd-specific string to `("%s scope isn't supported for analyzer %q —
    use regex, javascript, or python"):format(scope, analyzer_name)`.
  - **Verified end-to-end in a headless `nvim --headless -u NONE`
    session** (rtp-loaded from both this repo and the sibling `lib.nvim`
    checkout, `rendering.open`/`is_open`/`close` monkey-patched to capture
    suggestions without touching the real `kit.select` UI, `lib.nvim.notify`
    stubbed to capture messages): all 5 scopes, order-independence, `-c`
    back-compat, explicit-scope-over-flag precedence, the generalized
    treesitter hard error, and both new error paths (unnamed buffer for
    `path`, no file-under-cursor for `cfile`) — all behaved exactly as
    designed. No pre-existing bugs surfaced.
  - Docs updated: `docs/commands.md` (new "Scopes" section replacing
    "Project-wide (-c/--cwd) scope"), `docs/BINDINGS.md`, `docs/FEATURES.md`,
    `docs/configuration.md`, `docs/architecture.md`, `README.md`,
    `doc/recommender.txt` (section 9 renamed `PROJECT-WIDE SCOPE` →
    `SCOPES`, split into 9.1–9.4 subsections; old `*recommender-cwd-scope*`
    tag kept, now titling the `cwd`/`path` subsection specifically).

- **2026-07-24: `-c`/`--cwd` project-wide scope added** (roadmap item —
  new `FlagSpec {name="cwd", short="c", bool=true}` alongside `replace`, same
  short-flag pattern. New `lua/recommender/project.lua` finds files under
  `getcwd()` by analyzer extension (skips `config.cwd_ignore` dir names,
  caps at `config.cwd_max_files`), reads them with `vim.fn.readfile()`, and
  feeds the concatenated line list into the *same* `analyzer.analyze()` used
  for buffer scope, via a new optional 4th `lines` param on
  regex/javascript/python's `analyze()` (falls back to the current buffer
  when omitted — buffer-scope callers, including this file's `execute()`,
  are unaffected). treesitter is buffer-only (parses a live buffer's syntax
  tree, not raw text) — `execute()` hard-errors if `-c` is combined with it,
  via `project.supports_cwd(analyzer_name)`.

- **2026-07-24: `javascript`/`python` analyzers added** (roadmap item —
  regex-based, no parser dependency, same architecture as the `regex`
  backend but with JS/TS's `const %s = %s;` or Python's plain `%s = %s`
  alias syntax). `{analyzer}` positional values extended accordingly;
  `get_analyzer()`'s error message and the composer route's `values=`
  completion list both now read from one shared `ANALYZER_NAMES` list in
  `usrcmds.lua` instead of a hardcoded `"regex"`/`"treesitter"` check.
  Reminder from composer internals (confirmed in `lib.nvim`'s
  `argtypes.lua`): a route arg's `values` field only feeds tab-completion
  for `type = "STRING"` — it does NOT restrict what validates at runtime
  (only `enum` does that). Runtime restriction of `{analyzer}` is enforced
  by `execute()`'s own `_is_analyzer_name` lookup, same as before.

- **Textbook `path = {}` root-route case**: no subcommand word at all —
  exactly the grammar shape the roadmap's step 2 flags this trick for. The
  entire verb is ONE route (`path = {}`), so `tree.walk` resolves to it for
  every invocation regardless of tokens, including bare `:Recommender`
  (confirmed the Phase 8 "bare root-route" fix — shipped in `lib.nvim` mid
  rollout, no code changes needed on this end — is active: bare invocation
  correctly resolved analyzer="regex"/threshold=3 defaults through the same
  route rather than being silently skipped).
- **The actual motivating case for Phase 7's short-flag aliases**:
  `FlagSpec.short = "r"` was built specifically to unblock this repo's
  `-r`/`--replace` grammar (see the roadmap's Phase 7 section). One
  `FlagSpec` (`{name="replace", short="r", bool=true}`) covers both forms.
- **`ctx.flags`/`ctx.pos` fed the original logic directly — no
  reconstruction needed, unlike every prior "flags" migration
  (insights.nvim's `metrics`, emojis.nvim)**: composer's flag/
  positional split is *the same algorithm* the original inline loop already
  used (strip `-r`/`--replace` tokens, keep everything else as positional,
  in order) — not just format-compatible, semantically identical. So
  `execute(cfg, ctx.flags.replace or false, ctx.pos)` calls straight into
  the extracted-but-otherwise-unchanged dispatch function; no round-trip
  through reconstructed `--flag` strings was required.
- **Accepted behavior tightening, narrower than usual**: an undeclared
  `--flag` (e.g. `--bogus`) is now a hard composer error — previously it
  silently fell through to `pos_args` as an inert positional value (harmless
  no-op, since `tonumber("--bogus")` and the `regex`/`treesitter` string
  checks both just failed silently). An undeclared *short* `-x` is
  unaffected either way — composer leaves it as a lenient positional too,
  matching the original (which also only special-cased `-r` exactly).
- **All 5 of `keymaps.lua`'s `<cmd>Recommender...<cr>` string-coupled
  mappings verified dispatching correctly** post-migration (bare, `-r`,
  `regex`, `treesitter`, `regex 5`), plus flag-position independence
  (`-r regex 5` / `regex -r 5` / `regex 5 -r` all resolve identically) and
  the threshold-only edge case (`:Recommender 5` → analyzer stays default,
  threshold=5, since `pos_args[1]="5"` isn't `"regex"`/`"treesitter"` so
  falls through to `tonumber(pos_args[1])` for threshold).
- **No test suite in this repo** (CI is stylua+luacheck only, no headless
  `nvim` test job) — nothing to fix for a `lib.nvim` sibling checkout, unlike
  emojis.nvim/cascade.nvim.
- **`README.md` had a stale "Pure Neovim — no external dependencies" claim**
  that predates even the soft `lib.nvim.notify`/`map` bridge — now false
  outright since composer is hard-required. Fixed alongside every other
  "optional"/`lib.nvim` requirements-table mention across README, `docs/
  installation.md`, and `doc/recommender.nvim.txt` (none of which previously
  listed `lib.nvim` as a dependency at all, required or optional).
- **No pre-existing bugs found** while verifying.
