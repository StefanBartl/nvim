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

local M = {}

-- Local aliases (clarity over micro perf)
local fn = vim.fn

-- Detect availability of vim.system (Neovim >= 0.10)
local HAS_SYSTEM = (vim.system ~= nil)

-- Defaults --------------------------------------------------------------------

local DEFAULTS ---@type ProjectTreeConfig
DEFAULTS = {
  exclude_patterns = { "*/.git/*" },  -- portable, quoted shell globs
  outdir = (os.getenv("XDG_STATE_HOME") and (os.getenv("XDG_STATE_HOME") .. "/nvim/project-tree"))
           or (os.getenv("HOME") .. "/.local/state/nvim/project-tree"),
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

--- Build a portable find pipeline (Linux/macOS) that lists relative file paths.
--- `find <cwd> -type f [excludes] -print | sed -e "s#^<cwd>/##" | sort`
---@param cwd string
---@param exclude string[]
---@return string cmd
local function build_tree_cmd(cwd, exclude)
  -- Compose the 'find' arguments in a robust way
  local parts = { "find", fn.shellescape(cwd), "-type f" }
  for i = 1, #exclude do
    parts[#parts + 1] = "-not -path " .. fn.shellescape(exclude[i])
  end
  parts[#parts + 1] = "-print"

  -- Escape cwd for a sed prefix removal; make entries relative
  -- We replace "^{cwd}/" once, then strip a leading "/" if present.
  local escaped_cwd = cwd:gsub("([^%w_%./%-])", "%%%1")
  local sed_prefix = "^" .. escaped_cwd .. "/"

  local cmd = table.concat(parts, " ")
  cmd = cmd .. " | sed -e " .. fn.shellescape("s#" .. sed_prefix .. "##")
  cmd = cmd .. " | sort"
  return cmd
end

--- Run a shell command asynchronously and invoke callback with separated streams.
--- Uses vim.system when available; otherwise falls back to jobstart (older Neovim).
---@param cmd string
---@param cb fun(success:boolean, stdout:string, stderr:string): nil
local function run_shell(cmd, cb)
  if HAS_SYSTEM then
    vim.system({ "sh", "-lc", cmd }, { text = true }, function(obj)
      local ok = (obj.code == 0)
      cb(ok, obj.stdout or "", obj.stderr or "")
    end)
    return
  end

  -- Fallback for legacy Neovim: jobstart with buffered output
  local stdout, stderr = {}, {}
  local job = fn.jobstart({ "sh", "-lc", cmd }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then stdout[#stdout + 1] = table.concat(data, "\n") end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then stderr[#stderr + 1] = table.concat(data, "\n") end
    end,
    on_exit = function(_, code)
      cb(code == 0, table.concat(stdout, "\n"), table.concat(stderr, "\n"))
    end,
  })
  if job <= 0 then
    cb(false, "", "failed to start job")
  end
end

--- Compute an output file path from project name and config.
---@param proj string
---@return FilePath
local function output_path_for(proj)
  return M.opts.outdir .. "/" .. (M.opts.outfile_fmt:gsub("%%s", proj))
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
    use_system_clipboard = (cfg.use_system_clipboard ~= nil) and cfg.use_system_clipboard or DEFAULTS.use_system_clipboard,
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

  if M.opts.use_system_clipboard then
    local ok_read, lines = pcall(fn.readfile, outpath)
    if ok_read and type(lines) == "table" then
      local content = table.concat(lines, "\n")
      local ok_set = pcall(fn.setreg, "+", content)
      if ok_set then
        callback(true, (M.opts.notify_prefix .. "tree copied to clipboard (+)"))
        return
      end
      -- fall through to shell fallback if setreg failed
    end
  end

  local cmd = "xclip -selection clipboard < " .. fn.shellescape(outpath)
  run_shell(cmd, function(success, _, err)
    if success then
      callback(true, (M.opts.notify_prefix .. "tree copied via xclip"))
    else
      callback(false, (M.opts.notify_prefix .. "clipboard failed: " .. (err or "")))
    end
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
