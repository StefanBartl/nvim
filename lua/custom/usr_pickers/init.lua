---@module 'usrcmds.usr_pickers'
--- Pickers for Telescope & fzf-lua with robust, literal directory handling.
--- This module provides user commands and keymaps to browse files and grep content with:
---   • Directory prompts
---   • Literal path semantics (keeps segments like '@types' intact; no register/glob expansion)
---   • Home expansion only ('~'), platform-aware absolute path detection (POSIX, Windows, UNC)
---   • Telescope: multi-directory support for live_grep via `search_dirs`
---   • fzf-lua: single-cwd semantics with modern `live_grep`
---   • Context text inside prompts (e.g., "Directory (Telescope files): ")
---
--- Notes:
---   • Linux/macOS/Windows supported.
---   • Requires Telescope and/or fzf-lua installed for respective features.
---   • Ripgrep/fd should be available on PATH for best performance (Windows: winget/choco/scoop).

---@class _FzfCmds
local M = {}

-- Reusable libuv handle (Neovim 0.10+: vim.uv; older: vim.loop)
---@type uv
local uv = vim.uv or vim.loop

-- Immutable defaults ----------------------------------------------------------

---@type UsrPickersConfig
local DEFAULTS = {
  keys = {
    tel_files = "<leader>telf",
    tel_grep  = "<leader>telg",
    fzf_files = "<leader>fzff",
    fzf_grep  = "<leader>fzfg",
  },
  commands = {
    find_files_telescope = "FindFilesTelescope",
    grep_telescope       = "GrepTelescope",
    find_files_fzf       = "FindFilesFzf",
    grep_fzf             = "GrepFzf",
  },
  enable_keymaps = true,
  notify_level = vim.log.levels.INFO,
}

-- OS detection & helpers ------------------------------------------------------

---@type boolean
local IS_WINDOWS = (vim.loop.os_uname().sysname or ""):match("Windows") ~= nil

--- Return user's home directory in a cross-platform way.
--- On Windows prefer HOME, then USERPROFILE, then HOMEDRIVE+HOMEPATH.
--- @return string|nil
local function home_dir()
  if vim.env.HOME and vim.env.HOME ~= "" then
    return vim.env.HOME
  end
  if IS_WINDOWS then
    if vim.env.USERPROFILE and vim.env.USERPROFILE ~= "" then
      return vim.env.USERPROFILE
    end
    local hd, hp = vim.env.HOMEDRIVE, vim.env.HOMEPATH
    if hd and hp and hd ~= "" and hp ~= "" then
      return hd .. hp
    end
  end
  return nil
end

--- Expand "~" or "~/" only; do NOT expand registers or globs.
--- Keeps literal segments like "@types".
--- @param s string
--- @return string
local function expand_home(s)
  -- Supports "~" and "~/" forms; deliberately does NOT support "~user"
  if s == "~" then
    return home_dir() or s
  end
  if s:sub(1, 2) == "~/" then
    local h = home_dir()
    if h and h ~= "" then
      return h .. s:sub(2)
    end
  end
  return s
end

--- Check if a path is absolute on the current platform.
--- Supports POSIX "/", Windows "C:\", "C:/", and UNC "\\server\share".
--- @param p string
--- @return boolean
local function is_absolute(p)
  if not IS_WINDOWS then
    return p:sub(1, 1) == "/"
  end
  if p:match("^%a:[/\\]") then return true end          -- C:\ or C:/
  if p:match("^\\\\") or p:match("^//") then return true end -- UNC \\ or //
  return false
end

--- Normalize separators consistently.
--- Uses vim.fs.normalize (nvim >= 0.10) when available; also cleans "." and "..".
--- Otherwise, collapses repeated slashes and converts backslashes to slashes.
--- @param p string
--- @return string
local function normalize_separators(p)
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(p)
  end
  -- Fallback: convert "\" -> "/" and collapse multiple "/"
  p = p:gsub("\\", "/"):gsub("//+", "/")
  return p
end

--- Ensure a trailing path separator appropriate to the current OS/present style (for prompts).
--- On Windows, preserves "\" vs "/" choice if already used in the given path; otherwise uses "\".
--- On POSIX, uses "/".
--- @param p string
--- @return string
local function ensure_trailing_sep(p)
  if IS_WINDOWS then
    if p:match("[/\\]$") then return p end
    local preferred = p:find("\\", 1, true) and "\\" or "/"
    return p .. preferred
  else
    if p:sub(-1) == "/" then return p end
    return p .. "/"
  end
end

-- Utilities -------------------------------------------------------------------

--- Safe require with optional notice.
--- @param name string
--- @param on_fail? fun()
--- @return any|nil
local function safe_require(name, on_fail)
  local ok, mod = pcall(require, name)
  if ok then return mod end
  if on_fail then on_fail() end
  return nil
end

--- Normalize and validate a single directory path (cross-platform, literal).
--- - Only "~" is expanded.
--- - No register/glob expansion (keeps "@types" intact).
--- - Relative paths resolved against current working directory.
--- @param raw string
--- @return DirPath|nil, string?  @nodiscard
local function normalize_dir(raw)
  local s = vim.trim(raw or "")
  if s == "" then
    return (uv.cwd() or vim.fn.getcwd()), nil
  end

  -- Only expand "~"; keep everything else literal
  local expanded = expand_home(s)

  -- Resolve relative to cwd if needed
  if not is_absolute(expanded) then
    expanded = vim.fn.fnamemodify(expanded, ":p")
  end

  -- Normalize separators and tidy path
  expanded = normalize_separators(expanded)

  -- Validate directory
  local st = uv.fs_stat(expanded)
  if not st or st.type ~= "directory" then
    return nil, ("Not a directory: %s"):format(expanded)
  end
  return expanded, nil
end

--- Parse one or more dirs from a user arg string.
--- @param args string
--- @return string[]  @nodiscard
local function parse_dirs(args)
  ---@type string[]
  local result = {}

  local s = vim.trim(args or "")
  if s == "" then
    result[1] = (uv.cwd() or vim.fn.getcwd())
    return result
  end

  for token in s:gmatch("%S+") do
    local dir, err = normalize_dir(token)
    if dir then
      result[#result + 1] = dir
    else
      vim.notify(err or ("Invalid path: " .. token), vim.log.levels.WARN)
    end
  end
  return result
end

--- Command-line prompt for a directory with context info.
--- Shows context in the prompt (e.g., "Directory (Telescope files): ").
--- Uses cancelreturn to detect Esc and abort cleanly.
--- Treats '@' as literal filename char by temporarily widening 'isfname'.
--- @param context string
--- @return string|nil
local function prompt_dir(context)
  ---@type string
  local buf_dir = vim.fn.expand("%:p:h")
  if buf_dir == "" then
    buf_dir = (uv.cwd() or vim.fn.getcwd())
  end

  local CANCEL = "\x1f__USR_PICKERS_CANCEL__"

  -- Widen 'isfname' so '@' is treated as filename char during completion.
  local save_isfname = vim.o.isfname
  if not save_isfname:find("@", 1, true) then
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.o.isfname = save_isfname .. ",@"
  end

  ---@type string
  local input = vim.fn.input({
    prompt = ("Directory (%s): "):format(context),
    -- Default preserves user's path style; we do not normalize here
    default = ensure_trailing_sep(buf_dir),
    completion = "dir",
    cancelreturn = CANCEL,
  })

  -- Restore 'isfname'
  vim.o.isfname = save_isfname

  -- If cancelled, do nothing
  if input == CANCEL then
    return nil
  end

  -- Keep input literal; only expand "~"
  local candidate = input
  if candidate == "" then
    candidate = buf_dir
  end
  candidate = expand_home(candidate)
  candidate = normalize_separators(candidate)

  local st = uv.fs_stat(candidate)
  if not (st and st.type == "directory") then
    vim.notify(("Not a directory: %s"):format(candidate), vim.log.levels.WARN)
    return nil
  end

  return candidate
end

--- Idempotent user-command (re)definition.
--- @param name string
--- @param fn fun(opts:{args:string, fargs:string[]})
--- @param opts table
local function define_user_command(name, fn, opts)
  pcall(vim.api.nvim_del_user_command, name)
  vim.api.nvim_create_user_command(name, fn, opts)
end

-- Telescope wrappers ----------------------------------------------------------

--- Open Telescope find_files under a specific directory.
--- @param dir DirPath
local function telescope_files(dir)
  local builtin = safe_require("telescope.builtin", function()
    vim.notify("Telescope is not installed or failed to load", vim.log.levels.WARN)
  end)
  if not builtin then return end

  builtin.find_files({
    cwd = dir,
    hidden = true,
    no_ignore = false,
    follow = true,
  })
end

--- Open Telescope live_grep with optional multi-directory search.
--- @param dirs string[]
local function telescope_live_grep(dirs)
  local builtin = safe_require("telescope.builtin", function()
    vim.notify("Telescope is not installed or failed to load", vim.log.levels.WARN)
  end)
  if not builtin then return end

  local extra = function()
    -- Include hidden files but skip .git directory (ripgrep)
    return { "--hidden", "--glob", "!.git/*", "--glob", "!**/.git/**" }
  end

  if #dirs <= 1 then
    builtin.live_grep({
      cwd = dirs[1] or (uv.cwd() or vim.fn.getcwd()),
      additional_args = extra,
    })
  else
    builtin.live_grep({
      search_dirs = dirs,
      additional_args = extra,
    })
  end
end

-- fzf-lua wrappers ------------------------------------------------------------

--- Open fzf-lua files under a specific directory.
--- @param dir DirPath
local function fzf_files(dir)
  local fzf = safe_require("fzf-lua", function()
    vim.notify("fzf-lua is not installed or failed to load", vim.log.levels.WARN)
  end)
  if not fzf then return end

  fzf.files({
    cwd = dir,
    -- Follow symlinks, include hidden, strip cwd prefix; exclude .git aggressively
    fd_opts = "--follow --hidden --strip-cwd-prefix --exclude .git",
  })
end

--- Open fzf-lua live_grep under a specific directory (modern API).
--- @param dir DirPath
local function fzf_live_grep(dir)
  local fzf = safe_require("fzf-lua", function()
    vim.notify("fzf-lua is not installed or failed to load", vim.log.levels.WARN)
  end)
  if not fzf then return end

  -- Use modern API: live_grep (glob parsing enabled by default).
  fzf.live_grep({
    cwd = dir,
    rg_opts = table.concat({
      "--line-number",
      "--column",
      "--no-heading",
      "--color=never",
      "--smart-case",
      "--hidden",
      "--glob", "!.git/*",
      "--glob", "!**/.git/**",
    }, " "),
  })
end

-- User command handlers -------------------------------------------------------

--- :FindFilesTelescope [dir]
--- @param opts {args:string}
local function cmd_find_files_telescope(opts)
  local dirs = parse_dirs(opts.args)
  telescope_files(dirs[1])
end

--- :GrepTelescope [dir ...]
--- @param opts {args:string}
local function cmd_grep_telescope(opts)
  local dirs = parse_dirs(opts.args)
  telescope_live_grep(dirs)
end

--- :FindFilesFzf [dir]
--- @param opts {args:string}
local function cmd_find_files_fzf(opts)
  local dirs = parse_dirs(opts.args)
  fzf_files(dirs[1])
end

--- :GrepFzf [dir]
--- @param opts {args:string}
local function cmd_grep_fzf(opts)
  local dirs = parse_dirs(opts.args)
  fzf_live_grep(dirs[1])
end

-- Public API ------------------------------------------------------------------

--- Setup the module. Registers user commands and keymaps (idempotent).
--- @param cfg? UsrPickersConfig
--- @return nil
function M.setup(cfg)
  ---@type UsrPickersConfig
  local C = vim.tbl_deep_extend("force", DEFAULTS, cfg or {})

  define_user_command(C.commands.find_files_telescope, cmd_find_files_telescope, {
    nargs = "?",
    complete = "dir",
    desc = "Telescope find_files with optional cwd",
  })

  define_user_command(C.commands.grep_telescope, cmd_grep_telescope, {
    nargs = "*",
    complete = "dir",
    desc = "Telescope live_grep with optional multiple directories",
  })

  define_user_command(C.commands.find_files_fzf, cmd_find_files_fzf, {
    nargs = "?",
    complete = "dir",
    desc = "fzf-lua: files under optional cwd",
  })

  define_user_command(C.commands.grep_fzf, cmd_grep_fzf, {
    nargs = "?",
    complete = "dir",
    desc = "fzf-lua: ripgrep under optional cwd",
  })

  if C.enable_keymaps then
    local tel_files_key = C.keys.tel_files   -- <leader>telf
    local tel_grep_key  = C.keys.tel_grep    -- <leader>telg
    local fzf_files_key = C.keys.fzf_files   -- <leader>fzff
    local fzf_grep_key  = C.keys.fzf_grep    -- <leader>fzfg

    -- Telescope → files in chosen directory
    vim.keymap.set("n", tel_files_key, function()
      local dir = prompt_dir("Telescope files")
      if dir then telescope_files(dir) end
    end, { desc = "Telescope: files in chosen directory" })

    -- Telescope → live_grep in chosen directory
    vim.keymap.set("n", tel_grep_key, function()
      local dir = prompt_dir("Telescope live_grep")
      if dir then telescope_live_grep({ dir }) end
    end, { desc = "Telescope: live_grep in chosen directory" })

    -- fzf-lua → files in chosen directory
    vim.keymap.set("n", fzf_files_key, function()
      local dir = prompt_dir("fzf-lua files")
      if dir tlen fzf_files(dir) end
    end, { desc = "fzf-lua: files in chosen directory" })

    -- fzf-lua → live_grep in chosen directory
    vim.keymap.set("n", fzf_grep_key, function()
      local dir = prompt_dir("fzf-lua live_grep")
      if dir then fzf_live_grep(dir) end
    end, { desc = "fzf-lua: live_grep in chosen directory" })
  end
end

-- Set up once on first require
M.setup()

return M
