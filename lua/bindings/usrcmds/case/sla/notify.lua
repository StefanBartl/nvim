---@module 'bindings.usrcmds.case.sla.notify'
--- SLA.md §6C Paket 4: active push notifications for `config.sla_active_
--- priorities`, on top of the passive statusline badge (`ui/statusline/
--- modules/casedesk/init.lua`) — a badge only helps while you're actually
--- looking at the right buffer; this fires even when you're elsewhere.
---
--- "One warning per threshold, never repeated" (SLA.md §6C/§8's alarm-
--- fatigue rule) is tracked by a flat `warned` set keyed on
--- `short|label|deadline`, not just `short|label` — a clock's `deadline`
--- changes whenever it resets to a fresh period (the cadence clock does
--- exactly this on a customer reply, SLA.md §3's Nachtrag), so a new
--- period naturally gets its own key and can warn again, without any
--- explicit "clear the old warning" step. The set only ever grows within a
--- session — at casedesk's current scale (~20 cases, CONCEPT.md §6) that's
--- nowhere near worth pruning, same call SLA.md §6 already makes for
--- session invalidation.

local config = require("bindings.usrcmds.case.config")
local registry = require("bindings.usrcmds.case.registry")
local notify = require("lib.nvim.notify").create("[usrcmds.case.sla]")

local M = {}

---@type table<string, true>
local warned = {}

local timer = nil ---@type uv.uv_timer_t|nil

---@param entry Lib.Case.RegistryEntry
---@param status Lib.Case.SlaStatus
---@param label string
---@param c Lib.Case.SlaClockStatus
local function maybe_warn(entry, status, label, c)
  local sla = require("bindings.usrcmds.case.sla")
  if not sla.under_threshold(c, config.sla_warn_at) then
    return
  end
  local key = ("%s|%s|%d"):format(entry.short, label, c.deadline)
  if warned[key] then
    return
  end
  warned[key] = true

  local m = require("bindings.usrcmds.case.meta").read(entry.dir)
  local title = (m and m.title and m.title ~= "") and (" " .. m.title) or ""
  local urgency = c.remaining < 0 and "overdue" or "warning"
  notify.warn(
    ("SLA %s: %s P%s%s — %s %s"):format(urgency, entry.short, status.digit, title, label, sla.format_duration(c.remaining))
  )
end

--- Check every open, active-priority case's clocks against the warn
--- threshold, notifying (at most once per breach) for whichever ones cross
--- it. Safe to call as often as needed — the `warned` set makes repeat
--- calls a no-op for anything already flagged.
function M.check()
  if not config.sla_notifications_enabled then
    return
  end
  local sla = require("bindings.usrcmds.case.sla")

  local active = {}
  for _, p in ipairs(config.sla_active_priorities) do
    active[p] = true
  end

  for _, e in ipairs(registry.list()) do
    if e.state == config.default_state then
      local ok_status, status = pcall(sla.status, e)
      if ok_status and status and active[status.digit] then
        for _, c in ipairs(status.first_response) do
          maybe_warn(e, status, c.label, c)
        end
        if status.cadence then
          maybe_warn(e, status, status.cadence.label, status.cadence)
        end
        if status.fix then
          maybe_warn(e, status, status.fix.label, status.fix)
        end
      end
    end
  end
end

--- Start the background timer + `FocusGained` check. Idempotent — a second
--- call is a no-op rather than leaking a second timer, since `init.lua`'s
--- `M.enable()` (the only caller) could in principle run more than once in
--- a session (e.g. a config reload).
function M.setup()
  if not config.sla_notifications_enabled then
    return
  end
  if timer then
    return
  end

  local uv = vim.uv or vim.loop
  timer = uv.new_timer()
  if not timer then
    return
  end
  local interval_ms = config.sla_notify_interval_seconds * 1000
  timer:start(
    interval_ms,
    interval_ms,
    vim.schedule_wrap(function()
      local ok, err = pcall(M.check)
      if not ok then
        notify.debug("check failed: " .. tostring(err))
      end
    end)
  )

  local autocmd = require("lib.nvim.bindings.autocmd")
  autocmd.create("FocusGained", function()
    pcall(M.check)
  end, {
    group = autocmd.group("CasedeskSlaNotify", true),
    desc = "casedesk: re-check SLA clocks on FocusGained (SLA.md §6C)",
  })
end

return M
