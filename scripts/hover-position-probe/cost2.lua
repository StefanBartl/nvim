for _, dir in ipairs({
  "E:/repos/hover.nvim",
  "E:/repos/lib.nvim",
  "E:/repos/spotlight.nvim",
  "E:/repos/migrate.nvim",
  "E:/repos/documentation.nvim",
}) do
  vim.opt.rtp:append(dir)
end

local registry = require("hover.registry")
local out = {}
local function say(fmt, ...)
  out[#out + 1] = select("#", ...) > 0 and fmt:format(...) or fmt
end

local path = "E:/repos/hover.nvim/lua/hover/init.lua"
local lines = vim.fn.readfile(path)
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(buf, path)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.bo[buf].filetype = "lua"

local spots = {}
for row = 1, #lines do
  local line = lines[row] or ""
  local first = line:find("%S")
  if first then
    spots[#spots + 1] = { row = row, col = math.min(first + 1, #line) - 1 }
    local dot = line:find("%a[%w_]*%.[%w_]")
    if dot then
      spots[#spots + 1] = { row = row, col = dot }
    end
  end
end

--- Time the pipeline with exactly `mods` registered.
---@param label string
---@param mods string[]
local function bench(label, mods)
  registry.reset()
  for _, mod in ipairs(mods) do
    local m = require(mod)
    if type(m._reset) == 'function' then
      pcall(m._reset)
    end
    pcall(m.setup)
  end
  registry.position_at(buf, 1, 0)
  local t0 = vim.uv.hrtime()
  for _, p in ipairs(spots) do
    registry.position_at(buf, p.row, p.col)
  end
  local ns = vim.uv.hrtime() - t0
  say("  %-34s %8.1f us/ask   %6.1f ms over %d asks", label, ns / #spots / 1000, ns / 1e6, #spots)
end

say("buffer: %s, %d lines; %d sampled positions", vim.fn.fnamemodify(path, ":t"), #lines, #spots)
say("cost of one ask, by who is registered:")
bench("nothing registered", {})
bench("spotlight.nvim alone", { "spotlight.hover" })
bench("migrate.nvim alone", { "migrate.hover" })
bench("documentation.nvim alone", { "documentation.hover" })
bench("all three", { "spotlight.hover", "migrate.hover", "documentation.hover" })

local fd = io.open(vim.env.PROBE_OUT, "w")
fd:write(table.concat(out, "\n") .. "\n")
fd:close()
