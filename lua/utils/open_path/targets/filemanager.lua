---@module 'utils.open_path.targets.fm'
--- Open path under cursor in the system file manager (select file or open folder).
--- Integrates the behavior from your previous module (dbus-send on Linux; open -R on macOS; explorer on WSL/Windows).

---@class TargetFM
local T = {}

local H = require("utils.open_path.helpers")

--- Execute a background process cross-version (Neovim 0.9/0.10+).
---@param argv string[]
local function spawn(argv)
  if vim.system then
    vim.system(argv, { text = true }, function(_) end)
  else
    vim.fn.jobstart(argv, { detach = true })
  end
end

---@param require_existing boolean
---@param notify boolean
---@return boolean
function T.open(require_existing, notify)
  local raw = select(1, H.token_under_cursor())
  if not raw then return false end
  local info = H.normalize_and_probe(raw)
  if require_existing and not info then
    return false
  end
  if not info then
    if notify then vim.notify("open_path: path does not exist", vim.log.levels.WARN) end
    return false
  end

  local abs = info.abs
  local parent = info.is_dir and abs or vim.fn.fnamemodify(abs, ":h")
  if parent == "" or parent == "." then
    parent = H.safe_cwd()
  end

  local is_windows, is_macos, is_unix, is_wsl = H.platform()

  if is_windows then
    local target = info.is_dir and parent or (abs:gsub("/", "\\"))
    ---@type string[]
    local argv = info.is_dir and { "explorer.exe", parent:gsub("/", "\\") }
      or { "explorer.exe", "/select," .. target }
    spawn(argv)
    return true
  end

  if is_wsl then
    local list = vim.fn.systemlist({ "wslpath", "-w", info.is_dir and parent or abs })
    if vim.v.shell_error ~= 0 or not list or not list[1] or list[1] == "" then
      if notify then vim.notify("open_path: wslpath failed", vim.log.levels.ERROR) end
      return false
    end
    local winp = list[1]
    ---@type string[]
    local argv = info.is_dir and { "explorer.exe", winp } or { "explorer.exe", "/select," .. winp }
    spawn(argv)
    return true
  end

  if is_macos then
    ---@type string[]
    local argv = info.is_dir and { "open", parent } or { "open", "-R", abs }
    spawn(argv)
    return true
  end

  if is_unix then
    local function has_exe(cmd) return vim.fn.executable(cmd) == 1 end
    if has_exe("dbus-send") then
      local uri = vim.uri_from_fname(abs)
      ---@type string[]
      local argv = {
        "dbus-send", "--session",
        "--dest=org.freedesktop.FileManager1",
        "--type=method_call",
        "/org/freedesktop/FileManager1",
        "org.freedesktop.FileManager1.ShowItems",
        "array:string:" .. uri,
        "string:",
      }
      if vim.system then
        vim.system(argv, { text = true }, function(obj)
          if obj.code ~= 0 and notify then
            vim.notify("open_path: dbus-send failed", vim.log.levels.WARN)
          end
        end)
      else
        vim.fn.jobstart(argv, { detach = true })
      end
      return true
    else
      ---@type string[]
      local argv = { "xdg-open", parent }
      spawn(argv)
      return true
    end
  end

  if notify then vim.notify("open_path: unsupported OS", vim.log.levels.ERROR) end
  return false
end

return T
