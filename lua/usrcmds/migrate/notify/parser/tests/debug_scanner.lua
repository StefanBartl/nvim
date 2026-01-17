-- Debug Scanner - zeigt jeden Schritt
-- Speichere als debug_scanner.lua und führe aus mit :luafile %

local aliases = require("usrcmds.migrate.notify.parser.aliases")
local patterns = require("usrcmds.migrate.notify.parser.patterns")
local extractor = require("usrcmds.migrate.notify.parser.extractor")
local migrator = require("usrcmds.migrate.notify.parser.migrator")

local bufnr = vim.api.nvim_get_current_buf()
local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

print("=== SCANNER DEBUG ===\n")

-- Check filetype
local ft = vim.bo[bufnr].filetype
print(string.format("Filetype: %s", ft))

if ft ~= "lua" then
  print("❌ Not a Lua file, aborting")
  return
end

-- Detect aliases
local notify_alias, levels_alias = aliases.detect(bufnr)
print(string.format("Aliases detected: notify=%s, levels=%s\n",
  notify_alias or "nil", levels_alias or "nil"))

-- Scan lines
local matches = {}

for i = 1, #lines do
  local line = lines[i]

  -- Truncate long lines for display
  local display_line = line:sub(1, 60)
  if #line > 60 then
    display_line = display_line .. "..."
  end
  print(string.format("Line %d: %s", i, display_line))

  -- Check if processable
  local is_proc = patterns.is_processable(line)
  print(string.format("  processable: %s", tostring(is_proc)))

  if not is_proc then
    print("  ⏭️  skipping (comment/whitespace)")
  else
    -- Check vim.notify
    local is_vim = patterns.is_vim_notify(line)
    print(string.format("  is_vim_notify: %s", tostring(is_vim)))

    -- Check aliased
    local is_alias = notify_alias and patterns.is_aliased_notify(line, notify_alias) or false
    print(string.format("  is_aliased_notify: %s", tostring(is_alias)))

    if is_vim then
      print("  ✓ vim.notify match")
      local end_idx = extractor.find_call_end(lines, i)
      print(string.format("    call_end: %s", tostring(end_idx)))

      if end_idx and end_idx == i then
        local migrated, level = migrator.migrate_vim_notify_line(line)
        print(string.format("    migrated: %s", migrated or "nil"))
        print(string.format("    level: %s", level or "nil"))

        if migrated then
          table.insert(matches, {
            line = i,
            original = line,
            replacement = migrated,
            log_level = level,
          })
          print("    ✅ Added to matches")
        end
      end
    end

    if is_alias then
      print("  ✓ aliased notify match")
      local end_idx = extractor.find_call_end(lines, i)
      print(string.format("    call_end: %s", tostring(end_idx)))

      if end_idx and end_idx == i then
        local migrated, level = migrator.migrate_aliased_line(line, notify_alias or "", levels_alias)
        print(string.format("    migrated: %s", migrated or "nil"))
        print(string.format("    level: %s", level or "nil"))

        if migrated then
          table.insert(matches, {
            line = i,
            original = line,
            replacement = migrated,
            log_level = level,
          })
          print("    ✅ Added to matches")
        else
          print("    ❌ Migration failed")
        end
      else
        print(string.format("    ❌ end_idx check failed (end_idx=%s, i=%s)",
          tostring(end_idx), tostring(i)))
      end
    end
  end

  print()
end

print(string.format("\n=== TOTAL MATCHES: %d ===\n", #matches))

for idx, match in ipairs(matches) do
  print(string.format("Match %d:", idx))
  print(string.format("  Line: %d", match.line))
  print(string.format("  Level: %s", match.log_level or "nil"))

  local orig = match.original:sub(1, 60)
  if #match.original > 60 then orig = orig .. "..." end
  print(string.format("  Original: %s", orig))

  local repl = match.replacement:sub(1, 60)
  if #match.replacement > 60 then repl = repl .. "..." end
  print(string.format("  Replacement: %s", repl))
  print()
end

print("=== DEBUG COMPLETE ===")
