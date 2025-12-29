---@module 'lib.fs.dedup'
-- Deduplicate a list of filesystem paths while preserving the original order.
---@brief
-- This module exports a single function that:
--  1. Normalizes each input path using `vim.fs.normalize`.
--  2. Keeps the first occurrence of each normalized path and discards subsequent duplicates.
--  3. Returns a new array with normalized, unique paths in the same order as their first appearance.
--
-- Note: Normalization is textual and platform-aware (via Neovim's vim.fs.normalize).
-- It does not resolve filesystem symlinks or perform IO beyond normalization.
--
-- Examples:
--   ```lua
--   local dedup = require("lib.fs.dedup")
--   local input = { "./a/../b", "/home/user/project", "/home/user/project/" }
--   local out = dedup(input) -- out -> { "/home/user/b", "/home/user/project" } (depending on normalize behavior)
--   ```

---@diagnostic disable

local norm = vim.fs.normalize

---@param entries string[] list of path strings to deduplicate
---@return string[] normalized unique paths in original-first-occurrence order
return function(entries)
  -- Ensure we received a table/array; defensive nil-check is optional but recommended.
  -- The function expects `entries` to be an array-like table of strings.
  if type(entries) ~= "table" then
    return {}
  end

  -- `seen` is a set keyed by normalized path to mark already emitted paths.
  ---@type table<string, boolean>
  local seen = {}

  -- `out` collects deduplicated normalized paths preserving first-seen order.
  ---@type string[]
  local out = {}

  -- Iterate entries in order; for each path:
  -- 1) normalize it via vim.fs.normalize (platform-aware canonicalization)
  -- 2) if not seen yet, mark and append to output
  for _, p in ipairs(entries) do
    -- Defensive: convert non-string to string to avoid errors from vim.fs.normalize
    local input_path = p
    if type(input_path) ~= "string" then
      input_path = tostring(input_path)
    end

    -- Normalize path: this ensures paths that are textually equivalent after normalization
    -- (e.g., trailing slashes, "."/ "foo/../bar" segments) map to the same key.
    local n = norm(input_path)

    -- If normalization failed or returned nil, skip that entry (defensive).
    if n and n ~= "" then
      if not seen[n] then
        seen[n] = true
        out[#out + 1] = n
      end
    end
  end

  return out
end
