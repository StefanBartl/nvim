---@module 'usrcmds.project_tree'
---@brief Asynchronous project structure inspection (tree, count, clipboard)
---@description
--- Provides async, portable utilities to inspect a project's file structure from Neovim.
--- Features:
---   - Write a full file tree to a configured output file (excludes patterns)
---   - Count project files
---   - Copy the tree content to the system clipboard (preferred) or via xclip fallback
--- All operations are non-blocking and return structured results to the caller.
--- Linux/macOS only; uses POSIX tools (sh, find, sed, wc).
---
--- Safety & Design:
---   - Shell execution via vim.system (Neovim >= 0.10) with text=true
---   - Strong separation of concerns: low-level functions return results; UI notifies in user commands
---   - Portable find pipeline (no GNU -printf)
---   - Configurable excludes/outdir/filename format
---
---Konfigurationsbeispiele
--
--- Globaler State-Ordner (aktuelles Verhalten, nur anderer Slug):
-- require("usrcmds.project_tree").setup({
-- appname = "usrcmds-project-tree",
-- scope = "global",
-- })
---
--- Pro-Projekt-Ordner:
-- require("usrcmds.project_tree").setup({
--   scope = "per-project",
-- })
---
--- Expliziter Ordner ohne default_state_dir:
-- require("usrcmds.project_tree").setup({
--   outdir = "/var/tmp/my-nvim-state/project-tree",
-- })


local M = {}

local fn = vim.fn
local oslib = require("lib").os

-- Defaults --------------------------------------------------------------------

local DEFAULTS ---@type ProjectTreeConfig
DEFAULTS = {
  exclude_patterns = { "*/.git/*" },
  outdir = oslib.default_state_dir("project-tree"),
  outfile_fmt = "%s-tree.txt",
  notify_prefix = "[ProjectTree] ",
  use_system_clipboard = true,
}

M.opts = DEFAULTS

-- Helpers ---------------------------------------------------------------------

--- Ensure that a directory exists; behaves like mkdir -p.
--- Uses Vimscript mkdir for portability.
---@param dir FilePath
---@return boolean ok, string? err
local function ensure_dir(dir)
  if fn.isdirectory(dir) == 1 then return true, nil end
  local ok, err = pcall(fn.mkdir, dir, "p")
  if not ok then return false, "mkdir failed: " .. tostring(err) end
  if fn.isdirectory(dir) ~= 1 then return false, "mkdir returned non-directory" end
  return true, nil
end

--- Derive the current working directory and a project name (tail of cwd).
---@return string? cwd, string? proj, string? err
local function current_project()
  local cwd = fn.getcwd()
  if type(cwd) ~= "string" or cwd == "" then return nil, nil, "invalid working directory" end
  local proj = fn.fnamemodify(cwd, ":t")
  if type(proj) ~= "string" or proj == "" then return nil, nil, "failed to derive project name" end
  return cwd, proj, nil
end

--- Build a platform-specific pipeline that lists relative file paths, sorted.
--- Linux/macOS/WSL: POSIX find | sed | sort
--- Windows: PowerShell Get-ChildItem | filters | Sort-Object
---@param cwd string
---@param exclude string[]
---@return string cmd
local function build_tree_cmd(cwd, exclude)
  local is_windows = (oslib.name() == "windows")
  if not is_windows then
    -- POSIX branch (unchanged)
    local parts = { "find", fn.shellescape(cwd), "-type f" }
    for i = 1, #exclude do
      parts[#parts + 1] = "-not -path " .. fn.shellescape(exclude[i])
    end
    parts[#parts + 1] = "-print"

    local escaped_cwd = cwd:gsub("([^%w_%./%-])", "%%%1")
    local sed_prefix = "^" .. escaped_cwd .. "/"

    local cmd = table.concat(parts, " ")
    cmd = cmd .. " | sed -e " .. fn.shellescape("s#" .. sed_prefix .. "##")
    cmd = cmd .. " | sort"
    return cmd
  end

  -- Windows PowerShell branch
  -- Convert simple glob excludes like */.git/* to permissive regex
  local regexes = {}
  for i = 1, #exclude do
    local g = exclude[i]
    g = g:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1") -- escape regex meta
    g = g:gsub("%*", ".*")                           -- glob * → .*
    g = g:gsub("/", "[\\\\/]")                       -- accept / or \
    regexes[#regexes + 1] = g
  end

  local function ps_quote(s)
    return "'" .. tostring(s):gsub("'", "''") .. "'"
  end

  local ps = {}
  ps[#ps + 1] = "$ErrorActionPreference='Stop'"
  ps[#ps + 1] = "$cwd=[IO.Path]::GetFullPath(" .. ps_quote(cwd) .. ")"
  ps[#ps + 1] =
  "$files=Get-ChildItem -LiteralPath $cwd -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName"
  if #regexes > 0 then
    ps[#ps + 1] = "$rx=@(" .. table.concat(vim.tbl_map(ps_quote, regexes), ",") .. ")"
    ps[#ps + 1] = "$files=$files|Where-Object{ $l=$_; foreach($r in $rx){ if($l -match $r){return $false} }; $true }"
  end
  ps[#ps + 1] = "$rel=$files|ForEach-Object{ $_.Substring($cwd.Length+1) -replace '\\\\','/' }|Sort-Object"
  ps[#ps + 1] = "$rel"

  return table.concat(ps, "; ")
end

--- Run a shell command asynchronously using lib.os (chooses sh or PowerShell).
---@param cmd string
---@param cb fun(success:boolean, stdout:string, stderr:string): nil
local function run_shell(cmd, cb)
  oslib.run(cmd, function(ok, res)
    cb(ok, res.stdout or "", res.stderr or "")
  end)
end

--- Compute an output file path from project name and config.
---@param proj string
---@return FilePath
local function output_path_for(proj)
  local filename = (M.opts.outfile_fmt:gsub("%%s", proj))
  return oslib.path_join(M.opts.outdir, filename)
end

-- Prefer lib.os clipboard; keep xclip fallback for Linux
--- Copy the generated tree file to the system clipboard or via xclip fallback.
--- Callback receives (success, message).
---@param callback fun(success:boolean, msg:string): nil
---@return nil
function M.copy_tree_to_clipboard(callback)
  local _, proj, cerr = current_project()
  if not proj then
    callback(false, (M.opts.notify_prefix .. (cerr or "cwd error")))
    return
  end

  local outpath = output_path_for(proj)
  if fn.filereadable(outpath) == 0 then
    callback(false, (M.opts.notify_prefix .. "tree file does not exist: " .. outpath))
    return
  end

  local ok_read, lines = pcall(fn.readfile, outpath)
  if ok_read and type(lines) == "table" then
    local content = table.concat(lines, "\n")
    -- First try platform-native clipboard via lib.os
    if oslib.copy_to_clipboard(content) then
      callback(true, (M.opts.notify_prefix .. "tree copied to clipboard"))
      return
    end
  end

  -- Linux fallback: xclip (keine Aktion auf Windows/WSL/macOS)
  if oslib.name() == "linux" then
    local cmd = "xclip -selection clipboard < " .. fn.shellescape(outpath)
    run_shell(cmd, function(success, _, err)
      if success then
        callback(true, (M.opts.notify_prefix .. "tree copied via xclip"))
      else
        callback(false, (M.opts.notify_prefix .. "clipboard failed: " .. (err or "")))
      end
    end)
    return
  end

  callback(false, (M.opts.notify_prefix .. "clipboard backend unavailable"))
end

-- Public API ------------------------------------------------------------------

--- Initialize configuration. Idempotent; merges with defaults.
---@param cfg ProjectTreeConfig|nil
---@return nil
function M.setup(cfg)
  cfg = cfg or {}
  local o ---@type ProjectTreeConfig
  o = {
    exclude_patterns = cfg.exclude_patterns or DEFAULTS.exclude_patterns,
    outdir = cfg.outdir or DEFAULTS.outdir,
    outfile_fmt = cfg.outfile_fmt or DEFAULTS.outfile_fmt,
    notify_prefix = cfg.notify_prefix or DEFAULTS.notify_prefix,
    use_system_clipboard = (cfg.use_system_clipboard ~= nil) and cfg.use_system_clipboard or
        DEFAULTS.use_system_clipboard,
  }
  M.opts = o

  local ok, err = ensure_dir(M.opts.outdir)
  if not ok then
    -- Low-level: return silently; the user commands will surface this as needed
    vim.schedule(function()
      vim.notify(M.opts.notify_prefix .. "cannot ensure outdir: " .. tostring(err), vim.log.levels.WARN)
    end)
  end
end

--- Generate the project file tree and write it to the configured output file.
--- Callback receives (success, message, outpath|nil).
---@param callback fun(success:boolean, msg:string, outpath:string|nil): nil
---@return nil
function M.write_tree(callback)
  local cwd, proj, cerr = current_project()
  if not cwd or not proj then
    callback(false, (M.opts.notify_prefix .. (cerr or "cwd error")), nil)
    return
  end

  local ok_dir, derr = ensure_dir(M.opts.outdir)
  if not ok_dir then
    callback(false, (M.opts.notify_prefix .. "cannot create outdir: " .. tostring(derr)), nil)
    return
  end

  local outpath = output_path_for(proj)
  local cmd = build_tree_cmd(cwd, M.opts.exclude_patterns) .. " > " .. fn.shellescape(outpath)

  run_shell(cmd, function(success, _, err)
    if success then
      callback(true, (M.opts.notify_prefix .. "tree written: " .. outpath), outpath)
    else
      callback(false, (M.opts.notify_prefix .. "tree write failed: " .. (err or "unknown error")), outpath)
    end
  end)
end

--- Count files in the project (respects exclude_patterns).
--- Callback receives (success, message, count|nil).
---@param callback fun(success:boolean, msg:string, count:integer|nil): nil
---@return nil
function M.count_files(callback)
  local cwd, _, cerr = current_project()
  if not cwd then
    callback(false, (M.opts.notify_prefix .. (cerr or "cwd error")), nil)
    return
  end

  local cmd = build_tree_cmd(cwd, M.opts.exclude_patterns) .. " | wc -l"
  run_shell(cmd, function(success, out, err)
    if not success then
      callback(false, (M.opts.notify_prefix .. "count failed: " .. (err or "")), nil)
      return
    end
    -- Trim and parse number at end; portable across wc variants
    local n = tonumber((out or ""):match("(%d+)%s*$"))
    if not n then
      callback(false, (M.opts.notify_prefix .. "cannot parse count"), nil)
      return
    end
    callback(true, (M.opts.notify_prefix .. ("files: %d"):format(n)), n)
  end)
end

-- User Commands (UI-layer: do notifications here) -----------------------------

--- Setup 'project_tree'-Usercommands
---@return nil
function M.enable_usercmds()
  vim.api.nvim_create_user_command("ProjectTreeGet", function()
    M.write_tree(function(ok, msg)
      vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end, { desc = "Write project tree to configured output file" })

  vim.api.nvim_create_user_command("ProjectTreeCopyClipboard", function()
    M.copy_tree_to_clipboard(function(ok, msg)
      vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end, { desc = "Copy the project tree file to clipboard" })

  vim.api.nvim_create_user_command("ProjectFilesCount", function()
    M.count_files(function(ok, msg)
      vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end, { desc = "Count project files (excluding configured patterns)" })
end

return M ---@type ProjectTreeModule
