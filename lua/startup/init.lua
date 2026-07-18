---@module 'startup'
--- Startup phase runner with built-in measurement.
---
--- Replaces the previous `vim.defer_fn(..., 10|50)` scheme. Wall-clock timers
--- were never a real policy: `defer_fn` cannot run before the event loop goes
--- idle, which on this config happens ~4.3s in — long after VimEnter (~2.1s).
--- Modules that register VimEnter/BufReadPost handlers were therefore loaded
--- after the very events they listen for, and their handlers never fired.
---
--- Phases are now attached to events, and every phase is recorded so the policy
--- can be checked instead of assumed. See docs/ARCHITECTURE/startup.md.
---
--- Usage:
---   local startup = require("startup")
---   startup.now("options", function() require("options") end)
---   startup.on("VeryLazy", "mappings", function() require("bindings.mappings").setup() end)
---   :StartupReport

local M = {}

---@class StartupMark
---@field label string
---@field trigger string      -- "sync" or the event name it waited for
---@field at number|nil       -- ms since vim.g.start_time, nil while pending
---@field dur number|nil      -- ms spent inside the phase body
---@field err string|nil      -- error message if the phase body threw

---@type StartupMark[]
M.marks = {}

--- Milliseconds since the interpreter started (vim.g.start_time set in init.lua).
---@return number
local function elapsed()
  local t0 = vim.g.start_time
  if not t0 then
    return 0
  end
  return (vim.uv.hrtime() - t0) / 1e6
end

--- Run a phase body, recording timing and any error.
--- Errors are captured rather than propagated: one broken phase must not abort
--- the phases queued behind it.
---@param mark StartupMark
---@param fn fun()
local function run(mark, fn)
  mark.at = elapsed()
  local t0 = vim.uv.hrtime()
  local ok, err = pcall(fn)
  mark.dur = (vim.uv.hrtime() - t0) / 1e6
  if not ok then
    mark.err = tostring(err)
    vim.schedule(function()
      vim.notify(string.format("[startup] phase '%s' failed: %s", mark.label, mark.err), vim.log.levels.ERROR)
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

  if event == "UIReady" then
    if vim.v.vim_did_enter == 1 then
      vim.schedule(function() run(mark, fn) end)
    else
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function() vim.schedule(function() run(mark, fn) end) end,
      })
    end
    return
  end

  vim.api.nvim_create_autocmd(event, { once = true, callback = function() run(mark, fn) end })
end

--- Render the phase timeline as report lines.
---@return string[]
function M.report_lines()
  local lines = { string.format("Startup phases (%.0f ms since start)", elapsed()), string.rep("─", 62) }
  local total = 0

  for _, m in ipairs(M.marks) do
    if m.at then
      total = total + (m.dur or 0)
      lines[#lines + 1] = string.format(
        "%-22s %-12s ran %8.1f ms  took %7.1f ms%s",
        m.label,
        "[" .. m.trigger .. "]",
        m.at,
        m.dur or 0,
        m.err and "  ERROR" or ""
      )
    else
      lines[#lines + 1] = string.format(
        "%-22s %-12s PENDING — '%s' has not fired (or fired before registration)",
        m.label,
        "[" .. m.trigger .. "]",
        m.trigger
      )
    end
    if m.err then
      lines[#lines + 1] = "    " .. m.err
    end
  end

  lines[#lines + 1] = string.rep("─", 62)
  lines[#lines + 1] = string.format("%-22s %31.1f ms in phase bodies", "TOTAL", total)
  return lines
end

--- Register :StartupReport.
function M.setup_usercmd()
  pcall(vim.api.nvim_create_user_command, "StartupReport", function()
    vim.notify(table.concat(M.report_lines(), "\n"), vim.log.levels.INFO)
  end, { desc = "Startup: show phase timeline and pending phases" })
end

return M
