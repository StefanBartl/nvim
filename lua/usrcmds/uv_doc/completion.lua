---@module 'uv_doc.completion'
---@brief Command-line completion for uv_* symbols

local M = {}

local strings = require("lib.strings")
local fetcher = require("usrcmds.uv_doc.fetcher")

--- Provides completion candidates
---@param arglead string
---@param cmdline string|nil
---@param cursorpos integer|nil
---@nodiscard
---@return string[]
---@diagnostic disable-next-line: unused-local
function M.complete(arglead, cmdline, cursorpos)
  local all = fetcher.ensure_symbols()

  -- Fallback: introspect vim.uv/vim.loop
  if not all or #all == 0 then
    all = {}
    local uv = vim.uv or vim.loop
    if type(uv) == "table" then
      ---@type table<string, boolean>
      local tmp = {}
      for k, v in pairs(uv) do
        if type(v) == "function" then
          local canonical
          if k == "cwd" then
            canonical = "uv_cwd"
          elseif k == "chdir" then
            canonical = "uv_chdir"
          else
            local constructor = k:match("^new_(%w+)$")
            canonical = constructor and ("uv_" .. constructor .. "_init") or ("uv_" .. k)
          end
          if canonical then
            tmp[canonical] = true
          end
        end
      end

      for sym in pairs(tmp) do
        all[#all + 1] = sym
      end
      table.sort(all)
    end
  end

  -- Filter by arglead
  local q = tostring(arglead or "")
  q = strings.replace_plain(q, "vim.uv.", "")
  local needle = q:lower()

  if strings.is_empty_or_space(needle) then
    return all
  end

  ---@type string[]
  local matches = {}
  for i = 1, #all do
    local name = all[i]
    if strings.contains(name:lower(), needle) then
      matches[#matches + 1] = name
    end
  end

  return matches
end

return M
