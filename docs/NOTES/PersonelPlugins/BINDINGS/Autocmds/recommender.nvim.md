# recommender.nvim — Autocmds Cheatsheet

Sources: `lua/recommender_nvim/bindings/autocmds.lua` (empty stub), `lua/recommender_nvim/float/autocmds.lua`
Cross-reference: `docs/BINDINGS.md` — explicitly notes "No plugin-level autocommands... Replace mode registers a temporary, one-shot `WinClosed` autocmd" — matches source.

`bindings/autocmds.lua` is an intentionally empty stub, kept "for structural
symmetry" with usrcmds/keymaps — recommender.nvim has no autocmd-driven
activation.

The **one real autocmd** is dynamically registered per `:Replace`-mode
invocation of the suggestion float, not at setup time:

| Event | Augroup (clear) | Pattern | Action |
| --- | --- | --- | --- |
| `WinClosed` | `RecommenderNvimReplaceInsert` | none (matched in callback: reacts only if the closed window's buffer had filetype `TelescopePrompt`) | Diffs a buffer-line snapshot taken before `:Replace` ran against the buffer's current lines; if changed, moves to the target window and inserts the alias text |

Temporary, one-shot in effect: `nvim_del_augroup_by_id` is called immediately
inside the callback, before doing its actual work, even though it's not
registered with `once = true` on the autocmd itself.
