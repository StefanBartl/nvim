---@module 'config.ui_statusline'
--- Wires this host's own statusline AND tabline into ui.nvim, additively:
--- NvChad keeps booting exactly as before, and this simply takes over
--- `vim.o.statusline`/`vim.o.tabline` afterward -- at UIReady, once
--- everything else (including NvChad's own, now chadrc-less-default
--- statusline and tabline) has already finished loading, so it wins without
--- touching NvChad itself. Module name kept as "ui_statusline" rather than
--- renamed for the tabline addition -- it is one host wiring point for
--- everything `ui.nvim` draws, and a rename would ripple into init.lua's
--- startup phase and this file's own path for no functional gain.
---
--- `chadrc.lua` and `lua/wkdnvchad/` (the pre-extraction original this
--- plugin's code was ported from) are gone as of roadmap step 7's first
--- round -- NvChad now runs on its own built-in defaults, which is
--- irrelevant since this phase overwrites its statusline/tabline output
--- anyway. NvChad's plugin itself and a few of its core features (nvdash,
--- LSP signature popup, colorify) are still in use and not yet replaced --
--- see ui.nvim's own NOTES.md "Offene Punkte" and ROADMAP.md open decision
--- #3 for what is left of step 7. `nvchad.tabufline` specifically is
--- superseded by `ui.tabline.render` as of this round, though NvChad's own
--- tabufline autocmds (also maintaining `vim.t.bufs`) remain registered too
--- until NvChad itself comes out -- redundant bookkeeping, not a conflict:
--- both compute the same list independently.
---
--- Registered under the name "personal" so `:UI variant`/`:UI variants`
--- (ui.nvim's own runtime switcher) see it next to ui.nvim's four shipped,
--- generic presets -- see `ui.config.variants`.
---
--- `ui.setup({ usrcmds = true })`, not `{ all = true }`: `usrcmds` is the
--- `:UI` command family (theme, transparency, variant switching).
--- `keymaps` is deliberately left off -- ui.nvim's own buffer/tab keymaps
--- (`<Tab>`/`<S-Tab>`, `<leader>tr`/`<leader>tl`) would double-bind
--- whatever NvChad's own tabufline already owns, the exact last-writer-wins
--- problem this repo has been resolving elsewhere.
--- `ui.bindings.keymaps.tabufline.state.setup()` is called directly (not
--- via `ui.setup({ keymaps = true })`, which the paragraph above rules out)
--- because the tabline renderer needs `vim.t.bufs` maintained regardless of
--- whether ui.nvim's own buffer/tab keymaps are bound.

local M = {}

---@return nil
function M.setup()
  local notify = require("lib.nvim.notify").create("[config.ui_statusline]")

  local ok, err = pcall(function()
    require("ui").setup({ usrcmds = true })
    require("ui.config.variants").register("personal", require("config.ui_statusline.variant"))
    local assembled = require("ui.config").setup({ variant = "personal" })
    require("ui.bindings.keymaps.tabufline.state").setup()
    require("ui.statusline.render").enable(assembled.ui.statusline)
    require("ui.tabline.render").enable(assembled.ui.tabline)
  end)

  if not ok then
    notify.error("Failed to wire the personal ui.nvim statusline/tabline: " .. tostring(err))
  end
end

return M
