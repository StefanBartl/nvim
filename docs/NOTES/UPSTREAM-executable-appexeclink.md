# Upstream candidate: `executable()` is false for App Execution Aliases

**Status:** ready to file. Not yet reported upstream — check for an existing
issue first (see [Before filing](#before-filing)).

**Found:** 2026-08-26, while profiling this config's startup. The symptom that
led here was mundane (`require("options")` costing 63ms); the cause was not.

---

## The one-sentence version

On Windows, Neovim refuses to start a program through `jobstart()` because
`executable()` says it is not executable — while `vim.system()` starts the very
same program successfully, in the same Neovim, in the same session.

That framing matters. This is not "Windows aliases are odd"; it is **two
process-spawning APIs of one editor disagreeing about the same binary.**

---

## Reproduction

Needs a Store-installed PowerShell 7 (`winget install Microsoft.PowerShell`,
or any app that ships an App Execution Alias). No config involved — `-u NONE`.

```lua
-- repro.lua
local uv = vim.uv or vim.loop
local alias = vim.fn.expand("$LOCALAPPDATA") .. [[\Microsoft\WindowsApps\pwsh.exe]]

print("executable('pwsh')      = " .. vim.fn.executable("pwsh"))
print("exepath('pwsh')         = [" .. vim.fn.exepath("pwsh") .. "]")
print("executable(<full path>) = " .. vim.fn.executable(alias))
local st, err = uv.fs_stat(alias)
print("uv.fs_stat(<full path>) = " .. (st and "ok" or tostring(err)))

local res = vim.system({ "pwsh", "-NoLogo", "-NoProfile", "-Command",
  "$PSVersionTable.PSVersion.ToString()" }, { text = true }):wait(20000)
print("vim.system -> code=" .. res.code .. "  stdout=" .. vim.trim(res.stdout or ""))

local jid = vim.fn.jobstart({ "pwsh", "-NoLogo", "-NoProfile", "-Command", "exit 0" })
print("jobstart   -> " .. tostring(jid))
```

```
nvim --headless -u NONE -l repro.lua
```

### Observed — nvim 0.12.2, Windows 11

```
executable('pwsh')      = 0
exepath('pwsh')         = []
executable(<full path>) = 0
uv.fs_stat(<full path>) = EACCES: permission denied: C:\Users\…\WindowsApps\pwsh.exe

vim.system -> code=0  stdout=7.6.5
jobstart   -> E475: Invalid value for argument cmd: 'pwsh' is not executable
```

### Expected

Either both spawn APIs accept `pwsh`, or both reject it. `executable()` should
agree with whichever is right.

---

## Why it happens

`%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe` is not a file. It is an **App
Execution Alias**: a zero-length reparse point tagged `IO_REPARSE_TAG_APPEXECLINK`
whose target lives under `C:\Program Files\WindowsApps\…`, a directory locked
down by ACL.

A normal process cannot `stat()` it — note that libuv reports **`EACCES`, not
`ENOENT`**: the entry is *there*, it just cannot be read. Neovim's
`executable()` goes through `os_can_exe()` → `is_executable()` → a stat, and a
failed stat is treated as "no such executable".

`CreateProcess`, on the other hand, resolves the alias through the loader,
which is why `vim.system()` — which spawns directly — works. `jobstart()`
differs only in that it validates with `executable()` first, and that check is
what rejects it.

So the distinction that is being lost is **"stat failed" vs "does not exist"**.

---

## Suggested fix

In `src/nvim/os/fs.c`, where an executability check resolves to a stat: treat
`EACCES` on Windows as "exists, not inspectable" rather than as absent. A
minimal version is to fall back to `_waccess(path, 0)`, or to accept a PATH
candidate whose extension is in `PATHEXT` when the stat fails with `EACCES`
specifically (not `ENOENT`).

The narrow-and-safe variant, if maintainers dislike a general `EACCES` rule:
special-case the reparse tag. `GetFileAttributesW` reports
`FILE_ATTRIBUTE_REPARSE_POINT` on these without needing read access, and
`FindFirstFileW` exposes the tag in `WIN32_FIND_DATA.dwReserved0`, so
`IO_REPARSE_TAG_APPEXECLINK` can be identified precisely.

Either way, the acceptance test is the repro above: `executable()` and
`jobstart()` must agree with `vim.system()`.

---

## Why it is worth reporting

Impact beyond the one binary:

- **`&shell` detection.** Configs pick PowerShell 7 over 5.1 with
  `executable("pwsh")`. On a Store install, that silently keeps 5.1 — which is
  not merely an older version: 5.1's `>` redirect writes **UTF-16LE**, 7 writes
  UTF-8. This config had exactly that, and it surfaced as two plugins writing
  wide-character files (see the `insights.nvim` UTF-16 fix, 2026-08-25).
- **`:checkhealth` provider detection**, which is `executable()` throughout —
  a Store-installed `python`, `node` or `deno` reports as missing.
- **Every plugin** that guards a feature behind `vim.fn.executable(tool)`.
- **`jobstart()` vs `vim.system()`** behaving differently is a portability trap
  for plugin authors who reasonably assume they are interchangeable.

The Microsoft Store is a normal way to install PowerShell 7, Python and Node on
Windows, so this is not an exotic setup.

---

## Before filing

- Search the tracker for `AppExecLink`, `WindowsApps`, `executable() Windows
  Store`, `App Execution Alias`. This is a well-known Windows quirk in general
  (Python's `shutil.which()` and Git for Windows hit versions of it), so an
  issue may already exist — **link to it rather than opening a duplicate.**
- If one exists but is framed as "Windows is like that", the
  `vim.system` vs `jobstart` inconsistency is a new and stronger argument and
  is worth adding as a comment.
- Confirm on a current nightly, not just 0.12.2.
- Ideally confirm with a second aliased program (Store Python is the easy one),
  so the report is not read as PowerShell-specific.

## For a PR

The change is small and localized, but the semantics are a maintainer call:
"unreadable file counts as executable" widens `executable()` in a way that has
to be deliberate. Open the issue first and ask which of the two variants above
is wanted before writing the patch.

---

## What this config does in the meantime

`lua/options.lua` detects pwsh by **running** it rather than looking for it —
`vim.system({ "pwsh", …, "$PSVersionTable.PSVersion.Major" })`, asking for the
version so a stray non-PowerShell `pwsh` cannot answer 0. The spawn is
scheduled rather than inline: `vim.system` completes asynchronously but
`CreateProcess` does not, and starting a Store-aliased pwsh costs ~150 ms of
it.
