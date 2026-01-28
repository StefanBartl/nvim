---@module 'config.neotree.cwd_sync.buffer_resolver'
---@brief Buffer → Dir/Path resolution with project root support

local buffer_utils = require("config.neotree.utils.buffer")

local M = {}

---Derive directory and path with project root support
---@param buf integer
---@param use_project_root boolean
---@param fallback_to_bufdir boolean
---@return string|nil dir
---@return string|nil path
function M.resolve(buf, use_project_root, fallback_to_bufdir)
  local ctx = buffer_utils.get_buffer_context(buf)
  if not ctx then
    return nil, nil
  end

  local dir = ctx.dir

  if use_project_root then
    local ok, Root = pcall(require, "config.neotree.actions.project_root")
    if ok and type(Root.get) == "function" then
      local root = Root.get(buf)
      if root and root ~= "" then
        dir = root
      elseif not fallback_to_bufdir then
        return nil, nil -- No root and no fallback
      end
    end
  end

  return dir, ctx.file
end

return M
