---@module 'bindings.usrcmds.bindings_explorer.config'
--- Where the BINDINGS corpus lives, and — for `drift.lua`'s repo axis — where
--- the local plugin checkouts are. Feature docs: docs/FEATURES.md.

local M = {}

--- CDX: `BND-05` (see docs/FEATURES.md) removed the
--- `docs/NOTES/PersonelPlugins/BINDINGS/` tree; the corpus now reads each
--- plugin's own `docs/BINDINGS.md` via `M.plugin_sheets()`. `roots()[1]` still
--- points at that missing dir — the `isdirectory` guards make the corpus walk
--- harmless, but `:Bindings path personal` copies a dead path. Prune roots()
--- to Extern-only?

--- Both BINDINGS roots, absolute.
---@return string[]
function M.roots()
  local cfg = vim.fn.stdpath("config")
  return {
    vim.fs.joinpath(cfg, "docs", "NOTES", "PersonelPlugins", "BINDINGS"),
    vim.fs.joinpath(cfg, "docs", "NOTES", "ExternPlugins", "Bindings"),
  }
end

---@class Bindings.PluginSheet
---@field plugin string plugin name, also `records.lua`'s `plugin` field, e.g. "hover.nvim".
---@field file string absolute path to its `docs/BINDINGS.md`.

--- Where a personal plugin's `docs/BINDINGS.md` sits — local checkout first,
--- because that's what gets worked on: someone who just documented a binding
--- wants it in `:Bindings` now, not after the next `:Lazy update`. Missing
--- (remote mode, another machine) → the installed plugin does just as well,
--- same commit, only older.
---@param name string
---@return string|nil
local function plugin_sheet_path(name)
  local candidates = {}

  local ok, personal_utils = pcall(require, "plugins.personal.utils")
  if ok then
    local dev = personal_utils.local_dev(name)
    if dev then
      candidates[#candidates + 1] = vim.fs.joinpath(dev, "docs", "BINDINGS.md")
    end
  end

  candidates[#candidates + 1] =
    vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", name, "docs", "BINDINGS.md")

  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  return nil
end

--- The second corpus root: every personal plugin's `docs/BINDINGS.md`.
---
--- Why the corpus is no longer copies: until 2026-09-04 `PersonelPlugins/
--- BINDINGS/` held a hand-kept cheatsheet per plugin (107 files, 12,566 lines)
--- — a second copy of what each of the 32 repos already ships as
--- `docs/BINDINGS.md`. A copy can drift, and finding drift is exactly what
--- `:Bindings check` is for, so the explorer reads the source now.
---
--- Replacing the cheatsheet with a *link* to the repo doc was not an option:
--- `search` needs full text, `browse` parsed rows, `check`/`report` the
--- documented comparison page — all four read text, and a link is not text.
---
--- `ExternPlugins/Bindings/` is untouched: third-party plugins don't ship a
--- `docs/BINDINGS.md` to this standard, so their cheatsheets are originals.
---
--- `nil` + reason rather than an empty list when the plugin list itself was
--- unreadable — same stance as `M.repo_dirs` and `source.lua`: "found
--- nothing" and "couldn't look" are different claims. A plugin *without* a
--- readable `docs/BINDINGS.md` is not an error, just not a sheet.
---@return Bindings.PluginSheet[]|nil
---@return string|nil reason
function M.plugin_sheets()
  local ok, list = pcall(require, "plugins.personal.list")
  if not ok then
    return nil, "plugins.personal.list not loadable: " .. tostring(list)
  end

  local entries, err = list.read()
  if not entries then
    return nil, err or "plugins.personal.list.read() returned nothing"
  end

  local out = {}
  for _, entry in ipairs(entries) do
    local file = plugin_sheet_path(entry.name)
    if file then
      out[#out + 1] = { plugin = entry.name, file = file }
    end
  end

  -- This config itself is the one entry with no plugin repo to read a
  -- `docs/BINDINGS.md` from -- `BND-05` gave it one at the repo root instead,
  -- same file every other personal plugin keeps at the same relative path.
  -- Named "nvim-config" for continuity with the retired
  -- `PersonelPlugins/BINDINGS/*/nvim-config.md` sheets it replaces.
  local own = vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "BINDINGS.md")
  if vim.fn.filereadable(own) == 1 then
    out[#out + 1] = { plugin = "nvim-config", file = own }
  end

  table.sort(out, function(a, b)
    return a.plugin < b.plugin
  end)
  return out, nil
end

--- Both roots, but only the `folder` sub-category (`"Keymaps"`/`"Usercmds"`/
--- `"Autocmds"`) — both trees use the same three folder names.
---@param folder "Keymaps"|"Usercmds"|"Autocmds"
---@return string[]
function M.roots_for(folder)
  local out = {}
  for _, root in ipairs(M.roots()) do
    out[#out + 1] = vim.fs.joinpath(root, folder)
  end
  return out
end

--- Where `:Bindings report` writes when no `out=` is given: the same folder
--- as the hand-written 2026-09-02 drift report — the report belongs to the
--- task state, not the feature docs.
---@return string
function M.report_dir()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "ROADMAP", "personal", "All")
end

--- This config's own Lua tree. `drift.lua`'s repo axis uses it as a second
--- search location: a documented binding of a personal plugin is often
--- registered not by the plugin but here (lazy `keys` spec,
--- `bindings/mappings/*`) — without this, that would be a systematic false
--- finding of the axis.
---@return string
function M.config_lua_root()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "lua")
end

---@class Bindings.RepoDir
---@field name string cheatsheet stem, also `records.lua`'s `plugin` field, e.g. "images.nvim".
---@field dir string absolute path of the local checkout.

---@alias Bindings.RepoResolver fun(): Bindings.RepoDir[]|nil, string|nil

--- Default resolution: `plugins.personal.export` already yields exactly
--- `{ name, repo, dir }` per enabled personal plugin with a local checkout,
--- derived from the real lazy spec, not a hand-kept list.
---
--- `nil` + reason rather than an empty list when resolution itself failed —
--- same stance as `source.lua`: a report silently missing an axis otherwise
--- reads like one where the axis found nothing.
---@type Bindings.RepoResolver
local function default_repo_dirs()
  local ok, export = pcall(require, "plugins.personal.export")
  if not ok then
    return nil, "plugins.personal.export not loadable: " .. tostring(export)
  end

  local projects, err = export.projects()
  if err then
    return nil, err
  end
  if not projects or #projects == 0 then
    return nil, "no enabled personal plugin has a local checkout on this machine"
  end

  local out = {}
  for _, p in ipairs(projects) do
    out[#out + 1] = { name = p.name, dir = p.dir }
  end
  return out, nil
end

---@type Bindings.RepoResolver|nil
local repo_resolver = nil

--- Swap the resolution (tests against a fixture repo; a future move of this
--- module into its own repo where `plugins.personal` doesn't exist). `nil`
--- restores the default.
---@param fn Bindings.RepoResolver|nil
---@return nil
function M.set_repo_dirs(fn)
  repo_resolver = fn
end

--- Every plugin with a local checkout that `drift.lua`'s repo axis can scan.
---@return Bindings.RepoDir[]|nil
---@return string|nil reason why the axis couldn't be queried.
function M.repo_dirs()
  return (repo_resolver or default_repo_dirs)()
end

--- Directory names that under a collection root are never a project. Not
--- exhaustive: the Lua check below sorts out most of it, this just skips the
--- scandir for the common cases.
local SKIP_DIRS = { [".git"] = true, node_modules = true, target = true }

--- Whether `dir` looks like a Lua project: a `lua/` subdir or at least one
--- top-level `.lua` file.
---
--- Deliberately not `.git` — the repo axis reads source, not git history, and
--- a checkout without its own `.git` (submodule, unpacked release, worktree
--- copy) is just as greppable. Conversely a git repo without a line of Lua is
--- worthless to this axis.
---@param dir string
---@return boolean
local function looks_like_lua_project(dir)
  if vim.fn.isdirectory(vim.fs.joinpath(dir, "lua")) == 1 then
    return true
  end
  for name, type_ in vim.fs.dir(dir) do
    if type_ == "file" and name:match("%.lua$") then
      return true
    end
  end
  return false
end

--- Every Lua project directly under `root`, as a `Bindings.RepoDir` list.
---
--- For when the checkouts are not lazy-spec-resolvable but simply sit side by
--- side in a collection dir (`C:/repos`) — then the path IS the resolution,
--- and the axis covers every project under it, not just the plugin-enabled
--- ones. The directory name IS the `name`, because `records.lua`'s `plugin`
--- field is the cheatsheet stem and this corpus names sheets after repos; a
--- dir with no matching sheet shows up in the drift report as undocumented
--- rather than vanishing silently.
---
--- One level deep only. A recursive descent would re-find each checkout's own
--- `lua/`/`tests/`/`spec/` subdirs and report them as "repos".
---
--- `nil` + reason rather than an empty list when it couldn't look — same
--- distinction as `default_repo_dirs` and `repo.lua`'s `M.mentions`.
---@param root string collection dir, absolute or `~`/`$VAR`-expanded.
---@return Bindings.RepoDir[]|nil
---@return string|nil reason
function M.repo_dirs_under(root)
  if type(root) ~= "string" or root == "" then
    return nil, "no repo root given"
  end
  -- `:p` appends a separator, `normalize` turns Windows backslashes into
  -- slashes -- after that a pattern needs no escape special-casing.
  local abs = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(root), ":p")):gsub("/$", "")
  if vim.fn.isdirectory(abs) ~= 1 then
    return nil, ("repo root is not a directory: %s"):format(abs)
  end

  local out = {}
  for name, type_ in vim.fs.dir(abs) do
    local dir = vim.fs.joinpath(abs, name)
    local is_dir = type_ == "directory" or (type_ == "link" and vim.fn.isdirectory(dir) == 1)
    if is_dir and not SKIP_DIRS[name] and name:sub(1, 1) ~= "." then
      if looks_like_lua_project(dir) then
        out[#out + 1] = { name = name, dir = dir }
      end
    end
  end

  if #out == 0 then
    return nil, ("no Lua project directly under %s"):format(abs)
  end
  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out, nil
end

return M
