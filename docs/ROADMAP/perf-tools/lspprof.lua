-- lspprof.lua — find WHICH LSP work blocks the main loop, and when.
--
-- v2. The first version wrapped the handlers from a single vim.defer_fn(1200).
-- That is exactly wrong for a saturated loop: the deferred callback cannot run
-- while the loop is busy, so on a bad run it fired at +4.6 s — after the stall
-- it was meant to explain. Wrapping now happens repeatedly and idempotently
-- (at load, on every LspAttach, and on a repeating timer), so the wrappers are
-- in place before the interesting event no matter how late the config installs
-- its own handlers.
--
-- Usage:
--   nvim --cmd "luafile <this file>" <somefile>
--
-- Exclude one server (re-run per suspect):
--   nvim --cmd "lua vim.g.lspprof_skip='lua_ls'" --cmd "luafile <this file>" <file>

local uv = vim.uv or vim.loop

local INTERVAL_MS = 20
local STALL_MS = 80
local SLOW_MS = 30
local REWRAP_MS = 150 -- how often to re-scan for unwrapped handlers
local REPORT_AFTER_MS = 12000

local t0 = uv.hrtime()
local function now_s()
  return (uv.hrtime() - t0) / 1e9
end

local events = {}
local function note(at, what)
  events[#events + 1] = { at = at, what = what }
end

-- ── stall detector ───────────────────────────────────────────────────────────
local last = t0
local timer = uv.new_timer()
timer:start(INTERVAL_MS, INTERVAL_MS, function()
  local n = uv.hrtime()
  local late = (n - last) / 1e6 - INTERVAL_MS
  last = n
  if late >= STALL_MS then
    note((n - t0) / 1e9, ("STALL          loop blocked %.0f ms"):format(late))
  end
end)

-- ── client starts (with optional exclusion) ──────────────────────────────────
local skip = vim.g.lspprof_skip
local real_start = vim.lsp.start
vim.lsp.start = function(config, ...)
  local name = (type(config) == "table" and config.name) or "?"
  if skip and name == skip then
    note(now_s(), ("lsp.start      %s  [SKIPPED]"):format(name))
    return
  end
  local t = uv.hrtime()
  local res = real_start(config, ...)
  note(now_s(), ("lsp.start      %s  (%.0f ms in start())"):format(name, (uv.hrtime() - t) / 1e6))
  return res
end

-- ── idempotent wrapping of the client-side work ──────────────────────────────
local WRAPPED = {} -- marker table: fn -> true for functions we produced
local wrap_count = 0

local function wrap_handlers()
  for method, fn in pairs(vim.lsp.handlers) do
    if type(fn) == "function" and not WRAPPED[fn] then
      local inner = fn
      local wrapper = function(...)
        local t = uv.hrtime()
        local ok, a, b, c = pcall(inner, ...)
        local ms = (uv.hrtime() - t) / 1e6
        if ms >= SLOW_MS then
          note(now_s(), ("handler        %s  %.0f ms"):format(method, ms))
        end
        if not ok then error(a, 0) end
        return a, b, c
      end
      WRAPPED[wrapper] = true
      vim.lsp.handlers[method] = wrapper
      wrap_count = wrap_count + 1
    end
  end
end

local function wrap_diagnostic()
  local fn = vim.diagnostic.set
  if type(fn) ~= "function" or WRAPPED[fn] then
    return
  end
  local wrapper = function(ns, bufnr, diags, ...)
    local t = uv.hrtime()
    local res = fn(ns, bufnr, diags, ...)
    local ms = (uv.hrtime() - t) / 1e6
    if ms >= SLOW_MS then
      note(
        now_s(),
        ("diagnostic.set %d item(s)  %.0f ms"):format(type(diags) == "table" and #diags or -1, ms)
      )
    end
    return res
  end
  WRAPPED[wrapper] = true
  vim.diagnostic.set = wrapper
end

local function wrap_all()
  pcall(wrap_handlers)
  pcall(wrap_diagnostic)
end

wrap_all() -- immediately, before the config runs

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local c = vim.lsp.get_client_by_id(ev.data.client_id)
    note(now_s(), ("LspAttach      %s -> buf %d"):format(c and c.name or "?", ev.buf))
    wrap_all() -- the config's own handlers are certainly installed by now
  end,
})

-- Keep re-scanning: a plugin may replace a handler at any point, and a busy
-- loop can delay any single scheduled pass past the event we care about.
local rewrap = uv.new_timer()
rewrap:start(REWRAP_MS, REWRAP_MS, function()
  vim.schedule(wrap_all)
end)

-- ── what is the server actually doing ────────────────────────────────────────
-- lua_ls reports its workspace indexing here; lining this up against the stall
-- shows whether the block is the indexing result being processed.
pcall(function()
  vim.api.nvim_create_autocmd("LspProgress", {
    callback = function(ev)
      local v = ev.data and ev.data.params and ev.data.params.value
      if not v then
        return
      end
      if v.kind == "begin" or v.kind == "end" then
        local c = ev.data.client_id and vim.lsp.get_client_by_id(ev.data.client_id)
        note(
          now_s(),
          ("progress       %s  %s: %s%s"):format(
            c and c.name or "?",
            v.kind,
            v.title or "",
            v.message and (" — " .. v.message) or ""
          )
        )
      end
    end,
  })
end)

-- ── report ───────────────────────────────────────────────────────────────────
vim.defer_fn(function()
  timer:stop()
  rewrap:stop()
  table.sort(events, function(x, y)
    return x.at < y.at
  end)

  local lines = { ("=== lsp timeline + stalls (first %.0f s) ==="):format(REPORT_AFTER_MS / 1000) }
  for _, e in ipairs(events) do
    lines[#lines + 1] = ("  +%6.2f s  %s"):format(e.at, e.what)
  end
  lines[#lines + 1] = ("  (%d handler wrappers installed)"):format(wrap_count)

  pcall(vim.fn.writefile, lines, "lspprof.log")
  vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN)
end, REPORT_AFTER_MS)
