---@module 'bindings.usrcmds.case.meta'
--- Read/write the `.case.json` sidecar. Thin wrapper over lib.nvim.fs.json:
--- the only thing added here is the fixed filename and a safe "file doesn't
--- exist yet" read (a legacy case with no sidecar is not an error).

local config = require("bindings.usrcmds.case.config")
local json = require("lib.nvim.fs.json")

local M = {}

---@param case_dir string
---@return string
local function path(case_dir)
  return case_dir .. "/" .. config.meta_filename
end

---@class Lib.Case.Meta
---@field case string
---@field year string
---@field title string|nil
---@field company string|nil
---@field name string|nil
---@field notes string|nil
---@field priority string|nil
---@field tosca_version string|nil
---@field links string[]|nil
---@field blueprint string|nil
---@field created string|nil
---@field status string|nil
---@field last_reply_sent string|nil  ISO-8601 UTC, set by `:Case reply check`'s "sent?" prompt (SLA.md §6A) — the one signal the SLA cadence clock can't derive from the Activity Stream alone.

--- Read a case's sidecar. `nil` (not an error) when it doesn't exist yet —
--- true for every one of the 19 pre-existing cases.
---@param case_dir string
---@return Lib.Case.Meta|nil
function M.read(case_dir)
  local decoded, err = json.read(path(case_dir))
  if not decoded then
    if err and not err:match("^read failed") then
      require("lib.nvim.notify").create("[usrcmds.case]").warn("meta read: " .. err)
    end
    return nil
  end
  return decoded
end

---@param case_dir string
---@param meta Lib.Case.Meta
---@return boolean ok
---@return string|nil err
function M.write(case_dir, meta)
  return json.write(path(case_dir), meta)
end

--- Merge `fields` into the existing sidecar (or a bare `{ case = short }`
--- stub if there isn't one yet) and write it back — every OTHER field
--- already on disk is preserved. `M.write` itself has no such merge (every
--- existing caller already builds the full table it wants), but a
--- single-field update — SLA's auto-detected `priority`, `last_reply_sent`
--- — would otherwise have to read-modify-write by hand at every call site.
---@param case_dir string
---@param short string  used only for the stub when no sidecar exists yet
---@param fields table<string, any>
---@return boolean ok
---@return string|nil err
function M.patch(case_dir, short, fields)
  local current = M.read(case_dir) or { case = short, year = os.date("%Y"), links = {} }
  for k, v in pairs(fields) do
    current[k] = v
  end
  return M.write(case_dir, current)
end

return M
