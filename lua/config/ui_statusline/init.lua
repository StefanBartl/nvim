---@module 'config.ui_statusline'
--- Wires this host's own statusline AND tabline into ui.nvim, at UIReady.
--- Module name kept as "ui_statusline" rather than renamed for the tabline
--- addition -- it is one host wiring point for everything `ui.nvim` draws,
--- and a rename would ripple into init.lua's startup phase and this file's
--- own path for no functional gain.
---
--- **Historical, kept for the record (all true when written, none of it
--- true any more as of roadmap step 7's later rounds -- NvChad/NvChad,
--- base46 and NvChad's own nvchad.plugins bundle are gone entirely):**
--- this phase originally ran additively alongside NvChad's own,
--- chadrc-less-default statusline/tabline, winning the UIReady race by
--- running last without touching NvChad itself; NvChad's own tabufline
--- autocmds kept maintaining `vim.t.bufs` redundantly alongside
--- `ui.tabline.render`'s equivalent; and NvChad's plugin itself plus nvdash,
--- LSP signature and colorify were still in use, undecided. See ui.nvim's
--- own NOTES.md for the full closing of each of those.
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
--- `true` -- every ui.nvim keymap at its shipped default, no per-action
--- opt-in needed (see `ui.bindings.keymaps`'s own doc comment,
--- `ui.nvim@<pending>`) -- if the spec does not set the field at all.
---
--- `sticky = {...}` turns on `ui.context`, the sticky code-context overlay
--- that replaced `nvim-treesitter-context` on 2026-09-19 (the enclosing
--- function/class/loop lines, or in Markdown the heading chain, pinned over
--- the window's first rows). `:UI sticky` toggles it for the session, `:UI
--- sticky depth <1-6>` / `:UI sticky lines [ft] <n>` change how deep it
--- reaches, `:UI sticky up [n]` jumps to the n-th enclosing scope. It is
--- explicit-only in `ui.setup` -- `all = true` would not turn it on -- so it
--- is named here rather than in the spec; `sticky = false` opts out.
---
--- `position`/`style`/`chips` (new in ui.nvim 2026-09-24): where the overlay
--- sits and how it looks. `position.anchor = "top-right"` moves it into a
--- compact box pinned to the window's top-right corner instead of spanning
--- the full width at the top -- other anchors: `"top"` (the old default,
--- full width), `"bottom"`, `"top-left"`, `"top-center"`, `"bottom-left"`,
--- `"bottom-right"`, `"bottom-center"`; `position.row`/`col` override the
--- anchor outright for an exact spot. `style = "chips"` draws coloured
--- chips (the same visual language as `lsp.nvim`'s winbar breadcrumb)
--- instead of mimicking real buffer lines. `chips.layout = "stack"` puts one
--- chip per line (so a long nested heading's own truncation never eats into
--- a shorter one sharing the same line, unlike `"row"`, the one-shared-line
--- default); `chips.shape` is `"rounded"` (default, caps like the winbar) or
--- `"rect"` (flat block, no caps) -- trial, easy to flip back. See
--- `ui.nvim/docs/configuration.md`, Context section.
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
    local keymaps_opts = true
    if spec and spec.keymaps ~= nil then
      keymaps_opts = spec.keymaps
    end

    require("ui").setup({
      usrcmds = true,
      keymaps = keymaps_opts,
      -- The sticky code context (what nvim-treesitter-context did until
      -- 2026-09-19): explicit-only in ui.setup, never under `all`, because it
      -- draws over the buffer's first rows. `max_lines` is the row cap: 3 for
      -- code (the old spec's cap), 6 for Markdown so a whole H1..H6 chain
      -- fits. `headings.max_level` is the deepest Markdown heading level that
      -- gets pinned (1..6). `persist` keeps what `:UI sticky depth|lines` set
      -- across restarts (stdpath("state")/ui.nvim/sticky.json, on top of the
      -- values here); `:UI sticky reset` drops it again.
      sticky = {
        max_lines = { default = 3, markdown = 6 },
        headings = { max_level = 6 },
        persist = true,
        position = { anchor = "top-right" },
        style = "chips",
        chips = { layout = "stack" }, -- trial: one chip per line instead of one shared row; shape = "rounded" stays the default
      },
    })
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
