# emojis.nvim — Autocmds Cheatsheet

Source: `lua/emojis/bindings/autocmds.lua`

**None.** `M.setup(_cfg)` is an intentionally empty stub, kept purely for
structural symmetry with `usrcmds`/`keymaps`. Module doc: "emojis.nvim
deliberately has no autocmd-driven behaviour (e.g. no auto-clear on save)".
`docs/ROADMAP.md` used to list this under a "Nicht geplant" section; the
file was emptied 2026-07-24 (nothing pending left to track) so that
cross-reference is gone, but the design decision itself stands.

Confirmed via full-repo grep — no other autocmd registration exists anywhere
in emojis.nvim.

Cross-reference: `docs/BINDINGS.md` states this explicitly and matches.
