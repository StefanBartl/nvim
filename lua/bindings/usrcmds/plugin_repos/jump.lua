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

---Visit every spec head of every spec file, in file-name order. `visit`
---returns true to stop the scan.
---@param dir string
---@param visit fun(repo: string, file: string, lnum: integer, col: integer): boolean|nil
local function each_head(dir, visit)
  local ok_dir, names = pcall(vim.fn.readdir, dir)
  if not ok_dir then
    return
  end
  table.sort(names)
  for _, fname in ipairs(names) do
    if fname:match("%.lua$") then
      local file = vim.fs.joinpath(dir, fname)
      local ok, lines = pcall(vim.fn.readfile, file)
      if ok then
        local prev = ""
        for lnum, line in ipairs(lines) do
          local repo = spec_head(line, prev)
          if repo and visit(repo, file, lnum, line:find("[\"']") or 1) then
            return
          end
          if line:match("%S") and not line:match("^%s*%-%-") then
            prev = line
          end
        end
      end
    end
  end
end

---Locate the spec declaration of a plugin (first match in file-name order).
---@param name string Plugin basename, e.g. "sessions.nvim"; case-insensitive
---@param dir? string Spec directory (default: the config's `plugins/personal/specs`)
---@return { file: string, lnum: integer, col: integer }|nil
function M.find(name, dir)
  local want = name:lower()
  local hit
  each_head(dir or specs_dir(), function(repo, file, lnum, col)
    if repo:lower():match("/(.+)$") == want then
      hit = { file = file, lnum = lnum, col = col }
      return true
    end
  end)
  return hit
end

---Basenames of every plugin that has a spec head, sorted and unique.
---@param dir? string
---@return string[]
function M.names(dir)
  local seen, out = {}, {}
  each_head(dir or specs_dir(), function(repo)
    local base = repo:match("/(.+)$")
    if base and not seen[base] then
      seen[base] = true
      out[#out + 1] = base
    end
  end)
  table.sort(out)
  return out
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
  -- :edit can fail (E37 with 'nohidden' and a modified buffer, E1513 in a 'winfixbuf' window).
  local ok, err = pcall(vim.cmd.edit, { args = { hit.file } })
  if not ok then
    notify.error(("Cannot open %s: %s"):format(hit.file, tostring(err)))
    return false
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { hit.lnum, hit.col - 1 })
  vim.cmd("normal! zz")
  return true
end

return M
