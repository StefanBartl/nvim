---@module 'startup.report'
--- Presentation layer for the startup phase timeline.
---
--- Kept separate from `startup` itself so the runner stays loadable during the
--- earliest phase without dragging the UI kit onto the synchronous path — the
--- report is only ever built on demand, from :StartupReport.
---
--- Rendering goes through `lib.nvim.ui.kit` (themed, focusable, q/<Esc>-closable
--- surface) rather than a hand-rolled nvim_open_win, and highlight groups link
--- to standard ones so the report follows whatever colorscheme is active.

local startup = require("startup")

local M = {}

local NS = "startup_report"

--- Highlight groups, defined once and linked to standard groups so the report
--- inherits the active colorscheme instead of hardcoding colors.
local function define_hl()
  local hl = require("lib.nvim.ui.hl")
  hl.set("StartupHeader", { link = "Title" })
  hl.set("StartupLabel", { link = "Function" })
  hl.set("StartupSync", { link = "Constant" })
  hl.set("StartupEvent", { link = "Identifier" })
  hl.set("StartupBar", { link = "DiagnosticInfo" })
  hl.set("StartupSlow", { link = "DiagnosticWarn" })
  hl.set("StartupPending", { link = "DiagnosticError" })
  hl.set("StartupMuted", { link = "Comment" })
end

--- Duration bar. Widths are relative to the slowest phase, so the bar answers
--- "which phase dominates" rather than implying an absolute budget.
---@param dur number
---@param max number
---@return string
local function bar(dur, max)
  local width = 18
  if max <= 0 then
    return string.rep("·", width)
  end
  local filled = math.floor((dur / max) * width + 0.5)
  return string.rep("█", filled) .. string.rep("·", width - filled)
end

--- A phase counts as slow when it owns a meaningful share of total phase time.
--- Relative, not a fixed millisecond threshold: absolute timings swing wildly
--- between cold and warm runs on this config.
local SLOW_SHARE = 0.25

---@class Startup.Report.Line
---@field text string
---@field hl string|nil

--- How many stalls the event-loop section lists by name (longest first).
local STALLS_LISTED = 5

--- The event-loop section: stalls and busy time per second from
--- `startup.heartbeat`. Pure: takes the stats and the recording state, so the
--- rendering is testable from synthetic samples.
---@param stats Startup.Heartbeat.Stats
---@param state Startup.Heartbeat.State
---@return Startup.Report.Line[]
function M.heartbeat_lines(stats, state)
  local hb = require("startup.heartbeat")
  ---@type Startup.Report.Line[]
  local out = {}
  local function add(text, hl)
    out[#out + 1] = { text = text, hl = hl }
  end

  if not state.started then
    add(
      "  Event loop: not recorded (vim.g.startup_heartbeat = false, or start() not called).",
      "StartupMuted"
    )
    add("  Stalls with their owners: scripts/startup-probe (PROBE=stall,where)", "StartupMuted")
    return out
  end
  if not stats.first then
    add("  Event loop: no heartbeat yet — the loop has not run since start().", "StartupMuted")
    return out
  end

  add(
    ("  Event loop, %.0f s from the first heartbeat at %.0f ms%s"):format(
      state.window / 1000,
      stats.first,
      state.running and "  (still recording)" or ""
    ),
    "StartupHeader"
  )

  local n = #stats.stalls
  add(
    ("  %-20s %d, %.0f ms blocked, longest %.0f ms"):format(
      ("stalls > %d ms"):format(hb.STALL),
      n,
      stats.stall_sum,
      stats.stall_max
    ),
    n > 0 and "StartupSlow" or "StartupLabel"
  )
  local sorted = vim.list_slice(stats.stalls)
  table.sort(sorted, function(a, b)
    return a.gap > b.gap
  end)
  for i = 1, math.min(#sorted, STALLS_LISTED) do
    add(("  %20s %6.0f ms  at %7.0f ms"):format("", sorted[i].gap, sorted[i].at), "StartupSlow")
  end
  if n > STALLS_LISTED then
    add(("  %20s … %d more"):format("", n - STALLS_LISTED), "StartupMuted")
  end

  local secs = vim.tbl_map(function(ms)
    return ("%.0f"):format(ms)
  end, stats.busy)
  add(
    ("  %-20s %s ms  (total %.0f ms)"):format(
      "busy per second",
      table.concat(secs, " · "),
      stats.busy_total
    ),
    "StartupLabel"
  )
  add(
    "  In-process view of this session. Owners of a stall: scripts/startup-probe (PROBE=stall,where).",
    "StartupMuted"
  )
  return out
end

--- Build the report as annotated lines.
---@return Startup.Report.Line[]
function M.lines()
  local marks = startup.marks
  local total = startup.total()
  local pending = startup.pending()
  local failed = startup.failed()

  local max_dur = 0
  for _, m in ipairs(marks) do
    max_dur = math.max(max_dur, m.dur or 0)
  end

  ---@type Startup.Report.Line[]
  local out = {}
  local function add(text, hl)
    out[#out + 1] = { text = text, hl = hl }
  end

  -- Host context, cross-platform via lib.nvim (which delegates to
  -- lib.nvim.cross.platform, so WSL is not misreported as Linux).
  local env = require("lib.nvim.system.env").get()
  local host = env.is_windows and "Windows"
    or env.is_wsl and "WSL"
    or env.is_macos and "macOS"
    or "Linux"

  add(
    ("%s  ·  nvim %s  ·  %.0f ms since start"):format(
      host,
      tostring(vim.version()),
      startup.elapsed()
    ),
    "StartupMuted"
  )
  add("")

  for _, m in ipairs(marks) do
    if m.at then
      local dur = m.dur or 0
      local slow = total > 0 and (dur / total) >= SLOW_SHARE
      add(
        ("  %-20s %-10s %8.1f ms  %s %7.1f ms%s"):format(
          m.label,
          "[" .. m.trigger .. "]",
          m.at,
          bar(dur, max_dur),
          dur,
          m.err and "  ERROR" or ""
        ),
        m.err and "StartupPending" or slow and "StartupSlow" or "StartupLabel"
      )
    else
      add(
        ("  %-20s %-10s PENDING — never ran"):format(m.label, "[" .. m.trigger .. "]"),
        "StartupPending"
      )
    end
    if m.err then
      add("      " .. m.err:gsub("\n", " "), "StartupPending")
    end
  end

  add("")
  add(("  %-20s %31.1f ms in phase bodies"):format("TOTAL", total), "StartupHeader")

  if #pending > 0 or #failed > 0 then
    add("")
    for _, m in ipairs(pending) do
      add(
        ("  ! '%s' registered for '%s', which never fired — the phase does not run."):format(
          m.label,
          m.trigger
        ),
        "StartupPending"
      )
    end
    for _, m in ipairs(failed) do
      add(("  ! '%s' threw; phases after it still ran."):format(m.label), "StartupPending")
    end
    add("  See docs/NOTES/ARCHITECTURE/startup.md", "StartupMuted")
  end

  add("")
  add("  Phase bodies are only part of startup — the bulk is lazy.setup().", "StartupMuted")

  add("")
  local stats, hb_state = require("startup.heartbeat").snapshot()
  vim.list_extend(out, M.heartbeat_lines(stats, hb_state))

  return out
end

--- Plain string lines, for headless use and :StartupCheck.
---@return string[]
function M.text_lines()
  return vim.tbl_map(function(l)
    return l.text
  end, M.lines())
end

--- Open the report as a themed float.
---@return Lib.UI.Kit.Surface|nil
function M.open()
  define_hl()

  local lines = M.lines()
  local kit = require("lib.nvim.ui.kit")

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l.text))
  end

  local surf = kit.surface.open({
    lines = vim.tbl_map(function(l)
      return l.text
    end, lines),
    title = " Startup phases ",
    width = math.min(width + 2, vim.o.columns - 4),
    height = math.min(#lines, math.floor(vim.o.lines * 0.8)),
    relative = "editor",
    enter = true, -- the report is meant to be scrolled
    nice_quit = true, -- q / <Esc>
    filetype = "startup-report",
  })

  if not surf then
    -- Kit unavailable (e.g. lib.nvim not on the rtp yet) — the report still has
    -- to be readable, so fall back rather than failing.
    vim.notify(table.concat(M.text_lines(), "\n"), vim.log.levels.INFO)
    return nil
  end

  local ns = require("lib.nvim.ui.hl").namespace(NS)
  for i, l in ipairs(lines) do
    if l.hl then
      vim.api.nvim_buf_set_extmark(surf.bufnr, ns, i - 1, 0, {
        end_row = i - 1,
        end_col = #l.text,
        hl_group = l.hl,
      })
    end
  end

  return surf
end

--- Report policy violations only. Silent when the policy holds, so it is usable
--- as a check rather than something to read.
---@return boolean ok
function M.check()
  local notify = require("lib.nvim.notify").create("[startup] ")
  local pending, failed = startup.pending(), startup.failed()

  if #pending == 0 and #failed == 0 then
    notify.info(
      ("Startup policy OK — %d phases, %.0f ms in bodies."):format(
        #startup.marks,
        startup.total()
      )
    )
    return true
  end

  local msgs = {}
  for _, m in ipairs(pending) do
    msgs[#msgs + 1] = ("'%s' never ran: '%s' did not fire."):format(m.label, m.trigger)
  end
  for _, m in ipairs(failed) do
    msgs[#msgs + 1] = ("'%s' threw: %s"):format(m.label, m.err)
  end
  notify.error(table.concat(msgs, "\n"))
  return false
end

return M
