---@module 'usrcmds.gather.lua'
---@description Entry point for Lua gather commands with buffer and cwd modes

local notify = require("lib.notify").create("[usrcmds.gather.lua]")

require("usrcmds.gather.@types")

local hover_select = require("lib.ui.hover_select")

local M = {}

--- Gatherers for each symbol type
---@type table<UsrCmds.Gather.Lua.GatherType, table>
local gatherers = {
  functions = require("usrcmds.gather.lua.functions"),
  tables = require("usrcmds.gather.lua.tables"),
  strings = require("usrcmds.gather.lua.strings"),
}

--- Run gatherer in buffer mode (current buffer only)
---@param gather_type UsrCmds.Gather.Lua.GatherType
local function run_buffer_mode(gather_type)
  local gatherer = gatherers[gather_type]

  if not gatherer or not gatherer.run then
    notify.error("Unknown gather type: " .. gather_type)
    return
  end

  gatherer.run()
end

--- Run gatherer in cwd mode (all Lua files in working directory)
---@param gather_type UsrCmds.Gather.Lua.GatherType
local function run_cwd_mode(gather_type)
  local gatherer = gatherers[gather_type]

  if not gatherer or not gatherer.scan_buffer then
    notify.error("Gatherer does not support cwd mode: " .. gather_type)
    return
  end

  -- Find all Lua files
  local scanner = require("usrcmds.gather.lua.scanner")
  local files = scanner.find_lua_files()

  if #files == 0 then
    notify.warn("No Lua files found in cwd")
    return
  end

  -- Show confirmation dialog with statistics
  local confirm = require("usrcmds.gather.lua.confirm")

  confirm.show_confirmation(files, function()
    -- User confirmed - proceed with scan
    vim.notify("Scanning " .. #files .. " files...", vim.log.levels.INFO)

    -- Scan all files
    local file_matches = scanner.scan_files(files, gatherer.scan_buffer)

    if #file_matches == 0 then
      notify.warn("No " .. gather_type .. " found in cwd")
      return
    end

    -- Flatten all matches from all files
    local all_matches = scanner.flatten_matches(file_matches)

    -- Format for display (with file paths, line, col)
    local lines = {}
    for _, match in ipairs(all_matches) do
      if match.file then
        local rel_path = vim.fn.fnamemodify(match.file, ":~:.")
        local line_str = string.format("%s:%d:%d: %s", rel_path, match.line, match.col, match.name)
        table.insert(lines, line_str)
      end
    end

    -- Show in scratch buffer
    local ui = require("usrcmds.gather.lua.ui")
    local title = string.format("%s (CWD: %d matches)", gather_type:gsub("^%l", string.upper), #all_matches)
    ui.open_scratch(lines, title)

    notify.info(string.format("Found %d %s across %d files", #all_matches, gather_type, #file_matches))
  end, function()
    -- User cancelled - do nothing
  end)
end

--- Open hover selection to choose gather type and mode
---@param mode UsrCmds.Gather.Lua.ScanMode
function M.run(mode)
  mode = mode or "buffer"

  hover_select.open({
    title = "Lua gather (" .. mode .. ")",
    items = {
      "functions",
      "tables",
      "strings",
    },
    use_tab_navigation = true,
    auto_width = true,

    on_select = function(selected)
      ---@type UsrCmds.Gather.Lua.GatherType
      local gather_type

      if type(selected) == "table" then
        gather_type = selected[1]
      else
        gather_type = selected
      end

      if mode == "buffer" then
        run_buffer_mode(gather_type)
      elseif mode == "cwd" then
        run_cwd_mode(gather_type)
      else
        notify.error("Unknown mode: " .. mode)
      end
    end,
  })
end

return M
