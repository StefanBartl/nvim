---@module 'wkdoptions'
--- Entry point that enables the two configuration modules:
---   - wkdoptions/hl_config (visual/UX features & highlight groups)
---   - wkdoptions/options_config   (editor options & global toggles)
--- Public API:
---   require('wkdoptions').setup({ highlights = true, options = true })
--- Notes:
---   * 'higlights' is accepted as alias for 'highlights' (typo-friendly).
---   * Modules register their own user commands and autocmds only when enabled.

local M = {}

--- Enable selected subsystems.
---@param opts WKDOptions.EnableArgs|nil
---@return nil
function M.setup(opts)
  opts = opts or {}
  local enable_hl = (opts.highlights ~= nil) and opts.highlights or (opts.higlights ~= nil and opts.higlights or false)
  local enable_opt = (opts.options ~= nil) and opts.options or false

  if enable_hl then
    require("wkdoptions.hl_config").enable()
  end
  if enable_opt then
    require("wkdoptions.options_config").enable()
  end
end

return M
