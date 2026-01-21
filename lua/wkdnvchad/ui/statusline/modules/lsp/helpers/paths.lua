---@module 'wkdnvchad.ui.statusline.modules.helpers.paths'
--- Path helpers for statusline rendering (pure + fast + robust).
--- This file provides absolute and relative path resolution with proper
--- normalization, Git root detection (incl. worktrees), and home/cwd shortening.

---@type WkdNvC.UI.Stl.Modules.LSP.Cfg.Module
local config_mod = require("lib.lazy").require("wkdnvchad.ui.statusline.modules.lsp.config")

local M = {}

local api, fn, fs, uv = vim.api, vim.fn, vim.fs, vim.uv or vim.loop

-- Memoization cache for expensive operations
local path_cache = require("lib.memo.lru").new(128)

--- Normalize separators, collapse redundancies, unify drive letter case (best-effort).
--- This function is pure and does not touch the filesystem.
---@param s string|uv.uv_fs_t
---@return string
local function norm_sep(s)
  -- Always forward slashes internally; Neovim APIs accept/return both.
  s = tostring(s or ""):gsub("\\", "/")
  -- Collapse duplicate slashes except at prefix like "://"
  s = s:gsub("([^:])/+", "%1/")
  -- Normalize trailing "/." → "/"
  s = s:gsub("/%./", "/")
  -- Drive letter unify case (Windows only; benign elsewhere)
  s = s:gsub("^([A-Za-z]):/", function(d)
    return string.upper(d) .. ":/"
  end)
  return s
end

---@nodiscard
--- Make absolute path; prefer uv.fs_realpath for canonical result.
--- Returns empty string for non-file buffers or errors.
---@param path_or_buf integer|string
---@return string
function M.path_absolute(path_or_buf)
  local cache_key = tostring(path_or_buf)
  local cached = path_cache:get(cache_key)
  if cached then
    return cached
  end

  local path = ""
  if type(path_or_buf) == "number" then
    if not api.nvim_buf_is_loaded(path_or_buf) then
      return ""
    end
    path = api.nvim_buf_get_name(path_or_buf) or ""
  else
    path = tostring(path_or_buf or "")
  end
  if path == "" then
    return ""
  end

  -- Expand to absolute path first; :p handles ~/ and relative buffers
  local abs = fn.fnamemodify(path, ":p")
  -- Try realpath to resolve symlinks; fall back to abs if it fails
  ---@diagnostic disable-next-line fs_realpath exists in uv library
  local ok, real = pcall(uv.fs_realpath, abs)
  local canon = ok and real or abs

  local result = norm_sep(canon)
  path_cache:put(result)

  return result
end

---@nodiscard
--- Find Git root directory for a given file path.
--- Supports .git dir and worktree file that contains "gitdir: <path>".
---@param path string
---@return string|nil
local function find_git_root(path)
  local cache_key = "git_root:" .. path
  local cached = path_cache:get(cache_key)
  if cached then
    return cached
  end

  local dir = fn.fnamemodify(path, ":h")
  -- Use the new root helper (Neovim 0.10+); fallback to fs.find
  local froot = nil
  if fs.root then
    froot = fs.root(dir, ".git")
  else
    local git_hit = (fs.find(".git", { upward = true, path = dir }) or {})[1]
    if git_hit then
      froot = fn.fnamemodify(git_hit, ":h")
    end
  end
  if not froot or froot == "" then
    return nil
  end

  local result

  -- Worktree case: if ".git" is a file, read gitdir pointer and go up to worktree top-level
  local git_path = norm_sep(froot .. "/.git")
  local stat = uv.fs_stat(git_path)
  if stat and stat.type == "file" then
    local fd = uv.fs_open(git_path, "r", 438) -- 0666
    if fd then
      local content = uv.fs_read(fd, stat.size or 4096, 0) or ""
      uv.fs_close(fd)
      local gitdir = content:match("gitdir:%s*(.-)%s*$")
      if gitdir and #gitdir > 0 then
        -- For worktrees, the project root is the directory containing the .git file
        result = norm_sep(froot)
        path_cache:put(cache_key, result)
        return result
      end
    end
  end
  result = norm_sep(froot)
  path_cache:put(cache_key, result)
  return result
end

--- Shorten a path by replacing $HOME prefix with "~" if enabled.
---@param s string
---@return string
local function home_tilde(s)
  local options = config_mod.get_cfg()
  if not options.path_home_tilde then
    return s
  end
  ---@diagnostic disable-next-line lib.uv
  local home = norm_sep(vim.loop.os_homedir() or "")
  if home ~= "" and s:sub(1, #home) == home then
    local rest = s:sub(#home + 1)
    if rest == "" then
      return "~"
    end
    if rest:sub(1, 1) == "/" then
      rest = rest:sub(2)
    end
    return "~/" .. rest
  end
  return s
end

--- Compute a relative path against a given base directory.
--- Falls back to original if not a prefix.
---@param base string
---@param path string
---@return string
local function rel_from(base, path)
  base = norm_sep(base)
  path = norm_sep(path)
  -- Case-insensitive drive prefixes on Windows
  if base:match("^[A-Za-z]:/") and path:match("^[A-Za-z]:/") then
    if base:sub(1, 1) ~= path:sub(1, 1) then
      return path -- different drives → cannot relativize
    end
  end
  if path:sub(1, #base) == base then
    local rest = path:sub(#base + 1)
    if rest == "" then
      return "."
    end
    return (rest:sub(1, 1) == "/") and rest:sub(2) or rest
  end
  return path
end

--- Return a repo-relative, cwd-relative, or home-shortened relative path (pure).
---@param mode '"repo"'|'"cwd"'|'"home"'
---@param path string
---@return string
function M.path_relative(mode, path)
  local abs = M.path_absolute(path)
  if abs == "" then
    return "[No Name]"
  end

  local cache_key = mode .. ":" .. abs
  local cached = path_cache:get(cache_key)
  if cached then
    return cached
  end

  local result
  if mode == "repo" then
    local root = find_git_root(abs)
    if root and #root > 0 then
      local rel = rel_from(root, abs)
      -- Make sure we don't display a bare "."; keep at least filename
      if rel == "." then
        result = fn.fnamemodify(abs, ":t")
      end
      result = rel
    end
    -- No repo → fall through to home or cwd according to taste; here: home
    ---@diagnostic disable-next-line lib.uv
    return home_tilde(rel_from(vim.loop.os_homedir() or "", abs))
  elseif mode == "cwd" then
    local cwd = norm_sep(fn.getcwd())
    result = rel_from(cwd, abs)
  else -- "home"
    result = home_tilde(abs)
  end

  path_cache:put(cache_key, result)
  return result
end

--- Public: choose display path according to configured strategy.
--- "auto": repo if available, else cwd, else absolute with home-tilde.
---@param _cfg { path_mode?: WkdNvC.UI.Stl.Modules.Based.PathMode_t, path_home_tilde?: boolean }|nil
---@param path_or_buf integer|string
---@return string
function M.display_path(_cfg, path_or_buf)
  if type(_cfg) == "table" then
    if _cfg.path_mode ~= nil then
      config_mod.set("path_mode", _cfg.path_mode)
    end

    if _cfg.path_home_tilde ~= nil then
      config_mod.set("path_home_tilde", not not _cfg.path_home_tilde)
    end
  end

  local abs = M.path_absolute(path_or_buf)
  if abs == "" then
    return "[No Name]"
  end

  local mode = M.cfg.path_mode or "auto"
  if mode == "absolute" then
    return home_tilde(abs)
  elseif mode == "repo" then
    return M.path_relative("repo", abs)
  elseif mode == "cwd" then
    return M.path_relative("cwd", abs)
  elseif mode == "home" then
    return M.path_relative("home", abs)
  else -- "auto"
    local root = find_git_root(abs)
    if root then
      return rel_from(root, abs)
    end
    local cwd = norm_sep(fn.getcwd())
    local rel = rel_from(cwd, abs)
    if rel ~= abs then
      return rel
    end
    return home_tilde(abs)
  end
end

---@nodiscard
---@param bufnr integer
---@return string
function M.display_path_for_buf(bufnr)
  local options = config_mod.get_cfg()
  return M.display_path(
    { path_mode = options.path_mode, path_home_tilde = options.path_home_tilde },
    bufnr
  )
end

return M
