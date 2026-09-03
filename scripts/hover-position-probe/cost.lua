-- What does one ask of the position pipeline cost, with the position
-- contributors this machine actually has installed?
--
-- The *declining* cost is the one that matters, for the same reason the gopath
-- measurement did: the automatic trigger overwhelmingly lands where nothing
-- answers, so the misses are the population. A memo would be caching "nobody
-- had anything to say here" far more often than an answer.
for _, dir in ipairs({
  "E:/repos/hover.nvim",
  "E:/repos/lib.nvim",
  "E:/repos/spotlight.nvim",
  "E:/repos/documentation.nvim",
}) do
  vim.opt.rtp:append(dir)
end

local registry = require("hover.registry")

local out = {}
local function say(fmt, ...)
  out[#out + 1] = select("#", ...) > 0 and fmt:format(...) or fmt
end

for _, mod in ipairs({ "spotlight.hover", "migrate.hover", "documentation.hover" }) do
  local ok, m = pcall(require, mod)
  if ok and type(m) == "table" and type(m.setup) == "function" then
    local ok2, err = pcall(m.setup)
    say("  %-24s %s", mod, ok2 and "registered" or ("setup failed: " .. tostring(err)))
  else
    say("  %-24s not loadable", mod)
  end
end

say("registered contributors:")
for _, c in ipairs(registry.contributors()) do
  say(
    "  %-24s sources=%d previews=%d positions=%d on_request=%d",
    c.name,
    c.sources,
    c.previews,
    c.positions,
    c.on_request
  )
end

-- A realistic buffer to be reading: this plugin's own orchestration module.
local path = "E:/repos/hover.nvim/lua/hover/init.lua"
local lines = vim.fn.readfile(path)
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(buf, path)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.bo[buf].filetype = "lua"
say("buffer: %s, %d lines", vim.fn.fnamemodify(path, ":t"), #lines)

-- Where a reader's cursor actually sits.
--
-- The first cut of this walked column 0, and every number came out flattering
-- for a reason that had nothing to do with the pipeline: column 0 of a Lua
-- file is indentation, `token_at` and `dotted_at` both decline on whitespace
-- in a few instructions, and `find_map` -- up to 24 `fs_stat` calls with no
-- negative cache -- was never reached at all. So the columns below are chosen
-- to be *on* something, which is the only case a hover is ever asked about.
---@return { row: integer, col: integer }[]
local function positions_over(bufnr, n)
  local text = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local out = {}
  for row = 1, n do
    local line = text[row] or ""
    local first = line:find("%S")
    if first then
      -- Two columns into the first word: on a token, not on its edge.
      out[#out + 1] = { row = row, col = math.min(first + 1, #line) - 1 }
      -- And, where the line has a dotted name, inside it -- that is what
      -- documentation.nvim's preview is looking for, and the only path that
      -- reaches its directory walk.
      local dot = line:find("%a[%w_]*%.[%w_]")
      if dot then
        out[#out + 1] = { row = row, col = dot }
      end
    end
  end
  return out
end

local spots = positions_over(buf, #lines)
say("sampled positions: %d (first word of each line, plus every dotted name)", #spots)

local function bench(label, force)
  registry.position_at(buf, 1, 0, { force = force })
  local answered = 0
  local t0 = vim.uv.hrtime()
  for _, p in ipairs(spots) do
    if registry.position_at(buf, p.row, p.col, { force = force }) then
      answered = answered + 1
    end
  end
  local ns = vim.uv.hrtime() - t0
  say(
    "  %-22s %6d asks  %8.1f us/ask  %6.1f ms total  (%d answered)",
    label,
    #spots,
    ns / #spots / 1000,
    ns / 1e6,
    answered
  )
end

say("cost of one ask:")
bench("automatic trigger", false)
bench("explicit :Hover show", true)

io.open(vim.env.PROBE_OUT, "w"):write(table.concat(out, "\n") .. "\n"):close()
