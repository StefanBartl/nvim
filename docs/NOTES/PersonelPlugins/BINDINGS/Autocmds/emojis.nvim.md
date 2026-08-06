# emojis.nvim — Autocmds Cheatsheet

Source: `lua/emojis/bindings/autocmds.lua`

**None.** `M.setup(_cfg)` is an intentionally empty stub, kept purely for
structural symmetry with `usrcmds`/`keymaps`. Module doc: "emojis.nvim
deliberately has no autocmd-driven behaviour (e.g. no auto-clear on save):
see 'Nicht geplant' in `docs/ROADMAP.md`". That cross-reference is live
again: `docs/ROADMAP.md` was emptied 2026-07-24, but the source comment in
`lua/emojis/bindings/autocmds.lua` was never updated to match, so the link
was pointing at an empty section. Fixed 2026-08-06 (Lua/Neovim checklist
compliance pass) by restoring a "Nicht geplant" section in `docs/ROADMAP.md`
(status summary + the three deliberately-not-planned items, including this
one) instead of touching the source comment — the design decision itself
stands either way.

Confirmed via full-repo grep — no other autocmd registration exists anywhere
in emojis.nvim.

Cross-reference: `docs/BINDINGS.md` states this explicitly and matches.
