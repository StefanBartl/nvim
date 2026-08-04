---@module 'bindings.usrcmds.case.linkcheck'
--- Checks whether docs.tricentis.com links referenced by cases still
--- resolve (ROADMAP.md v7). Scoped to that one host on purpose: it's the
--- internal docs site whose pages actually get moved/retired — a generic
--- checker over every URL a case happens to mention would mostly report
--- noise (SNOW tickets, support-hub links, screenshots hosted elsewhere).

local curl = require("lib.nvim.net.curl")
local registry = require("bindings.usrcmds.case.registry")
local meta = require("bindings.usrcmds.case.meta")
local detect = require("bindings.usrcmds.case.detect")

local M = {}

local HOST_PATTERN = "^https?://docs%.tricentis%.com/"
local MAX_CONCURRENT = 4
local TIMEOUT_MS = 5000

---@class Lib.Case.LinkCheckTarget
---@field short string
---@field url string

---@class Lib.Case.LinkCheckResult
---@field short string
---@field url string
---@field status "alive"|"dead"|"uncertain"
---@field detail string

---@param short string
---@param dir string
---@return Lib.Case.LinkCheckTarget[]
local function tricentis_links(short, dir)
  local m = meta.read(dir)
  local links = (m and m.links and #m.links > 0) and m.links or detect.links(dir)
  local out = {}
  for _, url in ipairs(links) do
    if url:match(HOST_PATTERN) then
      out[#out + 1] = { short = short, url = url }
    end
  end
  return out
end

--- Every docs.tricentis.com link across every case (or just `only_short`).
---@param only_short string|nil
---@return Lib.Case.LinkCheckTarget[]
function M.targets(only_short)
  local out = {}
  for _, e in ipairs(registry.list()) do
    if not only_short or e.short == only_short then
      vim.list_extend(out, tricentis_links(e.short, e.dir))
    end
  end
  return out
end

--- Classify one curl response. curl's own exit code says nothing about the
--- HTTP status (0 means "the request completed", not "the page exists"), so
--- everything here reads `resp.status`. 405 (HEAD not allowed) and
--- 401/403 (behind auth) are NOT "dead" — the page is there, just not
--- answering the way we asked or not visible to an anonymous request.
---@param ok boolean
---@param resp Lib.Net.Curl.RawResponse|string
---@return "alive"|"dead"|"uncertain" status
---@return string detail
local function classify(ok, resp)
  if not ok then
    return "dead", "unreachable: " .. tostring(resp)
  end
  ---@cast resp Lib.Net.Curl.RawResponse
  local status = resp.status
  if status == 405 then
    return "alive", "HTTP 405 (HEAD not allowed, assumed reachable)"
  end
  if status == 401 or status == 403 then
    return "uncertain", ("HTTP %d (may require auth)"):format(status)
  end
  if status < 400 then
    return "alive", ("HTTP %d"):format(status)
  end
  return "dead", ("HTTP %d"):format(status)
end

--- Check `targets` with bounded concurrency, one HEAD request each. Async:
--- `on_done` fires once with every result, in target order, once every
--- request has settled (success, HTTP error, or network failure alike).
---@param targets Lib.Case.LinkCheckTarget[]
---@param on_done fun(results: Lib.Case.LinkCheckResult[])
function M.run(targets, on_done)
  if #targets == 0 then
    on_done({})
    return
  end

  local results = {}
  local next_i = 1
  local done = 0

  local function launch_next()
    if next_i > #targets then
      return
    end
    local i = next_i
    next_i = next_i + 1
    local t = targets[i]
    curl.fetch_raw(t.url, { method = "HEAD", timeout_ms = TIMEOUT_MS }, function(ok, resp)
      local status, detail = classify(ok, resp)
      results[i] = { short = t.short, url = t.url, status = status, detail = detail }
      done = done + 1
      if done == #targets then
        on_done(results)
      else
        launch_next()
      end
    end)
  end

  for _ = 1, math.min(MAX_CONCURRENT, #targets) do
    launch_next()
  end
end

--- Convenience: `M.targets` + `M.run` in one call.
---@param only_short string|nil
---@param on_done fun(results: Lib.Case.LinkCheckResult[])
function M.check(only_short, on_done)
  M.run(M.targets(only_short), on_done)
end

return M
