---@module 'bindings.usrcmds.case.sla'
--- Public API for casedesk's SLA layer (docs/ROADMAP/casedesk/SLA.md):
--- given a case, which of the three SAP-SLA clocks (Erstreaktion, laufende
--- Rückmeldung, Korrekturmaßnahme) apply and how much of each is left.
---
--- Two "ticket opened" anchors are surfaced side by side rather than one
--- being picked as THE answer (SLA.md §9.1): whether the Erstreaktion clock
--- should run from the SNOW ticket's real creation (earliest stream event)
--- or from when this case was assigned/picked up is still open. Showing
--- both keeps that open instead of silently assuming the more comfortable
--- one.

local config = require("bindings.usrcmds.case.config")
local meta = require("bindings.usrcmds.case.meta")
local read = require("lib.nvim.fs.read")
local clock = require("bindings.usrcmds.case.sla.clock")
local stream = require("bindings.usrcmds.case.sla.stream")

local uv = vim.uv or vim.loop

local M = {}

M.format_duration = clock.format_duration

---@param dir string
---@return string|nil path  Highest-numbered `NN_ActivityStream.md` under Research/.
local function newest_activity_stream(dir)
  local research_dir = dir .. "/Research"
  local fd = uv.fs_scandir(research_dir)
  if not fd then
    return nil
  end
  local best, best_n = nil, -1
  while true do
    local name = uv.fs_scandir_next(fd)
    if not name then
      break
    end
    local n = name:match("^(%d+)_ActivityStream%.md$")
    if n then
      local num = tonumber(n)
      if num > best_n then
        best_n, best = num, research_dir .. "/" .. name
      end
    end
  end
  return best
end

---@param iso string|nil  "2026-08-05T14:29:07Z"
---@return integer|nil
local function parse_iso(iso)
  if not iso then
    return nil
  end
  local y, mo, d, h, mi, s = iso:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not y then
    return nil
  end
  return clock.utc(tonumber(y), tonumber(mo), tonumber(d), tonumber(h), tonumber(mi), tonumber(s))
end

---@param m Lib.Case.Meta|nil
---@return string|nil digit
---@return Lib.Case.SlaLevel|nil level
local function level_of(m)
  local p = m and m.priority
  if not p then
    return nil, nil
  end
  local digit = p:match("^%s*(%d)")
  if not digit then
    return nil, nil
  end
  return digit, config.sla[digit]
end

---@param dir string
---@return Lib.Case.SlaStreamData
local function stream_data(dir)
  local path = newest_activity_stream(dir)
  if not path then
    return { customer = {}, assignments = {}, states = {} }
  end
  local content = read(path)
  if not content then
    return { customer = {}, assignments = {}, states = {} }
  end
  return stream.parse(content)
end

--- Is the case, right now, sitting in "Awaiting User Info" — the
--- customer's turn, nothing pending for the agent? Just the most recent
--- state event's `to`; SNOW's own state, not casedesk's Open/Closed/
--- Reassigned folder state.
---@param states Lib.Case.SlaStateEvent[]  ascending by `at`
---@return boolean
local function awaiting_customer(states)
  local latest = states[#states]
  return latest ~= nil and latest.to == "Awaiting User Info"
end

--- Total wall-clock time this case has spent sitting in "Awaiting User
--- Info" (EXTRACTION.md §5, decided 2026-08-10): unlike the cadence
--- clock above (which RESETS to a fresh full budget once the customer
--- replies — a periodic "give an update" obligation, so a reset is the
--- right model), the fix/Korrekturmaßnahme clock is a single cumulative
--- deadline, where resetting on every customer reply would effectively
--- give it unlimited budget across a multi-round exchange. A true
--- pause — extend the deadline by exactly how long the customer sat on
--- it — is what "the agent's clock doesn't run while it's the
--- customer's turn" actually means for a one-time deadline. Sums every
--- `Awaiting User Info` interval in the state history, not just whether
--- the case happens to be sitting there right now — an ongoing one
--- (no state change since) counts up to `now`.
---@param states Lib.Case.SlaStateEvent[]  ascending by `at`
---@param now integer
---@return integer seconds
local function total_awaiting_seconds(states, now)
  local total = 0
  for i, s in ipairs(states) do
    if s.to == "Awaiting User Info" then
      local resumed_at = states[i + 1] and states[i + 1].at or now
      total = total + math.max(0, resumed_at - s.at)
    end
  end
  return total
end

---@param ... integer|nil
---@return integer|nil  the largest non-nil argument, or nil if all are nil
local function latest_of(...)
  -- NOT `for _, v in ipairs({ ... })`: a leading nil (last_reply_sent is
  -- nil far more often than not — most cases never get :Case reply
  -- check's "sent" stamp) makes `{...}` a table with a hole at index 1,
  -- and ipairs stops at the first hole — silently skipping every argument
  -- after it. select() has no such gap-stopping behavior.
  local best = nil
  local n = select("#", ...)
  for i = 1, n do
    local v = select(i, ...)
    if v and (not best or v > best) then
      best = v
    end
  end
  return best
end

---@class Lib.Case.SlaClockStatus
---@field label string
---@field since integer     anchor epoch this clock counts from
---@field deadline integer  absolute epoch
---@field remaining integer seconds; negative = overdue
---@field budget integer    seconds, for percentage-based warnings
---@field done boolean      only meaningful for `first_response`: a reply was sent after `since`

---@class Lib.Case.SlaStatus
---@field digit string
---@field level Lib.Case.SlaLevel
---@field opened_at_created integer|nil
---@field opened_at_stream integer|nil
---@field assigned_at integer|nil
---@field last_customer_at integer|nil
---@field last_reply_sent integer|nil
---@field first_response Lib.Case.SlaClockStatus[]  one per available anchor
---@field cadence Lib.Case.SlaClockStatus|nil  nil while `awaiting_customer` — see that field
---@field fix Lib.Case.SlaClockStatus|nil
---@field awaiting_customer boolean  case is sitting in SNOW's "Awaiting
---  User Info" right now: no cadence obligation pending (nothing to give
---  an update ON), `cadence` is nil FOR THIS REASON, not because there's
---  no data. Confirmed against real casework: the clock resets — not
---  pauses-and-resumes — to a FULL fresh budget once the customer replies,
---  dated from that reply, not from whatever was left when it stopped.

---@param entry Lib.Case.RegistryEntry
---@return Lib.Case.SlaStatus|nil  nil when no parseable priority is set
function M.status(entry)
  local m = meta.read(entry.dir)
  local digit, level = level_of(m)
  if not level then
    return nil
  end

  local data = stream_data(entry.dir)
  local now = os.time()

  local opened_created = parse_iso(m and m.created)
  local opened_stream = data.earliest
  local assigned_at = data.assignments[#data.assignments] and data.assignments[#data.assignments].at
    or nil
  local last_customer_at = data.customer[#data.customer] and data.customer[#data.customer].at or nil
  local last_reply_sent = parse_iso(m and m.last_reply_sent)

  ---@type Lib.Case.SlaClockStatus[]
  local first_response = {}
  local function fr_clock(label, anchor)
    if not anchor then
      return
    end
    local dl = clock.deadline(anchor, level.first_response, level.window)
    first_response[#first_response + 1] = {
      label = label,
      since = anchor,
      deadline = dl,
      remaining = dl - now,
      budget = level.first_response,
      done = last_reply_sent ~= nil and last_reply_sent >= anchor,
    }
  end
  fr_clock("ab Ticket-Eingang", opened_stream)
  fr_clock("ab Zuweisung", assigned_at)

  -- Confirmed against real casework (SLA.md §3 Nachtrag): while the case
  -- sits in "Awaiting User Info", the agent owes no update, so there is no
  -- cadence deadline to show. The moment the customer replies (or the
  -- state moves off Awaiting User Info some other way), a FRESH cadence
  -- period starts from THAT timestamp — not resumed from wherever the
  -- clock stood when it stopped. `last_reply_sent`/`last_customer_at`
  -- whichever is more recent covers both directions: my own reply resets
  -- it same as before, and the customer's reply now does too.
  local is_awaiting = awaiting_customer(data.states)

  ---@type Lib.Case.SlaClockStatus|nil
  local cadence = nil
  if not is_awaiting then
    local cadence_since = latest_of(last_reply_sent, last_customer_at)
      or assigned_at
      or opened_stream
      or opened_created
    local cadence_budget = level.cadence[1]
    if cadence_since and cadence_budget then
      local dl = clock.deadline(cadence_since, cadence_budget, level.window)
      cadence = {
        label = "Rückmeldung",
        since = cadence_since,
        deadline = dl,
        remaining = dl - now,
        budget = cadence_budget,
        done = false,
      }
    end
  end

  ---@type Lib.Case.SlaClockStatus|nil
  local fix = nil
  local fix_since = opened_stream or opened_created
  if fix_since then
    -- EXTRACTION.md §5: extend both the deadline AND the budget by
    -- however long the case has sat in Awaiting User Info — see
    -- total_awaiting_seconds' doc comment for why this is a pause/extend,
    -- not the cadence clock's reset. `budget` grows too, not just
    -- `deadline`, so M.under_threshold's percentage stays meaningful
    -- against the case's REAL available time instead of flagging a
    -- long-paused P1 as falsely near-breach.
    local awaiting_seconds = total_awaiting_seconds(data.states, now)
    local effective_budget = level.fix + awaiting_seconds
    local dl = clock.deadline(fix_since, level.fix, level.fix_window) + awaiting_seconds
    fix = {
      label = "Korrekturmaßnahme",
      since = fix_since,
      deadline = dl,
      remaining = dl - now,
      budget = effective_budget,
      done = false,
    }
  end

  return {
    digit = digit,
    level = level,
    opened_at_created = opened_created,
    opened_at_stream = opened_stream,
    assigned_at = assigned_at,
    last_customer_at = last_customer_at,
    last_reply_sent = last_reply_sent,
    first_response = first_response,
    cadence = cadence,
    fix = fix,
    awaiting_customer = is_awaiting,
  }
end

--- The single most urgent clock across first_response/cadence/fix, or nil
--- when the case has no parseable priority or no clock could be anchored
--- at all. Shared by the statusline badge and `:Cases sla`'s sort order.
---@param status Lib.Case.SlaStatus
---@return Lib.Case.SlaClockStatus|nil
function M.most_urgent(status)
  local worst = nil
  local function consider(c)
    if c and (not worst or c.remaining < worst.remaining) then
      worst = c
    end
  end
  for _, c in ipairs(status.first_response) do
    consider(c)
  end
  consider(status.cadence)
  consider(status.fix)
  return worst
end

---@param c Lib.Case.SlaClockStatus
---@param warn_at number  fraction of budget remaining, e.g. 0.25
---@return boolean
function M.under_threshold(c, warn_at)
  if not c or c.budget <= 0 then
    return false
  end
  return c.remaining < 0 or (c.remaining / c.budget) < warn_at
end

return M
