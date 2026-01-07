---@module 'config.neotree.open_fm.wsl'
--- WSL-specific "open in file manager" for Neo-tree, fixed to avoid double-launch.
--- Key changes:
---   - Do not treat non-zero exit codes from explorer.exe as failure (WSL peculiarity).
---   - Only fall back if spawning the primary command fails altogether.

local node_utils = require("config.neotree.utils.node")

local M ---@type Cfg.NeoTree.Wsl.FM

M = {
    _cfg = {
        backend = "explorer",
        silent = true,
    }
}

---@private
---@return boolean
local function is_wsl()
  -- Prefer user helper if present
  local ok, mod = pcall(require, "lib.is_wsl")
  if ok and type(mod) == "function" then
    local ok2, ans = pcall(mod)
    if ok2 and type(ans) == "boolean" then
      return ans
    end
  end
  -- Fallback: heuristic via kernel release
  local uname = (vim.uv or vim.loop).os_uname().release:lower()
  return vim.fn.has("wsl") == 1 or uname:find("microsoft", 1, true) ~= nil
end

---@private
---@param s string
---@return string
local function quote_if_needed(s)
  -- Simple quoting to protect spaces; explorer.exe accepts quoted arguments
  if s:find("[%s]") then
    return '"' .. s .. '"'
  end
  return s
end

---@private
---@param p string
---@return string
local function abs_unix(p)
  -- Normalize to absolute, strip any accidental quotes first
  p = p:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  return vim.fn.fnamemodify(p, ":p")
end

---@private
---@param p string
---@return string|nil
local function to_windows_path(p)
  -- Convert a WSL/Linux path to a Windows path.
  p = abs_unix(p)
  local out = vim.fn.systemlist({ "wslpath", "-w", p })
  if vim.v.shell_error == 0 and out and out[1] and out[1] ~= "" then
    return out[1]
  end
  -- Heuristic for /mnt/<drive>/...
  local drv, rest = p:match("^/mnt/([a-zA-Z])/(.*)")
  if drv and rest then
    return (drv:upper() .. ":\\" .. rest:gsub("/", "\\"))
  end
  return nil
end

---@private
---@param argv string[]
---@return boolean spawned
local function spawn_detached(argv)
  -- Fire-and-forget spawn. Returns false only if spawning failed.
  if vim.system then
    -- Neovim >= 0.10: detach avoids exit-code callbacks entirely
    local ok = pcall(vim.system, argv, { detach = true })
    return ok
  else
    -- Older Neovim: jobstart returns >0 on success
    local id = vim.fn.jobstart(argv, { detach = true })
    return id > 0
  end
end


---@nodiscard
---@param cfg Cfg.NeoTree.Wsl.OpenConfig|nil
function M.setup(cfg)
  if type(cfg) == "table" then
    local b = cfg.backend
    if b == "auto" or b == "explorer" or b == "wslview" then
      M._cfg.backend = b
    end
    if type(cfg.silent) == "boolean" then
      M._cfg.silent = cfg.silent
    end
  end
end

--- Open selected node using Windows Explorer from within WSL.
--- Files are revealed with '/select,<path>', folders are opened directly.
---@param state Cfg.NeoTree.State
---@return boolean ok
function M.open(state)
  if not is_wsl() then
    if not M._cfg.silent then
      vim.notify("Open in File Manager (WSL): not a WSL session", vim.log.levels.WARN)
    end
    return false
  end

  -- Get the current node from the state
  local node = state and state.current_node or nil

  -- Get path via node_utils.get_path
  local raw, is_dir = node_utils.get_path(node)
  if raw == "" then
    if not M._cfg.silent then
      vim.notify("Open in File Manager (WSL): no path under cursor", vim.log.levels.WARN)
    end
    return false
  end

  -- Convert path to Windows
  local abs_win = to_windows_path(raw)
  if not abs_win or abs_win == "" then
    vim.notify("Open in File Manager (WSL): path conversion failed", vim.log.levels.ERROR)
    return false
  end

  -- Determine directory path (Files -> Parent, Folders -> direct)
  local dir_win = is_dir and abs_win or to_windows_path(vim.fn.fnamemodify(raw, ":h"))

  -- Backend selection
  local backend = M._cfg.backend
  if backend == "auto" then
    backend = "explorer"
  end

  if backend == "wslview" then
    -- wslview opens using Windows default handlers; directory support may vary
    local target = is_dir and (dir_win or abs_win) or abs_win
    local ok = spawn_detached({ "wslview", target })
    if not ok and not M._cfg.silent then
      vim.notify("Open in File Manager (WSL): failed to spawn wslview", vim.log.levels.ERROR)
    end
    return ok
  end

  -- Default backend: explorer.exe
  -- Important: do NOT check exit code (WSL sometimes returns non-zero on success).
  local primary = is_dir and { "explorer.exe", quote_if_needed(dir_win or abs_win) }
    or { "explorer.exe", "/select," .. quote_if_needed(abs_win) }

  local spawned = spawn_detached(primary)
  if spawned then
    return true
  end

  -- Only if spawning failed entirely, try a lightweight one-shot fallback.
  -- Note: we do NOT use fallback on non-zero exit codes anymore.
  local fallback = is_dir and { "cmd.exe", "/C", "start", "", quote_if_needed(dir_win or abs_win) }
    or { "cmd.exe", "/C", "start", "", quote_if_needed(abs_win) }

  local fb_ok = spawn_detached(fallback)
  if not fb_ok and not M._cfg.silent then
    vim.notify("Open in File Manager (WSL): failed to spawn fallback (cmd start)", vim.log.levels.ERROR)
  end
  return fb_ok
end

return M
