# pdfport.nvim — `:PdfPort [subcommand] [path]` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion via a
custom `PDF_PATH` type — `.pdf` files prioritized, `<cfile>` suggested when
completing with no input yet, reusing the plugin's own existing completion
logic verbatim). Replaces the old 6 flat `:PdfPortX` commands (fully removed,
no alongside period).

Source: `lua/pdfport_nvim/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `README.md`, `doc/pdfport.nvim.txt`

| Command | Effect |
| --- | --- |
| `:PdfPort [path]` | Open PDF with interactive mode/backend picker |
| `:PdfPort text [path]` | Extract to buffer (auto backend chain) |
| `:PdfPort float [path]` | Extract to floating window |
| `:PdfPort system [path]` | Open with system application |
| `:PdfPort terminal [path]` | Render as terminal image |
| `:PdfPort health` | Run `:checkhealth pdfport_nvim` |

All path-taking subcommands fall back to `<cfile>` then the current buffer
name when `[path]` is omitted — unchanged from the original.

## Notes

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
