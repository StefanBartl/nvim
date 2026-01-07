---@module 'config.neotree.utils.path'
---@brief Unified path operations: normalize, escape, convert, transform

local M = {}

local platform = require("config.neotree.utils.platform")

---Normalize path for reliable comparisons
---@param path string|nil
---@return string
function M.normalize(path)
  return vim.fs.normalize(path or "")
end

---Convert to absolute path
---@param path string
---@return string
function M.to_absolute(path)
  return vim.fn.fnamemodify(path, ":p")
end

---Convert to Unix-style path (for cross-platform consistency)
---@param path string
---@return string
function M.to_unix_path(path)
  path = M.to_absolute(path)
  path = path:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  return path
end

---Convert to Windows-style path
---@param path string
---@return string
function M.to_win_path(path)
  path = M.to_absolute(path)
  path = path:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  return (path:gsub("/", "\\"))
end

---Get parent directory
---@param path string
---@return string
function M.get_parent(path)
  return vim.fn.fnamemodify(path, ":h")
end

---Ensure path is a directory (converts file to parent dir)
---@param path string
---@return string
function M.ensure_dir(path)
  local uv = vim.uv or vim.loop
  local st = uv.fs_stat(path)

  if st and st.type ~= "directory" then
    local parent = M.get_parent(path)

    if parent == "" or parent == "." then
      -- uv.cwd() may return nil, vim.fn.getcwd() always returns string
      return uv.cwd() or vim.fn.getcwd()
    end

    return parent
  end

  return path
end

---Convert to relative path
---@param path string
---@param base string|nil Base directory (default: cwd or project root)
---@return string
function M.to_relative(path, base)
  if not base then
    base = (vim.uv or vim.loop).cwd()

    -- Try project root first
    local ok_root, Root = pcall(require, "config.neotree.helper.lv_project_root")
    if ok_root and type(Root.get) == "function" then
      base = Root.get(0) or base
    end
  end

  ---@cast base string

  local abs_path = M.normalize(M.to_absolute(path)):gsub("\\", "/"):gsub("/$", "")
  local abs_base = M.normalize(M.to_absolute(base)):gsub("\\", "/"):gsub("/$", "")

  if abs_path:sub(1, #abs_base) == abs_base then
    local rel = abs_path:sub(#abs_base + 2)
    return rel == "" and "." or rel
  end

  return vim.fn.fnamemodify(abs_path, ":~:.")
end

---Extract path from Neo-tree node with transformation
---@param node table Neo-tree node
---@param mode "absolute"|"relative"|"base_absolute"|"base_relative"
---@param opts? {base_dir?: string}
---@return string|nil path, string|nil error_msg
function M.from_node(node, mode, opts)
  opts = opts or {}

  if not node then
    return nil, "No node provided"
  end

  local path = node.path or (node.get_id and node:get_id())
  if not path or path == "" then
    return nil, "Node path is empty"
  end

  -- Handle "base_" prefix (convert file to directory)
  local is_dir = vim.fn.isdirectory(path) == 1
  if mode:match("^base_") then
    path = is_dir and path or M.get_parent(path)
    mode = mode:gsub("^base_", "")
  end

  -- Apply transformation
  if mode == "absolute" then
    return M.to_absolute(path)
  elseif mode == "relative" then
    return M.to_relative(path, opts.base_dir)
  else
    return nil, "Unknown mode: " .. tostring(mode)
  end
end

---Escape shell argument (cross-platform)
---@param path string
---@return string
function M.escape_shell_arg(path)
  if platform.is_windows() then
    return "'" .. path:gsub("'", "''") .. "'"
  else
    return "'" .. path:gsub("'", "'\\''") .. "'"
  end
end

---Quote path if it contains spaces
---@param path string
---@return string
function M.quote_if_needed(path)
  if path:find("[%s]") then
    return '"' .. path .. '"'
  end
  return path
end

return M
