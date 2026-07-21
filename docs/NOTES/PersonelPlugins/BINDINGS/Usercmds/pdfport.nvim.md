# pdfport.nvim — `:PdfPort [subcommand] [path]` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion via a
custom `PDF_PATH` type — `.pdf` files prioritized, `<cfile>` suggested when
completing with no input yet, reusing the plugin's own existing completion
logic verbatim). Replaces the old 6 flat `:PdfPortX` commands (fully removed,
no alongside period).

Source: `lua/pdfport/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `README.md`, `doc/pdfport.nvim.txt`

| Command | Effect |
| --- | --- |
| `:PdfPort [path]` | Open PDF with interactive mode/backend picker |
| `:PdfPort text [path]` | Extract to buffer (auto backend chain) |
| `:PdfPort float [path]` | Extract to floating window (prompts for a page range) |
| `:PdfPort system [path]` | Open with system application |
| `:PdfPort terminal [path]` | Render as terminal image (prompts for a page range) |
| `:PdfPort backends` | List all registered backends with live availability (float) |
| `:PdfPort health` | Run `:checkhealth pdfport` |

All path-taking subcommands fall back to `<cfile>` then the current buffer
name when `[path]` is omitted — unchanged from the original.

## Notes (2026-07 ROADMAP pass)

- **`backends` route added** — implements the ROADMAP's `:PdfPortBackends` item as a
  `:PdfPort backends` subcommand instead of a new flat command, staying consistent with
  the composer migration below. Reuses `registry.diagnostics()` (previously dead code,
  never called anywhere), shown via `lib.nvim.window.make_scratch` (falls back to
  `notify.info` if that module can't be required).
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
  to reflect the new reality (`:PdfPort` needs `lib.nvim.usercmd.composer`).
  `lib.nvim.ui.kit` (the picker enhancement) stays legitimately soft.
- No test suite and no CI exist for this repo, so no fix needed there.
- Keymaps are per-file-tree-integration and call `pdfport.open()` directly as
  a Lua function (like dap.nvim) — no command-string coupling, unaffected.
