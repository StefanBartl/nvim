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
---@field links string[]|nil
---@field blueprint string|nil
---@field created string|nil
---@field status string|nil

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

return M
