---@module 'usrcmds.migrate.notify.parser.tests.test_existing_notify'
---@brief Test existing notify() migration
---
--- Run with: :luafile %

local migrator = require("usrcmds.migrate.notify.parser.migrator")
local patterns = require("usrcmds.migrate.notify.parser.patterns")

print("=== TEST EXISTING NOTIFY() MIGRATION ===\n")

---@type table<string, {input: string, expected: string, level: string}>
local test_cases = {
  {
    name = "vim.log.levels.ERROR",
    input = 'notify("Failed to fetch genindex.html: " .. (main_err or "unknown"), vim.log.levels.ERROR)',
    expected = 'notify.error("Failed to fetch genindex.html: " .. (main_err or "unknown"))',
    level = "ERROR"
  },
  {
    name = "log.levels.INFO",
    input = 'notify("cache cleared", log.levels.INFO)',
    expected = 'notify.info("cache cleared")',
    level = "INFO"
  },
  {
    name = "levels.WARN",
    input = 'notify("Failed to fetch " .. href .. ": " .. page_err, levels.WARN)',
    expected = 'notify.warn("Failed to fetch " .. href .. ": " .. page_err)',
    level = "WARN"
  },
  {
    name = "Direct WARN",
    input = 'notify("Something went wrong", WARN)',
    expected = 'notify.warn("Something went wrong")',
    level = "WARN"
  },
  {
    name = "Integer level 2 (INFO)",
    input = 'notify("Processing complete", 2)',
    expected = 'notify.info("Processing complete")',
    level = "INFO"
  },
  {
    name = "Integer level 4 (ERROR)",
    input = 'notify("Fatal error occurred", 4)',
    expected = 'notify.error("Fatal error occurred")',
    level = "ERROR"
  },
  {
    name = "With opts table",
    input = 'notify("Task completed", vim.log.levels.INFO, { title = "My Plugin" })',
    expected = 'notify.info("Task completed", { title = "My Plugin" })',
    level = "INFO"
  },
  {
    name = "Already migrated (should skip)",
    input = 'notify.info("Already migrated")',
    expected = nil,
    level = nil
  },
  {
    name = "vim.notify (should skip - handled elsewhere)",
    input = 'vim.notify("Test", vim.log.levels.INFO)',
    expected = nil,
    level = nil
  },
}

local passed = 0
local failed = 0

for idx, test in ipairs(test_cases) do
  print(string.format("Test %d: %s", idx, test.name))
  print(string.format("  Input:    %s", test.input))

  -- Check pattern detection
  local is_existing = patterns.is_existing_notify(test.input)
  print(string.format("  Detected: %s", tostring(is_existing)))

  -- Try migration
  local migrated, level = migrator.migrate_existing_notify_line(test.input)

  if test.expected == nil then
    -- Should not migrate
    if migrated == nil then
      print("  ✅ Correctly skipped")
      passed = passed + 1
    else
      print(string.format("  ❌ Should skip, but got: %s", migrated))
      failed = failed + 1
    end
  else
    -- Should migrate
    if migrated == test.expected and level == test.level then
      print(string.format("  ✅ Correct: %s", migrated))
      passed = passed + 1
    else
      print(string.format("  ❌ Expected: %s", test.expected))
      print(string.format("     Got:      %s", migrated or "nil"))
      print(string.format("     Level expected: %s, got: %s", test.level, level or "nil"))
      failed = failed + 1
    end
  end

  print()
end

print(string.format("=== RESULTS: %d/%d PASSED ===", passed, passed + failed))

if failed > 0 then
  print(string.format("❌ %d tests FAILED", failed))
else
  print("✅ All tests PASSED")
end
