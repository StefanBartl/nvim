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
--- `ui.setup({ usrcmds = true, keymaps = ... })`, not `{ all = true }`:
--- `usrcmds` is the `:UI` command family (theme, transparency, variant
--- switching). `keymaps` used to be hard-coded off here on the assumption
--- that ui.nvim's own buffer/tab keymaps (`<Tab>`/`<S-Tab>`,
--- `<leader>tr`/`<leader>tl`) would double-bind whatever NvChad's own
--- tabufline already owns -- checked, and that assumption was wrong: NvChad's
--- own `<Tab>`/`<S-Tab>` only exist inside completion (`nvchad.blink.config`),
--- never in normal mode. The real cause of `<Tab>`/`<S-Tab>` going dark after
--- `lua/wkdnvchad/` was removed (step 7's first round) was simpler and worse:
--- `lua/wkdnvchad/mappings/init.lua` was the ONLY thing ever binding them in
--- this host, and deleting `wkdnvchad/` deleted that with it -- ui.nvim's own
--- equivalent was never turned on to replace it.
---
--- `opts.keymaps` now comes from this plugin's own installation spec
--- (`plugins/personal/init.lua`'s `"StefanBartl/ui.nvim"` entry) rather than
--- being fixed here, so enabling/disabling it or remapping one action is a
--- one-line edit in the spec, not a change to this wiring file. A custom
--- field there (`keymaps = {...}`), not lazy.nvim's own `opts`/`config`:
--- those would run `require("ui").setup(opts)` at plugin-load time, before
--- this host's own UIReady convention says keymaps may register (see
--- `bindings.mappings`'s identical reasoning in `init.lua`). Falls back to
--- `{ all = true }` -- every ui.nvim keymap at its shipped default -- if the
--- spec does not set the field at all.
---
--- `ui.bindings.keymaps.tabufline.state.setup()` is still called directly,
--- unconditionally, regardless of `opts.keymaps`: the tabline renderer needs
--- `vim.t.bufs` maintained even when a host turns ui.nvim's own keymaps off
--- entirely (`keymaps = false` in the spec).

local M = {}

---@return nil
function M.setup()
  local notify = require("lib.nvim.notify").create("[config.ui_statusline]")

  local ok, err = pcall(function()
    local ok_lazy, lazy_config = pcall(require, "lazy.core.config")
    local spec = ok_lazy and lazy_config.plugins["ui.nvim"]
    -- Not `(spec and spec.keymaps ~= nil) and spec.keymaps or default`: that
    -- and/or idiom breaks the moment the spec's own value IS `false` (which
    -- means something here -- "off entirely") since `X and false or Y`
    -- always evaluates to `Y`, silently discarding the `false`.
    local keymaps_opts = { all = true }
    if spec and spec.keymaps ~= nil then
      keymaps_opts = spec.keymaps
    end

    require("ui").setup({ usrcmds = true, keymaps = keymaps_opts })
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
