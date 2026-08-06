# buffer-ctx.nvim — Autocmds Cheatsheet

Source: `lua/buffer_ctx/mark/init.lua` (`M.setup`)
Extension point (unused): `lua/buffer_ctx/bindings/autocmds.lua` — a no-op
stub, kept as a documented place to add future autocmds without hunting for
where `setup()` wires things together.

| Event(s) | Augroup | Callback | Action |
| --- | --- | --- | --- |
| `BufDelete`, `BufWipeout` | `BufferCtxMarkCleanup` | `clear_marks(args.buf)` | Drop `:Mark` state for the deleted/wiped buffer |

## Details

- **Why it exists**: `:Mark toggle` keeps a per-buffer table
  (`marked[bufnr][extmark_id] = true`) in module state. Without this cleanup,
  that table would grow unboundedly across a long session as buffers get
  opened, marked, and closed — nothing else ever removes an entry.
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
- **State access (2026-08-06)**: `marked` is now read/written only through
  local `get_marks()`/`add_mark()`/`remove_mark()`/`clear_marks()` helpers
  instead of direct field access from four call sites — this autocmd's
  callback is one of them.

## Previously an issue here, now fixed

`:Mark` used to key marks by raw line number, not a stable extmark ID —
inserting or deleting lines above a mark desynced the visible `●` from the
actual marked line, and `:Mark yank` then copied the wrong lines. This is
fixed: `marked` is now keyed by extmark ID (`marked[bufnr][extmark_id] =
true`), resolved to its current line via `nvim_buf_get_extmark_by_id` on
every read, so edits above a mark no longer desync it. Regression coverage in
`docs/TESTS/mark_spec.lua`. Rationale/implementation notes:
`docs/ROADMAP/anchor-stable-marks.md` (kept as the historical record, marked
"Status: implemented").
