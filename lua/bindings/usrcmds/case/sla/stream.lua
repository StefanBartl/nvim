---@module 'bindings.usrcmds.case.sla.stream'
--- Extracts the handful of signals the SLA clock needs from a SNOW Activity
--- Stream (`Research/NN_ActivityStream.md`): Priority/Impact, every
--- customer message, every assignment, and the earliest timestamped event
--- on record — a candidate "ticket opened" anchor (SLA.md §9.2: `.case.json`'s
--- `created` is when the case FOLDER was made, which can trail the real
--- SNOW ticket by days, as it did for case 977392).
---
--- Never raises on unexpected input: a stream copied from a different SNOW
--- view, or garbage, degrades to an empty result — same "say so instead of
--- silently filing garbage" posture as ki.lua's M.parse_response, just with
--- "silently return nothing" instead of an error, since a missing SLA
--- signal is normal (not every case's stream has been pasted in yet) where
--- a missing KI-answer section is not.

local clock = require("bindings.usrcmds.case.sla.clock")

local M = {}

---@class Lib.Case.SlaEvent
---@field at integer     epoch (UTC)
---@field actor string|nil

---@class Lib.Case.SlaStreamData
---@field priority string|nil    raw value as SNOW shows it, e.g. "3 - Moderate"
---@field impact string|nil
---@field earliest integer|nil   epoch of the oldest timestamped event found
---@field customer Lib.Case.SlaEvent[]  ascending by `at`
---@field assignments Lib.Case.SlaEvent[]  ascending by `at`

---@param value string  e.g. "2026-08-05 05:58:36 GMT"
---@return integer|nil
local function parse_gmt(value)
  local y, mo, d, h, mi, s = value:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
  if not y then
    return nil
  end
  return clock.utc(tonumber(y), tonumber(mo), tonumber(d), tonumber(h), tonumber(mi), tonumber(s))
end

---@param value string  e.g. "2026-08-05 16:26:34" (LOCAL time, no GMT suffix —
---  "Field changes" blocks don't carry an `at:` line the way comments do)
---@return integer|nil
local function parse_local(value)
  local y, mo, d, h, mi, s = value:match("^(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)$")
  if not y then
    return nil
  end
  return os.time({
    year = tonumber(y),
    month = tonumber(mo),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(s),
  })
end

---@param text string
---@return Lib.Case.SlaStreamData
function M.parse(text)
  text = (text or ""):gsub("\r", "")
  local lines = vim.split(text, "\n", { plain = true })
  local n = #lines

  ---@type Lib.Case.SlaStreamData
  local out = { priority = nil, impact = nil, earliest = nil, customer = {}, assignments = {} }

  local function note_earliest(epoch)
    if epoch and (not out.earliest or epoch < out.earliest) then
      out.earliest = epoch
    end
  end

  for i = 1, n do
    local line = vim.trim(lines[i])

    if line == "Priority" or line == "Impact" then
      local value = lines[i + 1] and vim.trim(lines[i + 1]) or ""
      if value ~= "" then
        out[line == "Priority" and "priority" or "impact"] = value
      end
    end

    -- `at: 2026-08-05 05:58:36 GMT` — one line above is the block's memo
    -- type ("Customer added a memo", "SAP added a memo for the partner",
    -- ...), one line below is `from: <name>`.
    local at_value = line:match("^at:%s*(.+)$")
    if at_value then
      local epoch = parse_gmt(at_value)
      note_earliest(epoch)
      local label = lines[i - 1] and vim.trim(lines[i - 1]) or ""
      if epoch and label == "Customer added a memo" then
        local from_line = lines[i + 1] and vim.trim(lines[i + 1]) or ""
        local actor = from_line:match("^from:%s*(.+)$")
        out.customer[#out.customer + 1] = { at = epoch, actor = actor }
      end
    end

    -- `Assigned to` / `<name> was Empty` — the date lives 2 lines above,
    -- right after the block's own `Field changes` label, LOCAL time (no
    -- `at:`/GMT line for field-change blocks in this format).
    if line == "Assigned to" then
      local target_line = lines[i + 1] and vim.trim(lines[i + 1]) or ""
      local actor = target_line:match("^(.-) was ")
      local at = nil
      for j = i - 1, math.max(1, i - 4), -1 do
        at = parse_local(vim.trim(lines[j]))
        if at then
          break
        end
      end
      if at then
        out.assignments[#out.assignments + 1] = { at = at, actor = actor }
        note_earliest(at)
      end
    end
  end

  table.sort(out.customer, function(a, b)
    return a.at < b.at
  end)
  table.sort(out.assignments, function(a, b)
    return a.at < b.at
  end)

  return out
end

return M
