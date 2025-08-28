---@module 'utils.open_path.helpers'
--- Path detection, normalization, probing and small OS helpers.

---@class Helpers
local H = {}

--- Get a safe current working directory string.
---@return string
function H.safe_cwd()
  local uv = (vim.uv or vim.loop)
  local cwd = uv.cwd()
  if type(cwd) == "string" and cwd ~= "" then
    return cwd
  end
  return vim.fn.getcwd()
end

--- Return lowercased kernel release, or "" if unavailable.
---@return string
function H.os_release_lower()
  local uv = (vim.uv or vim.loop)
  local uts = uv.os_uname()
  local rel = uts and uts.release
  if type(rel) == "string" then
    return string.lower(rel)
  end
  return ""
end

--- Determine platform.
---@return boolean, boolean, boolean, boolean  -- is_windows, is_macos, is_unix, is_wsl
function H.platform()
  local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  local is_macos = vim.fn.has("mac") == 1
  local is_unix = vim.fn.has("unix") == 1
  local rel = H.os_release_lower()
  local is_wsl = (vim.fn.has("wsl") == 1) or (rel:find("microsoft", 1, true) ~= nil)
  return is_windows, is_macos, is_unix, is_wsl
end

--- Extract a file-like token under the cursor with optional :line[:col] suffix.
--- Supports `<cfile>` first, then falls back to regex scanning similar to your FM module.  :contentReference[oaicite:1]{index=1}
---@return string|nil path       -- Raw path token (may be relative)
---@return integer|nil line      -- 1-based line if provided
---@return integer|nil col       -- 1-based column if provided
function H.token_under_cursor()
  local function strip_quotes(s) return (s:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")) end
  local function strip_trailing_punct(s) return (s:gsub('[%s%)]*$', ""):gsub('[]%)}"\'.,;:]+$', "")) end
  local function expand_user(p) return p:sub(1,1) == "~" and vim.fn.expand(p) or p end

  local p = vim.fn.expand("<cfile>")
  p = expand_user(strip_trailing_punct(strip_quotes(p)))
  if p ~= "" then
    -- Check for :line[:col] suffix directly in the buffer text after the token
    local ln = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local _, e = ln:find(vim.pesc(p), 1, false)
    if e then
      local rest = ln:sub(e + 1)
      local lnum, cnum = rest:match("^:(%d+):?(%d*)")
      local line = lnum and tonumber(lnum) or nil
      local colnum = (cnum and cnum ~= "") and tonumber(cnum) or nil
      return p, line, colnum
    end
    return p, nil, nil
  end

  -- Fallback scans
  local line = vim.api.nvim_get_current_line()
  local win = line:match("([A-Za-z]:\\[^%s]+)") or line:match("([A-Za-z]:/[^%s]+)")
  if win then
    win = expand_user(strip_trailing_punct(strip_quotes(win)))
    local lnum, cnum = line:match(vim.pesc(win) .. ":(%d+):?(%d*)")
    return win, lnum and tonumber(lnum) or nil, (cnum ~= "" and tonumber(cnum) or nil)
  end
  local unc = line:match("(\\\\[^%s]+)")
  if unc then
    unc = expand_user(strip_trailing_punct(strip_quotes(unc)))
    local lnum, cnum = line:match(vim.pesc(unc) .. ":(%d+):?(%d*)")
    return unc, lnum and tonumber(lnum) or nil, (cnum ~= "" and tonumber(cnum) or nil)
  end
  local unix = line:match("(/[^%s]+)")
  if unix then
    unix = expand_user(strip_trailing_punct(strip_quotes(unix)))
    local lnum, cnum = line:match(vim.pesc(unix) .. ":(%d+):?(%d*)")
    return unix, lnum and tonumber(lnum) or nil, (cnum ~= "" and tonumber(cnum) or nil)
  end

  return nil, nil, nil
end

--- Normalize to absolute path and probe the filesystem.
---@param raw string
---@return DetectedPath|nil
function H.normalize_and_probe(raw)
  if not raw or raw == "" then return nil end
  local abs = vim.fn.fnamemodify(raw, ":p")
  local uv = (vim.uv or vim.loop)
  local stat = uv.fs_stat(abs)
  if not stat then return nil end
  local is_dir = (stat.type == "directory")
  ---@type DetectedPath
  local out = { abs = abs, is_dir = is_dir, line = nil, col = nil }
  return out
end

--- Jump to line/col if provided.
---@param line integer|nil
---@param col integer|nil
function H.jump_if_needed(line, col)
  if line and line > 0 then
    vim.api.nvim_win_set_cursor(0, { line, math.max((col or 1) - 1, 0) })
  end
end

return H
