---@module 'utils.search_all_drives.select_find_command'
--- Selects a robust cross-platform "list files" command as argv.
--- Design goals:
---   • Pure function: no side effects, returns (ok, argv|nil, err|nil).
---   • Security: argv form only; never concatenates shell strings.
---   • Predictable precedence on POSIX: fd → rg --files → find.
---   • Windows fallback kept (cmd.exe /c dir ...) but only used when OS is Windows.
---
--- Notes:
---   • This module does not spawn processes; it only chooses an argv vector.
---   • Callers decide the working directory and spawning details (async/sync).
---
--- Examples:
---   local ok, argv, err = choose_find_command()
---   if not ok then return nil, err end
---   -- spawn(argv[1], { args = { unpack(argv, 2) }, cwd = root })

---@class FindChooser
local M = {}

-- Local aliases kept minimal; no globals leaked.
local uv = vim and (vim.uv or vim.loop) or nil
local fn_executable = (vim and vim.fn and vim.fn.executable) or function()
  return 0
end

--- Lightweight OS check (pure; no I/O).
---@return boolean
local function is_windows()
  if not uv or not uv.os_uname then
    return false
  end
  local sys = uv.os_uname().sysname or ""
  -- Matches "Windows_NT" on modern systems
  return sys:find("Windows", 1, true) ~= nil
end

--- Safe predicate: is an executable available on PATH?
---@param name string
---@return boolean
local function has_exec(name)
  -- vim.fn.executable returns 1 when found, 0 otherwise
  if type(name) ~= "string" or name == "" then
    return false
  end
  return fn_executable(name) == 1
end

--- Build argv for fd with sensible defaults.
---@param opts { include_hidden?: boolean, follow_symlinks?: boolean, exclude_vcs?: boolean }|nil
---@return string[]
local function argv_fd(opts)
  opts = opts or {}
  -- Comments explain flag mapping; order is stable for reproducibility.
  local argv = { "fd", "--type", "f" } -- only files
  if opts.include_hidden ~= false then -- default true: behave like ripgrep --hidden
    argv[#argv + 1] = "--hidden"
  end
  if opts.follow_symlinks == true then
    argv[#argv + 1] = "--follow"
  end
  if opts.exclude_vcs ~= false then -- default true: skip .git by default
    argv[#argv + 1] = "--exclude"
    argv[#argv + 1] = ".git"
  end
  return argv
end

--- Build argv for ripgrep file listing.
---@param opts { include_hidden?: boolean, exclude_vcs?: boolean }|nil
---@return string[]
local function argv_rg(opts)
  opts = opts or {}
  local argv = { "rg", "--files", "--color", "never" }
  if opts.include_hidden ~= false then
    argv[#argv + 1] = "--hidden"
  end
  -- "--no-ignore-vcs" lists files even if excluded by .gitignore; many UIs prefer showing all.
  -- If callers want to respect VCS ignores, they can post-process or set exclude_vcs=true here.
  if opts.exclude_vcs == false then
    -- respect VCS ignores (default in rg), so we do nothing
  else
    argv[#argv + 1] = "--no-ignore-vcs"
  end
  return argv
end

--- Build argv for POSIX find (portable).
---@return string[]
local function argv_find_posix()
  -- Print regular files relative to the current working directory.
  -- Flags are intentionally minimal for portability (BSD/GNU find).
  return { "find", ".", "-type", "f", "-print" }
end

--- Build argv for Windows (cmd.exe dir).
---@return string[]
local function argv_dir_windows()
  -- /s recurse, /b bare format, /a:-d exclude directories
  return { "cmd.exe", "/c", "dir", "/s", "/b", "/a:-d" }
end

--- Choose a robust file listing command for the current platform.
--- Contract:
---   • On POSIX: prefer fd → rg → find; never returns nil unless all are missing.
---   • On Windows: returns "cmd.exe /c dir ..." if detected.
---   • No process is executed; only argv is returned.
---   • Returns (false, nil, err) if no suitable tool exists on POSIX.
---
--- Rationale:
---   • fd is fastest and has a clean interface for hidden/symlinks/excludes.
---   • rg --files is ubiquitous (ripgrep dependency already common in editor setups).
---   • find is universal fallback on Unix-like systems.
---   • Windows 'dir' keeps zero-dependency behavior without PowerShell requirement.
---
--- @param opts { include_hidden?: boolean, follow_symlinks?: boolean, exclude_vcs?: boolean }|nil
--- @return boolean ok                 -- true if a command was selected
--- @return string[]|nil argv          -- argv vector for spawning
--- @return string|nil err             -- error message when ok=false
function M.choose_find_command(opts)
  -- Windows path (kept isolated so POSIX code paths remain lean).
  if is_windows() then
    return true, argv_dir_windows(), nil
  end

  -- POSIX precedence: fd → rg → find
  if has_exec("fd") then
    return true, argv_fd(opts), nil
  end
  if has_exec("rg") then
    return true, argv_rg(opts), nil
  end
  if has_exec("find") then
    return true, argv_find_posix(), nil
  end

  -- Nothing suitable found; stay silent UI-wise (caller decides how to notify).
  return false, nil, "No suitable file-lister found (tried: fd, rg, find)"
end

return M
