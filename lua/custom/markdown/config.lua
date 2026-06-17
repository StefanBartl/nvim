---@module 'custom.markdown.config'
--- Centralized configuration with validation and safe defaults.

local M = {}


---@type Custom.MD.Config
local Defaults = {
  map_double_asterisk      = true,
  keep_inner_selection     = true,
  protect_h1               = false,
  use_zf_override          = true,
  enable_autocmds          = true,
  enable_keymaps           = true,
  ft_only                  = true,
  ensure_headline_spacing  = true,
  blockquote_hl = {
    -- `>` marker: green
    marker_fg     = "#39FF14",
    marker_bold   = false,
    marker_italic = false,
    -- text after `>`: normal fg, dark green background (auto-derived if nil)
    text_bg       = nil,   -- auto: 20% dim of marker_fg → "#152012"
    text_fg       = nil,   -- nil: inherits Normal fg
    text_italic   = false,
    text_bold     = true,
  },
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
      if type(Defaults[k]) == "table" and type(v) == "table" then
        State[k] = vim.tbl_extend("force", vim.deepcopy(Defaults[k]), v)
      else
        State[k] = v
      end
    end
  end
end

---@return Custom.MD.Config
function M.get()
  return State
end

return M
