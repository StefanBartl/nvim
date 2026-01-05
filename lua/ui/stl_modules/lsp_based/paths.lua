---@module 'ui.stl_modules.lsp_based.paths'
--- Path helpers for statusline rendering (pure + fast + robust).
--- This file provides absolute and relative path resolution with proper
--- normalization, Git root detection (incl. worktrees), and home/cwd shortening.

local api, fn, fs, uv = vim.api, vim.fn, vim.fs, vim.uv or vim.loop

local P = {}

-- Configuration is injected/linked from lsp_based; keep defaults here for safety.
---@type UI.Stl_Modules.LSP_Based.LspStlPathCfg
P.cfg = {
  path_mode = "auto", -- "auto"|"repo"|"cwd"|"absolute"
  path_home_tilde = true, -- replace $HOME prefix by "~"
}

--- Normalize separators, collapse redundancies, unify drive letter case (best-effort).
--- This function is pure and does not touch the filesystem.
---@param s string
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

--- Make absolute path; prefer uv.fs_realpath for canonical result.
--- Returns empty string for non-file buffers or errors.
---@param path_or_buf integer|string
---@return string
function P.path_absolute(path_or_buf)
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
  ---@diagnostic disable-next-line uv library
  return norm_sep(canon)
end

--- Find Git root directory for a given file path.
--- Supports .git dir and worktree file that contains "gitdir: <path>".
---@param path string
---@return string|nil
local function find_git_root(path)
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
        return norm_sep(froot)
      end
    end
  end
  return norm_sep(froot)
end

--- Shorten a path by replacing $HOME prefix with "~" if enabled.
---@param s string
---@return string
local function home_tilde(s)
  if not P.cfg.path_home_tilde then
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
function P.path_relative(mode, path)
  local abs = P.path_absolute(path)
  if abs == "" then
    return "[No Name]"
  end

  if mode == "repo" then
    local root = find_git_root(abs)
    if root and #root > 0 then
      local rel = rel_from(root, abs)
      -- Make sure we don't display a bare "."; keep at least filename
      if rel == "." then
        return fn.fnamemodify(abs, ":t")
      end
      return rel
    end
    -- No repo → fall through to home or cwd according to taste; here: home
    ---@diagnostic disable-next-line lib.uv
    return home_tilde(rel_from(vim.loop.os_homedir() or "", abs))
  elseif mode == "cwd" then
    local cwd = norm_sep(fn.getcwd())
    return rel_from(cwd, abs)
  else -- "home"
    return home_tilde(abs)
  end
end

--- Public: choose display path according to configured strategy.
--- "auto": repo if available, else cwd, else absolute with home-tilde.
---@param cfg { path_mode?: string, path_home_tilde?: boolean }|nil
---@param path_or_buf integer|string
---@return string
function P.display_path(cfg, path_or_buf)
  if type(cfg) == "table" then
    if cfg.path_mode then
      P.cfg.path_mode = cfg.path_mode
    end
    if cfg.path_home_tilde ~= nil then
      P.cfg.path_home_tilde = not not cfg.path_home_tilde
    end
  end
  local abs = P.path_absolute(path_or_buf)
  if abs == "" then
    return "[No Name]"
  end

  local mode = P.cfg.path_mode or "auto"
  if mode == "absolute" then
    return home_tilde(abs)
  elseif mode == "repo" then
    return P.path_relative("repo", abs)
  elseif mode == "cwd" then
    return P.path_relative("cwd", abs)
  elseif mode == "home" then
    return P.path_relative("home", abs)
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

return P
