# Testing open.nvim

How to manually test open.nvim's real feature surface. Telemetry
(Workstation dataset, 9 sessions) shows real entry-point signal, thin but
genuine: `context.resolve` 8 calls (the two-stage target/scope resolution
that backs every `:Open` invocation — the single most-exercised real
feature), `registry.dispatch` 4 and `registry.get` 4 (a handler actually
ran, not just resolved), `context.default_target` 2, `context.gather` 2,
`context.with_cache` 2, `integrations.menu.items` 2 and
`integrations.menu.submenu` 2 (confirms this config's own
`lua/config/menu/mappings.lua` genuinely wires `open.integrations.menu`
into the shared `<RightMouse>` dispatcher — not just declared, actually
firing), `registry.list_keys` 2, `platform.get` 1, `util.run_detached` 1.
`config.is_debug` (22) and `config.get` (12) are support calls other
functions make on every invocation, not their own feature — not used for
ordering here. This shapes the checklist: bare `:Open` resolution leads,
the context menu gets its own section (confirmed live in this config,
unlike a merely-documented integration), the viewer commands get real
depth since they're the largest single feature by doc surface even without
their own telemetry line.

Repo: `E:\repos\open.nvim`. Spec: `lua/plugins/personal/init.lua`
(`cmd = { "Open", "UrlView", "MDLinksView" }` — all three names registered
because `setup()` itself registers the viewer wrapper commands, so
lazy-loading on `Open` alone would leave `:UrlView`/`:MDLinksView` undefined
until something else pulled the plugin in; `dependencies = { "StefanBartl/lib.nvim" }`,
`opts = {}` — every default below is the plugin's own, nothing overridden
by this config). That means: `picker.enabled = false` (no ambiguity prompt,
ever — ambiguity always resolves to one deterministic handler),
`office_open.enabled = true` (docx/xlsx/pptx auto-redirect is live),
`menu.enable = true` (context-menu entries are contributed), and no
`opts.keymaps` at all — every binding below is a bare `:Open`/`:UrlView`/
`:MDLinksView` command, no keymap shortcuts exist in this session.

## Setup

```vim
:checkhealth open
```

**Expect**: Neovim version and `vim.system` OK, `lib.nvim.notify` and the
usercmd composer present, detected platform (this machine: Windows),
per-platform tool availability, `office_open` status with its configured
extensions, and every registered handler with its description. Open Neovim
from a real git repo with a mix of files, a markdown file with a few links,
and neo-tree available for the tree-buffer tests below.

---

## 1. Bare `:Open` — the two-stage resolution, and where the surprise comes from

The most-exercised real path (`context.resolve` leads telemetry). Per
WORKFLOW.md, target and scope resolve via two **independent** fallback
chains — worth confirming both, and the specific surprise they cause.

**Steps**

1. Cursor on ordinary prose (no path, no URL) in a buffer, `:Open` — expect
   `default_filemanager` (reveals the *buffer's own* path in Explorer, per
   step 3 of `default_target()`'s fallback).
2. Cursor on (or over, via `<cWORD>`) a bare URL-looking word mid-sentence
   in a markdown file, e.g. `github.com` written without a scheme prefix
   — `:Open`.
   - [ ] Confirm this opens the **browser**, not the filemanager — the
     heuristic only checks the *shape* of the text (`http(s)://`, `ftp://`,
     `www.` prefix), so this is a documented "gotcha," not a bug. Note
     that a bare `github.com` (no `www.`/scheme) does **not** trigger this
     — only text actually matching one of the three prefixes does; contrast
     with §6's URL resolver in `gopath.nvim`, which has a looser match.
3. Cursor on a real, existing file path written as text (not a link), e.g.
   `README.md` inside a comment, `:Open filemanager` (explicit target, no
   scope) — should resolve via `<cfile>` since `filemanager` is a
   `PATH_TARGETS` entry, landing on that exact file, not the buffer.
4. Open a neo-tree buffer, cursor on any node, bare `:Open` — expect the
   node's own path handed to `default_filemanager`, **regardless** of target
   choice (tree node always wins first, per `context.lua`'s `M.resolve()`).

---

## 2. Explicit scope always beats the heuristic — `%`, `cfile`, `cwd`, `git`, `path=`, keywords

**Steps**

```vim
:Open filemanager %
:Open terminal cwd
:Open filemanager git
:Open browser path=/tmp/x.md
:Open split zshrc
```

**Expect**: each ignores cursor context entirely and resolves exactly what
the scope names. `git` **outside** any git repo (a scratch dir with no
`.git`) should be a clean no-op ("Nothing to open"), not a wrong directory
or an error — confirm it doesn't fall back to cwd.

- [ ] A dynamic keyword: `:Open split pwsh_profile` — expect a brief delay
  the *first* time (shells out to resolve `$PROFILE`), then instant on
  repeat. `:Open browser gitignore_global` — confirm keywords work as the
  scope to *any* target, not just `split`/`tab`.
- [ ] Tab-completion: `:Open split zsh<Tab>` — should offer `zshrc`/
  `zprofile` only (prefix-filtered keyword completion), not the full list.
- [ ] User-defined keyword for this session:
  `:lua require("open").setup({ keywords = { MY_TEST = "E:\\repos" } })`,
  then `:Open filemanager MY_TEST` — confirm it resolves to that literal
  path.

---

## 3. `split`/`vsplit`/`tab` — handlers, not modifiers, and their two guardrails

**Steps**

```vim
:Open split zshrc
:Open split https://example.com
```

**Expect**: the first opens a real horizontal split on the resolved path.
The second is **rejected outright** — "Text looks like a URL, not a local
path" — since these three handlers are `PATH_TARGETS` only, per
`open/handlers/nvim_internal.lua`.

- [ ] A scope that resolves to a **nonexistent** path, e.g.
  `:Open split path=/definitely/not/a/real/file.txt` — should fail with a
  clear error (path validated to exist *before* the ex-command runs), never
  a silent empty `[No Name]` split.
- [ ] `:Open split git` on a repo whose root is (as usual) a directory —
  confirm this opens Neovim's built-in directory listing rather than
  erroring — WORKFLOW.md calls this out as valid, if rare.

---

## 4. `:Open terminal` — always resolves to a directory

**Steps**

```vim
:Open terminal cfile
```
with the cursor on a **file** path (not a directory).

**Expect**: a `botright split` + `:terminal` opens rooted in that file's
**parent** directory (`resolve_dir()` walks up via `fnamemodify(path, ":h")`
before any `:lcd`) — never an error about `cd`-ing into a non-directory.

- [ ] `:Open terminal git` — fast path to a shell at the repo root
  regardless of how deeply nested the current buffer is.
- [ ] Confirm there is no vsplit/tab variant — the terminal handler only
  ever opens via `botright split`, move the window yourself if you want it
  elsewhere.

---

## 5. `office_open` — the transparent docx/xlsx/pptx redirect

**On by default in this config** (`office_open.enabled = true`,
unmodified). This is a `BufReadCmd` autocmd, not a command — it fires on
**any** read of a matching extension, not just `:Open`.

**Steps**

Find or create a real `.docx`/`.xlsx`/`.pptx` file, then try reaching it
multiple ways:

- [ ] `:e report.docx` directly from the command line.
- [ ] `gf` on a path reference to a `.xlsx` file in a buffer.
- [ ] Open it through a picker (pickers.nvim) or filetree.nvim's `<CR>`.

**Expect**: every path above opens the file in its system default
application (Word/Excel/etc.), **never** shows binary garbage in a Neovim
buffer, and the placeholder buffer Neovim briefly created is wiped
afterward — check `:ls` doesn't leave a stale `[docx]` entry behind.

- [ ] Launch Neovim directly on a `.docx` file from a shell
  (`nvim report.docx`) — since this was the *only* buffer, confirm Neovim
  falls back to an empty `[No Name]` buffer instead of exiting or erroring.

---

## 6. Context menu (`nvzone/menu`) — confirmed live in this config

**This config's own `lua/config/menu/mappings.lua` genuinely wires this
in** (telemetry confirms `integrations.menu.items`/`submenu` actually
fired) — worth testing for real, not just trusting the wiring.

**Steps**

`<RightMouse>` on:
1. A buffer whose cursor sits on a real URL.
2. A buffer whose cursor sits on an existing file path.
3. A neo-tree buffer, cursor on a file node.
4. Plain prose with neither a path nor a URL under the cursor.

**Expect**: entries self-gate per context — "Open in Browser" appears only
for case 1, "Reveal in File Manager"/"Open in Terminal" only for cases 2–3
(existing-path contexts), "List Links Here" (`:Open viewer %`) appears in
**every** case, and case 4 shows only that last entry, not broken/greyed
versions of the others.

---

## 7. `:Open viewer` / `:UrlView` / `:MDLinksView` — discover, then pick

**Steps**

```vim
:UrlView
```
in a markdown buffer with a few real links (a mix of `[text](https://…)`
and bare URLs).

**Expect**: a `lib.nvim.ui.kit.chooser` picker — whole-line highlight,
`j`/`k`-only navigation (`h`/`l`/`w`/etc. mapped to `<Nop>` — try one and
confirm it's genuinely inert, not just unbound). `<CR>` on a URL entry
opens the browser; on a picked **local file** (try `:MDLinksView`) it opens
in a **Neovim split**, not the file manager — even if `filemanager.reveal`
is configured, per WORKFLOW.md's explicit warning that the viewer's
`open_file` setting (`"split"` by default here) is independent of
`default_filemanager`.

- [ ] `:MDLinksView cwd` (every markdown link project-wide) vs `:UrlView`
  (only browser-openable targets) on the same file with both a
  `[docs](https://x.dev)` link and a `[local](./README.md)` link — confirm
  `:UrlView` only lists the first, `:MDLinksView` lists both (they
  deliberately overlap only on URL-shaped markdown links).
- [ ] `'<,'>UrlView` (visual range) — scans only the selected lines, not the
  whole buffer.
- [ ] `out=table`/`out=csv`/`out=mdlinks`/`out=clipboard`/`out=echo` — each
  produces the documented shape; `mdlinks` specifically should paste as
  real `[label](target)` lines with a sensible auto-label (host for a URL,
  basename for a path) when the source had none.
- [ ] `--dupes`/`--flat`/`--anchors`/`match=%.md$` — each visibly changes
  the result set from the plain `cwd` scan (dupes reappear, subdirectories
  drop out, TOC anchors like `[x](#x)` reappear, non-`.md` files disappear).
- [ ] Tab-completion: `:UrlView cwd sort=<Tab>` → `none file kind alpha`,
  `:UrlView cwd out=<Tab>` → the full output-kind list.
- [ ] A `file.md#heading` target from the picker — confirm it jumps to that
  heading after opening, not just the top of the file.

---

## 8. Debug mode — the actual troubleshooting tool

**Steps**

```vim
:lua require("open").setup({ debug = true })
:Open browser somepath
```

**Expect**: `:messages` shows both the `context.lua` gather/resolve log
line (raw signals: tree path, cfile, cword, visual, buffer path, then the
decided text/is_url/is_path) and the `registry.lua` dispatch line (which
handler actually got called) — enough to answer "why did `:Open` pick
*that*" without reading source. Turn it back off, confirm the log lines
stop (the call is gated behind `is_debug()`, zero cost when off — worth
spot-checking there's no leftover message on the next invocation).

---

## 9. The WSL notepad gotcha (informational — only testable if you run WSL)

**Skip on plain Windows** (this machine's normal path uses `explorer.exe`/
`notepad.exe` directly and never hits `wslpath`). If you do have a WSL
Neovim session available: `:Open notepad` on some selected text — the
handler must convert `vim.fn.tempname()`'s Linux-side path to its
`\\wsl$\...`/drive-letter form via `lib.nvim.cross.fs.wslpath.to_win()`
*before* handing it to `notepad.exe`, or the open fails 100% of the time
(not intermittently — two processes with disjoint filesystem views, per
WORKFLOW.md). Not applicable to a native-Windows session; recorded here so
it isn't silently skipped without a reason.

---

## What this checklist does not cover in depth

The opt-in `picker.enabled` ambiguity prompt (`false` in this config,
unmodified — `candidate_targets()`'s multi-handler path never fires here).
`open.integrations.telescope` (not wired into this config's telescope
setup — a separate opt-in source, not loaded by `setup()`). The
`custom_handlers` extension point (none registered in this session).
Per-platform browser variants (`chrome`/`firefox`/`edge`/`brave`/`opera`) —
same dispatch mechanism as `default_browser`, differing only in which
executable is targeted; testing one (§1/§2 above) exercises the shared
code path.
