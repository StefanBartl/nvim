---@module 'config.neotree.fzf_grep_picker'
--- Neo-tree → fzf-lua live_grep scoped to the selected node's directory.
--- Works on Linux, macOS, Windows, and WSL. If the node is a file, the parent
--- directory is used; if it is a directory, that directory is used directly.

local M = {}

--==============================================================================
-- Platform helpers
--==============================================================================

---@private
---@return boolean
local function is_windows()
  -- True for native Windows builds of Neovim
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

---@private
---@return boolean
local function is_wsl()
  -- Detect WSL by feature flag or kernel release string
  local uv = (vim.uv or vim.loop)
  local ok_uname, uts = pcall(uv.os_uname)
  local rel = (ok_uname and uts and uts.release) and tostring(uts.release):lower() or ""
  return vim.fn.has("wsl") == 1 or rel:find("microsoft", 1, true) ~= nil
end

---@private
---@return string
local function safe_cwd()
  -- Always return a non-nil current working directory
  local uv = (vim.uv or vim.loop)
  local cwd = uv.cwd()
  if type(cwd) == "string" and cwd ~= "" then
    return cwd
  end
  return vim.fn.getcwd()
end

--==============================================================================
-- Path normalization
--==============================================================================

---@private
---@param p string
---@return string
local function abs_path(p)
  -- Make an absolute path using Neovim/Vim semantics (handles ~ etc.)
  ---@type string
  local abs = vim.fn.fnamemodify(p, ":p")
  return abs
end

---@private
---@param any_path string
---@return string dir_abs
local function ensure_dir(any_path)
  -- If it's a file path, return its parent directory; if it's already a
  -- directory, return as-is. If the parent is ambiguous, fall back to CWD.
  local uv = (vim.uv or vim.loop)
  local st = uv.fs_stat(any_path)
  if st and st.type ~= "directory" then
    local parent = vim.fn.fnamemodify(any_path, ":h")
    if parent == "" or parent == "." then
      return safe_cwd()
    end
    return parent
  end
  return any_path
end

---@private
---@param dir string
---@return string
local function to_windows_path_if_needed(dir)
  -- On native Windows binaries of Neovim, ensure ripgrep sees a Windows path.
  -- Cases:
  --   • Already Windows (C:\... or \\server\share\...): return as-is.
  --   • Linux-like (/mnt/c/... or /home/...): try converting via wsl.exe wslpath -w.
  if not is_windows() then
    return dir
  end

  -- Already Windows style?
  if dir:match("^[A-Za-z]:[\\/]") or dir:match("^\\\\[^\\]+\\[^\\]+") then
    return dir
  end

  -- Try wslpath through wsl.exe → returns UNC like \\wsl$\Distro\home\user\project
  if vim.fn.executable("wsl.exe") == 1 then
    local out = vim.fn.systemlist({ "wsl.exe", "wslpath", "-w", dir })
    if vim.v.shell_error == 0 and out and out[1] and out[1] ~= "" then
      return out[1]
    end
  end

  -- Heuristic for /mnt/<drive>/...
  local drv, rest = dir:match("^/mnt/([a-zA-Z])/(.*)")
  if drv then
    return (drv:upper() .. ":\\" .. rest:gsub("/", "\\"))
  end

  -- Fallback: keep forward-slash path; ripgrep usually tolerates it
  return dir
end

---@private
---@param dir string
---@return string
local function normalize_dir_for_backend(dir)
  -- If Neovim runs as a native Windows binary (and not inside WSL),
  -- normalize to a Windows/UNC path for ripgrep. Otherwise, keep as-is.
  if is_windows() and not is_wsl() then
    return to_windows_path_if_needed(dir)
  end
  return dir
end

--==============================================================================
-- Public action
--==============================================================================

--- Open fzf-lua live_grep limited to the directory of the current Neo-tree node.
---@param state table  -- Neo-tree state passed into mapping callbacks
---@return nil
function M.live_grep_node_dir(state)
  -- 1) Get the current node from Neo-tree
  if not state or not state.tree or not state.tree.get_node then
    vim.notify("[neo-tree fzf] Invalid state; cannot get node", vim.log.levels.WARN)
    return
  end
  local node = state.tree:get_node()
  if not node then
    vim.notify("[neo-tree fzf] No node under cursor", vim.log.levels.WARN)
    return
  end

  -- 2) Extract a filesystem path from the node
  --    For file/directory nodes, node:get_id() resolves to the absolute path.
  local path = node:get_id()
  if type(path) ~= "string" or path == "" then
    vim.notify("[neo-tree fzf] Node has no path", vim.log.levels.WARN)
    return
  end

  -- 3) Normalize to an absolute directory
  local dir = ensure_dir(abs_path(path))
  dir = normalize_dir_for_backend(dir)

  -- 4) Invoke fzf-lua live_grep scoped to that directory
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[neo-tree fzf] fzf-lua not found", vim.log.levels.ERROR)
    return
  end

  -- Use both 'cwd' and 'search_dirs' to strictly limit ripgrep to 'dir'.
  -- Passing 'search_dirs' as a list ensures proper quoting for spaces.
  fzf.live_grep({
    cwd = dir,
    search_dirs = { dir },
    prompt = "RG " .. vim.fn.fnamemodify(dir, ":~"),
    -- Optional: include hidden files and ignore .git
    -- additional_args = function() return { "--hidden", "--glob", "!.git" } end,
  })
end

return M
