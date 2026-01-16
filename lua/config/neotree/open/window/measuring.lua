---@module 'config.neotree.open.window.measuring'
---@brief Timing wrapper around Neo-tree window controller

local uv = vim.loop
local controller = require("config.neotree.open.window.controller")

local M = {}

local print_record = true
local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/neotree_timings.json"

-- ============================================================================
-- Timing / Statistics (session + cwd + persistence)
-- ============================================================================

local Timing = {
  ---@type Cfg.NeoTree.Open.Win.TimingEntry[]
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

---@param entry Cfg.NeoTree.Open.Win.TimingEntry
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

---@param method string
---@param position string
---@param duration_ns integer
---@param action_type Cfg.NeoTree.Position
function Timing.record(method, position, duration_ns, action_type)
  local cwd = uv.cwd() or vim.fn.stdpath("config")
  local cwd_files = count_files_shallow(cwd)

  local first_session = not opened_session[position]
  local first_cwd = not opened_per_cwd[cwd]

  opened_session[position] = true
  opened_per_cwd[cwd] = true

  ---@type Cfg.NeoTree.Open.Win.TimingEntry
  local entry = {
    method = method,
    position = position,
    duration_ns = duration_ns,
    cwd = cwd,
    cwd_files = cwd_files,
    first_session = first_session,
    first_cwd = first_cwd,
    action_type = action_type,
  }

  Timing.entries[#Timing.entries + 1] = entry
  persist_append(entry)

  if print_record == true then
    print(
      string.format(
        ("[neo-tree.open.win.timing_rec] %s %s %s %.3f ms"),
        entry.action_type,
        entry.method,
        entry.position,
        entry.duration_ns / 1e6
      )
    )
  end
end

---@param list Cfg.NeoTree.Open.Win.TimingEntry[]
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

---@param entries Cfg.NeoTree.Open.Win.TimingEntry[]
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

---@param entries Cfg.NeoTree.Open.Win.TimingEntry[]
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

---@param target_position string
---@param method string
---@return fun()
function M.make_opener(target_position, method)
  local opener = controller.make_opener(target_position)

  return function()
    local start_ns = uv.hrtime()
    opener()
    local duration_ns = uv.hrtime() - start_ns

    Timing.record(method, target_position, duration_ns, controller.get_state().position)
  end
end

return M
