---@module 'usrcmds.migrate.notify.parser'
---@brief Main parser orchestrator

local aliases = require("usrcmds.migrate.notify.parser.aliases")
local patterns = require("usrcmds.migrate.notify.parser.patterns")
local extractor = require("usrcmds.migrate.notify.parser.extractor")
local migrator = require("usrcmds.migrate.notify.parser.migrator")

local M = {}

local api = vim.api

---Scan buffer and return all matches
---@param bufnr integer
---@return MigrateNotify.Match[]
function M.scan_buffer(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  if vim.bo[bufnr].filetype ~= "lua" then
    return {}
  end

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local matches = {}

  -- Detect aliases
  local notify_alias, levels_alias = aliases.detect(bufnr)

  local i = 1
  while i <= #lines do
    local line = lines[i]

    -- Skip non-processable lines (comments)
    if not patterns.is_processable(line) then
      i = i + 1
      goto continue
    end

    -- Try vim.notify first (direct calls)
    if patterns.is_vim_notify(line) then
      local end_idx = extractor.find_call_end(lines, i)

      if end_idx then
        if end_idx == i then
          -- Single line
          local migrated, level = migrator.migrate_vim_notify_line(line)
          if migrated then
            table.insert(matches, {
              line = i,
              end_line = i,
              col = 0,
              end_col = #line,
              original = line,
              replacement = migrated,
              log_level = level,
            })
          end
        else
          -- Multiline
          local call_lines = {}
          for j = i, end_idx do
            table.insert(call_lines, lines[j])
          end

          local migrated, level = migrator.migrate_multiline(call_lines)
          if migrated then
            table.insert(matches, {
              line = i,
              end_line = end_idx,
              col = 0,
              end_col = #lines[end_idx],
              original = table.concat(call_lines, "\n"),
              replacement = migrated,
              log_level = level,
            })
          end

          i = end_idx
        end
      end
    end

    -- Try aliased notify (when aliases are detected)
    -- IMPORTANT: Use 'if' not 'elseif' to allow both patterns to be checked
    if notify_alias and patterns.is_aliased_notify(line, notify_alias) then
      local end_idx = extractor.find_call_end(lines, i)

      if end_idx and end_idx == i then
        -- Only handle single-line aliased calls for now
        local migrated, level = migrator.migrate_aliased_line(
          line,
          notify_alias,
          levels_alias
        )
        if migrated then
          table.insert(matches, {
            line = i,
            end_line = i,
            col = 0,
            end_col = #line,
            original = line,
            replacement = migrated,
            log_level = level,
          })
        end
      end
    end

    ::continue::
    i = i + 1
  end

  return matches
end

return M
