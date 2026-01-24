---@module 'uv_doc.config'
---@brief Configuration management for uvdoc

local M = {}

---@type UVDocConfig
local DEFAULTS = {
  open = "float",
  max_bytes = 512 * 1024,
  user_agent = "uvdoc.nvim/0.4 (+https://docs.libuv.org/en/v1.x/)",
  timeout = 15000,
}

---@type UVDocConfig
local CFG = vim.deepcopy(DEFAULTS)

--- Gets current configuration
---@nodiscard
---@return UVDocConfig
function M.get()
  return CFG
end

--- Updates configuration
---@param opts UVDocConfig|table
function M.set(opts)
  CFG = vim.tbl_deep_extend("force", CFG, opts or {})
end

--- Resets to defaults
function M.reset()
  CFG = vim.deepcopy(DEFAULTS)
end

return M
