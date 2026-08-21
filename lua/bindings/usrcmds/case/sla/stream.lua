---@module 'bindings.usrcmds.case.sla.stream'
--- Extracts the handful of signals the SLA clock needs from an Activity
--- Stream (`Research/NN_ActivityStream.md`): Priority/Impact, every
--- customer message, every assignment, and the earliest timestamped event
--- on record — a candidate "ticket opened" anchor (SLA.md §9.2: `.case.json`'s
--- `created` is when the case FOLDER was made, which can trail the real
--- ticket by days, as it did for case 977392).
---
--- Two source formats, dispatched via `stream_format.detect` (EXTRACTION.md
--- §13): SNOW's own copy-paste (`parse_snow`, the original and still
--- primary target) and SAP Resolve's Tampermonkey-formatted Conversations
--- export (`parse_saperesolve`). `priority`/`impact` stay nil for the
--- latter — EXTRACTION.md §13 documents that as a real gap in the export
--- itself, not a parser shortcoming.
---
--- Never raises on unexpected input: a stream copied from a different view,
--- or garbage, degrades to an empty result — same "say so instead of
--- silently filing garbage" posture as ki.lua's M.parse_response, just with
--- "silently return nothing" instead of an error, since a missing SLA
--- signal is normal (not every case's stream has been pasted in yet) where
--- a missing KI-answer section is not.

local clock = require("bindings.usrcmds.case.sla.clock")
local stream_format = require("bindings.usrcmds.case.stream_format")

local M = {}

---@class Lib.Case.SlaEvent
---@field at integer     epoch (UTC)
---@field actor string|nil

---@class Lib.Case.SlaStateEvent
---@field at integer
---@field to string
---@field from string|nil

---@class Lib.Case.SlaStreamData
---@field priority string|nil    raw value as SNOW shows it, e.g. "3 - Moderate"
---@field impact string|nil
---@field earliest integer|nil   epoch of the oldest timestamped event found
---@field customer Lib.Case.SlaEvent[]  ascending by `at`
---@field assignments Lib.Case.SlaEvent[]  ascending by `at`
---@field states Lib.Case.SlaStateEvent[]  ascending by `at` — SNOW's OWN
---  ticket state ("New"/"Active"/"Awaiting User Info"), not to be confused
---  with casedesk's Open/Closed/Reassigned folder state (registry.lua)

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
local function parse_snow(text)
  text = (text or ""):gsub("\r", "")
  local lines = vim.split(text, "\n", { plain = true })
  local n = #lines

  ---@type Lib.Case.SlaStreamData
  local out =
    { priority = nil, impact = nil, earliest = nil, customer = {}, assignments = {}, states = {} }

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

    -- `State` / `<to> was <from>` — same block shape as `Assigned to`
    -- above. Doesn't match the trailing `State`/`New` pair in the
    -- Field-changes-less metadata dump at the very end of a stream: that
    -- value line has no " was ", so `to` stays nil and the block is
    -- skipped. SLA.md §3 Nachtrag: the cadence clock needs to know whether
    -- the case is currently sitting in "Awaiting User Info" (the
    -- customer's turn — nothing pending for the agent) or was handed back.
    if line == "State" then
      local target_line = lines[i + 1] and vim.trim(lines[i + 1]) or ""
      local to, from = target_line:match("^(.-) was (.+)$")
      local at = nil
      for j = i - 1, math.max(1, i - 4), -1 do
        at = parse_local(vim.trim(lines[j]))
        if at then
          break
        end
      end
      if at and to then
        out.states[#out.states + 1] = { at = at, to = to, from = from }
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
  table.sort(out.states, function(a, b)
    return a.at < b.at
  end)

  return out
end

--- `[idx/total] M/D/YY at H:MM AM/PM` — the header's own timestamp, no
--- timezone marker at all (unlike SNOW's separate `at: … GMT` line).
--- Tampermonkey formats these from the browser's own local clock, so —
--- same choice `parse_local` above already makes for SNOW's local-time
--- lines — they're interpreted as LOCAL time via `os.time`, not treated as
--- UTC (SLA.md's own documented DST lesson: getting this wrong silently
--- shifts every timestamp by 1-2h, not something that throws).
---@param date_part string  "8/17/26"
---@param time_part string  "3:52 PM"
---@return integer|nil
local function parse_saperesolve_datetime(date_part, time_part)
  local mo, d, yy = date_part:match("^(%d+)/(%d+)/(%d+)$")
  if not mo then
    return nil
  end
  local h, mi, ampm = time_part:match("^(%d+):(%d+)%s*([AaPp][Mm])$")
  if not h then
    return nil
  end
  h = tonumber(h)
  ampm = ampm:upper()
  if ampm == "PM" and h ~= 12 then
    h = h + 12
  elseif ampm == "AM" and h == 12 then
    h = 0
  end
  return os.time({
    year = 2000 + tonumber(yy),
    month = tonumber(mo),
    day = tonumber(d),
    hour = h,
    min = tonumber(mi),
    sec = 0,
  })
end

--- SNOW-vocabulary state transitions synthesized from SAP Resolve's action
--- labels — deliberately the SAME strings `parse_snow`'s own `State`
--- block produces ("Awaiting User Info"/"Active"), so `sla/init.lua`'s
--- `awaiting_customer()` and every other consumer of `states` works on
--- either source without a single downstream change.
---@type table<string, { to: string, from: string }>
local SAPERESOLVE_STATE_TRANSITIONS = {
  ["Returned Case to Customer"] = { to = "Awaiting User Info", from = "Active" },
  ["Information from Customer"] = { to = "Active", from = "Awaiting User Info" },
}

--- Customer-authored actions, for the `customer` array (SLA.md's
--- `last_customer_at` cadence anchor). "Described the problem" (case
--- creation, the last/oldest entry) is deliberately excluded — matches
--- SNOW, where the initial ticket Description isn't a "Customer added a
--- memo" event either, only contributes to `earliest`.
---@type table<string, boolean>
local SAPERESOLVE_CUSTOMER_ACTIONS = {
  ["Information from Customer"] = true,
  ["Business Impact"] = true,
}

--- EXTRACTION.md §13, Paket 6a. Every entry is fully described by its own
--- header line — no body text needed for what this parser extracts, so it
--- works line-by-line rather than block-by-block like `parse_snow`.
---
--- `priority`/`impact` stay nil: the Conversations export carries neither
--- field in any form (EXTRACTION.md §13's "zwei echte Lücken"), not
--- something this parser could recover by trying harder. `assignments`
--- stays empty too — no equivalent signal in this export.
---@param text string
---@return Lib.Case.SlaStreamData
local function parse_saperesolve(text)
  text = (text or ""):gsub("\r", "")

  ---@type Lib.Case.SlaStreamData
  local out =
    { priority = nil, impact = nil, earliest = nil, customer = {}, assignments = {}, states = {} }

  local function note_earliest(epoch)
    if epoch and (not out.earliest or epoch < out.earliest) then
      out.earliest = epoch
    end
  end

  for line in text:gmatch("[^\n]+") do
    local idx, date_part, time_part, actor, action = line:match(
      "^%[(%d+)/%d+%]%s+(%d+/%d+/%d+)%s+at%s+(%d+:%d+%s*[AaPp][Mm])%s*|%s*([^|]-)%s*|%s*(.+)$"
    )
    if idx then
      local at = parse_saperesolve_datetime(date_part, time_part)
      if at then
        note_earliest(at)
        actor = vim.trim(actor)
        action = vim.trim(action)

        if SAPERESOLVE_CUSTOMER_ACTIONS[action] then
          out.customer[#out.customer + 1] = { at = at, actor = actor }
        end

        local transition = SAPERESOLVE_STATE_TRANSITIONS[action]
        if transition then
          out.states[#out.states + 1] = { at = at, to = transition.to, from = transition.from }
        end
      end
    end
  end

  table.sort(out.customer, function(a, b)
    return a.at < b.at
  end)
  table.sort(out.states, function(a, b)
    return a.at < b.at
  end)

  return out
end

---@param text string
---@return Lib.Case.SlaStreamData
function M.parse(text)
  if stream_format.detect(text) == "saperesolve" then
    return parse_saperesolve(text)
  end
  return parse_snow(text)
end

return M
