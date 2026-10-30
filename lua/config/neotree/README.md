# config.neotree

What is left of this config's own neo-tree layer: the per-source
`window.mappings` tables under `keymaps/` (neo-tree command names and
`noop`s only) and one event handler. Everything that ran code of its own --
the source switcher, the Alt toggle keys, node utilities, a health check --
is filetree.nvim's since 2026-09-19 (`source_switcher`, `tree_toggle`; see
`plugins/personal/specs/navigate.lua` for how they are configured here).

`job_handle_close.lua` is a local patch for neo-tree itself: `utils.job`
(the git status/rev-parse/ls-files/diff runner) never closes the
`uv_process_t` it spawns, so every save or directory change leaked one
process handle (and on Windows the process object behind it). `plugins/neotree.lua`
installs the wrapper before `setup()`; it closes the handle when the job is
finished and passes everything else through. Drop it once upstream closes
the handle itself.
