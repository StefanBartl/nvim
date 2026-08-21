---@module 'bindings.usrcmds.case.stream_format'
--- Which activity-stream export format a pasted text is in — SNOW's own
--- copy-paste (`sla/stream.lua`'s and `extract/stream.lua`'s original and
--- still primary target) or SAP Resolve's Tampermonkey-formatted
--- Conversations export (EXTRACTION.md §13). Shared by both parsers so
--- neither has to depend on the other, or duplicate this.
---
--- Cheap: only the first non-empty line matters, and both formats are
--- unambiguous there. `nil` for anything else — never an error, same
--- "degrade to an empty result" posture both parsers already document for
--- unrecognized input; a third format (or garbage) just means neither
--- adapter runs.

local M = {}

---@alias Lib.Case.StreamFormat "snow"|"saperesolve"

---@param text string|nil
---@return Lib.Case.StreamFormat|nil
function M.detect(text)
  for line in ((text or ""):gsub("\r", "")):gmatch("[^\n]*") do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      if trimmed == "Activity" then
        return "snow"
      end
      if trimmed:match("^%[%d+/%d+%]") then
        return "saperesolve"
      end
      return nil
    end
  end
  return nil
end

--- `[idx/total] M/D/YY at H:MM AM/PM` — a SAP Resolve entry header's own
--- timestamp, with no timezone marker at all (unlike SNOW's separate
--- `at: … GMT` line). Tampermonkey formats these from the browser's own
--- local clock, so — same choice `sla/stream.lua`'s `parse_local` already
--- makes for SNOW's local-time lines — they're read as LOCAL time via
--- `os.time`, not treated as UTC (SLA.md's documented DST lesson: getting
--- this wrong silently shifts every timestamp by an hour or two, and
--- silently is the problem).
---@param date_part string  "8/17/26"
---@param time_part string  "3:52 PM"
---@return integer|nil epoch
local function saperesolve_datetime(date_part, time_part)
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

---@class Lib.Case.SapResolveHeader
---@field idx integer    the entry's own `[idx/total]` index — descending, `1` is the NEWEST entry
---@field total integer  total entry count as the export itself declares it
---@field at integer     epoch
---@field actor string   customer name, `SAP`, or `Integration API` (EXTRACTION.md §13)
---@field action string  e.g. "Returned Case to Customer"

--- One SAP Resolve entry header, or nil for any other line. Every signal
--- either parser extracts from this format lives entirely in the header —
--- no body text needed — so both work line-by-line through this rather
--- than block-by-block the way the SNOW parsers must.
---@param line string
---@return Lib.Case.SapResolveHeader|nil
function M.saperesolve_header(line)
  local idx, total, date_part, time_part, actor, action = (line or ""):match(
    "^%[(%d+)/(%d+)%]%s+(%d+/%d+/%d+)%s+at%s+(%d+:%d+%s*[AaPp][Mm])%s*|%s*([^|]-)%s*|%s*(.+)$"
  )
  if not idx then
    return nil
  end
  local at = saperesolve_datetime(date_part, time_part)
  if not at then
    return nil
  end
  return {
    idx = tonumber(idx),
    total = tonumber(total),
    at = at,
    actor = vim.trim(actor),
    action = vim.trim(action),
  }
end

return M
