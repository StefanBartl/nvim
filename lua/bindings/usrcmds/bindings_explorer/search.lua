---@module 'bindings.usrcmds.bindings_explorer.search'
--- Static full-text search over the BINDINGS roots — the fallback when no
--- live-grep picker engine is available (see `live.lua`, the preferred path).
--- Reads files directly and matches in pure Lua, like casedesk's
--- `case.query.M.grep` — no ripgrep call, no extra dependency for a fallback.

local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")
local config = require("bindings.usrcmds.bindings_explorer.config")

local M = {}

---@class Bindings.Hit
---@field root string BINDINGS root the file sits under
---@field path string absolute path
---@field line integer 1-based line number
---@field text string trimmed line content

---@param value string
---@param pattern string
---@return boolean
local function matches(value, pattern)
  return value:lower():find(pattern:lower(), 1, true) ~= nil
end

--- Hold one file against `pattern`, line by line.
---@param root string root the file sits under (see `Bindings.Hit`)
---@param path string
---@param pattern string
---@param hits Bindings.Hit[] filled in place
---@return nil
local function scan_file(root, path, pattern, hits)
  local content = read(path)
  if not content then
    return
  end
  local lineno = 0
  for line in (content:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
    lineno = lineno + 1
    if matches(line, pattern) then
      hits[#hits + 1] = { root = root, path = path, line = lineno, text = vim.trim(line) }
    end
  end
end

--- Search every `.md` file under `roots` for `pattern` (case-insensitive
--- substring, like `case.query.M.grep`'s default).
---
--- A `roots` entry may also be a single file: the plugin scope
--- (`:Bindings search keymaps hover.nvim`, see `plugin_scope.lua`) resolves to
--- cheatsheet paths, which go through the same list as a directory here — just
--- like `live.lua`, where ripgrep takes files and directories in the same
--- position. The `root` of such a hit is the file's directory: the field says
--- where the file sits, not what the caller passed.
---@param pattern string
---@param roots string[]|nil nil = both full BINDINGS roots
---@return Bindings.Hit[]
function M.search(pattern, roots)
  local hits = {}
  if not pattern or pattern == "" then
    return hits
  end

  for _, root in ipairs(roots or config.roots()) do
    if vim.fn.isdirectory(root) == 1 then
      for _, f in ipairs(collect_recursive.files(root)) do
        if f:match("%.md$") then
          scan_file(root, f, pattern, hits)
        end
      end
    elseif vim.fn.filereadable(root) == 1 then
      scan_file(vim.fs.dirname(root), root, pattern, hits)
    end
  end

  return hits
end

return M
