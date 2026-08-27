# pdfport.nvim — `:PdfPort [subcommand] [path]` Cheatsheet

One command, built via `lib.nvim.bindings.usercmd.composer` (`<Tab>` completion via a
custom `PDF_PATH` type — `.pdf` files prioritized, `<cfile>` suggested when
completing with no input yet, reusing the plugin's own existing completion
logic verbatim). Replaces the old 6 flat `:PdfPortX` commands (fully removed,
no alongside period).

Source: `lua/pdfport/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `README.md`, `doc/pdfport.txt`

| Command | Effect |
| --- | --- |
| `:PdfPort [path]` | Open PDF with interactive mode/backend picker |
| `:PdfPort text [path]` | Extract to buffer (auto backend chain) |
| `:PdfPort float [path] [pages=…]` | Extract to floating window. Prompts for a page range **unless** `pages=` is given (`pages=1-3,5`). **kv added 2026-08-24.** |
| `:PdfPort system [path]` | Open with system application |
| `:PdfPort terminal [path] [pages=…]` | Render as terminal image. Same `pages=` kv as `float`. **Added 2026-08-24.** |
| `:PdfPort backends` | List all registered backends with live availability (float) |
| `:PdfPort create [path]` | Create a PDF from an image/markdown/text/html/office file (path arg, `<cfile>`, or current buffer) |
| `:PdfPort merge {output} {input1} {input2} ...` | Merge two or more existing PDFs into one |
| `:PdfPort producers` | List all registered creation producers with live availability (float) |
| `:PdfPort health` | Run `:checkhealth pdfport` |

All path-taking subcommands fall back to `<cfile>` then the current buffer
name when `[path]` is omitted — unchanged from the original.

## Notes (2026-07 ROADMAP pass)

- **`backends` route added** — implements the ROADMAP's `:PdfPortBackends` item as a
  `:PdfPort backends` subcommand instead of a new flat command, staying consistent with
  the composer migration below. Reuses `registry.diagnostics()` (previously dead code,
  never called anywhere), shown via `lib.nvim.window.make_scratch` (falls back to
  `notify.info` if that module can't be required).
- **`pages=` skips the prompt (2026-08-24)** — a composer kv on the `float`/`terminal`
  routes. The prompt is fine for a human but leaves the two subcommands unusable from a
  script or another plugin, since there is no way to answer it non-interactively. A
  `pages=` that parses to no page number (`pages=`, `pages=abc`) is reported and nothing
  opens, rather than falling through to the prompt or to the whole document. Note the
  completion only offers `pages=` once a partial lead is typed (`:PdfPort float p<Tab>`);
  with an empty lead the PDF-path completer takes the slot.
- **`float`/`terminal` now prompt for a page range** (`lua/pdfport/util/page_range.lua`,
  `vim.ui.input`) before opening — `<Esc>` cancels the whole open, not just the prompt.
- **Backends are now lazy-registered** (`pdfport.backends.load_all(cfg)`) — `:PdfPort`
  itself doesn't change, but the first real `:PdfPort text`/`float`/etc. call is what
  actually triggers `require()` of the resolved backend module, not `setup()`.

## Notes (original composer migration)

- **`path = {}` root route**: the bare `:PdfPort [path]` case (mode picker,
  no subcommand token) uses composer's root-route pattern — same technique
  used for replacer.nvim's flat `{old} {new} [--flags]` grammar. A route with
  an empty `path` array matches even when no literal subcommand token is
  present, so `:PdfPort` and `:PdfPort mydoc.pdf` both land there while
  `:PdfPort text mydoc.pdf` walks into the `text` subtree instead.
- **lib.nvim went from purely-audited-optional to required**: pdfport.nvim's
  own architecture audit (`docs/ROADMAP/Zentral-Prinzipien.md`) explicitly
  called lib.nvim "optional-by-design, deliberate standalone-first choice" —
  left as a historical snapshot (not rewritten, matches the "skip ROADMAP
  docs" policy), but README/installation.md/vimdoc/health.lua all updated
  to reflect the new reality (`:PdfPort` needs `lib.nvim.bindings.usercmd.composer`).
  `lib.nvim.ui.kit` (the picker enhancement) stays legitimately soft.
- Keymaps are per-file-tree-integration and call `pdfport.open()` directly as
  a Lua function (like dap.nvim) — no command-string coupling, unaffected.

## Notes (2026-08 checklist pass)

- A headless test suite and CI now exist (`TESTS/run.lua`, gated in
  `.github/workflows/ci.yml` alongside stylua/luacheck) — the "no test suite and no CI"
  note above from the composer-migration pass is stale/superseded, left in place as a
  historical snapshot rather than rewritten.
- `doc/pdfport.nvim.txt` was renamed to `doc/pdfport.txt` (tags `pdfport.nvim-*` ->
  `pdfport-*`) so `:h pdfport` resolves, matching `fileops.txt`/`replacer.txt`.

## Notes (2026-08-09 pdf_create P0 pass)

- **New creation ("write") direction**, mirroring the read path exactly:
  `core/composer.lua` resolves a **producer** (not a backend) through a
  per-input-kind `create_chain`, same shape as `core/resolver.lua` for
  backends. `producers/img2pdf.lua` + `producers/magick.lua` are the only
  shipped producers (image input only); lazy-registered via
  `producers/init.lua` exactly like `backends/init.lua`.
- **`create`/`producers` routes added**, same `show_diagnostics()` helper
  reused by both `backends` and `producers` (previously duplicated inline in
  the `backends` route).
- `require("pdfport").create({ inputs = {...} })` / `can_create(kind)` /
  `register_producer(p)` are the new public Lua API, mirroring
  `open`/`extract`/`register_backend`.
- The `filetree.nvim` `require("pdfport_nvim")` bug noted in the personal
  ROADMAP (`filetree/util/pdf.lua`) was found already fixed on disk — no code
  change needed there.
- Full design + P1-P3 (Markdown/HTML/Office producers, caller wiring into
  `images.nvim`/`markdown.nvim`/`filetree.nvim`) in
  `docs/ROADMAP/PDF_CREATE.md`; shipped-feature summary in `docs/FEATURES.md`.

## Notes (2026-08-09 pdf_create P2-P3 pass)

- **P3 shipped**: `producers/weasyprint.lua` + `producers/chromium.lua` (html),
  `producers/soffice.lua` (office), and three merge producers —
  `producers/qpdf.lua` + `producers/pdftk.lua` + `producers/ghostscript.lua` —
  registered as ordinary `"pdf"`-kind producers (input kind `"pdf"` already
  existed in `PdfPort.InputKind`, unused until now) rather than a bespoke
  merge subsystem: `require("pdfport").merge({inputs, output, ...})` is a
  thin wrapper that calls `composer.create()` with `from = "pdf"`, reusing
  the exact same resolve/on_conflict/progress machinery as every other
  input kind. New `:PdfPort merge {output} {input1} {input2} ...` route
  reads the input list via `ctx.rest` (lib.nvim usercmd composer's
  leftover-tokens field) rather than a fixed positional-arg schema.
- **Of P2** (caller wiring into `images.nvim`/`markdown.nvim`/`filetree.nvim`),
  only `filetree.nvim`'s side is in scope of this repo/session —
  `filetree.util.pdf.create()` + the new `pdf_create` feature (`gP` keymap)
  call straight into `pdfport.create()`, documented in filetree.nvim's own
  `Keymaps/filetree.nvim.md` and `docs/ROADMAP/PDFPORT_INTEGRATION.md`.
  `images.nvim`/`markdown.nvim` wiring remains open — separate repos, not
  touched this pass.
- `create_chain.pdf = { "qpdf", "pdftk", "ghostscript" }` added to
  `config/DEFAULTS.lua` — the merge fallback chain, same shape as every
  other `create_chain` entry, not a new top-level config key.

## Notes (2026-08 deps pass)

- `docs/install.json` declares pdfport.nvim's 6 optional external tools
  (pdftotext, pdftoppm, tesseract, curl, ollama, chafa) for
  `lib.nvim.deps` — the first plugin to ship one. Each entry carries a
  required `why` (see the `lib.nvim.md` cheatsheet's `:Lib deps` section for
  the mechanism); `:PdfPort health`'s own `:checkhealth` output is
  unchanged, this is a separate, cross-plugin-aware surface
  (`:Lib deps show pdfport.nvim`), not a replacement for it.
- `pdftotext` and `pdftoppm` are declared as two tool entries sharing one
  `poppler-utils`/`poppler` package on most managers — worth knowing if this
  file is used as a template: `lib.nvim.deps.install.plan` de-duplicates the
  package name in the composed command, but both tools still show
  individually in `:Lib deps show`.
