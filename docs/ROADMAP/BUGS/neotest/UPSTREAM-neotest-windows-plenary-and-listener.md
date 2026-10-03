# Upstream candidates: neotest on Windows (plenary runs hang, unauthenticated listener)

**Status:** ready to file, **not filed**. Posting is outward-facing (public text under the user's
GitHub account) and needs an explicit yes. Check for existing issues first (see
[Before filing](#before-filing)).

**Found:** 2026-10-02/03, while measuring neotest's startup cost and then actually running tests
with the real config. Full investigation, measurements and the local workaround:
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/nvim-config/Backlog/TASKS/neotest-listener-und-windows-laeufe-2026-10-03.md`.

Checked against: neotest `27bf921` (2026-08-16), neotest-plenary `3523adc` (2024-09-15, still
`master`), Neovim 0.12.2, Windows 11. Line numbers re-checked against upstream `master` on 2026-10-03.

| # | Repo | What | Existing report | Where to file |
| --- | --- | --- | --- | --- |
| 1 | `nvim-neotest/neotest-plenary` | Windows paths spliced into a Lua string: every run hangs | [#17](https://github.com/nvim-neotest/neotest-plenary/issues/17) (open, same symptom) | comment on #17, PR if wanted |
| 2 | `nvim-neotest/neotest` | `subprocess.init` opens an unauthenticated `localhost` RPC listener, no way to turn it off | none (related, different: #430, #441, #563) | new issue; see the note on severity |

---

## 1. neotest-plenary: runs never finish on Windows

### The one-sentence version

`adapter.lua:87` builds `-c "lua _run_tests({file = '<path>', ...})"` by pasting the path into a Lua
string literal; on Windows the path is `C:\Users\...`, `\U` is an invalid escape in LuaJIT, the
command fails, and the headless child never exits.

### Cause

```lua
"lua _run_tests({results = '" .. results_path .. "', file = '" .. nio.fn.escape(pos.path, "'") .. "', filter = " .. vim.inspect(filters) .. "})",
```

`nio.fn.escape(pos.path, "'")` only escapes quotes. `pos.path` and `results_path` (a `%TEMP%` path)
contain backslashes. `run_tests.lua` leaves only through `os.exit` inside `_run_tests`, so when the
`-c` chunk fails to compile nothing ever exits: the child sits idle (0 s CPU), neotest waits for a
result file that is never written, and the spinner never stops. One orphaned `nvim` per run.

Forward slashes in the paths make the same command line finish in under a second.

### Fix

`vim.inspect` yields valid Lua on every platform:

```lua
"lua _run_tests({results = " .. vim.inspect(results_path)
  .. ", file = " .. vim.inspect(pos.path)
  .. ", filter = " .. vim.inspect(filters) .. "})",
```

Verified: `-c "lua _run_tests({results = "C:\\Users\\...\\results", file = "C:\\...\\x_spec.lua", filter = {}})"`
runs, results come back (8 passed / 1 failed in the sample project), no leftover process.

### Second Windows fault (not neotest-plenary's, easy to harden against)

If the parent Neovim exports `NVIM_LISTEN_ADDRESS` (some configs do, for a predictable pipe), the
test child inherits it and Neovim aborts at startup in C:
`nvim.exe: Failed $NVIM_LISTEN_ADDRESS: address already in use` (exit 1, no result file).
`env = { NVIM_LISTEN_ADDRESS = "" }` in the returned spec avoids it. The two faults overlap: fixing
only this one turns "9/9 failed" into "hangs forever".

### Draft: comment for #17

> I hit this on Windows and found the cause, in case it helps.
>
> `adapter.lua:87` builds the child command by splicing the file path into a Lua string literal:
>
> ```lua
> "lua _run_tests({results = '" .. results_path .. "', file = '" .. nio.fn.escape(pos.path, "'") .. "', filter = " .. vim.inspect(filters) .. "})",
> ```
>
> `nio.fn.escape(pos.path, "'")` only escapes quotes. On Windows `pos.path` is `C:\Users\...` and
> `results_path` is a `%TEMP%` path, so the generated chunk contains `\U`, `\A`, ... which are invalid
> escape sequences in LuaJIT (`invalid escape sequence '\U'`). The `-c "lua ..."` command fails, and
> because `run_tests.lua` only leaves via `os.exit` inside `_run_tests`, the headless child never
> exits: it sits idle (0 s CPU) and neotest waits for a result file that is never written. One
> orphaned `nvim` per run.
>
> Using `vim.inspect` for the values yields valid Lua on every platform (it escapes backslashes and
> quotes):
>
> ```lua
> "lua _run_tests({results = " .. vim.inspect(results_path)
>   .. ", file = " .. vim.inspect(pos.path)
>   .. ", filter = " .. vim.inspect(filters) .. "})",
> ```
>
> With this, `-c "lua _run_tests({results = "C:\\Users\\...\\results", file = "C:\\...\\x_spec.lua", filter = {}})"`
> runs and the results come back (8 passed / 1 failed in my sample, no leftover process). Forward
> slashes in the paths also work as a workaround.
>
> A second, separate Windows problem: if the parent Neovim exports `NVIM_LISTEN_ADDRESS` (some
> configs do, to get a predictable pipe), the child inherits it and Neovim aborts at startup with
> `Failed $NVIM_LISTEN_ADDRESS: address already in use` (exit 1, no result file). Setting
> `NVIM_LISTEN_ADDRESS = ""` in the spec's `env` avoids that. Not neotest-plenary's fault, but it is
> an easy thing to harden against in `build_spec`.

If a PR is wanted: change only the `-c "lua _run_tests(..."` element; add the `env` entry only if the
maintainers agree.

### Local workaround (in this config)

`lua/config/neotest/init/windows_fixes.lua`, `fix_plenary_adapter()`: wraps `build_spec`, turns `\`
into `/` in the `_run_tests(` argument, sets `NVIM_LISTEN_ADDRESS = ""` for the child. Remove it when
upstream is fixed.

---

## 2. neotest: unauthenticated `localhost` RPC listener, no option to disable it

### The one-sentence version

When the client starts, `neotest.lib.subprocess.init()` runs `serverstart("localhost:0")`: a TCP RPC
listener on a random loopback port, without authentication, for the whole session, and there is no
setup option to turn it off.

### Facts

- `lua/neotest/lib/subprocess.lua:36` opens it; `lua/neotest/client/init.lua:379` calls
  `subprocess.init()` whenever `subprocess.enabled()` is false. It opens on the first visit to a
  test buffer (client start), not only when tests run.
- Only the parse helper (`nvim --embed --headless -n -u NONE`) uses it: it connects back with
  `sockconnect("tcp", parent_address, {rpc = true})` (`subprocess.lua:185`). `serverlist`,
  `serverstop`, `rpcrequest` and `sockconnect` appear nowhere else in neotest, neotest-plenary,
  nvim-nio or plenary. In sessions where the helper fails to start, the listener stays open and unused.
- Neovim RPC has no authentication. In the review a second `nvim` connected to the port without
  credentials and ran Lua in the session (`nvim_exec_lua`).
- Cost: helper plus listener were +75 / +149 ms of blocking time in our measurements (1 test file /
  100 spec files, median of 5), without a visible gain for single-process use.
- Every other `subprocess.*` call is guarded by `subprocess.enabled()`, so skipping `init()` makes
  neotest parse in the main process (the `enabled() == false` paths). Replacing
  `require("neotest.lib.subprocess").init` with a no-op before `setup()` works, but depends on
  internals. That is this config's workaround (`disable_parse_subprocess()` in `windows_fixes.lua`).

### Severity (decide before filing publicly)

Low: it needs local access to the machine, loopback only, and the port is random. It is still code
execution as the user for any local process (another user on a shared machine, a sandboxed or
malicious local program). Options: file it publicly as a plain issue (current draft: factual, no
exploit walk-through) or report it privately first (GitHub Security Advisory on the repo). The user
decides.

### Draft: new issue

**Title:** `subprocess.init` opens an unauthenticated `localhost` RPC listener and there is no option to turn it off

> ### What happens
>
> When the client starts, `neotest.lib.subprocess.init()` (`lua/neotest/lib/subprocess.lua:36`,
> called from `Client:_start`, `lua/neotest/client/init.lua:379`) runs `serverstart("localhost:0")`.
> That opens a TCP RPC listener on a random port on the loopback interface. Neovim's RPC has no
> authentication: any local process (any user on a shared machine, any sandboxed or malicious local
> program) that finds the port can connect and run `nvim_exec_lua` in the user's editor, i.e. execute
> arbitrary code as the user.
>
> I confirmed it: a second `nvim` connected with `nvim --server localhost:<port> --remote-expr ...`
> and ran Lua in the session without credentials. The listener opens on the first visit to a test
> buffer (client start), not only when tests run.
>
> ### Why it is there
>
> Only the parse helper uses it: the helper (`nvim --embed --headless -n -u NONE`) connects back with
> `sockconnect("tcp", parent_address, {rpc = true})` (`subprocess.lua:185`) to report results. In
> sessions where the helper never starts (for example because it fails to start), the listener stays
> open and unused for the whole session. `serverlist`, `serverstop`, `rpcrequest` and `sockconnect`
> are used nowhere else in neotest or the adapters I checked.
>
> ### Why this matters
>
> - Security: an open, unauthenticated RPC port that is not documented anywhere in the README.
> - Cost: starting the helper plus the listener cost about 75 to 150 ms of blocking time in my
>   measurements (1 test file / 100 spec files, startup of the first test run; median of 5), and
>   gives no visible gain for the single-process case.
> - There is no supported way to avoid it. I currently replace
>   `require("neotest.lib.subprocess").init` with a no-op before `setup()`, which works because every
>   other `subprocess.*` call is guarded by `subprocess.enabled()`, but that depends on internals.
>
> ### Proposal
>
> A setup option, for example `subprocess = { enabled = false }` (or `parse_in_subprocess = false`),
> that skips `subprocess.init()`; neotest then parses in the main process as the
> `enabled() == false` paths already do. Alternatively or additionally: use a pipe/Unix socket with
> an unguessable name instead of `localhost:0`, and `serverstop` the address once the helper has
> connected, so the listener does not outlive the handshake.
>
> I am happy to send a PR for the option if the approach is acceptable.
>
> ### Environment
>
> Neovim 0.12.2, Windows 11, neotest `27bf921`, neotest-plenary `3523adc`. (The listener code path is
> not platform specific.)

---

## Before filing

- Re-check the line numbers against upstream `master`.
- Re-check that the listener still opens on the then-current version: `:echo serverlist()` after
  opening a test file, **without** the local no-op from `windows_fixes.lua`.
- Search both repos once more for the issue titles above (`gh issue list --search`).
- The offer of a PR in issue 2 is a commitment in the user's name: drop the sentence if unwanted.
- Link this report's local workaround only if useful; do not paste the user's config paths.

## Status log

- 2026-10-03: investigated, workaround built into the config and verified (headless and real TUI),
  drafts written and checked against upstream. Not filed.
