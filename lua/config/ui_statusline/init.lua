---@module 'config.ui_statusline'
--- Wires this host's own statusline into ui.nvim, additively: NvChad/
--- wkdnvchad keep booting exactly as before, and this simply takes over
--- `vim.o.statusline` afterward -- at UIReady, once everything else
--- (including NvChad's own chadrc-driven statusline) has already finished
--- loading, so it wins without touching `chadrc.lua` or NvChad at all.
---
--- Registered under the name "personal" so `:UI variant`/`:UI variants`
--- (ui.nvim's own runtime switcher) see it next to ui.nvim's four shipped,
--- generic presets -- see `ui.config.variants`.
---
--- `ui.setup({ usrcmds = true })`, not `{ all = true }`: `usrcmds` is the
--- `:UI` command family (theme, transparency, variant switching).
--- `keymaps` is deliberately left off -- ui.nvim's own buffer/tab keymaps
--- (`<Tab>`/`<S-Tab>`, `<leader>tr`/`<leader>tl`) would double-bind
--- whatever wkdnvchad/NvChad's own tabufline already owns, the exact
--- last-writer-wins problem this repo has been resolving elsewhere.
---
--- This is deliberately NOT roadmap step 7 (removing NvChad/wkdnvchad
--- entirely) -- see ui.nvim's own ROADMAP.md, open decision #3. It only
--- makes this one statusline the one actually drawn.

local M = {}

---@return nil
function M.setup()
  local notify = require("lib.nvim.notify").create("[config.ui_statusline]")

  local ok, err = pcall(function()
    require("ui").setup({ usrcmds = true })
    require("ui.config.variants").register("personal", require("config.ui_statusline.variant"))
    local assembled = require("ui.config").setup({ variant = "personal" })
    require("ui.statusline.render").enable(assembled.ui.statusline)
  end)

  if not ok then
    notify.error("Failed to wire the personal ui.nvim statusline: " .. tostring(err))
  end
end

return M
