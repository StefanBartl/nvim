# buffer-ctx.nvim — Autocmds Cheatsheet

Source: `lua/buffer_ctx/mark/init.lua` (`M.setup`)
Extension point (unused): `lua/buffer_ctx/bindings/autocmds.lua` — a no-op
stub, kept as a documented place to add future autocmds without hunting for
where `setup()` wires things together.

| Event(s) | Augroup | Callback | Action |
| --- | --- | --- | --- |
| `BufDelete`, `BufWipeout` | `BufferCtxMarkCleanup` | `marked[args.buf] = nil` | Drop `:Mark` state for the deleted/wiped buffer |

## Details

- **Why it exists**: `:Mark toggle` keeps a per-buffer table
  (`marked[bufnr][lnum] = true`) in module state. Without this cleanup, that
  table would grow unboundedly across a long session as buffers get opened,
  marked, and closed — nothing else ever removes an entry.
- **Registration**: created inside `mark/init.lua`'s `M.setup(opts)`, which
  only runs when the `:Mark` subsystem is enabled (`mark ~= false` in
  `setup()`, the default). Disabling `:Mark` means this autocmd is never
  registered at all — no dangling group left behind.
- **Augroup hygiene**: `nvim_create_augroup(..., { clear = true })`, so
  calling `setup()` more than once doesn't accumulate duplicate autocmds in
  the group.
- **Not covered by this autocmd**: buffer-local extmarks/signs used for the
  visual `●` indicator are Neovim's own responsibility (cleared automatically
  when the buffer is wiped) — this autocmd only clears buffer-ctx's own
  `marked` Lua table, which is a separate, plugin-owned piece of state.

## Known issue this interacts with

`:Mark` keys marks by raw line number, not a stable extmark ID — inserting or
deleting lines above a mark desyncs the visible `●` from the actual marked
line, and `:Mark yank` then copies the wrong lines. This autocmd only cleans
up on buffer *deletion*, it does not address the *within-buffer-edit* drift.
Tracked in the repo: `docs/ROADMAP/anchor-stable-marks.md`.
