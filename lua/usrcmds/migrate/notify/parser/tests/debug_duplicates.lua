---@module 'usrcmds.migrate.notify.parser.tests.debug_duplicates'
---@brief Debug duplicate matches
---
--- Run with: :luafile %
--- Use on your actual buffer to see what's happening

local parser = require("usrcmds.migrate.notify.parser")

local bufnr = vim.api.nvim_get_current_buf()

print("=== DUPLICATE MATCH DEBUG ===\n")

-- Scan buffer
local matches = parser.scan_buffer(bufnr)

print(string.format("Total matches found: %d\n", #matches))

-- Group by line
local by_line = {}
for _, match in ipairs(matches) do
  local line_num = match.line
  if not by_line[line_num] then
    by_line[line_num] = {}
  end
  table.insert(by_line[line_num], match)
end

-- Find duplicates
local has_duplicates = false

for line_num, line_matches in pairs(by_line) do
  if #line_matches > 1 then
    has_duplicates = true
    print(string.format("⚠️  Line %d has %d matches:", line_num, #line_matches))

    for idx, match in ipairs(line_matches) do
      print(string.format("\n  Match %d:", idx))
      print(string.format("    Original:    %s", match.original:sub(1, 80)))
      print(string.format("    Replacement: %s", match.replacement:sub(1, 80)))
      print(string.format("    Level:       %s", match.log_level or "nil"))
    end

    print()
  end
end

if not has_duplicates then
  print("✅ No duplicate matches found!\n")

  -- Show all matches
  for _, match in ipairs(matches) do
    print(string.format("Line %d: %s → %s",
      match.line,
      match.original:sub(1, 40),
      match.replacement:sub(1, 40)))
  end
else
  print("❌ Duplicates detected! This will cause double-insertion.\n")
end

print("\n=== END DEBUG ===")
