---@module 'lsp.servers.lua_ls.build_library'
-- Discover project-local "types"/"@types"

-- filesystem helpers
local is_dir = require("lib.filesystem.is_dir")
local join = require("lib.filesystem.joinpath")
local is_subpath = require("lib.filesystem.is_subpath")
local find_type_dirs = require("lsp.servers.lua_ls.find_type_dirs")
-- Table helpers
local dedup = require("lib.tables.dedup")

---@param root string|nil
---@return string[]
return function(root)
  local lib = vim.api.nvim_get_runtime_file("", true) ---@type string[]

  local stdconfig = vim.fn.stdpath("config")
  if root and is_subpath(root, stdconfig) then
    local cfg_atypes = join({ stdconfig, "lua", "@types" })
    local cfg_types = join({ stdconfig, "lua", "types" })
    if is_dir(cfg_atypes) then
      lib[#lib + 1] = cfg_atypes
    end
    if is_dir(cfg_types) then
      lib[#lib + 1] = cfg_types
    end
  end

  if root and is_dir(root) then
    local lua_root = join({ root, "lua" })
    local scan_base = is_dir(lua_root) and lua_root or root
    local found = find_type_dirs(scan_base, { max_results = 200, max_depth = 12 })
    for i = 1, #found do
      lib[#lib + 1] = found[i]
    end
  end

  return dedup(lib)
end
