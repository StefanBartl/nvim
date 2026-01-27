---@module 'tools.autocmd_audit'
--- Static analysis tool to audit Neovim autocmd definitions.

local M = {}

local bo, uv = vim.bo, vim.loop
local tbl_insert, tbl_concat, tbl_sort = table.insert, table.concat, table.sort

---@type string
local ROOT = vim.fn.stdpath("config") .. "/lua"

---@type table<string, table[]>
local by_event = {}

---@type table[]
local all_autocmds = {}

---@type string[]
local KNOWN_EVENTS = {
  "BufAdd","BufDelete","BufEnter","BufLeave","BufNew","BufNewFile",
  "BufRead","BufReadPost","BufReadPre","BufUnload","BufWinEnter",
  "BufWinLeave","BufWipeout","BufWrite","BufWritePost","BufWritePre",
  "CmdlineEnter","CmdlineLeave","ColorScheme","CursorHold","CursorHoldI",
  "CursorMoved","CursorMovedI","DiagnosticChanged","DirChanged",
  "FileType","FocusGained","FocusLost","InsertEnter","InsertLeave",
  "LspAttach","LspDetach","ModeChanged","OptionSet","QuitPre",
  "TextChanged","TextChangedI","TextYankPost","UIEnter","VimEnter",
  "VimLeave","VimResized","WinEnter","WinLeave",
}

---@type string[]
local SORT_MODES = { "source", "event", "frequency" }

---@type string[]
local ARG_KEYS = {
  "event=",
  "sort=",
  "impl=",
  "summary=",
  "freq=",
  "root=",
}

---@param raw string
---@return string[]
local function normalize_events(raw)
  local events = {}
  for ev in raw:gmatch([["([^"]+)"]]) do
    tbl_insert(events, ev)
  end
  if #events == 0 then
    local single = raw:match([["([^"]+)"]])
    if single then
      events[1] = single
    end
  end
  tbl_sort(events)
  return events
end

---@param items string[]
---@param prefix string
---@return string[]
local function complete_from_list(items, prefix)
  local out = {}
  for _, item in ipairs(items) do
    if item:find(prefix, 1, true) == 1 then
      out[#out + 1] = item
    end
  end
  return out
end

---@param arglead string
---@param cmdline string
---@param cursor_pos integer
---@return string[]
---@diagnostic disable-next-line: unused-local
local function complete_cmd(arglead, cmdline, cursor_pos)
  local args = cmdline:sub(1, cursor_pos):gsub("^%S+%s*", "")
  local last = args:match("(%S+)$") or ""

  if last == "" or args:sub(-1) == " " then
    return ARG_KEYS
  end

  if last:find("^event=") then
    local prefix = last:sub(#"event=" + 1)
    local matches = {}
    for _, ev in ipairs(KNOWN_EVENTS) do
      if ev:lower():find(prefix:lower(), 1, true) == 1 then
        matches[#matches + 1] = "event=" .. ev
      end
    end
    return matches
  end

  if last:find("^sort=") then
    local prefix = last:sub(#"sort=" + 1)
    local out = {}
    for _, mode in ipairs(SORT_MODES) do
      if mode:find(prefix, 1, true) == 1 then
        out[#out + 1] = "sort=" .. mode
      end
    end
    return out
  end

  if last:find("^(impl|summary|freq)=") then
    local key = last:match("^(%w+=)")
    return { key .. "true", key .. "false" }
  end

  return complete_from_list(ARG_KEYS, last)
end

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
      if ch == "{" then depth = depth + 1 end
      if ch == "}" then depth = depth - 1 end
    end
    tbl_insert(out, line)
    if depth == 0 then
      return tbl_concat(out, "\n"), l
    end
  end
  return tbl_concat(out, "\n"), #lines
end

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
          local impl = read_brace_block(lines, i, brace_col)
          for _, ev in ipairs(events) do
            by_event[ev] = by_event[ev] or {}
            tbl_insert(by_event[ev], {
              path = rel_path,
              line = i,
              implementation = impl,
            })
          end
          tbl_insert(all_autocmds, {
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

---@param dir string
local function scan_dir(dir)
  local fd = uv.fs_scandir(dir)
  if not fd then return end
  while true do
    local name, typ = uv.fs_scandir_next(fd)
    if not name then break end
    local full = dir .. "/" .. name
    if typ == "directory" then
      scan_dir(full)
    elseif typ == "file" and name:sub(-4) == ".lua" then
      scan_file(full, full:gsub("^" .. ROOT .. "/", ""))
    end
  end
end

---@param args string
---@return table
local function parse_args(args)
  local opts = {
    event = nil,
    sort = "source",
    show_impl = true,
    show_summary = true,
    show_freq = true,
    root = ROOT,
  }
  for key, val in args:gmatch("(%w+)=([^%s]+)") do
    if key == "event" then opts.event = val
    elseif key == "sort" then opts.sort = val
    elseif key == "impl" then opts.show_impl = val ~= "false"
    elseif key == "summary" then opts.show_summary = val ~= "false"
    elseif key == "freq" then opts.show_freq = val ~= "false"
    elseif key == "root" then opts.root = val end
  end
  return opts
end

--- Generate output buffer content
---@param opts table
---@return string[]
local function generate_output(opts)
  local lines = {}

  -- Header
  tbl_insert(lines, "=== Autocmd Audit Report ===")
  tbl_insert(lines, "")
  tbl_insert(lines, "Root: " .. opts.root)
  tbl_insert(lines, "Total autocmds found: " .. #all_autocmds)
  tbl_insert(lines, "")

  -- Summary by event
  if opts.show_summary then
    tbl_insert(lines, "--- Summary by Event ---")
    local events = vim.tbl_keys(by_event)
    tbl_sort(events)
    for _, ev in ipairs(events) do
      tbl_insert(lines, string.format("  %-20s : %d", ev, #by_event[ev]))
    end
    tbl_insert(lines, "")
  end

  -- Filter by event if requested
  local items = opts.event and (by_event[opts.event] or {}) or all_autocmds

  if #items == 0 then
    tbl_insert(lines, "No autocmds found" .. (opts.event and " for event: " .. opts.event or ""))
    return lines
  end

  -- Sort
  if opts.sort == "event" then
    tbl_sort(items, function(a, b)
      return tbl_concat(a.events, ",") < tbl_concat(b.events, ",")
    end)
  elseif opts.sort == "frequency" then
    local freq = {}
    for _, item in ipairs(items) do
      local key = item.path .. ":" .. item.line
      freq[key] = (freq[key] or 0) + 1
    end
    tbl_sort(items, function(a, b)
      local ka = a.path .. ":" .. a.line
      local kb = b.path .. ":" .. b.line
      return freq[ka] > freq[kb]
    end)
  end
  -- else: source order (default)

  -- Detail output
  tbl_insert(lines, "--- Autocmd Details ---")
  tbl_insert(lines, "")

  for idx, item in ipairs(items) do
    local events_str = tbl_concat(item.events, ", ")
    tbl_insert(lines, string.format("[%d] %s", idx, events_str))
    tbl_insert(lines, string.format("    %s:%d", item.path, item.line))

    if opts.show_impl then
      tbl_insert(lines, "")
      for impl_line in item.implementation:gmatch("[^\n]+") do
        tbl_insert(lines, "    " .. impl_line)
      end
    end

    tbl_insert(lines, "")
  end

  return lines
end

---@return nil
function M.enable()
  vim.api.nvim_create_user_command("ListAutocmdSources", function(cmd)
    local opts = parse_args(cmd.args)

    -- Reset state
    by_event = {}
    all_autocmds = {}

    -- Scan
    scan_dir(opts.root)

    -- Generate output
    local output = generate_output(opts)

    -- Create buffer
    vim.cmd("new")
    bo.buftype = "nofile"
    bo.bufhidden = "wipe"
    bo.swapfile = false
    bo.filetype = "autocmd-audit"

    -- Set content
    vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
    bo.modifiable = false
  end, {
    nargs = "*",
    complete = complete_cmd,
  })
end

return M
