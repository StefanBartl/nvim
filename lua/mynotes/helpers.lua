---@module 'mynotes.helpers'

local M = {}

local fn = vim.fn
local levels = vim.log.levels

--- Cheap notifier with level.
---@param msg string
---@param level integer
---@param debug boolean|nil
local function note(msg, level, debug)
  if debug ~= false then
    vim.notify("[MyNotes " .. msg, level)
  end
end

--- Normalize directory and ensure it exists.
---@nodiscard
---@param path string
---@return string|nil norm
function M.norm_dir(path)
  local p = fn.expand(path)
  local st = vim.loop.fs_stat(p)
  if not st or st.type ~= "directory" then
    note(("Directory does not exist: %s"):format(p), levels.ERROR)
    return nil
  end
  return p
end

--- Check presence of ripgrep; warn if missing (both engines rely on it).
---@return boolean
local function assert_rg()
  if fn.executable("rg") ~= 1 then
    note("ripgrep (rg) not found in PATH; live grep will not work.", levels.ERROR)
    return false
  end
  return true
end

-- fzf-lua adapter ------------------------------------------------------------

---@nodiscard
---@return boolean ok, table|nil mod
---@return nil
local function try_fzf()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    note("fzf-lua is not available (require failed).", levels.WARN)
    return false, nil
  end
  return true, fzf
end

--- fzf-lua: find files with preview, fixed cwd and custom prompt.
---@param cwd_fn function cwd fn
---@param title string|nil Optional prompt title
---@return nil
function M.fzf_files(cwd_fn, title)
  assert(cwd_fn and type(cwd_fn) == "function", "cwd_fn must be a function")

  local cwd = cwd_fn()
  if not cwd then
    return
  end
  local ok, fzf = try_fzf()
  if not ok or not fzf then
    return
  end
  -- Preview is on by default in fzf-lua; prompt config via `prompt`.
  fzf.files({
    cwd = cwd,
    prompt = (title or "") .. " > ",
  })
end

--- fzf-lua: live grep with preview.
--- Note: `live_grep_glob` is deprecated; use `live_grep` (glob parsing enabled by default).
---@param cwd_fn function cwd fn
---@param title string|nil Optional prompt title
---@return nil
function M.fzf_grep(cwd_fn, title)
  assert(cwd_fn and type(cwd_fn) == "function", "cwd_fn must be a function")

  if not assert_rg() then
    return
  end
  local cwd = cwd_fn()
  if not cwd then
    return
  end
  local ok, fzf = try_fzf()
  if not ok or not fzf then
    return
  end
  fzf.live_grep({
    cwd = cwd,
    prompt = (title or "") .. " > ",
    -- Optional hints:
    -- file_ignore_patterns = { "node_modules", "%.git/", "build/" },
    -- rg_opts = "--hidden --glob '!.git' --line-number --column --smart-case",
  })
end

-- Telescope adapter ----------------------------------------------------------

---@nodiscard
---@return boolean ok, table|nil builtin
local function try_telescope()
  local ok, tb = pcall(require, "telescope.builtin")
  if not ok then
    note("telescope.builtin is not available (require failed).", levels.WARN)
    return false, nil
  end
  return true, tb
end

--- Telescope: find files with preview, fixed cwd and title.
---@param cwd_fn function cwd fn
---@param title string|nil Optional prompt title
---@return nil
function M.tel_files(cwd_fn, title)
  assert(cwd_fn and type(cwd_fn) == "function", "cwd_fn must be a function")

  local cwd = cwd_fn()
  if not cwd then
    return
  end
  local ok, tb = try_telescope()
  if not ok or not tb then
    return
  end
  tb.find_files({
    cwd = cwd,
    prompt_title = title or "",
    previewer = true,
    hidden = true, -- also show dotfiles
  })
end

--- Telescope: live grep with preview, fixed cwd and title.
---@param cwd_fn function cwd fn
---@param title string|nil Optional prompt title
---@return nil
function M.tel_grep(cwd_fn, title)
  assert(cwd_fn and type(cwd_fn) == "function", "cwd_fn must be a function")

  if not assert_rg() then
    return
  end
  local cwd = cwd_fn()
  if not cwd then
    return
  end
  local ok, tb = try_telescope()
  if not ok or not tb then
    return
  end
  tb.live_grep({
    cwd = cwd,
    prompt_title = title or "",
    previewer = true,
  })
end

return M
