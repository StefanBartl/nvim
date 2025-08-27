---@module 'config.neotree.open_fm.wsl'
--- WSL-specific "open in file manager" for Neo-tree.
--- Converts Linux paths to Windows paths via `wslpath -w`
--- and opens Windows Explorer (file reveal or folder open).
--- Falls back to `cmd.exe /C start` and optionally `wslview`/`xdg-open`.

local M ---@type NeoTreeWslFM
M = { _cfg = { backend = "explorer", silent = true } }

---@private
---@return boolean
local function is_wsl()
  -- Prefer user helper if present
  local ok, mod = pcall(require, "lib.is_wsl")
  if ok and type(mod) == "function" then
    local ok2, ans = pcall(mod)
    if ok2 and type(ans) == "boolean" then return ans end
  end
  -- Fallback detection
  local has = vim.fn.has
  local uname = (vim.uv or vim.loop).os_uname().release:lower()
  return has("wsl") == 1 or uname:find("microsoft", 1, true) ~= nil
end

---@private
---@param s string
---@return string
local function quote_if_needed(s)
  if s:find("[%s]") then
    -- Wrap in quotes if spaces exist; Explorer supports quoted path segments
    return '"' .. s .. '"'
  end
  return s
end

---@private
---@param p UnixPath
---@return WinPath|nil
local function to_windows_path(p)
  -- Normalize to absolute, strip quotes to keep system calls clean
  p = vim.fn.fnamemodify(p, ":p")
  p = p:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")

  -- Convert using wslpath; reliable on all WSL distros
  local out = vim.fn.systemlist({ "wslpath", "-w", p })
  if vim.v.shell_error == 0 and out and out[1] and out[1] ~= "" then
    return out[1]
  end

  -- Fallback: /mnt/c/... → C:\...
  local drv, rest = p:match("^/mnt/([a-zA-Z])/(.*)")
  if drv and rest then
    return (drv:upper() .. ":\\" .. rest:gsub("/", "\\"))
  end

  -- Last resort: unchanged; some setups may still accept UNC-like paths
  return p
end

---@private
---@param argv string[]
---@param on_fail fun(code: integer|nil, stderr: string|nil)
local function run_detached(argv, on_fail)
  if vim.system then
    vim.system(argv, { text = true }, function(obj)
      if obj.code ~= 0 then on_fail(obj.code, obj.stderr) end
    end)
  else
    local job = vim.fn.jobstart(argv, { detach = true })
    if job <= 0 then on_fail(nil, "jobstart failed") end
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

---@nodiscard
---@param cfg WslOpenConfig|nil
function M.setup(cfg)
  if type(cfg) == "table" then
    if cfg.backend == "auto" or cfg.backend == "explorer" or cfg.backend == "wslview" then
      M._cfg.backend = cfg.backend
    end
    if type(cfg.silent) == "boolean" then
      M._cfg.silent = cfg.silent
    end
  end
end

--- Open the selected node using Windows Explorer from within WSL.
--- Files are revealed with "/select,<path>", folders are opened directly.
---@param state table -- Neo-tree window state passed by the mapping
---@return boolean ok -- true if a launch was attempted; false on early error
function M.open(state)
  if not is_wsl() then
    if not M._cfg.silent then
      vim.notify("Open in File Manager (WSL): WSL only", vim.log.levels.WARN)
    end
    return false
  end

  local raw = get_node_path(state)
  if raw == "" then
    if not M._cfg.silent then
      vim.notify("Open in File Manager (WSL): no path under cursor", vim.log.levels.WARN)
    end
    return false
  end

  local abs_win = to_windows_path(raw)
  if not abs_win or abs_win == "" then
    vim.notify("Open in File Manager (WSL): path conversion failed", vim.log.levels.ERROR)
    return false
  end

  local is_dir = (vim.fn.isdirectory(raw) == 1) -- probe Linux path; works inside WSL
  local dir_win = is_dir and abs_win or to_windows_path(vim.fn.fnamemodify(raw, ":h"))

  -- Primary launcher selection
  local backend = M._cfg.backend
  if backend == "auto" then
    -- Use explorer if available, otherwise try wslview
    backend = "explorer"
  end

  if backend == "wslview" then
    -- Optional: wslview opens using Windows default handlers; dirs support varies by version
    local target = is_dir and (dir_win or abs_win) or abs_win
    run_detached({ "wslview", target }, function(_, stderr)
      vim.notify("wslview failed: " .. (stderr or ""), vim.log.levels.WARN)
    end)
    return true
  end

  -- Default: explorer.exe
  local primary = is_dir
      and { "explorer.exe", quote_if_needed(dir_win or abs_win) }
      or { "explorer.exe", "/select," .. quote_if_needed(abs_win) }

  local fallback = { "cmd.exe", "/C", "start", "", quote_if_needed(dir_win or abs_win) }

  run_detached(primary, function(_, _)
    -- Explorer’s exit codes can be flaky; do a best-effort fallback
    if vim.system then
      vim.system(fallback, { detach = true }, function(_) end)
    else
      vim.fn.jobstart(fallback, { detach = true })
    end
  end)

  return true
end

return M

