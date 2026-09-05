# Testing pdfport.nvim

How to manually test pdfport.nvim's real feature surface. Telemetry shows
**zero** recorded calls (`TelemetryReport.md`: 29 accumulated sessions, 70
instrumented functions, "keine instrumentierten Aufrufe aufgezeichnet") —
so priority here comes entirely from reading `README.md`, `docs/WORKFLOW.md`
(unusually thorough — reads like a finished audit trail, with several
gotchas already spelled out precisely enough to lift directly into test
steps below), and the source.

Repo: `$REPOS_DIR\pdfport.nvim`. Spec: `lua/plugins/personal/init.lua`
(`cmd = "PdfPort"` — fixed 2026-08-28, was `{ "PdfPort", "PdfPortText",
"PdfPortFloat", "PdfPortSystem", "PdfPortTerminal", "PdfPortHealth" }`, five
of which named commands the plugin never registers, see §1 below. No
`dependencies` entry despite
`lib.nvim` being a hard requirement per the README — `lib.nvim` still loads
because it's `lazy = false` itself, so nothing breaks in practice, but the
spec doesn't declare the dependency the way most other personal-plugin
entries do). `opts` sets `default_backend = "auto"`, `fallback_chain =
{ "pdftotext", "pdfplumber", "marker", "docling", "ollama", "claude" }`
(**note: no `tesseract`**, unlike the plugin's own `config/DEFAULTS.lua`
and the README's own quickstart snippet, both of which include it — this
config's own chain deliberately or accidentally drops OCR fallback),
`extract_opts = { max_pages = nil, timeout_ms = 30000 }`, `render_opts =
{ mode = "buffer", split = "current", focus = true }` (**note:
`split = "current"`, not the plugin default `"vsplit"`** — buffer mode
reuses the current window instead of opening a new split), `progress_style
= "statusline"`, `ollama_model = "qwen2.5-coder:7b"` (a code model, not a
vision one — worth knowing before testing the Ollama backend on a
scanned/image PDF, see §3).

## Setup

```vim
:checkhealth pdfport
```

**Expect**: core modules, every backend/producer/renderer/integration
status, and the live registry. Have at least one real PDF on hand — a
text-based one (for backend extraction) and, if you want to exercise OCR
paths, a scanned/image-only one.

---

## 1. Five dead lazy-load command triggers — fixed 2026-08-28, confirm the real command still lazy-loads

**Was a real bug in this config's spec, now fixed — this section is a
regression check, not an open question.** The spec's `cmd` list used to be
`{ "PdfPort", "PdfPortText", "PdfPortFloat", "PdfPortSystem",
"PdfPortTerminal", "PdfPortHealth" }`. Reading `lua/pdfport/bindings/usrcmds.lua`'s
`M.register()`, the plugin registers **exactly one** user command,
`:PdfPort`, built as a single `composer.verb("PdfPort", { routes = {...} })`
with subcommands `text`/`float`/`system`/`terminal`/`health`/`backends`/
`create`/`producers`/`merge` reached as `:PdfPort text`, `:PdfPort float`,
etc. There is no `nvim_create_user_command`/`composer.verb` call anywhere
in this plugin's source for the literal names `PdfPortText`, `PdfPortFloat`,
`PdfPortSystem`, `PdfPortTerminal`, or `PdfPortHealth` — confirmed by
grepping the whole `lua/`/`plugin/` tree for those strings, no hits outside
the old spec itself. Fixed by trimming the spec to `cmd = "PdfPort"`.

**Steps**

```vim
:PdfPort
```
on a fresh start (plugin not yet loaded).

- [ ] Confirm lazy.nvim's stub still fires on bare `:PdfPort` (watch for the
  `deps_popup` notification if this is the first run) and the command runs
  normally afterwards — the trimmed `cmd` list didn't accidentally break
  lazy-loading itself.
- [ ] `:command PdfPort<Tab>` after loading should show only `:PdfPort` (no
  `PdfPortText`/`PdfPortFloat`/etc. ever existed as separate commands, so
  there's nothing to lose by their removal from `cmd`).

---

## 2. `:PdfPort [path]` — the mode picker, and `system`/`terminal` bypassing backends entirely

**Steps**

```vim
:PdfPort
```
on a real PDF (`<cfile>` or current buffer).

**Expect**: the interactive mode picker (`buffer`/`float`/`terminal`/
`system`, plus backend-specific choices) — via `lib.nvim`'s UI kit if
available, `vim.ui.select` fallback otherwise. "System application" should
always be one of the offered choices (per `pick_open()`'s canonical-list
guarantee in WORKFLOW.md — there used to be two independently-drifting
copies of this list; confirm there's exactly one now, i.e. the same labels
show up from `:PdfPort` and from any embedding caller like a file-tree
keymap).

- [ ] **The concrete claim to verify**: `:PdfPort system` and `:PdfPort
  terminal` special-case *before* backend resolution
  (`core/dispatcher.lua`) — they should work even with **every** text
  extraction backend reporting unavailable in `:checkhealth pdfport`. If
  you have a machine/session with no `pdftotext`/`pdfplumber`/etc.
  installed, or can fake it by temporarily breaking `PATH`, confirm
  `terminal` (needs only `pdftoppm` + a terminal image tool) and `system`
  still work.
- [ ] `:PdfPort text` — extract to a scratch buffer, `split = "current"` per
  this config (reuses the current window, not a new vsplit — the one place
  this config's `render_opts` diverges from the plugin default). Re-run
  `:PdfPort text` on the **same unchanged file** — should be near-instant,
  no visible progress indicator at all (cache hit skips
  `start_progress()` entirely, per WORKFLOW.md — correct behavior, not a
  bug, but easy to mistake for "did nothing").

---

## 3. Backend fallback chain — this config's own chain, and a request that silently degrades

**Steps**

```vim
:PdfPort backends
```

**Expect**: all registered backends (pdftotext, pdfplumber, marker,
docling, ollama, claude, tesseract) with live availability — **tesseract
is still listed** even though this config's `fallback_chain` omits it
(every registered backend not in the chain is appended at the end per
`core/resolver.lua`'s own rule — always reachable, never silently dropped;
confirm it's there, just last).

- [ ] Explicitly request `claude` without `ANTHROPIC_API_KEY`/
  `claude_api_key` set (this config leaves `claude_api_key = nil`):
  ```lua
  require("pdfport").open({ path = "/some/real.pdf", backend_id = "claude", mode = "buffer" })
  ```
  **Expect**: no error — it silently falls through to the rest of
  `fallback_chain` (pdftotext first here) and you get a plain-text result
  with **no indication** your explicit `claude` request was skipped. This
  is the exact trap WORKFLOW.md calls out — confirm it reproduces, then
  check `:PdfPort backends` (or `registry.diagnostics()`) is genuinely the
  only way to have known in advance.
- [ ] If Ollama is actually running locally: try extracting a **scanned
  image-only** PDF via the `ollama` backend. This config sets
  `ollama_model = "qwen2.5-coder:7b"` — a code-completion model, not a
  vision-capable one. Confirm whether this produces a garbled/irrelevant
  result (wrong model for the task) rather than real OCR — worth knowing
  before trusting Ollama extraction results from this specific config.

---

## 4. `float` / `terminal` — the page-range prompt, and `pages=` for scripting

**Steps**

```vim
:PdfPort float
```
on a multi-page PDF — should prompt (`vim.ui.input`) for a page range.

- [ ] Leave it blank, `<CR>` — should default to **all pages** for `float`.
- [ ] `<Esc>` on the prompt — cancels, confirm nothing opens (no error, no
  partial window).
- [ ] `:PdfPort terminal` with a blank answer — should default to **page 1
  only** (different default than `float`'s "all pages" — easy to mix up).
- [ ] `:PdfPort float report.pdf pages=1-3,5` — skips the prompt entirely,
  opens exactly those pages.
- [ ] `:PdfPort float report.pdf pages=abc` (unparseable) — should be
  **reported and nothing opens** — not a silent fall-through to the prompt,
  and not the whole document. This is the concrete script-safety guarantee
  WORKFLOW.md documents; confirm it holds.

---

## 5. `create` and `merge` — the write side

**Steps**

```vim
:PdfPort create
```
on an image or markdown file (`<cfile>`/current buffer).

**Expect**: a real PDF produced via the resolved producer chain
(`create_chain.image = {"img2pdf","magick"}`, `create_chain.markdown =
{"pandoc"}`, etc.) — check the output file actually exists next to the
input afterward.

```vim
:PdfPort merge out.pdf a.pdf b.pdf
```

**Expect**: a single merged `out.pdf` (qpdf → pdftk → Ghostscript fallback
chain). Try it with only one input path — should error "need at least 2
input PDFs, got 1", not silently "merge" a single file.

- [ ] `:PdfPort producers` — same diagnostics-panel shape as `:PdfPort
  backends`, listing all nine creation producers with live availability.
- [ ] Run `:PdfPort create`/`:PdfPort merge` twice on the same output path
  on purpose — per WORKFLOW.md, creation has **no cache** (unlike
  extraction) — confirm each run genuinely re-executes the producer rather
  than returning a stale cached result.

---

## 6. File-tree integrations — check what's actually wired in *this* config before assuming the README's default keymaps exist

**This config specifically removed pdfport.nvim's own neo-tree keymap
wiring** — `lua/config/neotree/keymaps/filesystem/init.lua`'s own comment
says so explicitly: `pdfport`'s native `<leader>po/pt/ps/pi/pb` integration
was deleted in favor of **filetree.nvim's own preview feature**, which
dispatches PDFs via `<Tab>`/`<CR>` in the tree using pdfport as its backend
(not pdfport's own keymap layer). This means the README's "Adds
`<leader>po/pt/ps/pi` keymaps to neo-tree" claim does **not** describe this
session — those specific lhs values were never bound here.

**Steps**

1. In neo-tree, cursor on a real PDF node, `<Tab>` and `<CR>` — per
   filetree.nvim's own preview feature, should dispatch through pdfport
   (confirm a PDF actually opens/previews, not an error) — cross-reference
   [`filetree.md`](filetree.md) §10 (Preview) if this doesn't behave as
   expected.
2. Confirm `<leader>po`/`<leader>pt`/`<leader>ps`/`<leader>pi`/`<leader>pb`
   are genuinely **unbound** in a neo-tree buffer (`:map <leader>po` while
   the tree is focused) — expect nothing, since pdfport's own neo-tree
   integration module is not `require()`'d anywhere in this config.

**What *is* wired**: Telescope and fzf-lua PDF previews are real here —
`lua/config/telescope/init.lua`'s `pdf_filetype_hook()` and
`lua/config/fzf/files/init.lua`'s `pdf_preview()` both `pcall(require,
"pdfport.integrations.…")` and wire the result into the picker preview
pane.

- [ ] In Telescope's `find_files`, arrow down to a `.pdf` result — the
  preview pane should show extracted text (raw, not a rendered buffer —
  WORKFLOW.md is explicit this path never touches a renderer), bounded by
  `max_pages = 3`.
- [ ] Same check in fzf-lua's files picker.

---

## 7. Gotchas worth confirming directly (all named explicitly in `docs/WORKFLOW.md`)

- [ ] **`system`/`terminal` never populate `result.text`.** Call
  `pdfport.open({ path = "...", mode = "system" }, function(result) print(vim.inspect(result)) end)`
  from `:lua` — confirm `result.text` is `nil` (a synthetic `status = "ok"`
  result), unlike `mode = "buffer"`/`"float"`, which should return real text.
- [ ] **Batch summary counts outcomes, not attempts.** If you have several
  PDFs to open at once (visual-mode batch via a tree, if wired — or a
  scripted loop with the `on_done(ok, err)` third argument to
  `pdfport.open`), deliberately make one fail (e.g. point one path at a
  non-PDF file) — the summary should report the real success count, not
  the attempted count.
- [ ] **`claude` backend never leaks the API key to `ps`.** Not directly
  observable without a process monitor, but worth knowing if you're
  auditing `backends/claude.lua` — the key goes into a temporary curl `-K`
  config file, not a `-H` argv element.

---

## What this checklist does not cover in depth

Custom backend/producer registration (`register_backend()`/
`register_producer()`) — a Lua API surface with no interactive UI of its
own; exercising it is a code-review question, not a click-through one.
`render_page()` (the primitive `images.nvim` builds on) — covered from the
`images.nvim` side already, if that plugin's own checklist exists.
`oil.nvim`/`nvim-tree`/`netrw` integrations specifically — same shape as
neo-tree (§6), and none of the three is the active tree plugin in this
config (filetree.nvim/neo-tree is).
