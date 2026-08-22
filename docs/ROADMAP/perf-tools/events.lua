-- events.lua — stalls AND a timeline of what happened, on one clock.
--
-- stall.lua answers "when was the loop blocked". It cannot answer "by what".
-- luaprof.lua names a file:line but aggregates over the whole run, so a single
-- 470ms block is hard to pick out of it.
--
-- This sits in between: the same self-lateness timer as stall.lua, plus a
-- timestamp for every event that plausibly explains a block — each lazy.nvim
-- plugin load (with its own load time as lazy measured it), VimEnter,
-- VeryLazy, LspAttach, and LSP progress. The report interleaves both, so a
-- block is read off directly against what ran during it.
--
-- Load it BEFORE the config, so the timer ticks during startup:
--   nvim --cmd "luafile <this file>" <somefile>
--
-- After REPORT_AFTER_MS it prints the timeline and writes ./events.log.

local uv = vim.uv or vim.loop

local INTERVAL_MS = 20
local STALL_MS = 80
local REPORT_AFTER_MS = 12000

local t0 = uv.hrtime()
local last = t0

---@type { at: number, kind: string, text: string, late?: number }[]
local marks = {}

---@param kind string
---@param text string
local function mark(kind, text)
  marks[#marks + 1] = { at = (uv.hrtime() - t0) / 1e9, kind = kind, text = text }
end

-- ── the stall timer ─────────────────────────────────────────────────────────

local timer = uv.new_timer()
timer:start(INTERVAL_MS, INTERVAL_MS, function()
  local now = uv.hrtime()
  local late = (now - last) / 1e6 - INTERVAL_MS
  last = now
  if late >= STALL_MS then
    -- `at` is when the block ENDED; the block covers [at - late, at].
    marks[#marks + 1] = { at = (now - t0) / 1e9, kind = "STALL", text = "", late = late }
  end
end)

-- ── event sources ───────────────────────────────────────────────────────────

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    mark("event", "VimEnter")
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    mark("event", "VeryLazy")
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyLoad",
  callback = function(ev)
    local name = tostring(ev.data)
    -- lazy records its own load time per plugin; report it, since a plugin
    -- that took 200ms to load is exactly the kind of thing a block is made of.
    local ok, cfg = pcall(require, "lazy.core.config")
    local ms = ""
    if ok then
      local p = cfg.plugins[name]
      local t = p and p._ and p._.loaded and p._.loaded.time
      if type(t) == "number" then
        ms = (" (%.0f ms)"):format(t / 1e6)
      end
    end
    mark("plugin", name .. ms)
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local c = vim.lsp.get_client_by_id(ev.data.client_id)
    mark("lsp", "LspAttach " .. (c and c.name or "?"))
  end,
})

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local v = ev.data and ev.data.params and ev.data.params.value
    if type(v) == "table" and v.kind == "begin" then
      mark("lsp", "progress: " .. tostring(v.title))
    end
  end,
})

-- ── report ──────────────────────────────────────────────────────────────────

vim.defer_fn(function()
  timer:stop()

  table.sort(marks, function(a, b)
    return a.at < b.at
  end)

  local total, count = 0, 0
  local lines = {
    ("=== timeline + stalls >= %d ms (first %.0f s) ==="):format(STALL_MS, REPORT_AFTER_MS / 1000),
    "  a STALL line covers [at - blocked, at] — read the events just above it",
    "",
  }

  for _, m in ipairs(marks) do
    if m.kind == "STALL" then
      total = total + m.late
      count = count + 1
      lines[#lines + 1] =
        ("  +%6.2f s  ***** STALL  blocked %6.0f ms  (from +%.2f s)"):format(m.at, m.late, m.at - m.late / 1000)
    else
      lines[#lines + 1] = ("  +%6.2f s  %-7s %s"):format(m.at, m.kind, m.text)
    end
  end

  lines[#lines + 1] = ""
  if count == 0 then
    lines[#lines + 1] = "  no stalls — the loop stayed responsive"
  else
    lines[#lines + 1] = ("  ---- %d stall(s), %.0f ms blocked in total"):format(count, total)
  end

  pcall(vim.fn.writefile, lines, "events.log")
  vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN)
end, REPORT_AFTER_MS)
