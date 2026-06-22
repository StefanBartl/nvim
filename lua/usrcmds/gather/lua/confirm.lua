---@module 'usrcmds.gather.lua.confirm'
---@description CWD scan confirmation with file statistics and time estimation

local notify = require("lib.nvim.notify").create("[usrcmds.gather.lua.confirm]")

local hover_select = require("lib.nvim.ui.hover_select")

local M = {}

--- Count lines in a file efficiently
---@param filepath string
---@return integer lines
local function count_file_lines(filepath)
  local count = 0
  local file = io.open(filepath, "r")

  if not file then
    return 0
  end

  for _ in file:lines() do
    count = count + 1
  end

  file:close()
  return count
end

--- Gather statistics about Lua files in paths
---@param files string[] List of file paths
---@return UsrCmds.Gather.Lua.ScanStats
function M.gather_stats(files)
  local stats = {
    total_files = #files,
    total_dirs = 0,
    total_lines = 0,
    estimated_time_sec = 0,
  }

  -- Count unique directories
  local dirs = {}
  for _, filepath in ipairs(files) do
    local dir = vim.fn.fnamemodify(filepath, ":h")
    dirs[dir] = true

    -- Sample first 50 files to estimate total lines
    if stats.total_lines == 0 or #files <= 50 then
      stats.total_lines = stats.total_lines + count_file_lines(filepath)
    end
  end

  stats.total_dirs = vim.tbl_count(dirs)

  -- Extrapolate line count if sampled
  if #files > 50 then
    local avg_lines = stats.total_lines / 50
    stats.total_lines = math.floor(avg_lines * #files)
  end

  -- Time estimation (empirical: ~100 files/sec with Tree-sitter)
  stats.estimated_time_sec = math.ceil(#files / 100)

  return stats
end

--- Format statistics for display
---@param stats UsrCmds.Gather.Lua.ScanStats
---@return string[] lines
local function format_stats(stats)
  local lines = {
    "CWD Scan Statistics",
    "═══════════════════════════════",
    "",
    string.format("📁 Directories: %d", stats.total_dirs),
    string.format("📄 Lua files:   %d", stats.total_files),
    string.format("📝 Lines (est): %s", vim.fn.printf("%'d", stats.total_lines)),
    "",
    string.format("⏱️  Estimated time: ~%d seconds", stats.estimated_time_sec),
    "",
    "─────────────────────────────────",
  }

  -- Warning for large scans
  if stats.total_files > 500 then
    table.insert(lines, "")
    table.insert(lines, "⚠️  WARNING: Large project detected!")
    table.insert(lines, "This scan may take considerable time.")
    table.insert(lines, "Consider using a more specific directory.")
  elseif stats.total_lines > 50000 then
    table.insert(lines, "")
    table.insert(lines, "⚠️  WARNING: High line count!")
    table.insert(lines, "Scanning " .. vim.fn.printf("%'d", stats.total_lines) .. " lines may be slow.")
  end

  return lines
end

--- Show confirmation dialog with statistics
---@param files string[] List of file paths to scan
---@param on_confirm function Callback if user confirms
---@param on_cancel function|nil Callback if user cancels
function M.show_confirmation(files, on_confirm, on_cancel)
  -- Gather statistics
  local stats = M.gather_stats(files)

  -- Build confirmation message
  local message_lines = format_stats(stats)
  table.insert(message_lines, "")
  table.insert(message_lines, "Proceed with scan?")

  -- Show as notification first
  vim.notify(table.concat(message_lines, "\n"), vim.log.levels.INFO)

  -- Show hover selection for confirmation
  vim.defer_fn(function()
    hover_select.open({
      title = "Confirm CWD Scan",
      items = {
        "✓ Yes, proceed with scan",
        "✗ No, cancel operation",
      },
      on_select = function(selected)
        ---@cast selected string
        if selected:match("^✓") then
          notify.info("Starting CWD scan...")
          on_confirm()
        else
          notify.info("CWD scan cancelled")
          if on_cancel then
            on_cancel()
          end
        end
      end,
    })
  end, 100) -- Small delay to ensure notification is visible
end

return M
