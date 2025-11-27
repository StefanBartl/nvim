---@module 'custom.pathfinder.extractor'
--- Enhanced extraction utilities for finding path-like substrings inside a line.
--- The implementation applies multiple heuristics:
---  1) stacktrace-style patterns (path:line:col, path:line)
---  2) extension-driven extraction (expand from known extensions)
---  3) absolute path matching (unix/windows)
---  4) quoted / parenthesized cleaning
--- Returns an array of candidate tables compatible with the existing `candidate` type:
--- { raw = "...", path = "...", lineno = number|nil, col = number|nil }

-- AUDIT: Modularise to /extractor

local notifier = require("custom.pathfinder.notifier")
local find = require("custom.pathfinder.extractor.find")
local helpers = require("custom.pathfinder.extractor.helpers")

--- Enhanced extraction entrypoint.
--- Applies multiple heuristics in order of reliability and returns deduplicated candidates.
---@param line string
---@return candidates
return function (line)
  line = line or ""
  notifier.notify(("enhanced_extract_candidates: scanning line -> %s"):format(line), "debug")

  -- 1) stacktrace-style patterns (highest confidence)
  local results = find.stack_patterns(line) or {}
  local n_stack = #results
  notifier.notify(("enhanced: stack patterns found %d"):format(n_stack), "debug")

  -- 2) extension driven expansions
  local ext_results = find.by_extension(line) or {}
  for _, c in ipairs(ext_results) do
    table.insert(results, c)
  end
  notifier.notify(("enhanced: after extension scan %d"):format(#results), "debug")

  -- 3) absolute path catch
  local abs_results = find.absolute_paths(line) or {}
  for _, c in ipairs(abs_results) do
    table.insert(results, c)
  end
  notifier.notify(("enhanced: after absolute path scan %d"):format(#results), "debug")

  -- deduplicate and return
  local uniqed = helpers.uniq(results)
  notifier.notify(("enhanced_extract_candidates: total unique candidates %d"):format(#uniqed), "debug")
  return uniqed
end

