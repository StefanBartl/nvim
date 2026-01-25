---@module 'usrcmds.migrate.notify.parser.tests.test_positions'
---@brief Test position calculation in migrator
---
--- Run with: :luafile %

local migrator = require("usrcmds.migrate.notify.parser.migrator")

print("=== TEST POSITION CALCULATION ===\n")

local test_line = '  notify("genindex unavailable; try :h luvref.txt", vim.log.levels.WARN)'

print("Input line:")
print("  '" .. test_line .. "'")
print()

-- Call the migrator
local migrated, level = migrator.migrate_existing_notify_line(test_line)

print("Migrator output:")
print("  migrated: '" .. (migrated or "nil") .. "'")
print("  level:    " .. (level or "nil"))
print()

-- Check if the line is correct
local expected = '  notify.warn("genindex unavailable; try :h luvref.txt")'

if migrated == expected then
  print("✅ Migration correct!")
else
  print("❌ Migration incorrect!")
  print("\nExpected:")
  print("  '" .. expected .. "'")
  print("\nGot:")
  print("  '" .. (migrated or "nil") .. "'")

  -- Character-by-character comparison
  if migrated then
    print("\nDifference analysis:")
    local min_len = math.min(#expected, #migrated)

    for i = 1, math.max(#expected, #migrated) do
      local e_char = expected:sub(i, i)
      local m_char = migrated:sub(i, i)

      if e_char ~= m_char then
        print(string.format("  Position %d: expected '%s' (byte %d), got '%s' (byte %d)",
          i,
          e_char ~= "" and e_char or "<end>",
          e_char:byte() or 0,
          m_char ~= "" and m_char or "<end>",
          m_char:byte() or 0
        ))
      end
    end
  end
end

print("\n=== END TEST ===")
