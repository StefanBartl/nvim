-- position_probe.lua -- how often is the position pipeline asked the same
-- (bufnr, row, col, changedtick) twice?
--
-- The question behind roadmap 2.5. Registers a position contributor that
-- always returns nil, so it counts the asks without changing what the session
-- does: `position_at` runs every contributor until one answers, and one that
-- never answers is invisible except in this table.
--
-- Registered under its own name, so it does not take the "user" slot away
-- from a real contribution in the config being measured.
local M = {}

---@type table<string, integer> key -> how often it was asked
local seen = {}
---@type string|nil the key of the previous ask
local last = nil

M.asks = 0 -- every ask of the position pipeline
M.distinct = 0 -- distinct (bufnr, row, col, changedtick)
M.repeats = 0 -- asks whose key had been asked before
M.consecutive = 0 -- ... and whose key was the *immediately* previous one
M.same_row = 0 -- asks at the same (bufnr, row, changedtick) as the previous, col ignored

---@type string|nil
local last_row_key = nil

--- Start counting. Idempotent.
function M.install()
  M.reset()
  require("hover.registry").register("position-probe", {
    positions = {
      function(bufnr, row, col)
        local tick = vim.api.nvim_buf_get_changedtick(bufnr)
        local key = ("%d:%d:%d:%d"):format(bufnr, row, col, tick)
        local row_key = ("%d:%d:%d"):format(bufnr, row, tick)

        M.asks = M.asks + 1
        if seen[key] then
          seen[key] = seen[key] + 1
          M.repeats = M.repeats + 1
          if last == key then
            M.consecutive = M.consecutive + 1
          end
        else
          seen[key] = 1
          M.distinct = M.distinct + 1
        end
        if last_row_key == row_key then
          M.same_row = M.same_row + 1
        end

        last, last_row_key = key, row_key
        return nil -- never answers; the pipeline is unchanged
      end,
    },
  })
end

function M.reset()
  seen, last, last_row_key = {}, nil, nil
  M.asks, M.distinct, M.repeats, M.consecutive, M.same_row = 0, 0, 0, 0, 0
end

--- One line, so it can be read over RPC or dropped in a statusline.
---@return string
function M.line()
  local pct = M.asks > 0 and (M.repeats / M.asks * 100) or 0
  return ("asks=%d distinct=%d repeats=%d (%.1f%%) consecutive=%d same_row=%d"):format(
    M.asks,
    M.distinct,
    M.repeats,
    pct,
    M.consecutive,
    M.same_row
  )
end

--- The full report, for `:lua print(require("position_probe").report())`.
---@return string
function M.report()
  local rows = {}
  for key, n in pairs(seen) do
    if n > 1 then
      rows[#rows + 1] = { key = key, n = n }
    end
  end
  table.sort(rows, function(a, b)
    return a.n > b.n
  end)

  local out = { "position pipeline, this session:", "  " .. M.line() }
  if #rows > 0 then
    out[#out + 1] = ("  %d key(s) asked more than once, worst first:"):format(#rows)
    for i = 1, math.min(#rows, 10) do
      out[#out + 1] = ("    %s  x%d"):format(rows[i].key, rows[i].n)
    end
  end
  return table.concat(out, "\n")
end

return M
