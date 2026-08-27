---@module 'startup'
--- Startup phase runner with built-in measurement.
---
--- Replaces the previous `vim.defer_fn(..., 10|50)` scheme. Wall-clock timers
--- were never a real policy: `defer_fn` cannot run before the event loop goes
--- idle, which on this config happens ~2s AFTER VimEnter. Modules that register
--- VimEnter/BufReadPost handlers were therefore loaded after the very events
--- they listen for, and their handlers never fired.
---
--- Phases are attached to events, and every phase is recorded so the policy can
--- be checked instead of assumed. See docs/ARCHITECTURE/startup.md.
---
--- Usage:
---   local startup = require("startup")
---   startup.now("options", function() require("options") end)
---   startup.on("UIReady", "mappings", function() require("bindings.mappings").setup() end)
---   :StartupReport   -- themed float, see startup.report
---   :StartupCheck    -- policy violations only, exit-code friendly

local M = {}

--- Synthetic trigger: VimEnter has fired and the following paint is not blocked.
M.UI_READY = "UIReady"

---@class Startup.Mark
---@field label string
---@field trigger string      # "sync" or the event name it waited for
---@field at number|nil       # ms since vim.g.start_time, nil while pending
---@field dur number|nil      # ms spent inside the phase body
---@field err string|nil      # error message if the phase body threw

---@type Startup.Mark[]
M.marks = {}

--- Milliseconds since the interpreter started (vim.g.start_time set in init.lua).
---@return number
function M.elapsed()
  local t0 = vim.g.start_time
  if not t0 then
    return 0
  end
  return (vim.uv.hrtime() - t0) / 1e6
end

--- Run a phase body, recording timing and any error.
--- Errors are captured rather than propagated: one broken phase must not abort
--- the phases queued behind it.
---@param mark Startup.Mark
---@param fn fun()
local function run(mark, fn)
  mark.at = M.elapsed()
  local t0 = vim.uv.hrtime()
  local ok, err = pcall(fn)
  mark.dur = (vim.uv.hrtime() - t0) / 1e6
  if not ok then
    mark.err = tostring(err)
    vim.schedule(function()
      require("lib.nvim.notify").create("[startup] ").error(
        string.format("phase '%s' failed: %s", mark.label, mark.err)
      )
    end)
  end
end

--- Run a phase synchronously, right now.
--- Use for anything that must be in place before the first paint or before an
--- event that fires during startup (VimEnter, the first BufReadPost).
---@param label string
---@param fn fun()
function M.now(label, fn)
  local mark = { label = label, trigger = "sync" }
  M.marks[#M.marks + 1] = mark
  run(mark, fn)
end

--- Defer a phase until an event fires.
---
--- `event` is a real autocmd event ("BufReadPost", "FileType", "CmdlineEnter")
--- or the synthetic "UIReady".
---
--- "UIReady" means: VimEnter has fired and the paint that follows it is not
--- blocked — implemented as VimEnter + vim.schedule. It deliberately does NOT
--- use lazy.nvim's `User VeryLazy`: lazy only emits that event when some plugin
--- spec subscribes to it, and it was measured not firing at all in headless
--- runs. Core config phases must not depend on a plugin manager's bookkeeping,
--- so we derive the same timing from an event Neovim always fires.
---
--- If the event has already fired by the time this is called, the phase stays
--- visible as "PENDING" in :StartupReport — that is the policy violation the
--- old timer scheme hid. ("UIReady" handles the already-fired case explicitly,
--- since it is legitimate to register it late, e.g. on config reload.)
---@param event string
---@param label string
---@param fn fun()
function M.on(event, label, fn)
  local mark = { label = label, trigger = event }
  M.marks[#M.marks + 1] = mark

  if event == M.UI_READY then
    if vim.v.vim_did_enter == 1 then
      vim.schedule(function() run(mark, fn) end)
    else
      require("lib.nvim.bindings.autocmd").create("VimEnter", function()
        vim.schedule(function() run(mark, fn) end)
      end, { once = true })
    end
    return
  end

  require("lib.nvim.bindings.autocmd").create(event, function() run(mark, fn) end, { once = true })
end

--- Phases that never ran: their event has not fired, or had already fired when
--- the phase registered. Both are bugs — see docs/ARCHITECTURE/startup.md.
---@return Startup.Mark[]
function M.pending()
  return vim.tbl_filter(function(m) return m.at == nil end, M.marks)
end

--- Phases whose body threw.
---@return Startup.Mark[]
function M.failed()
  return vim.tbl_filter(function(m) return m.err ~= nil end, M.marks)
end

--- Total time spent inside phase bodies (not wall-clock startup time — the bulk
--- of startup happens in lazy.setup() before the first phase runs).
---@return number
function M.total()
  local sum = 0
  for _, m in ipairs(M.marks) do
    sum = sum + (m.dur or 0)
  end
  return sum
end

--- Marks sorted by duration, slowest first.
---@return Startup.Mark[]
function M.slowest()
  local sorted = vim.deepcopy(M.marks)
  table.sort(sorted, function(a, b) return (a.dur or 0) > (b.dur or 0) end)
  return sorted
end

--- Register :StartupReport and :StartupCheck.
function M.setup_usercmds()
  local usercmd = require("lib.nvim.bindings.usercmd")

  usercmd.create("StartupReport", function()
    require("startup.report").open()
  end, { desc = "Startup: phase timeline (themed float)" })

  usercmd.create("StartupCheck", function()
    require("startup.report").check()
  end, { desc = "Startup: report policy violations only" })
end

return M
