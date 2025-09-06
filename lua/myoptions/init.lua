---@module 'myoptions'
--- Entry point that enables the two configuration modules:
---   - MyOptions/Highlight_Cfg (visual/UX features & highlight groups)
---   - MyOptions/Options_Cfg   (editor options & global toggles)
--- Public API:
---   require('myoptions').enable({ highlights = true, options = true })
--- Notes:
---   * 'higlights' is accepted as alias for 'highlights' (typo-friendly).
---   * Modules register their own user commands and autocmds only when enabled.

local M = {}

---@class MyOptionsEnableArgs
---@field highlights boolean|nil
---@field higlights boolean|nil  -- alias
---@field options boolean|nil

--- Enable selected subsystems.
---@param opts MyOptionsEnableArgs|nil
---@return nil
function M.enable(opts)
  opts = opts or {}
  local enable_hl = (opts.highlights ~= nil) and opts.highlights or (opts.higlights ~= nil and opts.higlights or false)
  local enable_opt = (opts.options ~= nil) and opts.options or false

  if enable_hl then
    require("myoptions.Highlight_Cfg").enable()
  end
  if enable_opt then
    require("myoptions.Options_Cfg").enable()
  end
end

return M
