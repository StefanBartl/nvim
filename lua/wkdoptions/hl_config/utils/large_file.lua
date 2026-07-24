---@module 'wkdoptions.hl_config.utils.large_file'
--- File size guards with memoization and safe fs_stat calls.

local lazy = require("lib.lua.lazy")
local memo = lazy.require("lib.lua.memo")

local M = {}

--- Get file size in KiB (memoized per path)
---@nodiscard
---@param path string
---@return integer|nil kb
local get_size_kb = memo.fn(function(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  local uv = vim.uv or vim.loop
  local ok, st = pcall(uv.fs_stat, path)

  if not ok or not st or type(st.size) ~= "number" then
    return nil
  end

  return math.floor(st.size / 1024)
end, { weak = "k", size = 128 })

--- Check if buffer exceeds size threshold
---@nodiscard
---@param bufnr integer|nil
---@param limit_kb integer
---@return boolean
function M.exceeds(bufnr, limit_kb)
  bufnr = bufnr or 0

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return false -- unnamed buffers are always small
  end

  local kb = get_size_kb(path)
  if not kb then
    return false -- can't stat = assume safe
  end

  return kb > limit_kb
end

--- Check against global large_file_kb threshold
---@nodiscard
---@param bufnr integer|nil
---@param cfg WKDOptions.HL_CFG
---@return boolean
function M.is_large(bufnr, cfg)
  local limit = cfg.large_file_kb or 5000
  return M.exceeds(bufnr, limit)
end

--- Check against feature-specific threshold (with global fallback)
---@nodiscard
---@param bufnr integer|nil
---@param feature_limit integer|nil -- nil = use global
---@param cfg WKDOptions.HL_CFG
---@return boolean
function M.is_large_for_feature(bufnr, feature_limit, cfg)
  local limit = feature_limit or cfg.large_file_kb or 5000
  return M.exceeds(bufnr, limit)
end

return M
