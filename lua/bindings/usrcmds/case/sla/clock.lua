---@module 'bindings.usrcmds.case.sla.clock'
--- Pure time arithmetic for the SLA module — no Neovim API, so it works
--- without a running editor (see docs/ROADMAP/casedesk/SLA.md §4: "the one
--- part of this whole feature that isn't just plumbing"). Two entry points:
--- `elapsed` (how much SLA-relevant time lies between two epochs) and
--- `deadline` (the absolute epoch a business-time budget lands on from a
--- start point) — everything else in the sla/ tree is built on these two.
---
--- 24x7 windows are trivial arithmetic; 10x5 windows have to skip nights
--- and weekends, which is the entire reason this module exists instead of
--- `to - from` inline everywhere.

local M = {}

local DAY_SECONDS = 86400

---@class Lib.Case.SlaWindow
---@field from integer  business start, hour of day (local time), e.g. 8
---@field to integer    business end, hour of day (local time), e.g. 18
---@field days integer[]  `os.date("*t").wday` values (1=Sunday..7=Saturday) that count as business days

--- Sentinel for "no restriction" — every second counts, nights and
--- weekends included. The alternative to a `Lib.Case.SlaWindow` wherever
--- one is expected.
M.ALWAYS = "24x7"

---@param wday integer
---@param window Lib.Case.SlaWindow
---@return boolean
local function is_business_day(wday, window)
  for _, wd in ipairs(window.days) do
    if wd == wday then
      return true
    end
  end
  return false
end

--- Seconds of SLA-relevant time between `from` and `to`. `to <= from`
--- returns 0, never negative — this is a duration, not a signed delta.
---@param from integer epoch
---@param to integer epoch
---@param window Lib.Case.SlaWindow|"24x7"
---@return integer
function M.elapsed(from, to, window)
  if to <= from then
    return 0
  end
  if window == M.ALWAYS then
    return to - from
  end

  -- Walk day by day rather than second by second — O(days between from
  -- and to), and a day is only ever partially in-window at its two ends.
  local total = 0
  local cursor = from
  while cursor < to do
    local d = os.date("*t", cursor)
    local midnight = cursor - (d.hour * 3600 + d.min * 60 + d.sec)
    local day_end = math.min(to, midnight + DAY_SECONDS)

    if is_business_day(d.wday, window) then
      local win_start = midnight + window.from * 3600
      local win_end = midnight + window.to * 3600
      local overlap_start = math.max(cursor, win_start)
      local overlap_end = math.min(day_end, win_end)
      if overlap_end > overlap_start then
        total = total + (overlap_end - overlap_start)
      end
    end
    cursor = day_end
  end
  return total
end

--- The absolute epoch reached after `budget` seconds of SLA-relevant time
--- elapse starting at `from`. Inverse of `M.elapsed` in the sense that
--- `M.elapsed(from, M.deadline(from, budget, window), window) == budget`
--- (up to the whole-second rounding both operate at).
---@param from integer epoch
---@param budget integer seconds of business time
---@param window Lib.Case.SlaWindow|"24x7"
---@return integer epoch
function M.deadline(from, budget, window)
  if budget <= 0 then
    return from
  end
  if window == M.ALWAYS then
    return from + budget
  end

  local remaining = budget
  local cursor = from
  -- Bounded to just over a year of calendar days so a misconfigured
  -- window (e.g. empty `days`) fails loud (returns `cursor` at the bound)
  -- instead of spinning.
  for _ = 1, 366 do
    local d = os.date("*t", cursor)
    local midnight = cursor - (d.hour * 3600 + d.min * 60 + d.sec)
    local next_midnight = midnight + DAY_SECONDS

    if is_business_day(d.wday, window) then
      local win_start = midnight + window.from * 3600
      local win_end = midnight + window.to * 3600
      local seg_start = math.max(cursor, win_start)
      if seg_start < win_end then
        local available = win_end - seg_start
        if remaining <= available then
          return seg_start + remaining
        end
        remaining = remaining - available
      end
    end
    cursor = next_midnight
  end
  return cursor
end

--- Days since 1970-01-01 for a UTC/proleptic-Gregorian civil date — Howard
--- Hinnant's `days_from_civil`, pure integer arithmetic (`math.floor`
--- instead of Lua 5.3's `//`, since LuaJIT is 5.1). Deliberately NOT
--- `os.time`-based: the obvious "build a local table, diff it against its
--- own UTC round-trip" idiom looks like it should recover the UTC offset,
--- but on this Windows host it silently returns the STANDARD-time offset
--- year-round — `os.date("!*t", …)`'s `isdst` comes back unset, so feeding
--- that table back into `os.time` makes it assume no DST even in August,
--- undercounting CEST by exactly one hour. This function has no `os.time`
--- call in it at all, so there's no DST table to get wrong.
---@param y integer
---@param mo integer
---@param d integer
---@return integer days
local function days_from_civil(y, mo, d)
  local yy = mo <= 2 and (y - 1) or y
  local era = math.floor((yy >= 0 and yy or (yy - 399)) / 400)
  local yoe = yy - era * 400
  local mp = mo + (mo > 2 and -3 or 9)
  local doy = math.floor((153 * mp + 2) / 5) + d - 1
  local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
  return era * 146097 + doe - 719468
end

--- Epoch of `y-mo-d h:mi:s` interpreted as **UTC**, independent of the
--- host's timezone or DST state. Used for the Activity Stream's
--- `at: ... GMT` lines and `.case.json`'s ISO-8601 `created`.
---@param y integer
---@param mo integer
---@param d integer
---@param h integer
---@param mi integer
---@param s integer
---@return integer epoch
function M.utc(y, mo, d, h, mi, s)
  return days_from_civil(y, mo, d) * DAY_SECONDS + h * 3600 + mi * 60 + s
end

--- Human-readable duration, sign-aware (negative = overdue). `"1T 2h 5m"`,
--- `"-45m"`, `"3h"`. Used by `sla/init.lua`'s status lines and the
--- statusline badge — deliberately not `timeline.format_duration`, which
--- has no negative case and collapses to "touched" at zero (right for a
--- lower-bound work duration, wrong for a deadline that can be missed).
---@param seconds integer
---@return string
function M.format_duration(seconds)
  local sign = seconds < 0 and "-" or ""
  local s = math.abs(seconds)
  local days = math.floor(s / DAY_SECONDS)
  local hours = math.floor((s % DAY_SECONDS) / 3600)
  local minutes = math.floor((s % 3600) / 60)

  local parts = {}
  if days > 0 then
    parts[#parts + 1] = days .. "T"
  end
  if hours > 0 or days > 0 then
    parts[#parts + 1] = hours .. "h"
  end
  if days == 0 then
    parts[#parts + 1] = minutes .. "m"
  end
  return sign .. table.concat(parts, " ")
end

return M
