---@module 'usrcmds.gather.lua.scanner'
---@description Common scanning logic for CWD-wide Lua file analysis

require("usrcmds.gather.@types")

local M = {}

--- Find all Lua files in current working directory recursively
---@return string[] paths List of absolute file paths
function M.find_lua_files()
  local cwd = vim.fn.getcwd()

  -- Use globpath to find all .lua files recursively
  local files = vim.fn.globpath(cwd, "**/*.lua", false, true)

  -- Filter out files in common ignore patterns
  local ignore_patterns = {
    "/%.git/",
    "/node_modules/",
    "/%.cache/",
    "/build/",
    "/dist/",
    "/target/",
  }

  local filtered = {}
  for _, file in ipairs(files) do
    local should_include = true

    for _, pattern in ipairs(ignore_patterns) do
      if file:match(pattern) then
        should_include = false
        break
      end
    end

    if should_include then
      table.insert(filtered, file)
    end
  end

  return filtered
end

--- Scan multiple files using a gatherer's scan_buffer function
---@param files string[] List of file paths
---@param scan_fn fun(bufnr: integer): UsrCmds.Gather.Lua.ScanResult
---@return UsrCmds.Gather.Lua.FileMatches[] file_matches
function M.scan_files(files, scan_fn)
  local file_matches = {}

  for _, path in ipairs(files) do
    -- Load file into buffer
    local bufnr = vim.fn.bufadd(path)
    vim.fn.bufload(bufnr)

    -- Scan buffer
    local result = scan_fn(bufnr)

    -- Add file path to matches
    if #result.matches > 0 then
      for _, match in ipairs(result.matches) do
        match.file = path
      end

      table.insert(file_matches, {
        path = path,
        matches = result.matches,
      })
    end
  end

  return file_matches
end

--- Build flat list of all matches across files
---@param file_matches UsrCmds.Gather.Lua.FileMatches[]
---@return UsrCmds.Gather.Lua.Match[]
function M.flatten_matches(file_matches)
  local all_matches = {}

  for _, file_data in ipairs(file_matches) do
    for _, match in ipairs(file_data.matches) do
      table.insert(all_matches, match)
    end
  end

  return all_matches
end

return M
