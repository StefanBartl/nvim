---@module 'lsp.servers.lua_ls.debug'
--- Utilities for debugging LuaLS setup: root detection and workspace library inspection.

local uv = vim.uv or vim.loop

-- filesystem helpers
local is_subpath = require("lib.filesystem.is_subpath")
local find_upward_dir = require("lib.filesystem.find_upward_dir")

---@class LuaLsDebug
local M = {}

-- ===================================================================
-- ROOT RESOLUTION
-- ===================================================================

---@param start_dir? string
---@return string|nil
local function strict_root(start_dir)
  -- start_dir fallback to current working directory
  local dir = start_dir or (uv.cwd and uv.cwd()) or vim.fn.getcwd()
  if not dir or dir == "" then
    return nil
  end

  -- check VCS roots
  local vcs_root = find_upward_dir({ ".git", ".hg", ".svn" }, dir)
  if vcs_root then
    return vcs_root
  end

  -- check Lua project markers
  local lua_markers = find_upward_dir({ ".luarc.json", ".neoconf.json", "selene.toml", "stylua.toml" }, dir)
  if lua_markers then
    return lua_markers
  end

  -- fallback to standard Neovim config directory if applicable
  local stdconfig = vim.fn.stdpath("config")
  if is_subpath(dir, stdconfig) then
    return stdconfig
  end

  -- fallback to provided start_dir
  return dir
end

--- Get root for current buffer
---@param bufnr? integer
---@return string|nil
function M.root_for_buf(bufnr)
  local fname = ""
  if type(bufnr) == "number" then
    fname = vim.api.nvim_buf_get_name(bufnr) or ""
  end
  return strict_root(fname ~= "" and vim.fs.dirname(fname) or nil)
end

---@nodiscard
---@return string|nil
function M.debug_root()
  return strict_root()
end

-- ===================================================================
-- WORKSPACE LIBRARY
-- ===================================================================

--- Build workspace library for given root
---@param root? string
---@return string[]
function M.debug_library(root)
  root = root or strict_root()
  if not root then
    return {}
  end
  local ok, build_library = pcall(require, "lsp.servers.lua_ls.build_library")
  if not ok or type(build_library) ~= "function" then
    return {}
  end
  return build_library(root)
end

-- ===================================================================
-- UTILITIES
-- ===================================================================

--- Print current debug info to Neovim message area
---@param bufnr? integer
---@return nil
function M.print_debug_info(bufnr)
  local root = M.root_for_buf(bufnr)
  local lib = M.debug_library(root)
  vim.notify("LuaLS Debug Info:", vim.log.levels.INFO)
  vim.notify("Root: " .. tostring(root), vim.log.levels.INFO)
  vim.notify("Library paths: " .. table.concat(lib, ", "), vim.log.levels.INFO)
end

return M
