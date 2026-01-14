---@module 'config.neotree.open.window'
---@brief Neo-tree opener with advanced timing statistics, persistence, and project-size correlation

local map = require("lib.map")
local buffer_utils = require("config.neotree.utils.buffer")

local uv = vim.loop
local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/neotree_timings.json"

local M = {}

local print_record = true

---@enum Cfg.NeoTree.MeasurePositionEnum
local PositionEnum = {
  left = "left",
  right = "right",
  float = "float",
  current = "current",
}

---@type Cfg.NeoTree.Cfg
M.cfg = {
  extra_lhs = {
    ["<A-c>"] = { "¢" },
    ["<A-f>"] = { "đ" },
    ["<A-l>"] = { "ł" },
    ["<A-r>"] = { "¶" },
  },
}

-- ============================================================================
-- Timing / Statistics (session + cwd + persistence)
-- ============================================================================

---@class NeoTreeTiming.Entry
---@field method string
---@field position string
---@field duration_ns integer
---@field cwd string
---@field cwd_files integer|nil
---@field first_session boolean
---@field first_cwd boolean

local Timing = {
  ---@type NeoTreeTiming.Entry[]
  entries = {},
}

---@type table<string, boolean>
local opened_session = {}

---@type table<string, boolean>
local opened_per_cwd = {}

---@param path string
---@return integer|nil
local function count_files_shallow(path)
  local handle = uv.fs_scandir(path)
  if not handle then
    return nil
  end
  local count = 0
  while true do
    local name = uv.fs_scandir_next(handle)
    if not name then
      break
    end
    count = count + 1
  end
  return count
end

---@param entry NeoTreeTiming.Entry
local function persist_append(entry)
  local data = {}
  local fd = io.open(state_file, "r")
  if fd then
    local ok, decoded = pcall(vim.json.decode, fd:read("*a"))
    fd:close()
    if ok and type(decoded) == "table" then
      data = decoded
    end
  end
  data[#data + 1] = entry
  fd = io.open(state_file, "w")
  if fd then
    fd:write(vim.json.encode(data))
    fd:close()
  end
end

-- Pretty-print for a single timing entry
do
  ---@param e NeoTreeTiming.Entry
  local function print_entry(e)
    local flags = {}
    if e.first_session then
      flags[#flags + 1] = "first-session"
    end
    if e.first_cwd then
      flags[#flags + 1] = "first-cwd"
    end

    local flag_str = #flags > 0 and (" [" .. table.concat(flags, ", ") .. "]") or ""

    print(
      string.format(
        "[neo-tree] %-8s pos=%-7s time=%7.3f ms cwd=%s files=%s%s",
        e.method,
        e.position,
        e.duration_ns / 1e6,
        e.cwd,
        e.cwd_files and tostring(e.cwd_files) or "?",
        flag_str
      )
    )
  end

  -- Call this at the end of Timing.record(...)
  -- print_entry(entry)
end

---@param method string
---@param position string
---@param duration_ns integer
function Timing.record(method, position, duration_ns)
  local cwd = uv.cwd() or vim.fn.stdpath("config")
  local cwd_files = count_files_shallow(cwd)

  local first_session = not opened_session[position]
  local first_cwd = not opened_per_cwd[cwd]

  opened_session[position] = true
  opened_per_cwd[cwd] = true

  local entry = {
    method = method,
    position = position,
    duration_ns = duration_ns,
    cwd = cwd,
    cwd_files = cwd_files,
    first_session = first_session,
    first_cwd = first_cwd,
  }

  Timing.entries[#Timing.entries + 1] = entry
  persist_append(entry)

  if print_record == true then
    print(
      string.format(
        "[neo-tree] %s %s %.3f ms",
        entry.method,
        entry.position,
        entry.duration_ns / 1e6
      )
    )
  end
end

---@param list NeoTreeTiming.Entry[]
---@return table
local function aggregate(list)
  if #list == 0 then
    return { count = 0 }
  end
  local min, max, sum = math.huge, 0, 0
  for i = 1, #list do
    local d = list[i].duration_ns
    if d < min then
      min = d
    end
    if d > max then
      max = d
    end
    sum = sum + d
  end
  return {
    count = #list,
    min_ns = min,
    max_ns = max,
    avg_ns = math.floor(sum / #list),
  }
end

---@param ns integer|nil
---@return string
local function fmt_ns(ns)
  if not ns then
    return "-"
  end
  return string.format("%.3f ms", ns / 1e6)
end

---@param entries NeoTreeTiming.Entry[]
local function bucket_by_project_size(entries)
  local buckets = {
    small = {},
    medium = {},
    large = {},
  }
  for i = 1, #entries do
    local e = entries[i]
    if e.cwd_files then
      if e.cwd_files < 200 then
        buckets.small[#buckets.small + 1] = e
      elseif e.cwd_files < 2000 then
        buckets.medium[#buckets.medium + 1] = e
      else
        buckets.large[#buckets.large + 1] = e
      end
    end
  end
  return buckets
end

---@param entries NeoTreeTiming.Entry[]
local function print_stats(title, entries)
  local s = aggregate(entries)
  print(
    string.format(
      "%-32s count=%d avg=%s min=%s max=%s",
      title,
      s.count,
      fmt_ns(s.avg_ns),
      fmt_ns(s.min_ns),
      fmt_ns(s.max_ns)
    )
  )
end

function Timing.print_report(all_entries)
  local all = all_entries or Timing.entries

  print("Neo-tree Timing Statistics")
  print("----------------------------------------")

  print_stats("Overall", all)

  local first_session = {}
  local reopen_session = {}
  local first_cwd = {}
  local reopen_cwd = {}

  for i = 1, #all do
    local e = all[i]
    if e.first_session then
      first_session[#first_session + 1] = e
    else
      reopen_session[#reopen_session + 1] = e
    end
    if e.first_cwd then
      first_cwd[#first_cwd + 1] = e
    else
      reopen_cwd[#reopen_cwd + 1] = e
    end
  end

  print("")
  print_stats("First open (session)", first_session)
  print_stats("Reopen (session)", reopen_session)
  print_stats("First open (cwd)", first_cwd)
  print_stats("Reopen (cwd)", reopen_cwd)

  print("")
  print("First open by project size:")
  local buckets = bucket_by_project_size(first_cwd)
  for name, list in pairs(buckets) do
    print_stats("  " .. name, list)
  end
end

-- ============================================================================
-- User Commands
-- ============================================================================

vim.api.nvim_create_user_command("NeoTreeTimings", function()
  Timing.print_report()
end, {})

vim.api.nvim_create_user_command("NeoTreeTimingsPersistent", function()
  local fd = io.open(state_file, "r")
  if not fd then
    print("No persistent timing data found")
    return
  end
  local decoded = vim.json.decode(fd:read("*a"))
  fd:close()
  Timing.print_report(decoded or {})
end, {})

vim.api.nvim_create_user_command("NeoTreeTimingsClear", function()
  os.remove(state_file)
  Timing.entries = {}
  opened_session = {}
  opened_per_cwd = {}
  print("Neo-tree timing statistics cleared")
end, {})

-- ============================================================================
-- Neo-tree opener with timing
-- ============================================================================

---@param position Cfg.NeoTree.Position
---@param method string
---@return fun()|nil
local function make_neotree_opener(position, method)
  local ok_nt, NeoCmd = pcall(require, "neo-tree.command")
  if not ok_nt then
    vim.notify("[neotree.open.window] neo-tree.command not available", vim.log.levels.WARN)
    return
  end

  if not PositionEnum[position] then
    position = PositionEnum.left
  end

  return function()
    local start_ns = uv.hrtime()

    local ctx = buffer_utils.get_buffer_context()
    local reveal_file, dir
    if ctx then
      reveal_file = ctx.file
      dir = ctx.dir
    end

    NeoCmd.execute({
      source = "filesystem",
      toggle = true,
      reveal = true,
      reveal_file = reveal_file,
      reveal_force_cwd = false,
      position = position,
      dir = dir,
    })

    vim.schedule(function()
      Timing.record(method, position, uv.hrtime() - start_ns)
    end)
  end
end

local function register_aliases(lhs, pos, desc)
  local cb = make_neotree_opener(pos, lhs)
  if not cb then
    return
  end

  map("n", lhs, cb, { desc = desc, silent = true })

  local m_lhs = lhs:gsub("^<A%-", "<M-")
  if m_lhs ~= lhs then
    pcall(map, "n", m_lhs, cb, { desc = desc .. " (Meta alias)", silent = true })
  end

  if M.cfg.extra_lhs and M.cfg.extra_lhs[lhs] then
    for _, alt in ipairs(M.cfg.extra_lhs[lhs]) do
      pcall(map, "n", alt, cb, { desc = desc .. " (alias)", silent = true })
    end
  end
end

---@param opts Cfg.NeoTree.Cfg|nil
function M.attach_opener_mappings(opts)
  if type(opts) == "table" then
    if opts.extra_lhs then
      M.cfg.extra_lhs = vim.tbl_deep_extend("force", M.cfg.extra_lhs or {}, opts.extra_lhs)
      opts.extra_lhs = nil
    end
    for k, v in pairs(opts) do
      M.cfg[k] = v
    end
  end

  local specs = {
    { lhs = "<A-c>", pos = "current", desc = "[Neo-tree] Toggle & Reveal (current)" },
    { lhs = "<A-f>", pos = "float", desc = "[Neo-tree] Toggle & Reveal (float)" },
    { lhs = "<A-l>", pos = "left", desc = "[Neo-tree] Toggle & Reveal (left)" },
    { lhs = "<A-r>", pos = "right", desc = "[Neo-tree] Toggle & Reveal (right)" },
  }

  for i = 1, #specs do
    local m = specs[i]
    register_aliases(m.lhs, m.pos, m.desc)
  end
end

return M
