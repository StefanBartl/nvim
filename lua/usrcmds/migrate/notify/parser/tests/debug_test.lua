-- Debug-Test für den Parser
-- Speichere diese Datei und führe sie aus mit :luafile %

local aliases = require("usrcmds.migrate.notify.parser.aliases")
local patterns = require("usrcmds.migrate.notify.parser.patterns")
local extractor = require("usrcmds.migrate.notify.parser.extractor")
local migrator = require("usrcmds.migrate.notify.parser.migrator")

-- Test-Zeilen
local test_lines = {
  'local notify, levels = vim.notify, vim.log.levels',
  'notify("no node under cursor", levels.WARN)',
  'notify("Cleared all marks", levels.INFO)',
}

print("=== DEBUG TEST ===\n")

-- Test 1: Alias-Detektion
print("1. Alias Detection:")
local bufnr = vim.api.nvim_get_current_buf()
local notify_alias, levels_alias = aliases.detect(bufnr)
if not notify_alias then
    vim.notify("notify_alias is nil", vim.log.levels.WARN)
    return nil
end
print(string.format("   notify_alias: %s", notify_alias or "nil"))
print(string.format("   levels_alias: %s", levels_alias or "nil"))
print()

-- Test 2: Pattern-Matching
print("2. Pattern Matching:")
for i, line in ipairs(test_lines) do
  if i > 1 then  -- Skip alias declaration line
    local is_processable = patterns.is_processable(line)
    local is_aliased = patterns.is_aliased_notify(line, notify_alias)

    print(string.format("   Line %d: %s", i, line))
    print(string.format("      processable: %s", tostring(is_processable)))
    print(string.format("      is_aliased: %s", tostring(is_aliased)))
  end
end
print()

-- Test 3: Extraction
print("3. Call Extraction:")
for i, line in ipairs(test_lines) do
  if i > 1 then
    local call_text, start_col, end_col = extractor.extract_aliased(line, notify_alias)
    print(string.format("   Line %d:", i))
    print(string.format("      call_text: %s", call_text or "nil"))
    print(string.format("      positions: [%s, %s]",
      start_col and tostring(start_col) or "nil",
      end_col and tostring(end_col) or "nil"))
  end
end
print()

-- Test 4: Migration
print("4. Migration:")
for i, line in ipairs(test_lines) do
  if i > 1 then
    local migrated, level = migrator.migrate_aliased_line(line, notify_alias, levels_alias)
    print(string.format("   Line %d:", i))
    print(string.format("      original: %s", line))
    print(string.format("      migrated: %s", migrated or "nil"))
    print(string.format("      level: %s", level or "nil"))
  end
end
print()

print("=== END DEBUG TEST ===")
