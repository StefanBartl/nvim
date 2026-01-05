---@module 'custom.markdown.config'
--- Centralized configuration with validation and safe defaults.

local M = {}

---@type Custom.MD.Config
local Defaults = {
  map_double_asterisk = true,
  keep_inner_selection = true,
  protect_h1 = false,
  use_zf_override = true,
  enable_autocmds = true,
  enable_keymaps = true,
  ft_only = true,
  ensure_headline_spacing = true, -- ensure whitespace + separator before H2+ headlines
}

---@type Custom.MD.Config
local State = vim.deepcopy(Defaults)

---@param opts table
---@return nil
function M.setup(opts)
  if type(opts) ~= "table" then
    return
  end
  for k, v in pairs(opts) do
    if Defaults[k] ~= nil then
      State[k] = v
    end
  end
end

---@return Custom.MD.Config
function M.get()
  return State
end

return M
