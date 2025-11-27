---@module 'custom.pathfinder.finder'
--- Contains the logic to extract candidate paths from a line and to resolve them
--- using local existence checks and external search tools.
--- The module always emits notifier messages for debug/tracing.

local M = {}
local util = require("custom.pathfinder.util")
local notifier = require("custom.pathfinder.notifier")

--- Resolve a candidate path to an existing file on disk.
--- Strategy:
--- 1. If candidate.path is absolute and exists -> done.
--- 2. If candidate.path looks like exists relative to cwd -> done.
--- 3. Otherwise run external search commands (configured by caller) to look for basename matches.
--- Returns first found absolute path or nil.
---@param candidate candidate # as produced by extract_candidates
---@param opts table -- { search_commands = {...}, max_results = n }
---@return string|nil found_path
function M.resolve_candidate(candidate, opts)
  opts = opts or {}
  local search_commands = opts.search_commands or {}
  local max_results = opts.max_results or 20

  notifier.notify(("resolve_candidate: trying %s"):format(candidate.path), "debug")
  local norm = util.normalize_sep(candidate.path)

  -- 1) absolute path check
  if util.exists(norm) then
    notifier.notify(("resolve_candidate: absolute exists -> %s"):format(norm), "info")
    return norm
  end

  -- 2) try relative to cwd and common roots (project root heuristic)
  local cwd = vim.loop.cwd()
  local try1 = cwd .. "/" .. candidate.path
  try1 = util.normalize_sep(try1)
  if util.exists(try1) then
    notifier.notify(("resolve_candidate: found relative -> %s"):format(try1), "info")
    return try1
  end

  -- 3) run external searchers for basename
  local base = util.basename(candidate.path)
  if not base or base == "" then
    notifier.notify("resolve_candidate: no basename available", "debug")
    return nil
  end

  notifier.notify(("resolve_candidate: searching for basename '%s' with external commands"):format(base), "debug")

  for _, cmd in ipairs(search_commands) do
    -- append pattern to search command. Command strings in opts are expected to accept a trailing query.
    -- Example: "fd --hidden --follow --type f --strip-cwd-prefix" -> we append " <basename>"
    local full = ("%s %s"):format(cmd, vim.fn.shellescape(base))
    local lines, err = util.system_lines(full)
    if err and err ~= "" then
      notifier.notify(("resolve_candidate: search error for cmd '%s': %s"):format(cmd, err), "warn")
    end

    -- process results
    for i, l in ipairs(lines) do
      if i > max_results then break end
      local candidate_path = l
      -- normalize
      candidate_path = util.normalize_sep(candidate_path)
      if util.exists(candidate_path) then
        notifier.notify(("resolve_candidate: external found -> %s"):format(candidate_path), "info")
        return candidate_path
      end
    end
  end

  notifier.notify(("resolve_candidate: no match for '%s'"):format(candidate.path), "debug")
  return nil
end

--- If no file is found, attempt to find the first folder segment that exists nearby.
--- For example if path contains "foo/bar/baz.lua" and "bar" exists somewhere, return that folder.
---@param candidate candidate
---@return string|nil folder_path
function M.find_nearest_folder(candidate)
  local parts = {}
  for part in candidate.path:gmatch("[^/\\]+") do
    table.insert(parts, part)
  end
  -- try progressively shorter suffixes
  for i = 1, #parts do
    local suffix = table.concat(parts, "/", i)
    -- search for folder name using fd/find with --type d
    local search_cmds = {
      ("fd --hidden --follow --type d %s"):format(vim.fn.shellescape(suffix)),
      ("rg --hidden --files --glob '!**/*' --type d | rg %s"):format(vim.fn.shellescape(suffix)),
      ("find . -type d -name " .. vim.fn.shellescape(suffix)),
    }
    for _, cmd in ipairs(search_cmds) do
      local lines = vim.fn.systemlist(cmd)
      for _, l in ipairs(lines) do
        if l and l ~= "" then
          local candidate_folder = util.normalize_sep(l)
          if util.exists(candidate_folder) then
            notifier.notify(("find_nearest_folder: found folder -> %s"):format(candidate_folder), "info")
            return candidate_folder
          end
        end
      end
    end
  end

  notifier.notify("find_nearest_folder: nothing found", "debug")
  return nil
end

return M
