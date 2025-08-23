-- /config/neotree/open_fm/win.lua
---@module 'config.neotree.open_fm.win'
--- Windows-specific "open in file manager" for Neo-tree.
--- Selects files in Explorer and opens folders directly.
--- Designed to be called from a Neo-tree window mapping with `state`.

---@version 1.0.0

---@class NeoTreeFMWin
---@field open fun(state: table): boolean
---@field _ @private
local M = {}

---@private
---@param p string
---@return string
local function to_winpath(p)
  -- Expand to absolute path, strip wrapping quotes, normalize slashes
  p = vim.fn.fnamemodify(p, ":p")
  p = p:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  p = p:gsub("/", "\\")
  return p
end

---@private
---@param argv string[]
---@param on_fail fun(code: integer|nil, stderr: string|nil)
local function run_or_fallback(argv, on_fail)
  -- Prefer vim.system (Neovim ≥ 0.10), else jobstart as best-effort fire-and-forget
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

---@private
---@param state table
---@return string path
local function get_node_path(state)
  ---@type any
  local node = state and state.tree and state.tree:get_node() or nil
  return node and (node.path or node:get_id()) or ""
end

--- Open the selected node in Windows Explorer.
--- Files are revealed with "/select,<path>", folders are opened directly.
--- If the direct explorer call returns a non-zero exit code, a fallback via
--- "cmd.exe /C start" is attempted to at least open the directory.
---@param state table -- Neo-tree window state passed by the mapping
---@return boolean ok -- true if a launch was attempted; false on early error
function M.open(state)
  if not (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) then
    vim.notify("Open in Explorer: Windows only", vim.log.levels.WARN)
    return false
  end

  local raw = get_node_path(state)
  if raw == "" then
    vim.notify("Open in Explorer: no path under cursor", vim.log.levels.WARN)
    return false
  end

  local abs = to_winpath(raw)
  local is_dir = (vim.fn.isdirectory(abs) == 1)
  local dir    = is_dir and abs or to_winpath(vim.fn.fnamemodify(abs, ":h"))

  ---@type string[]
  local primary = is_dir and { "explorer.exe", dir } or { "explorer.exe", "/select," .. abs }
  ---@type string[]
  local fallback = { "cmd.exe", "/C", "start", "", dir }

  run_or_fallback(primary, function(_code, _stderr)
    -- Silent fallback; Explorer exit codes are unreliable on some systems
    if vim.system then
      vim.system(fallback, { detach = true }, function(_) end)
    else
      vim.fn.jobstart(fallback, { detach = true })
    end
  end)

  return true
end

return M
