---@module 'config.neotree.open_fm.unix'
--- Linux/macOS-specific "open in file manager" for Neo-tree.
--- Opens files or folders with the system default file manager
--- using `xdg-open` (Linux) or `open` (macOS).
--- Designed to be called from a Neo-tree window mapping with `state`.

local node_utils = require("config.neotree.utils.node")

local M = {}

---@private
---@param p string
---@return string
local function to_unixpath(p)
  -- Expand to absolute path and strip quotes
  p = vim.fn.fnamemodify(p, ":p")
  p = p:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  return p
end

---@private
---@param argv string[]
---@param on_fail fun(code: integer|nil, stderr: string|nil)
local function run_or_fallback(argv, on_fail)
  if vim.system then
    vim.system(argv, { text = true }, function(obj)
      if obj.code ~= 0 then
        on_fail(obj.code, obj.stderr)
      end
    end)
  else
    local ok = vim.fn.jobstart(argv, { detach = true })
    if ok <= 0 then
      on_fail(nil, "jobstart failed")
    end
  end
end

--- Open the selected node in system file manager (Linux/macOS).
---@param state table -- Neo-tree window state passed by the mapping
---@return boolean ok -- true if a launch was attempted; false on early error
function M.open(state)
  if not (vim.fn.has("unix") == 1 or vim.fn.has("mac") == 1) then
    vim.notify("Open in File Manager: Unix only", vim.log.levels.WARN)
    return false
  end

  -- Get current node and resolve path
  local node = state and state.current_node or nil
  local path, _ = node_utils.get_path(node)
  if path == "" then
    vim.notify("Open in File Manager: no path under cursor", vim.log.levels.WARN)
    return false
  end

  local abs = to_unixpath(path)

  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = { "open", abs }
  else
    cmd = { "xdg-open", abs }
  end

  run_or_fallback(cmd, function(_, stderr)
    vim.notify("Open in File Manager failed: " .. (stderr or ""), vim.log.levels.ERROR)
  end)

  return true
end

return M
