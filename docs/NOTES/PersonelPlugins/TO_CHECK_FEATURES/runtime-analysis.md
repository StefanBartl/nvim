# Testing runtime-analysis.nvim

How to manually test every implemented feature of `runtime-analysis.nvim`
and its `runtime-analysis.telemetry` module. One-time setup, then one
section per feature: prerequisites, steps, what to expect.

Repo: `$REPOS_DIR\runtime-analysis.nvim`. Spec: `plugins/personal/init.lua`
(`lazy = false`, depends on `lib.nvim`).

## Setup

Already wired into this config — nothing extra to install. To confirm it
loaded:

```vim
:lua print(require("runtime-analysis") ~= nil)
```
should print `true`. If you changed `opts.telemetry` in
`lua/config/telemetry.lua` or the plugin spec, `:Lazy reload runtime-analysis.nvim`
(or just restart Neovim) to pick it up.

---

## 1. The HTTP request runner (`:RARequest` / `:RASend`)

**Steps**

1. `:RARequest` — opens a new buffer, cursor at the end of `GET https://`.
2. Type a real URL, e.g. `GET https://httpbin.org/get`.
3. `:RASend`.

**Expect**: a vertical split opens beside the request buffer showing status
code, headers and body. Sending again reuses the same split (no new window
each time). Try a POST too:

```http
POST https://httpbin.org/post
Content-Type: application/json

{"hello": "world"}
```

`:RASend` from inside that buffer should show the echoed JSON body in the
response.

**Also check**: `:RASend` on a buffer with a malformed first line (e.g. just
`hello`) should `vim.notify` a parse error, not throw.

---

## 2. documentation.nvim integration (`M.open_request`, `gs`)

**Prerequisites**: `documentation.nvim` installed (it is) and a generated
map for some repo with at least one recognized route. documentation.nvim
only recognizes JS/TS/Express-shaped routes today (`app.get("/path", fn)`),
so this needs a small scratch JS file — there is no such code in any of
your Lua repos.

**Steps**

1. Create a scratch dir with a file like:
   ```js
   const app = require("express")();
   app.get("/users/:id", function getUser(req, res) {});
   ```
2. `cd` Neovim into that dir, `:DocMap`, then `:DocBrowse`.
3. Press `7` (or cycle with `1`..`7`) to switch to **Endpoints** mode.
4. Move to the `/users/:id` row, press `gs`.

**Expect**: a new `:RARequest`-style buffer opens, pre-filled with
`GET /users/:id` (method + path, no host). Complete the URL yourself and
`:RASend` it.

**Also check the soft-dependency path**: temporarily rename
`$REPOS_DIR\runtime-analysis.nvim` (or otherwise make `require("runtime-analysis")`
fail) and press `gs` again from Endpoints mode — expect a clear
`notify.warn` ("runtime-analysis.nvim is not installed…"), not an error.

---

## 3. Telemetry — manual instrumentation (`wrap`, `wrap_loaded`, `wrap_fn`)

**Steps**

```lua
local telemetry = require("runtime-analysis.telemetry")
local t = telemetry.new({ namespace = "manual-test", persist = false })

local mod = { greet = function(name) return "hi " .. name end }
t.wrap(mod)          -- registers, installs nothing yet
t.start()            -- installs the dispatcher

mod.greet("world")
mod.greet("again")

vim.print(t.report())
t.stop()
t.unwrap()
```

**Expect**: `report().entries` shows `greet` with `calls = 2`. After
`t.stop()`, `mod.greet` is restored to the exact original function
(`t.is_running()` is `false`).

**Also check `wrap_loaded`**: point it at a plugin's real root module, e.g.
`t.wrap_loaded("markdown")` (if markdown.nvim is loaded), and confirm
`t.wrapped_keys()` lists submodule-qualified names like
`bindings.actions.next_heading`, not just the façade's own functions.

---

## 4. Telemetry — `auto()`

**Steps**

```lua
local telemetry = require("runtime-analysis.telemetry")
local inst = telemetry.auto({
  namespace = "auto-test",
  main = "markdown",     -- any already-loaded plugin's root module
  deep = true,
  profile_args = true,
  persist = false,
})
print(inst ~= nil)       -- true if markdown.nvim is loaded
```

**Expect**: `nil` if `main` is not loaded yet (try a bogus module name);
otherwise an already-started instance (`inst.is_running() == true`).

---

## 5. Telemetry — the lazy.nvim adapter (auto-instrument on load)

This is what's actually wired into your config via
`plugins/personal/init.lua`'s `runtime-analysis.nvim` spec entry
(`opts.telemetry`, built by `lua/config/telemetry.lua`). It runs on every
real Neovim startup already — the steps below just make that visible.

**Steps**

1. Start Neovim normally (a fresh session).
2. `:RATelemetry` (bare — report across every live instance).

**Expect**: one entry per personal plugin that has actually loaded so far
(namespace = the plugin's lazy.nvim short name), plus `lib.nvim` — all
already `running`, with real call counts if you've used any keymaps.
Plugins that haven't loaded yet (lazy on `cmd`/`ft`/`event`) simply have no
entry yet; open a `.md` buffer (loads `markdown.nvim`) and re-run
`:RATelemetry` — a new `markdown.nvim` entry should appear.

**Also check the catch-up path specifically**: `lib.nvim` is a
`lazy = false` *dependency* of `runtime-analysis.nvim`, so its own
`LazyLoad` fires before `runtime-analysis.nvim`'s `config()` can register
the autocmd — `:RATelemetry lib.nvim` should still show a running instance
with real calls (proof the catch-up scan, not just the ongoing event,
caught it).

---

## 6. `:RATelemetry` subcommands

**Steps** (namespace = any plugin shown by a bare `:RATelemetry`, e.g. `markdown.nvim`)

```vim
:RATelemetry markdown.nvim           " report for just that namespace
:RATelemetry stop markdown.nvim      " pause counting
:RATelemetry start markdown.nvim     " resume
:RATelemetry reset markdown.nvim     " drop collected data (memory + disk)
:RATelemetry coverage                " which wrapped functions were never called
:RATelemetry disabled                " list currently-disabled namespaces
:RATelemetry export /tmp/report.json
:RATelemetry export /tmp/report.md   " same data, Markdown instead
```

**Expect**: `stop` freezes the count (use the plugin, re-check — no
change); `start` resumes it; `reset` zeroes it (both in the float and on
disk — `:RATelemetry markdown.nvim` right after shows `0 calls`); `export`
writes a real file at the given path, format inferred from the extension.

**Tab-completion check**: `:RATelemetry stop <Tab>` should offer namespaces
only, never `start`/`stop`/etc. again.

---

## 7. Persistent disable/enable

**Steps**

```vim
:RATelemetry disable markdown.nvim
```

1. Restart Neovim entirely.
2. `:RATelemetry` (bare).

**Expect**: `markdown.nvim` is either absent or shown as disabled — it did
**not** silently resume counting after the restart, unlike a plain `stop`.
`:RATelemetry enable markdown.nvim` then a restart should show it counting
again.

---

## 8. Browser report (Markdown + `report_style`)

**Prerequisites**: [`mdview.nvim`](../mdview/mdview.md) installed (it is)
for the `"mdview"`/`"auto"` styles to actually open a browser tab; without
it they degrade to the `"kit"` float.

**Steps**

```vim
:lua require("runtime-analysis.telemetry").setup({ report_style = "auto" })
:RATelemetry open markdown.nvim
```

**Expect**: a browser tab opens showing a live-updating Markdown report
(GFM table, not the terminal box-drawing `:RATelemetry` itself shows).
Trigger a few more `markdown.nvim` keymaps and the tab should update
without re-running `:RATelemetry open` — it's watching the file mdview's
relay serves.

**Also check** `report_style = "file"` (write-only, no window — confirm the
file appears at the path `:RATelemetry open` prints) and `"kit"` (the
in-editor float, no browser at all).

---

## 9. Report metadata (`Options.info`)

**Steps**

```lua
local git = require("lib.nvim.git")
local t = require("runtime-analysis.telemetry").new({
  namespace = "info-test",
  persist = false,
  info = git.info("E:/repos/runtime-analysis.nvim"),
})
print(vim.inspect(t.report().info))
```

**Expect**: a table with `branch`, `version` (tag or short hash) and
`commit` for that repo. `:RATelemetry info-test` (via `t.lines()`/the
float) should render an `info` line near the top with those same values.

---

## 10. Reading telemetry without a live instance (`telemetry.load`)

**Steps** (after step 6's `export`, or any namespace with `persist = true` on disk)

```lua
local data = require("runtime-analysis.telemetry").load("markdown.nvim")
print(vim.inspect(data and data.functions or "nil (nothing ever persisted)"))
```

**Expect**: real function/call data if `markdown.nvim` has ever flushed to
disk this machine; `nil` for a namespace that genuinely never has (try a
made-up name) — never a well-formed-but-empty table for the "never
existed" case.

---

## 11. lib.nvim's own aggregate (`lib.strategies.telemetry_wrap`)

Covered by step 5's `:RATelemetry lib.nvim` already, but to see the
mechanism directly:

```lua
require("lib.strategies.telemetry_wrap").teardown()  -- undo the config-driven instance first
local inst = require("lib.strategies.telemetry_wrap").setup({ profile_args = false })
require("lib").trim("  x  ")
print(inst.report().entries[1].key, inst.report().entries[1].calls)
require("lib.strategies.telemetry_wrap").teardown()
```

**Expect**: prints `trim   1`. After `teardown()`, `require("lib").trim`
still works exactly as before (identity-restored) — this is lib.nvim's
generic aggregate, not something lazy_spec-specific, so any `lib.*` call
elsewhere in your session should be unaffected.

---

## 12. `###`-separated multi-request buffers, and real `.http`/`.rest` files

**Steps**

1. `:RARequest`, then replace the buffer contents with:
   ```http
   GET https://httpbin.org/get?x=1

   ###

   POST https://httpbin.org/post
   Content-Type: application/json

   {"n": 1}
   ```
2. Put the cursor inside the first block, `:RASend`.
3. Move the cursor into the second block (anywhere after the `###` line),
   `:RASend` again.
4. Save the buffer as a real file, e.g. `E:/repos/scratch/test.rest`
   (`.rest`, not `.http`, to exercise this plugin's own `ftdetect`), close
   it, reopen with `:e`.

**Expect**: step 2 hits `/get`, step 3 hits `/post` with the JSON echoed
back — never the wrong block, never the whole buffer. Step 4's reopened
`.rest` file has `filetype=http` (`:set filetype?`) and `:RASend` from
inside it behaves identically to the scratch-buffer case — no special
setup needed for a real, committed file.

---

## 13. Request history (`:RA history`, `:RA history clear`)

**Steps**

1. Send a couple of real requests (§1 or §12).
2. `:RA history`.

**Expect**: a `vim.ui.select` picker, newest first, each row showing
timestamp/status/method/url — **no headers, no body** even for a request
that had them (open the picker and confirm there is nowhere to see the
`Content-Type`/body you sent). Picking one opens a new request buffer
pre-filled `METHOD url` only. `:RA history clear` then `:RA history`
again — expect "no request history for this project yet".

**Also check it's per-project**: send a request from a different `cwd`
(a second real repo), `:RA history` there shows only *that* project's
sends, not the first one's.

---

## 14. `:RA yank` and `:RA cancel`

**Steps**

```vim
:RASend
:RA yank
```

then paste (`p`) somewhere.

**Expect**: only the response **body** is pasted — no status line, no
headers. `:RA yank` before any send at all should `vim.notify` a warning
("no response yet"), not error.

**Cancel** — needs a slow endpoint:

```http
GET https://httpbin.org/delay/5
```

`:RASend`, then immediately `:RA cancel`.

**Expect**: the response split shows `✗ cancelled` right away, well
before 5 seconds pass. `:RA cancel` with nothing in flight →
`vim.notify` "no request in flight", not an error.

---

## 15. Variables and environments (`:RA env`)

**Steps**

1. In a real project root, create `http-client.env.json`:
   ```json
   { "dev": { "baseUrl": "https://httpbin.org" } }
   ```
2. `:RA env dev`.
3. New request buffer:
   ```http
   GET {{baseUrl}}/get
   ```
4. `:RASend`.

**Expect**: the request actually goes to `https://httpbin.org/get` —
`{{baseUrl}}` resolved. Check the "sending ..." placeholder and `:RA
history` both still show the **literal** `{{baseUrl}}/get`, never the
resolved URL. Try `:RASend` with **no** environment selected and a
`{{var}}` in the buffer — expect a clear error naming the missing
environment, not a request sent with `{{baseUrl}}` as a literal
hostname.

**Also check the private-file warning**: create
`http-client.private.env.json` next to it (a real secret file) without
adding it to `.gitignore`, send a request — expect a one-time
`vim.notify` `WARN` about it not being gitignored.

---

## 16. curl import/export (`:RA import` / `:RA export`)

**Steps**

1. Copy a real "copy as cURL" snippet from your browser's devtools (or
   type one), e.g.:
   ```
   curl 'https://httpbin.org/get' -H 'X-Test: 1'
   ```
   to the clipboard.
2. `:RA import`.
3. `:RASend` the resulting buffer.
4. Put the cursor back in that block, `:RA export`, paste (`p`).

**Expect**: step 2 opens a request buffer with the real method/url/
headers from the pasted command. Step 4's pasted text is a real,
runnable `curl` command line again (multi-line, backslash-continued) —
if you resolved any `{{var}}` in the buffer first, confirm the exported
command still shows the literal `{{token}}`, never the resolved value.

---

## 17. `Auth:` shorthand

**Steps**

```http
GET https://httpbin.org/bearer
Auth: Bearer some-token
```

`:RASend`, check the request that actually went out (httpbin's
`/bearer` endpoint echoes what it received).

**Expect**: the real `Authorization: Bearer some-token` header was sent.
Try `Auth: Basic alice:s3cret` too (`/basic-auth/alice/s3cret` endpoint)
— expect it to be base64-encoded automatically into a real `Authorization:
Basic ...` header (RFC 7617), not sent as literal `alice:s3cret`.

---

## 18. Response assertions (`# @expect status N`)

**Steps**

```http
# @expect status 200
GET https://httpbin.org/status/200
```

`:RASend`. Then change the URL to `/status/404`, `:RASend` again.

**Expect**: the first send is a plain `vim.notify` ("✓ expect status
200"), quickfix list untouched. The second populates the quickfix list
with **one entry** naming both the expected and actual status, pointing
at the `@expect` line itself — but the quickfix list is **not**
auto-opened (`:copen` yourself to see it).

---

## 19. GraphQL and multipart request bodies (`docs/ROADMAP.md` §2.6)

**GraphQL steps**

```http
POST https://httpbin.org/anything
X-Request-Type: GraphQL
Content-Type: application/json

query GetThing($id: ID!) {
  thing(id: $id) { name }
}

{"id": "42"}
```

`:RASend`.

**Expect**: httpbin's `/anything` echoes back the request it received —
the response body should show a real JSON payload shaped
`{"query": "query GetThing...", "variables": {"id": "42"}}`, **not**
the literal `X-Request-Type` header (it must not appear in the echoed
request headers at all — it was consumed, never forwarded).

**Multipart steps** — needs a real local file to upload:

1. Create a small real file, e.g. `E:/repos/scratch/upload.txt`
   containing some text.
2. New request buffer:
   ```http
   POST https://httpbin.org/post
   Content-Type: multipart/form-data; boundary=----TestBoundary123

   ------TestBoundary123
   Content-Disposition: form-data; name="title"

   my title
   ------TestBoundary123
   Content-Disposition: form-data; name="file"; filename="upload.txt"

   < ./upload.txt
   ------TestBoundary123--
   ```
3. Save this buffer next to `upload.txt` (so the relative path resolves —
   or use an absolute path in the `< ` line), `:RASend`.

**Expect**: httpbin's `/post` response echoes `"form": {"title": "my
title"}` and `"files": {"file": "<the real content of upload.txt>"}` —
the real file bytes were sent, not the literal `< ./upload.txt` text.

**Also check `:RA export`** on the multipart block — the exported `curl`
command should use `-F "file=@./upload.txt;filename=upload.txt"` (curl's
own file-reference syntax), never a `--data-raw` with raw file bytes
crammed into it.

---

## 20. Call trees — "who called this" (`docs/ROADMAP.md` §3.1)

**Steps**

```lua
local telemetry = require("runtime-analysis.telemetry")
local mod = { f = function() end }
local t = telemetry.new({ namespace = "calltree-test", persist = false })
t.wrap(mod, "m")
t.start({ call_tree = true })

local function site_a() mod.f() end
local function site_b() mod.f() end
site_a()
site_a()
site_b()

vim.print(t.report().entries[1].callers)
t.stop()
```

**Expect**: a list of `{fingerprint, count, share}` — the fingerprints
are real `path/to/file.lua:LINE` call-site locations (two distinct
ones, `site_a`'s line appearing with `count = 2`, `site_b`'s with
`count = 1`), **not** resolved function *names* — this feature
deliberately only ever captures source+line.

---

## 21. Sampling (`docs/ROADMAP.md` §3.2)

**Steps**

```lua
local telemetry = require("runtime-analysis.telemetry")
local mod = { f = function() end }
local t = telemetry.new({ namespace = "sample-test", persist = false })
t.wrap(mod, "m", { sample = 3 })
t.start({ profile_args = true })
for i = 1, 9 do mod.f(i) end
local e = t.report().entries[1]
print("calls", e.calls, "fingerprints seen", e.distinct or #e.args)
t.stop()
```

**Expect**: `calls` is the real, exact count (9) — sampling never
touches the count itself. Only every 3rd call actually got its argument
fingerprinted (roughly 3 of the 9 values), which you can see because the
distinct-argument total is smaller than 9.

---

## 22. Startup attribution (`docs/ROADMAP.md` §3.3)

**This is already wired into your real config** (`init` hook in
`plugins/personal/init.lua`'s `runtime-analysis.nvim` spec) — the steps
below just make it visible.

**Steps**

1. Restart Neovim (a fresh session, so startup timing is real).
2. Once it's up: `:RATelemetry startup`.

**Expect**: a waterfall — per-module self/total time, grouped by module
root (one row per plugin's own Lua namespace), sorted worst first. Real
numbers in the low milliseconds for most plugins, not all zero. `:RATelemetry
startup 10` shows only the top 10.

---

## 23. Error fingerprinting (`docs/ROADMAP.md` §3.4)

**Steps**

```lua
local telemetry = require("runtime-analysis.telemetry")
local mod = { risky = function(x) if x == "bad" then error("boom: " .. x) end end }
local t = telemetry.new({ namespace = "errfp-test", persist = false })
t.wrap(mod, "m")
t.start({ errors = true })
pcall(mod.risky, "ok")
pcall(mod.risky, "bad")
pcall(mod.risky, "bad")
vim.print(t.report().entries[1].error_fp)
t.stop()
```

**Expect**: `errors = 2` on the entry, and `error_fp` shows one bounded
fingerprint bucket for the `"boom: bad"`-shaped error, with `count = 2`
— real error text, fingerprinted the same bounded way argument
profiling is.

---

## 24. Comparing across time windows (`:RATelemetry compare`)

**Prerequisites**: a namespace with `persist = true` and at least a
couple of days of real data (any of your own plugins with telemetry on
for a while works — check `:RATelemetry` for one with `sessions > 1`).

**Steps**

```vim
:RATelemetry compare markdown.nvim 7
```

**Expect**: a report naming newly-hot functions, gone-cold functions,
and functions whose call pattern changed between "this window" and "the
one before it" — real function names from that plugin, not placeholder
text. Try a namespace with almost no history — expect an honest "not
enough data" style message, not a crash or a report full of zeros
pretending to be meaningful.

---

## 25. Startup cost vs. use (`:RATelemetry cost`)

**Prerequisites**: needs both startup attribution (§22) and regular
call-counting telemetry to have run in the same session — true for your
real config already.

**Steps**

```vim
:RATelemetry cost
```

**Expect**: one row per namespace, joining §22's own per-module-root
startup cost against that namespace's real call count — sorted worst
(expensive to load, rarely called) first. Every row should be a real
namespace you recognize (a plugin actually in `plugins/personal/init.lua`),
never a guessed match between a startup module root and an unrelated
namespace name.

---

## 26. The HTML dashboard (`report_style = "html"`, `docs/ROADMAP.md` §4.4)

**Steps**

```vim
:lua require("runtime-analysis.telemetry").setup({ report_style = "html" })
:RATelemetry open markdown.nvim
```

(or any namespace with real data — a bare `:RATelemetry open` with no
namespace works too, for the combined dashboard).

**Expect**: a real browser tab/window opens automatically, showing a
table — one row per function, Calls/Errors/Mean/Top argument/Top caller
columns. Click a column header — the table re-sorts (click again,
re-sorts the other direction). Type into the filter box at the top — the
table narrows to matching namespace/function substrings live, no `<CR>`
needed. Click a row — it expands below showing the full argument/error/
caller fingerprint breakdown (the same `└`/`✗`/`←` symbols `:RATelemetry`'s
own terminal report uses) and, if this function has one, a highlighted
memoization hint. The page should also look visually consistent with
`:DocMap open`'s own page (same color palette, same font, same "toolbar
search box" style) without actually reusing that page's code.

**Also check**: `:RATelemetry open` on a namespace with **zero** calls
recorded yet — expect a clean, real page (not an error) with an empty
table and an honest "no rows match" message if you then type into the
filter box.

---

## 27. Wrapper provenance (`:RA provenance <path>`)

**Steps**

```vim
:RA provenance vim.notify
```

then, from inside a real telemetry session (any of your plugins), find
one of its own wrapped functions, e.g.:

```vim
:RA provenance markdown.formatting.something.a_real_function_name
```

(pick a real dotted path from `:RATelemetry markdown.nvim`'s own report
— any `key` shown there, prefixed with the module).

**Expect**: `vim.notify` is reported **best-effort** — a real source
file:line, explicitly labeled as an inference (something else likely
wraps `vim.notify` too, e.g. `noice.nvim` if you have it). The real
wrapped function from your own telemetry is reported **exact** — "wrapped
by runtime-analysis.telemetry: markdown.nvim" (or whichever namespace),
not a guess.

---

## 28. Live module inspection (`:RA inspect <module>`)

**Steps**

```vim
:RA inspect runtime-analysis.telemetry
```

Then try `<Tab>` after `:RA inspect ` — should complete against real,
currently-loaded module names.

**Expect**: a kit float (or `vim.notify` fallback if `lib.nvim.ui.kit`
is somehow unavailable) listing real functions with real upvalue counts
and source locations, nested tables with their own shape, and — pick a
module you know has a metatable with `__index` pointing at a table
(or construct one in a scratch `:lua` block) — a `[shadows __index]`
tag on any key that overrides an inherited one. `:RA inspect
this-module-was-never-required` → a clear "not loaded in this session"
error, not a crash.

---

## 29. Diff loaded-vs-declared (`runtime-analysis.loaded`, `docs/ROADMAP.md` §5.3)

This module has no `:RA` command of its own — it is consumed by
`documentation.nvim`'s own `:DocBrowse loaded` mode. See
[`documentation.md`](documentation.md)'s own section on it for the full
manual test; the one thing worth confirming from *this* side:

```lua
print(require("runtime-analysis.loaded").is_loaded("runtime-analysis.telemetry"))
print(vim.inspect(require("runtime-analysis.loaded").functions("runtime-analysis.telemetry")))
```

**Expect**: `true`, and a real table of function names (`new`, `auto`,
`instances`, ...) — `package.loaded` reflects *this* running session, so
this only ever answers meaningfully for a module actually loaded right
now, in the Neovim you're typing this into.

---

## 30. Keymap/command usage tracking (`:RA usage`)

**Steps**

```vim
:RA usage start
```

1. Press a few of your own real keymaps (anything bound via
   `vim.keymap.set` with a function callback — most of your personal
   plugins' own bindings qualify).
2. Type a couple of real commands (`:w`, `:DocMap`, anything).
3. `:RA usage`.

**Expect**: real counts next to the keymaps you actually pressed and the
commands you actually typed — nothing you didn't press shows a nonzero
count. Abort a command with `<Esc>` before it commits (e.g. type `:foo`
then `<Esc>`) — confirm it does **not** get counted. `:RA usage stop`,
press more keys — `:RA usage` again shows the same counts as before
(collection genuinely stopped, not just paused-but-still-counting).
