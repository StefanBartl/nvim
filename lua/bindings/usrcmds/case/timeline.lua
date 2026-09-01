---@module 'bindings.usrcmds.case.timeline'
--- "When and how long was this case actually worked?" — reconstructed
--- purely from file mtimes under the case folder, no separate logbook that
--- could drift from what actually happened (same reasoning as
--- `detect.last_touched`, and CONCEPT.md §3's "the state IS the folder":
--- derive from what's already there instead of tracking a second copy).
---
--- Consecutive touches close together in time are grouped into one work
--- session. A session's span is a LOWER BOUND on time actually spent — an
--- mtime marks when a save happened, not when editing started, so a session
--- with a single touch collapses to zero duration even though real work
--- came before that save.

local collect_recursive = require("lib.nvim.fs.collect_recursive")
local config = require("bindings.usrcmds.case.config")

local M = {}

local uv = vim.uv or vim.loop

---@class Lib.Case.TimelineEvent
---@field path string  relative to the case dir, forward slashes
---@field mtime integer  epoch seconds

---@param case_dir string
---@return Lib.Case.TimelineEvent[] ascending by mtime
local function events(case_dir)
  local out = {}
  for _, f in ipairs(collect_recursive.files(case_dir)) do
    local st = uv.fs_stat(f)
    local mtime = st and st.mtime and st.mtime.sec
    if mtime then
      out[#out + 1] = { path = f:sub(#case_dir + 2):gsub("\\", "/"), mtime = mtime }
    end
  end
  table.sort(out, function(a, b)
    return a.mtime < b.mtime
  end)
  return out
end

---@class Lib.Case.TimelineSession
---@field start integer
---@field finish integer
---@field events Lib.Case.TimelineEvent[]

--- Groups touches into sessions the same way a calendar infers "how long
--- was this meeting" from click timestamps alone: no fixed session length,
--- just "still the same sitting" (gap under `config.timeline_session_gap_minutes`)
--- vs. "came back later" (a new session starts).
---@param case_dir string
---@return Lib.Case.TimelineSession[] sessions # ascending, oldest first
function M.sessions(case_dir)
  local evs = events(case_dir)
  if #evs == 0 then
    return {}
  end

  local gap = config.timeline_session_gap_minutes * 60
  local sessions = { { start = evs[1].mtime, finish = evs[1].mtime, events = { evs[1] } } }
  for i = 2, #evs do
    local last = sessions[#sessions]
    if evs[i].mtime - last.finish <= gap then
      last.finish = evs[i].mtime
      last.events[#last.events + 1] = evs[i]
    else
      sessions[#sessions + 1] = { start = evs[i].mtime, finish = evs[i].mtime, events = { evs[i] } }
    end
  end
  return sessions
end

---@param seconds integer
---@return string
function M.format_duration(seconds)
  if seconds <= 0 then
    return "touched"
  end
  local h = math.floor(seconds / 3600)
  local m = math.floor((seconds % 3600) / 60)
  if h > 0 then
    return m > 0 and ("%dh%02dm"):format(h, m) or ("%dh"):format(h)
  end
  return m > 0 and ("%dm"):format(m) or "<1m"
end

return M
