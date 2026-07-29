# `lib.nvim`

## Neue Features implementieren

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

---

docmodler cli

---

## docmodule — missing-readme (2026-07-28)

docmap's `missing-readme` check (info-severity: "module without a README — should be a
decision, not an accident") flagged 72 modules under `lua/lib/*` with no `README.md`. All 72
now have one, written after reading the actual source (not generated from the module name) —
terse prose-only style for tiny single-function modules (following the existing
`lib.nvim.fs.is_subpath` convention), fuller `# title + Usage` style for modules with real
surface area. The 17 `lib.vim.*` stub modules (placeholders per `doc/vim-parity.md`, not yet
ported to classic Vim) got a shared template noting their stub status instead of invented
behavior.

`nvim --headless -l scripts/gen_map.lua --check --lenient` confirms 0 `missing-readme` and 0
`dead-readme-link` findings afterward; `docs/map/*` regenerated and verified deterministic.

Two unrelated bugs surfaced while reading source for this (fixed the first, documented but did
not fix the second — a real behavior change, out of scope for a docs pass):
- `lua/lib/nvim/cross/fs/separators/has_win_sep`: `---@return boolean` was wrong — the function
  actually returns the matched substring or `nil` (Lua `string.match` semantics). Fixed the
  annotation (here and in `cross/@types/fs.lua`) to `string|nil`.
- `lua/lib/nvim/buf_win_tab/safe_adjacent_buffer` keeps its own private "is this a normal file
  buffer" check, distinct from and subtly weaker than `buf_win_tab/normal_buffer`'s
  `is_normal_file_buffer` (doesn't require loaded/readable) — documented in its new README,
  not merged, since unifying them would be a real behavior change to verify separately.
