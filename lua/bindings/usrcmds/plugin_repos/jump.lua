---@module 'bindings.usrcmds.plugin_repos.jump'
---@brief `:MyPlugins jumpTo <name>` -- open the install spec of a personal plugin.
---@description
--- Scans the per-category spec files in `lua/plugins/personal/specs/` for the
--- line that declares `"<owner>/<name>"` as the first element of a lazy spec
--- (`{ "owner/name", ... }`, or a bare `"owner/name",` line directly after a
--- lone `{` / `return {`) and opens that file with the cursor on it. Plain
--- text scan, no spec evaluation: the spec files are the source of truth and
--- the line is what the user wants to edit. Independent of
--- `plugins.personal.core.list`, so a plugin whose source mode is "disabled"
--- (absent from that list) can still be jumped to.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos]")

local M = {}

---Directory holding the per-category spec files.
---@return string
local function specs_dir()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "plugins", "personal", "specs")
end

---The repo string a line declares as a spec head, if any. The repo must be the
---first thing on the line (optionally behind `{`); a bare string only counts
---right after a lone `{` or `return {`, so an entry of a `dependencies = {`
---list is not mistaken for the declaration.
---@param line string
---@param prev string Previous non-comment, non-blank line
---@return string|nil repo "owner/name"
local function spec_head(line, prev)
  local inline, repo = line:match("^%s*({?)%s*[\"']([%w_.%-]+/[%w_.%-]+)[\"']")
  if not repo then
    return nil
  end
  if
    inline == "{"
    or prev:match("^%s*{%s*$")
    or prev:match("^%s*{%s*%-%-")
    or prev:match("^%s*return%s*{%s*$")
  then
    return repo
  end
  return nil
end

---@class PluginRepos.Jump.Head
---@field repo string "owner/name"
---@field file string
---@field lnum integer
---@field col integer 1-based column of the opening quote

---Scan results per spec directory, valid while the (mtime, size) signature of its files is
---unchanged. `names()` runs on every Tab press of the completion and the spec files change
---only on a config edit, so re-reading ~7500 lines each time (about 10 ms) is wasted work.
---@type table<string, { sig: string, heads: PluginRepos.Jump.Head[] }>
local cache = {}

---Every spec head of every spec file, in file-name order.
---@param dir string
---@return PluginRepos.Jump.Head[]
local function heads_of(dir)
  -- An explicit check: readdir() on a missing directory prints E484 instead of raising.
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end
  local ok_dir, names = pcall(vim.fn.readdir, dir)
  if not ok_dir then
    return {}
  end
  table.sort(names)

  local files, sig = {}, {}
  for _, fname in ipairs(names) do
    if fname:match("%.lua$") then
      local file = vim.fs.joinpath(dir, fname)
      local st = vim.uv.fs_stat(file)
      files[#files + 1] = file
      sig[#sig + 1] = st and ("%s:%d.%d:%d"):format(fname, st.mtime.sec, st.mtime.nsec, st.size)
        or fname
    end
  end
  local signature = table.concat(sig, "|")
  local cached = cache[dir]
  if cached and cached.sig == signature then
    return cached.heads
  end

  ---@type PluginRepos.Jump.Head[]
  local heads = {}
  for _, file in ipairs(files) do
    local ok, lines = pcall(vim.fn.readfile, file)
    if ok then
      local prev = ""
      for lnum, line in ipairs(lines) do
        local repo = spec_head(line, prev)
        if repo then
          heads[#heads + 1] =
            { repo = repo, file = file, lnum = lnum, col = line:find("[\"']") or 1 }
        end
        if line:match("%S") and not line:match("^%s*%-%-") then
          prev = line
        end
      end
    end
  end
  cache[dir] = { sig = signature, heads = heads }
  return heads
end

---Locate the spec declaration of a plugin (first match in file-name order).
---@param name string Plugin basename, e.g. "sessions.nvim"; case-insensitive
---@param dir? string Spec directory (default: the config's `plugins/personal/specs`)
---@return { file: string, lnum: integer, col: integer }|nil
function M.find(name, dir)
  local want = name:lower()
  for _, head in ipairs(heads_of(dir or specs_dir())) do
    if head.repo:lower():match("/(.+)$") == want then
      return { file = head.file, lnum = head.lnum, col = head.col }
    end
  end
  return nil
end

---Basenames of every plugin that has a spec head, sorted and unique.
---@param dir? string
---@return string[]
function M.names(dir)
  local seen, out = {}, {}
  for _, head in ipairs(heads_of(dir or specs_dir())) do
    local base = head.repo:match("/(.+)$")
    if base and not seen[base] then
      seen[base] = true
      out[#out + 1] = base
    end
  end
  table.sort(out)
  return out
end

---Whether `file` is the file the current buffer shows.
---@param file string
---@return boolean
local function is_current_file(file)
  local current = vim.api.nvim_buf_get_name(0)
  if current == "" then
    return false
  end
  local a, b = vim.fs.normalize(current), vim.fs.normalize(file)
  if vim.fn.has("win32") == 1 then
    a, b = a:lower(), b:lower()
  end
  return a == b
end

---Open the spec file of `name` at its declaration.
---@param name string
---@param dir? string
---@return boolean ok
function M.jump(name, dir)
  local hit = M.find(name, dir)
  if not hit then
    notify.warn(("No install spec for '%s' found in plugins/personal/specs"):format(name))
    return false
  end
  -- Same file: only move the cursor. `:edit` of the current buffer fails with E37 while it has
  -- unsaved changes, and jumping between two plugins of one (being edited) spec file is the
  -- main use of this command.
  if not is_current_file(hit.file) then
    -- :edit can fail (E37 with 'nohidden' and a modified buffer, E1513 in a 'winfixbuf' window).
    -- `magic.file = false`: the path is literal, `%`, `#` and `$VAR` are not expanded.
    local ok, err = pcall(vim.cmd.edit, { args = { hit.file }, magic = { file = false } })
    if not ok then
      notify.error(("Cannot open %s: %s"):format(hit.file, tostring(err)))
      return false
    end
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { hit.lnum, hit.col - 1 })
  vim.cmd("normal! zz")
  return true
end

return M
