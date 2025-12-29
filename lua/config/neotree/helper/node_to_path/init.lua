---@module 'config.neotree.helper.node_to_path'
--- Helper module to compute paths from Neo-tree nodes
--- Can return absolute paths, relative paths (to project root or cwd), or base directories

local fn = vim.fn
local relpath = require("lib.fs.relpath")

---@alias mode 'absolute' | 'relative'

---@param node table Neo-tree node (state.tree:get_node())
---@param mode mode return type, 'absolute' or 'relative'
---@param opts? table optional settings
--- opts.base_dir boolean: if true, return directory instead of file path
---@return string|nil path, string|nil optional message if nothing found
return function (node, mode, opts)
  opts = opts or {}
  if not node then
    return nil, "No node provided"
  end

  local path = node.path or node:get_id()
  if not path or path == "" then
    return nil, "Node path is empty"
  end

  -- if base_dir requested
  if opts.base_dir then
    path = (fn.isdirectory(path) == 1) and path or fn.fnamemodify(path, ":h")
  end

  if mode == "absolute" then
    path = fn.fnamemodify(path, ":p")
  elseif mode == "relative" then
    local base = (vim.uv or vim.loop).cwd() or fn.getcwd()
    local ok_root, Root = pcall(require, "utils.lv_project_root")
    if ok_root and type(Root.get) == "function" then
      base = Root.get(0) or base
    end
    path = relpath(path, base)
  else
    return nil, "Unknown mode: " .. tostring(mode)
  end

  return path
end
