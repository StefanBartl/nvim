---@module 'bindings.usrcmds.plugin_repos.sync_state'
---@brief The saved result of the last `:MyPlugins sync` (`stdpath("state")/myplugins_sync.json`).
---@description
--- What it is for: `:MyPlugins sync issues` reopens the triage list after a restart, and a
--- skip survives closing the dashboard. What it is not for: a skip never outlives the next
--- full run -- that run writes a fresh result (a skip is "not now, for this synchronization",
--- never a permanent exclusion; those belong into `plugins.modes`).
---
--- The file is written atomically (temp file + rename), read defensively (a damaged or
--- foreign file is "no saved result", never an error) and never holds the transient preview.

local M = {}

---Format version; a file with another one is ignored.
M.VERSION = 1

local uv = vim.uv or vim.loop

---@class MyPlugins.SyncSaved
---@field version integer
---@field saved_at integer         Unix time.
---@field dir string               The base directory the run used.
---@field dry_run boolean
---@field records MyPlugins.SyncRecord[]

---@return string
function M.path()
  return vim.fn.stdpath("state") .. "/myplugins_sync.json"
end

---@param r any
---@return boolean
local function valid_record(r)
  return type(r) == "table"
    and type(r.name) == "string"
    and r.name ~= ""
    and type(r.path) == "string"
    and type(r.state) == "string"
end

---Write the result. `records` are copied without their `preview`/`preview_parts`.
---@param dir string
---@param records MyPlugins.SyncRecord[]
---@param opts? { path?: string, dry_run?: boolean, now?: integer }
---@return boolean ok
---@return string|nil err
function M.save(dir, records, opts)
  opts = opts or {}
  local path = opts.path or M.path()
  local clean = {}
  for _, r in ipairs(records) do
    local copy = vim.deepcopy(r)
    copy.preview = nil
    copy.preview_parts = nil
    clean[#clean + 1] = copy
  end
  ---@type MyPlugins.SyncSaved
  local data = {
    version = M.VERSION,
    saved_at = opts.now or os.time(),
    dir = dir,
    dry_run = opts.dry_run == true,
    records = clean,
  }
  local ok_enc, text = pcall(vim.json.encode, data)
  if not ok_enc then
    return false, "cannot encode the sync result: " .. tostring(text)
  end
  local parent = vim.fs.dirname(path)
  if parent and parent ~= "" then
    vim.fn.mkdir(parent, "p")
  end
  local tmp = ("%s.tmp.%d.%d"):format(path, uv.os_getpid(), uv.hrtime())
  local f, open_err = io.open(tmp, "wb")
  if not f then
    return false, "cannot write " .. tmp .. ": " .. tostring(open_err)
  end
  local wrote, write_err = f:write(text)
  local closed = f:close()
  if not wrote or not closed then
    pcall(os.remove, tmp)
    return false, "cannot write " .. tmp .. ": " .. tostring(write_err)
  end
  local renamed, rename_err = uv.fs_rename(tmp, path)
  if not renamed then
    pcall(os.remove, tmp)
    return false, "cannot replace " .. path .. ": " .. tostring(rename_err)
  end
  return true, nil
end

---Read the saved result. nil (and why) when there is none or it cannot be trusted.
---@param opts? { path?: string }
---@return MyPlugins.SyncSaved|nil data
---@return string|nil err
function M.load(opts)
  local path = (opts and opts.path) or M.path()
  local stat = uv.fs_stat(path)
  if not stat then
    return nil, "no saved sync result yet (run :MyPlugins sync)"
  end
  -- A runaway file is not ours (a result is a few KB); do not read it into memory.
  if stat.size > 1024 * 1024 then
    return nil, "the saved sync result is too large to be one"
  end
  local f = io.open(path, "rb")
  if not f then
    return nil, "cannot read " .. path
  end
  local text = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, text, { luanil = { object = true, array = true } })
  if not ok or type(data) ~= "table" then
    return nil, "the saved sync result is damaged"
  end
  if data.version ~= M.VERSION or type(data.records) ~= "table" then
    return nil, "the saved sync result has another format version"
  end
  local records = {}
  for _, r in ipairs(data.records) do
    if valid_record(r) then
      r.skipped = r.skipped == true
      r.ahead = tonumber(r.ahead) or 0
      r.behind = tonumber(r.behind) or 0
      r.changed = tonumber(r.changed) or 0
      r.dirty = r.dirty == true
      records[#records + 1] = r
    end
  end
  data.records = records
  data.dir = type(data.dir) == "string" and data.dir or ""
  -- The shape was checked field by field above; `vim.json.decode` itself can only say `table`.
  ---@type MyPlugins.SyncSaved
  ---@diagnostic disable-next-line: assign-type-mismatch
  local saved = data
  return saved, nil
end

return M
