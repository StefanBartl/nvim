---@module 'bindings.usrcmds.context_open.util'
--- Small shared helper: force-load a lazy.nvim plugin spec that is
--- `cmd`-gated (not `ft`/`event`-gated), so a provider's very first
--- invocation in a session still finds the plugin's Lua modules on the
--- runtime path. `open.nvim` and `pdfport.nvim` are both `cmd`-only in
--- plugins/personal/init.lua; calling e.g. `require("open.context")` before
--- `:Open` has ever run would otherwise fail with "module not found".
---
--- Cheap and idempotent: `lazy.core.loader.load` checks `plugin._.loaded`
--- itself and no-ops when the plugin is already on the runtime path (the
--- common case -- gopath.nvim/markdown.nvim/images.nvim are already loaded
--- via `event`/`ft` by the time a keymap can fire).

local M = {}

---@param plugin_name string  lazy.nvim spec name, e.g. "open.nvim"
---@return nil
function M.ensure_loaded(plugin_name)
  local ok, loader = pcall(require, "lazy.core.loader")
  if not ok then
    return
  end
  pcall(loader.load, plugin_name, { source = "context_open" })
end

return M
