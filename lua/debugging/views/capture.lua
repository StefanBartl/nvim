---@module 'debugging.views.capture'
---Unified capture system for :messages, Noice, etc.

local M = {}

---@param s string
---@return string
local function rstrip(s)
  return (s:gsub("%s*$", ""))
end

---@param bin string
---@return boolean
local function has_exec(bin)
  return vim.fn.executable(bin) == 1
end

---@return { is_mac:boolean, is_win:boolean, is_wsl:boolean, is_wayland:boolean, is_x11:boolean }
local function detect_platform()
  local uname = (vim.uv or vim.loop).os_uname()
  local sys = (uname.sysname or ""):lower()
  local rel = (uname.release or ""):lower()
  local is_mac = sys:find("darwin", 1, true) ~= nil
  local is_win = sys:find("windows", 1, true) ~= nil or package.config:sub(1, 1) == "\\"
  local is_wsl = (vim.fn.has("wsl") == 1) or rel:find("microsoft", 1, true) ~= nil
  local is_wayland = (vim.env.WAYLAND_DISPLAY or "") ~= ""
  local is_x11 = (vim.env.DISPLAY or "") ~= ""
  return { is_mac = is_mac, is_win = is_win, is_wsl = is_wsl, is_wayland = is_wayland, is_x11 = is_x11 }
end

---@param cmd string[]
---@param input? string
---@return boolean,string|nil
local function run_command(cmd, input)
  if vim.system then
    local res = vim.system(cmd, { text = true, stdin = input }):wait()
    if res.code == 0 then
      return true, nil
    end
    return false, (res.stderr ~= "" and res.stderr) or ("exit code " .. res.code)
  else
    local out = vim.fn.system(cmd, input or "")
    return vim.v.shell_error == 0, out
  end
end

---@param path string
---@param content string
---@return boolean,string|nil
local function write_file(path, content)
  local dir = vim.fn.fnamemodify(path, ":h")
  if dir == "" then
    return false, "Invalid directory for path: " .. path
  end
  local ok_mkdir, err_mkdir = pcall(vim.fn.mkdir, dir, "p")
  if not ok_mkdir then
    return false, "mkdir failed: " .. tostring(err_mkdir)
  end
  local f, err = io.open(path, "w")
  if not f then
    return false, "open failed: " .. (err or path)
  end
  if content ~= "" and not content:match("\n$") then
    content = content .. "\n"
  end
  f:write(content)
  f:close()
  return true, nil
end

---@param text string
---@param debug boolean
---@return boolean
local function copy_to_clipboard(text, debug)
  local ok = pcall(vim.fn.setreg, "+", text)
  if ok then
    if debug then
      vim.notify("DebugViews: setreg('+') ok", vim.log.levels.DEBUG)
    end
    return true
  end

  local P = detect_platform()

  if P.is_mac and has_exec("pbcopy") then
    local ok2, err = run_command({ "pbcopy" }, text)
    if ok2 then return true end
    if debug then vim.notify("pbcopy failed: " .. tostring(err), vim.log.levels.DEBUG) end
  end

  if P.is_wsl or P.is_win then
    if has_exec("clip.exe") then
      local ok2, err = run_command({ "clip.exe" }, text)
      if ok2 then return true end
      if debug then vim.notify("clip.exe failed: " .. tostring(err), vim.log.levels.DEBUG) end
    end
    local clip_abs = "/mnt/c/Windows/System32/clip.exe"
    if not has_exec("clip.exe") and vim.fn.filereadable(clip_abs) == 1 then
      local ok2, err = run_command({ clip_abs }, text)
      if ok2 then return true end
      if debug then vim.notify("abs clip.exe failed: " .. tostring(err), vim.log.levels.DEBUG) end
    end
  end

  if P.is_wayland and has_exec("wl-copy") then
    local ok2, err = run_command({ "wl-copy" }, text)
    if ok2 then return true end
    if debug then vim.notify("wl-copy failed: " .. tostring(err), vim.log.levels.DEBUG) end
  end

  if P.is_x11 then
    if has_exec("xclip") then
      local ok2, err = run_command({ "xclip", "-selection", "clipboard" }, text)
      if ok2 then return true end
      if debug then vim.notify("xclip failed: " .. tostring(err), vim.log.levels.DEBUG) end
    end
    if has_exec("xsel") then
      local ok2, err = run_command({ "xsel", "--clipboard", "--input" }, text)
      if ok2 then return true end
      if debug then vim.notify("xsel failed: " .. tostring(err), vim.log.levels.DEBUG) end
    end
  end

  return false
end

---@return string dir, string logfile
local function resolve_paths()
  local base = (vim.env.REPOS_DIR and vim.env.REPOS_DIR ~= "" and vim.env.REPOS_DIR) or vim.fn.stdpath("state")
  if vim.fs and vim.fs.normalize then
    base = vim.fs.normalize(base)
  end
  local join = (vim.fs and vim.fs.joinpath) or function(...) return table.concat({ ... }, "/") end
  local dir = join(base, "debug_views")
  local logfile = join(dir, ("messages-%s.log"):format(os.date("%Y%m%d-%H%M%S")))
  return dir, logfile
end

---Capture :messages with optional file save and clipboard
---@param opts DebugViews.CaptureOpts|nil
---@return boolean success, string|nil content
function M.capture_messages(opts)
  opts = opts or {}
  local debug = opts.debug == true
  local save_file = opts.save_file ~= false
  local clipboard = opts.clipboard ~= false

  local dir, logfile = resolve_paths()
  if debug then
    vim.notify(("DebugViews: dir=%s\nlog=%s"):format(dir, logfile), vim.log.levels.DEBUG)
  end

  local ok_exec, res = pcall(vim.api.nvim_exec2, "messages", { output = true })
  local messages = ok_exec and rstrip(res.output or "") or ""
  if debug then
    vim.notify(("DebugViews: captured %d bytes"):format(#messages), vim.log.levels.DEBUG)
  end

  if save_file then
    local ok_write, err = write_file(logfile, messages)
    if not ok_write then
      vim.notify("DebugViews: write failed: " .. tostring(err), vim.log.levels.ERROR)
    else
      vim.notify("DebugViews: saved to " .. logfile, vim.log.levels.INFO)
    end
  end

  if clipboard then
    local ok_clip = copy_to_clipboard(messages, debug)
    if not ok_clip then
      vim.notify(
        "DebugViews: clipboard not available. Install: pbcopy/wl-copy/xclip/xsel/clip.exe",
        vim.log.levels.WARN
      )
    elseif debug then
      vim.notify("DebugViews: clipboard copy ok", vim.log.levels.DEBUG)
    end
  end

  return true, messages
end

return M

