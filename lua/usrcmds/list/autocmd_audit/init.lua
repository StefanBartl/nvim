---@module 'tools.autocmd_audit'
--- Static analysis tool to audit Neovim autocmd definitions.
--- Scans Lua source files without executing them and extracts
--- autocmd events, implementations, and source locations.

local M = {}

local uv = vim.loop

---@type string
local ROOT = vim.fn.stdpath("config") .. "/lua"

---@type table<string, table[]>
-- maps event name -> list of implementations
local by_event = {}

---@type table[]
-- flat list preserving discovery order
local all_autocmds = {}

--- Normalize event argument into a sorted string list.
---@param raw string
---@return string[]
local function normalize_events(raw)
  local events = {}

  -- table literal: { "A", "B" }
  for ev in raw:gmatch([["([^"]+)"]]) do
    table.insert(events, ev)
  end

  -- single string: "A"
  if #events == 0 then
    local single = raw:match([["([^"]+)"]])
    if single then
      events[1] = single
    end
  end

  table.sort(events)
  return events
end

--- Read a full Lua table literal starting at `{`.
--- Keeps original formatting.
---@param lines string[]
---@param start_line integer
---@param start_col integer
---@return string, integer
local function read_brace_block(lines, start_line, start_col)
  local depth = 0
  local out = {}

  for l = start_line, #lines do
    local line = lines[l]
    local from = (l == start_line) and start_col or 1

    for i = from, #line do
      local ch = line:sub(i, i)
      if ch == "{" then
        depth = depth + 1
      end
      if ch == "}" then
        depth = depth - 1
      end
    end

    table.insert(out, line)

    if depth == 0 then
      return table.concat(out, "\n"), l
    end
  end

  return table.concat(out, "\n"), #lines
end

--- Process a single Lua file.
---@param abs_path string
---@param rel_path string
local function scan_file(abs_path, rel_path)
  local lines = vim.fn.readfile(abs_path)

  for i, line in ipairs(lines) do
    local api_call = line:find("nvim_create_autocmd", 1, true)

    if api_call then
      local event_arg = line:match("nvim_create_autocmd%s*%((.-),")

      if event_arg then
        local events = normalize_events(event_arg)

        local brace_col = line:find("{", api_call)
        if brace_col then
          local impl, _ = read_brace_block(lines, i, brace_col)

          for _, ev in ipairs(events) do
            by_event[ev] = by_event[ev] or {}
            table.insert(by_event[ev], {
              path = rel_path,
              line = i,
              implementation = impl,
            })
          end

          table.insert(all_autocmds, {
            events = events,
            path = rel_path,
            line = i,
            implementation = impl,
          })
        end
      end
    end
  end
end

--- Append a multi-line string to a line list without using string.format.
---@param out string[]
---@param text string
local function append_multiline(out, text)
  for line in text:gmatch("([^\n]*)\n?") do
    table.insert(out, line)
  end
end

--- Recursively scan directories.
---@param dir string
local function scan_dir(dir)
  local fd = uv.fs_scandir(dir)
  if not fd then
    return
  end

  while true do
    local name, typ = uv.fs_scandir_next(fd)
    if not name then
      break
    end

    local full = dir .. "/" .. name
    if typ == "directory" then
      scan_dir(full)
    elseif typ == "file" and name:sub(-4) == ".lua" then
      local rel = full:gsub("^" .. ROOT .. "/", "")
      scan_file(full, rel)
    end
  end
end

--- Render report into a scratch buffer.
local function render()
  local out = {}

  -- Count total event registrations
  local total_registrations = 0
  for _, list in pairs(by_event) do
    total_registrations = total_registrations + #list
  end

  table.insert(out, "Autocmd Audit Summary")
  table.insert(out, "---------------------")
  table.insert(out, ("Total unique autocmd calls: %d"):format(#all_autocmds))
  table.insert(out, ("Total event registrations: %d"):format(total_registrations))
  table.insert(out, "")

  -- Statistics by event
  local stats = {}
  for ev, list in pairs(by_event) do
    table.insert(stats, { ev, #list })
  end

  table.sort(stats, function(a, b)
    return a[2] > b[2]
  end)

  table.insert(out, "Event frequency:")
  for _, item in ipairs(stats) do
    table.insert(out, ('  "%s": %d'):format(item[1], item[2]))
  end

  table.insert(out, "")
  table.insert(out, "Detailed listing (by source)")
  table.insert(out, "----------------------------")

  -- List all autocmds in discovery order
  for idx, item in ipairs(all_autocmds) do
    table.insert(out, "")
    table.insert(out, ("%d. %s:%d"):format(idx, item.path, item.line))
    table.insert(out, ("Events: %s"):format(table.concat(item.events, ", ")))
    table.insert(out, "Implementation:")
    append_multiline(out, item.implementation)
  end

  vim.cmd("new")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
end

--- Public entry point.
local function run()
  by_event = {}
  all_autocmds = {}

  scan_dir(ROOT)
  render()
end

-- Register user command
function M.enable()
  vim.api.nvim_create_user_command("ListAutocmdSources", function()
    run()
  end, {})
end

return M
