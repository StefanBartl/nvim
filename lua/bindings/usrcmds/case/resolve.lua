---@module 'bindings.usrcmds.case.resolve'
--- "Which case is meant?" — the one place every route answers this, so
--- `[case]` is optional the same way everywhere: explicit argument wins,
--- else the case owning the focused buffer, else nil (caller falls back to
--- a kit.select). Buffer membership is checked against the registry rather
--- than an upward filesystem walk for a marker file, because most cases
--- adopted from the legacy layout have no `.case.json` beyond what
--- migrate.lua backfilled — registry membership works regardless.

local registry = require("bindings.usrcmds.case.registry")
local render = require("bindings.usrcmds.case.render")
local config = require("bindings.usrcmds.case.config")
local meta = require("bindings.usrcmds.case.meta")

local M = {}

---@param bufname string
---@return Lib.Case.RegistryEntry|nil
local function entry_from_buffer(bufname)
  if bufname == "" then
    return nil
  end
  bufname = bufname:gsub("\\", "/")
  for _, e in ipairs(registry.list()) do
    local d = e.dir:gsub("\\", "/")
    if bufname == d or bufname:sub(1, #d + 1) == d .. "/" then
      return e
    end
  end
  return nil
end

--- Synchronous resolution: argument > current buffer. Returns nil (not an
--- error) when neither pins down a case — the caller decides whether that
--- means "prompt the user" or "fail".
---@param explicit string|nil  Already CASE-argtype-validated (short form) or nil.
---@return Lib.Case.RegistryEntry|nil
function M.sync(explicit)
  if explicit and explicit ~= "" then
    return registry.find(render.to_short(explicit))
  end
  return entry_from_buffer(vim.api.nvim_buf_get_name(0))
end

--- Full resolution incl. UI fallback: argument > buffer > kit.select over
--- open cases. Always calls `cb` exactly once; `cb(nil)` means the user
--- cancelled or there was nothing to pick from.
---@param explicit string|nil
---@param cb fun(entry: Lib.Case.RegistryEntry|nil)
function M.pick(explicit, cb)
  local direct = M.sync(explicit)
  if direct then
    cb(direct)
    return
  end
  if explicit and explicit ~= "" then
    -- Argument was given but didn't resolve — don't silently fall through
    -- to "pick any case", that would hide a typo behind an unrelated case.
    cb(nil)
    return
  end

  local kit = require("lib.nvim.ui.kit")
  local open_entries = {}
  for _, e in ipairs(registry.list()) do
    if e.state == config.default_state then
      open_entries[#open_entries + 1] = e
    end
  end
  if #open_entries == 0 then
    cb(nil)
    return
  end

  kit.select({
    message = "Case",
    selection = open_entries,
    format_item = function(e)
      local m = meta.read(e.dir)
      local company = m and m.company
      return company and ("%s (%s)"):format(e.short, company) or e.short
    end,
    on_select = function(item)
      cb(item)
    end,
    on_cancel = function()
      cb(nil)
    end,
  })
end

return M
