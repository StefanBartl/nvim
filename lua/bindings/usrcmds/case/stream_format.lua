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

return M
