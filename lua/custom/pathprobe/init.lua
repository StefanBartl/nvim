---@module 'pathprobe'
--- Resolve truncated file-path tails from error messages into real absolute paths and open them.
--- This module provides a visual/normal-mode mapping (<leader>pp) that:
---   1) reads the visual selection (preferred) or <cfile> under the cursor,
---   2) sanitizes it (strip quotes, trailing punctuation, :line[:col]),
---   3) constructs suffix candidates from the last N path components,
---   4) searches multiple sensible roots (buffer dir, CWD, git root, stdpath data/config),
---   5) picks the best match (shortest abs path; asks via vim.ui.select on ambiguity),
---   6) opens the file in a new window and jumps to line/column.
---
--- Design notes:
--- - Pure Lua using vim.fs.find (Neovim ≥0.9) and vim.fs.normalize (≥0.10) with fallbacks.

local M = {}

local uv = vim.uv or vim.loop

-- Local aliases (micro-optimizations are negligible, but keep code tidy)
local fn, api, fs = vim.fn, vim.api, vim.fs

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

--- Check if a path exists and is a directory.
---@param p string
---@return boolean
local function is_dir(p)
  if type(p) ~= "string" or p == "" then
    return false
  end
  local st = uv.fs_stat(p)
  return st and st.type == "directory" or false
end

--- Normalize a path using vim.fs.normalize if present; otherwise return input.
---@param p string
---@return string
local function normalize(p)
  if type(p) ~= "string" then
    return ""
  end
  local ok, res = pcall(function()
    if fs and fs.normalize then
      return fs.normalize(p)
    end
    return p
  end)
  return ok and res or p
end

--- Join path segments safely.
---@param a string
---@param b string
---@return string
local function join(a, b)
  return (fs and fs.joinpath and fs.joinpath(a, b)) or (a:gsub("/+$", "") .. "/" .. b:gsub("^/+", ""))
end

--- Return directory of a path.
---@param p string
---@return string
local function dirname(p)
  return (fs and fs.dirname and fs.dirname(p)) or p:match("^(.*)/[^/]+$") or "."
end

--- Remove duplicates while retaining order.
---@param arr string[]
---@return string[]
local function dedup(arr)
  local seen, out = {}, {}
  for _, v in ipairs(arr) do
    if type(v) == "string" and v ~= "" then
      local k = normalize(v)
      if not seen[k] then
        seen[k] = true
        out[#out + 1] = v
      end
    end
  end
  return out
end

--- Ends-with check for full paths, comparing path tails segment-wise.
---@param abs string   -- absolute candidate
---@param tail string  -- suffix like "neo-tree/ui/renderer.lua"
---@return boolean
local function path_ends_with(abs, tail)
  if type(abs) ~= "string" or type(tail) ~= "string" then
    return false
  end
  abs, tail = abs:gsub("\\", "/"), tail:gsub("\\", "/")
  if #tail > #abs then
    return false
  end
  -- Ensure we match on segment boundary, i.e. ".../tail" or exact equal
  if abs:sub(-#tail) ~= tail then
    return false
  end
  if #abs == #tail then
    return true
  end
  local prev = abs:sub(#abs - #tail, #abs - #tail)
  return prev == "/"
end

--- Parse ":line[:col]" at the end (also tolerates a trailing colon like ":805:").
---@param s string
---@return string base, integer|nil line, integer|nil col
local function split_line_col(s)
  -- Strip trailing punctuation, including a dangling colon (common in stacktraces)
  -- Examples:
  --   ".../file.lua:805:"   -> base=".../file.lua", line=805
  --   ".../file.lua:12:34"  -> base=".../file.lua", line=12, col=34
  --   ".../file.lua:12"     -> base=".../file.lua", line=12
  s = s:gsub("[%)%]%.,;:]+$", "")

  -- Full "path:line:col"
  local a, b, l, c = s:find("^(.-):(%d+):(%d+)$")
  if a then
    local base = s:sub(1, a and (b - #(":" .. l .. ":" .. c)) or #s)
    return base, tonumber(l), tonumber(c)
  end

  -- Simple "path:line"
  local a2, b2, l2 = s:find("^(.-):(%d+)$")
  if a2 then
    local base = s:sub(1, a2 and (b2 - #(":" .. l2)) or #s)
    return base, tonumber(l2), nil
  end

  return s, nil, nil
end

--- Sanitize a rough token into a path-like tail.
---@param s string
---@return string
local function sanitize_token(s)
  if type(s) ~= "string" then
    return ""
  end
  -- Replace Windows slashes just in case; drop quotes and ellipses
  s = s:gsub("\\", "/"):gsub("[\"'`]+", ""):gsub("^%.*%/*", "")
  -- Drop leading drive letters like "C:/" remnants (not used on POSIX, but harmless)
  s = s:gsub("^%u:/", "")
  -- Keep only path-ish characters
  s = s:gsub("[^%w%._%-%/]+", "/")
  -- Collapse duplicate slashes
  s = s:gsub("/+", "/")
  return s
end

--- Split into path segments.
---@param tail string
---@return string[]
local function split_segments(tail)
  local segs = {}
  for part in tail:gmatch("[^/]+") do
    if part ~= "" then
      segs[#segs + 1] = part
    end
  end
  return segs
end

--- Produce suffix candidates from the last N components, longest-first.
---@param tail string
---@param max_components integer
---@return string[]
local function suffix_candidates(tail, max_components)
  local segs = split_segments(tail)
  local n = #segs
  if n == 0 then
    return {}
  end
  local maxc = math.max(1, math.min(max_components, n))
  local out = {}
  for k = maxc, 1, -1 do
    local start = n - k + 1
    local t = table.concat(segs, "/", start, n)
    out[#out + 1] = t
  end
  return out
end

--- Attempt to get a git root for a given directory.
---@param dir string
---@return string|nil
local function git_root(dir)
  if not is_dir(dir) then
    return nil
  end
  local ok, proc = pcall(vim.system, { "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true })
  if not ok or not proc then
    return nil
  end
  local res = proc:wait()
  if res.code ~= 0 or not res.stdout or res.stdout == "" then
    return nil
  end
  local root = res.stdout:gsub("%s+$", "")
  return is_dir(root) and root or nil
end

--- Guess sensible search roots.
---@return string[]
local function guess_roots()
  local roots = {}
  local cwd = (uv.cwd and uv.cwd()) or fn.getcwd()
  local buf = api.nvim_buf_get_name(0)
  local bufdir = buf ~= "" and dirname(buf) or nil
  local cfg = fn.stdpath("config")
  local data = fn.stdpath("data")
  local cache = fn.stdpath("cache")
  if bufdir and is_dir(bufdir) then
    roots[#roots + 1] = bufdir
  end
  if cwd and is_dir(cwd) then
    roots[#roots + 1] = cwd
  end
  local g = (bufdir and git_root(bufdir)) or (cwd and git_root(cwd)) or nil
  if g then
    roots[#roots + 1] = g
  end
  if is_dir(cfg) then
    roots[#roots + 1] = cfg
  end
  if is_dir(data) then
    roots[#roots + 1] = data
  end
  if is_dir(cache) then
    roots[#roots + 1] = cache
  end
  return dedup(roots)
end

--- Search for matches using vim.fs.find with a predicate.
---@param tail string
---@param roots string[]
---@param limit integer
---@return string[]
local function find_by_tail(tail, roots, limit)
  local results = {}
  local max_hits = math.max(1, limit or 100)
  local total = 0
  for _, r in ipairs(roots) do
    local ok, hits = pcall(fs.find, function(name, path)
      -- name is basename; path is directory
      local abs = join(path, name)
      return path_ends_with(abs, tail)
    end, { path = r, type = "file", limit = max_hits })
    if ok and type(hits) == "table" then
      for _, p in ipairs(hits) do
        results[#results + 1] = normalize(p)
        total = total + 1
        if total >= max_hits then
          return results
        end
      end
    end
  end
  return results
end

--- Pick the "best" match. Heuristic: shortest absolute path.
---@param matches string[]
---@return string|nil
local function pick_best(matches)
  local best, best_len = nil, math.huge
  for _, m in ipairs(matches) do
    local L = #m
    if L < best_len then
      best, best_len = m, L
    end
  end
  return best
end

--- Open file and jump to line/col robustly.
---@param path string
---@param open_cmd '"vsplit"'|'"split"'|'"edit"'
---@param line integer|nil
---@param col integer|nil
---@return boolean
local function open_and_jump(path, open_cmd, line, col)
  if type(path) ~= "string" or path == "" then
    return false
  end
  local cmd = open_cmd or "vsplit"
  if cmd ~= "vsplit" and cmd ~= "split" and cmd ~= "edit" then
    cmd = "vsplit"
  end

  -- Use +{lnum} in the ex command so the cursor lands at the line before autocmds can move it.
  -- keepalt to preserve jumplist metadata; fnameescape for safety.
  if line and line > 0 then
    vim.cmd(string.format("keepalt %s +%d %s", cmd, line, vim.fn.fnameescape(path)))
  else
    vim.cmd(string.format("keepalt %s %s", cmd, vim.fn.fnameescape(path)))
  end

  -- If a column is provided, set it asynchronously after the buffer is fully displayed.
  if col and col > 0 then
    local l = math.max(1, line or vim.api.nvim_win_get_cursor(0)[1])
    local c = math.max(0, col - 1)
    vim.schedule(function()
      -- Guard: window may have changed; still set on current window (target split is current)
      pcall(vim.api.nvim_win_set_cursor, 0, { l, c })
    end)
  end

  return true
end
--------------------------------------------------------------------------------
-- Selection extraction
--------------------------------------------------------------------------------

--- Get visual selection (single line), trimmed. Returns nil if not in visual mode.
---@return string|nil
local function get_visual_selection_line()
  local mode = api.nvim_get_mode().mode
  if mode ~= "v" and mode ~= "V" and mode ~= "\022" then
    return nil
  end -- char, line, block
  -- Get marks '< and '>
  local srow, scol = unpack(api.nvim_buf_get_mark(0, "<"))
  local erow, ecol = unpack(api.nvim_buf_get_mark(0, ">"))
  if srow == 0 or erow == 0 then
    return nil
  end
  if srow ~= erow then
    -- Prefer the line under the cursor if multi-line; paths are usually single-line in messages
    local line = api.nvim_get_current_line()
    return line and line:match("%S+") and line or line
  end
  local line = api.nvim_buf_get_lines(0, srow - 1, srow, false)[1] or ""
  local i = math.min(scol + 1, #line + 1)
  local j = math.min(ecol + 1, #line + 1)
  if j < i then
    i, j = j, i
  end
  local slice = line:sub(i, j)
  slice = slice:gsub("^%s+", ""):gsub("%s+$", "")
  return slice ~= "" and slice or nil
end

--- Get a path-ish token in normal mode. Prefer <cfile>, fallback to word under cursor.
---@return string|nil
local function get_normal_token()
  local tok = fn.expand("<cfile>")
  if type(tok) == "string" and tok ~= "" then
    return tok
  end
  tok = fn.expand("<cword>")
  return (type(tok) == "string" and tok ~= "") and tok or nil
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Resolve and open from current selection or cursor.
---@param opts Custom.PathProbe.Opts|nil
---@return boolean
function M.probe(opts)
  opts = opts or {}
  local max_components = tonumber(opts.max_components or 6) or 6
  local ask = opts.ask_on_ambiguous ~= false
  local open_cmd = opts.open_cmd or "vsplit"

  -- 1) Extract token
  local raw = get_visual_selection_line() or get_normal_token()
  if not raw then
    vim.notify(
      "[pathprobe] No path-like token found. Select a path segment or place cursor on it.",
      vim.log.levels.WARN
    )
    return false
  end

  -- 2) Split :line:col, then sanitize
  local base, line, col = split_line_col(raw)
  local tail = sanitize_token(base)
  if tail == "" then
    vim.notify("[pathprobe] Token is not a recognizable path.", vim.log.levels.WARN)
    return false
  end

  -- 3) Determine roots
  local roots = opts.search_roots
  if type(roots) ~= "table" or #roots == 0 then
    roots = guess_roots()
  end
  if #roots == 0 then
    vim.notify("[pathprobe] No search roots available.", vim.log.levels.ERROR)
    return false
  end

  -- 4) Try suffix candidates, longest-first
  local candidates = suffix_candidates(tail, max_components)
  local all_matches = {}
  for _, suf in ipairs(candidates) do
    local found = find_by_tail(suf, roots, 150)
    for _, p in ipairs(found) do
      all_matches[#all_matches + 1] = p
    end
    if #found == 1 then
      return open_and_jump(found[1], open_cmd, line, col)
    elseif #found > 1 then
      -- Accumulate and continue; longer suffix may already disambiguate, but we’ll offer a picker later if needed
    end
  end

  if #all_matches == 0 then
    vim.notify(string.format("[pathprobe] No match for '%s' in %d roots.", tail, #roots), vim.log.levels.WARN)
    return false
  end

  -- 5) Disambiguate
  local best = pick_best(all_matches)
  if not ask or #all_matches == 1 then
    return open_and_jump(best or all_matches[1], open_cmd, line, col)
  end

  vim.ui.select(all_matches, {
    prompt = "Multiple matches – pick one",
    format_item = function(item)
      local rel = item
      -- try to make a nice relative display against the first root
      local r0 = roots[1]
      if type(r0) == "string" and #r0 > 1 and item:sub(1, #r0) == r0 then
        rel = "./" .. item:sub(#r0 + 2)
      end
      return rel
    end,
  }, function(choice)
    if choice then
      open_and_jump(choice, open_cmd, line, col)
    end
  end)

  return true
end

--- Create default keymaps and user command.
---@return nil
function M.enable_keymaps()
  -- Normal mode: <leader>pp probes the token under cursor
  api.nvim_set_keymap(
    "n",
    "<leader>pp",
    [[<cmd>lua require('pathprobe').probe({ open_cmd = "vsplit", ask_on_ambiguous = true })<CR>]],
    { noremap = true, silent = true, desc = "PathProbe: resolve truncated path tail and open" }
  )

  -- Visual mode: <leader>pp probes the selection
  api.nvim_set_keymap(
    "v",
    "<leader>pp",
    [[:<C-U>lua require('pathprobe').probe({ open_cmd = "vsplit", ask_on_ambiguous = true })<CR>]],
    { noremap = true, silent = true, desc = "PathProbe: resolve selected truncated path tail and open" }
  )

  -- Optional command: :PathProbe[!] reads selection if visual, else <cfile>.
  -- :PathProbe! uses :split instead of :vsplit
  api.nvim_create_user_command("PathProbe", function(cmd)
    local open_cmd = cmd.bang and "split" or "vsplit"
    M.probe({ open_cmd = open_cmd, ask_on_ambiguous = true })
  end, { desc = "Resolve truncated path tail and open file; use ! for horizontal split" })
end

return M
