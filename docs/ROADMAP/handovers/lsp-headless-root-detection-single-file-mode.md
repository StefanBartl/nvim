# `lsp_ls` attaches in "single-file mode" under a plain `nvim --headless -c "luafile ..."` invocation

> Found 2026-09-13 while trying to run the `LLS-44`-style live-diagnostics
> gegenprobe (`wkdbook-Neovim/Referenz_Notes/04_lps_diagnostics-und-listen/
> Headless-Diagnose-Gegenprobe.md`) against `rules.nvim`, to verify two
> `rules.nvim` dogfooding findings (`NEW-38`/`NEW-42`, see
> `wkdbook-myplugins/rules.nvim/handovers/2026-09-13-self-review-fixes.md`).
> Not fixed — this is a problem report, not a fix.

## The problem, in one sentence

Under a plain headless invocation (`nvim --headless -c "luafile <script>" -c
"qa!"`, no interactive session, no real buffer-open event sequence), the
`lua_ls` client attaches successfully (`LspAttach` fires, `#vim.lsp.
get_clients() == 1`) but resolves its workspace root incorrectly — it ends
up in **single-file mode**, meaning `.luarc.json` at the repo root is never
read and cross-file type resolution doesn't happen, even though
`vim.fn.getcwd()` correctly reports the target repo.

## Why this matters

It silently breaks the established `Headless-Diagnose-Gegenprobe` technique
(`LLS-44`'s own recommended method: verify a suspicious LuaLS finding
against the real running server, not just a static scan tool) for **any**
repo, whenever the verification script is driven by a plain `luafile`
invocation rather than a real interactive `:edit` + the usual `FileType`/
`BufEnter` autocmd sequence. Two `rules.nvim` dogfooding findings
(`NEW-38`: does `diagnostics.globals = ["vim"]` actually degrade `vim` to
`any`, given `workspace.library` is unset; `NEW-42`: does `duplicate-
set-field` actually fire for a runtime `vim.fn.readfile = function...`
reassignment) are stuck open because of this — the gegenprobe script ran,
attached, and returned `0` diagnostics in every configuration tried, but
that result is meaningless if the server never read `.luarc.json` in the
first place.

## Reproduction

```bash
cd B:/repos/rules.nvim   # any repo with its own .luarc.json works
VERIFY_PATH="TESTS/checks_spec.lua" nvim --headless \
  -c "luafile <verify_diag.lua, see below>" -c "qa!"
```

`verify_diag.lua` — the exact script used, copied from the ecosystem's own
documented technique
(`wkdbook-Neovim/Referenz_Notes/04_lps_diagnostics-und-listen/
Headless-Diagnose-Gegenprobe.md`), with one added diagnostic line at the
end:

```lua
vim.lsp.handlers["window/showMessageRequest"] = function(_, result, _)
  if result and result.actions then
    for _, action in ipairs(result.actions) do
      if action.title:find("Don't", 1, true) or action.title:find("Disable", 1, true) then
        return action
      end
    end
    return result.actions[#result.actions]
  end
end

local path = vim.fn.expand(_G.VERIFY_PATH)
vim.cmd("edit " .. vim.fn.fnameescape(path))
local bufnr = vim.api.nvim_get_current_buf()

local attached = false
vim.api.nvim_create_autocmd("LspAttach", {
  buffer = bufnr,
  once = true,
  callback = function() attached = true end,
})

vim.wait(1500)
pcall(vim.cmd, "LspStart")
if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
  pcall(vim.cmd, "LspStart lua_ls")
end

local waited = 0
while not attached and waited < 20000 do
  vim.wait(200)
  waited = waited + 200
  if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then attached = true end
end
print("attached: " .. tostring(attached) .. ", clients: " .. #vim.lsp.get_clients({ bufnr = bufnr }))
for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
  print("  client: " .. c.name .. ", root: " .. tostring(c.config.root_dir))
end

vim.wait(4000)
local diags = vim.diagnostic.get(bufnr)
print("diagnostic count: " .. #diags)
```

### Actual output

```
cwd: B:\repos\rules.nvim
[LSP.Start] No LSP configured for filetype ''
[LSP.Start] LSP 'lua_ls' starting...
attached: true after 200ms, clients: 1
  client: lua_ls
[LSP.Start] ✓ LSP 'lua_ls' attached successfully
LSP[lua_ls][Warning] Failed to modify settings:
* The current mode is single-file mode, server cannot create `.luarc.json` without workspace.
* The language client does not support modifying settings from the server side.

Please modify following settings manually:
* `Lua.workspace.checkThirdParty`: set to `"Disable"` ;

diagnostic count: 0
root: function: 0x020fdc8471e0
```

### What was ruled out

- **Not a scratch-file root-detection quirk.** Tried both a brand-new,
  untracked scratch file directly in the repo root (`__verify_new38.lua`)
  and an existing, git-tracked file three directories deep
  (`TESTS/checks_spec.lua`) — identical "single-file mode" warning both
  times.
- **Not a wrong process `cwd`.** `vim.fn.getcwd()` printed the correct
  path (`B:\repos\rules.nvim`) in every run.
- **The client does attach** — this isn't a "no LSP configured" failure,
  `#vim.lsp.get_clients()` is `1` and `LspAttach` genuinely fires within
  ~200ms.

### The one concrete lead

`c.config.root_dir` printed as `function: 0x...` — a Lua **function**, not
a resolved path string. Neovim 0.11+'s native `vim.lsp.config` accepts
`root_dir` as either a string or a resolver function
(`fun(bufnr, on_dir)`); whatever this config's `lsp.nvim`-based wrapper
passes for `lua_ls` appears to be the *unevaluated resolver function*
still sitting in `client.config.root_dir` at the point this script reads
it, rather than an already-resolved directory. Two live hypotheses, not
yet distinguished:

1. The resolver function itself works fine interactively but depends on
   something this headless invocation doesn't provide before `:LspStart`
   runs (a `FileType` autocmd having already fired, a plugin's own
   `VimEnter`/lazy-load sequence, cursor/window state the resolver reads).
2. `client.config.root_dir` legitimately *always* holds the resolver
   function rather than a resolved string in this Neovim/plugin version
   (i.e. printing it this way was never going to show a path), and the
   real root-resolution failure is happening *inside* that function when
   it's actually invoked — which this script never observed directly.

Neither has been tested. The natural next probe: call
`c.config.root_dir(bufnr, function(dir) print("resolved: " .. tostring(dir)) end)`
by hand in the same script, right after attach, to see what the resolver
actually returns when invoked under these conditions — this would
distinguish hypothesis 1 (prints a wrong/nil dir) from hypothesis 2
(prints the correct dir, meaning the *display* was misleading and the
real bug is elsewhere in how `lua_ls` itself decided "single-file mode"
despite a correctly-resolved root).

## What's needed to actually close this

- Find the `lsp.nvim` (or wherever `lua_ls`'s `root_dir` is configured in
  this setup) source for the `[LSP.Start]`-prefixed wrapper visible in the
  reproduction output above, and read what it passes as `root_dir` for
  `lua_ls`.
- Run the resolver-invocation probe described above to tell the two
  hypotheses apart.
- Once the actual root cause is known, decide whether the fix belongs in
  `lsp.nvim` itself (if it's a plugin, per this directory's own filing
  rule such a fix's *handover* would move to that plugin's own
  `wkdbook-myplugins/<plugin>/NOTES/`) or in this config's own wiring of
  it.
- Re-run the `NEW-38`/`NEW-42` gegenprobe from
  `wkdbook-myplugins/rules.nvim/handovers/2026-09-13-self-review-fixes.md`
  once headless root-detection is confirmed working, and close those two
  findings out either way (fix `rules.nvim`'s `.luarc.json`/tests, or
  confirm no change needed).
