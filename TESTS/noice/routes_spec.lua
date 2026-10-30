-- TESTS/noice/routes_spec.lua -- noice's router stops at the first matching route, so the generic
-- `event = "notify"` -> mini route must not sit in front of the notify skip rules, and no route
-- (skip or view) may match the cmdline itself (noice routes it through the same router) unless it
-- names "cmdline" on purpose and says why in `cmdline_reason`.

return function(H)
  local eq = H.eq
  local routes = require("config.noice").routes

  -- Minimal model of noice's filter: event / kind equality, `find` as a Lua pattern, `any`
  -- as an OR of sub-filters. Only these keys are modelled; any other key (`not`, `cond`,
  -- `min_height`, ...) errors so the model can never silently disagree with noice -- extend
  -- it when a route needs one.
  local modelled = { event = true, kind = true, find = true, any = true }
  local matches
  function matches(filter, msg)
    for k in pairs(filter) do
      if not modelled[k] then
        error("routes_spec model does not support filter key '" .. k .. "'")
      end
    end
    if filter.event then
      -- noice accepts a single event or a list of events.
      local events = type(filter.event) == "table" and filter.event or { filter.event }
      if not vim.tbl_contains(events, msg.event) then
        return false
      end
    end
    if filter.kind and filter.kind ~= msg.kind then
      return false
    end
    if filter.find and not msg.text:find(filter.find) then
      return false
    end
    if filter.any then
      local hit = false
      for _, sub in ipairs(filter.any) do
        if matches(sub, msg) then
          hit = true
          break
        end
      end
      if not hit then
        return false
      end
    end
    return true
  end

  -- First match wins (opts.stop defaults to true); returns "skip", the view name or nil.
  -- A route without a view is a skip route too: noice's Router.add sets `opts.skip` when
  -- `view` is nil (e.g. an opts-only `{ skip_empty = true }` route).
  local function route(msg)
    for _, r in ipairs(routes) do
      if matches(r.filter, msg) then
        if (r.opts and r.opts.skip) or r.view == nil then
          return "skip"
        end
        return r.view
      end
    end
  end

  eq(
    route({ event = "notify", kind = "warn", text = "Buffer is not modifiable" }),
    "skip",
    "'Buffer is not modifiable' notify is skipped"
  )
  eq(
    route({ event = "notify", kind = "info", text = "No signature help" }),
    "skip",
    "'No signature help' notify is skipped"
  )
  eq(
    route({ event = "notify", kind = "info", text = "hello" }),
    "mini",
    "other notifications still go to mini"
  )
  eq(
    route({ event = "msg_show", kind = "", text = "file written" }),
    "mini",
    "an `any` route is modelled (msg_show 'written' -> mini)"
  )

  -- The BufReadPost text is still skipped as a message and as a notify ...
  local bufread = "Error detected while processing BufReadPost Autocommands for x"
  eq(
    route({ event = "msg_show", kind = "emsg", text = bufread }),
    "skip",
    "BufReadPost emsg is skipped"
  )
  eq(
    route({ event = "notify", kind = "error", text = bufread }),
    "skip",
    "BufReadPost notify is skipped"
  )
  eq(
    route({ event = "msg_show", kind = "", text = "No signature help" }),
    "skip",
    "'No signature help' message is skipped"
  )

  -- ... but noice routes the command line itself through the same router: a skip
  -- route without an event matched the line being typed and hid the cmdline
  -- (`:lua vim.notify('... Autocommands for x')` vanished at "for").
  eq(
    route({
      event = "cmdline",
      kind = "",
      text = "lua vim.notify('" .. bufread .. "', vim.log.levels.ERROR)",
    }),
    nil,
    "a cmdline containing the BufReadPost text is not skipped"
  )
  eq(
    route({ event = "cmdline", kind = "", text = "echo 'No signature help'" }),
    nil,
    "a cmdline containing 'No signature help' is not skipped"
  )
  -- Every route -- skip AND view -- must name its event: an event-less filter also
  -- matches the cmdline (event "cmdline") and would hide it (skip) or move it into
  -- another view. A route that targets "cmdline" on purpose must say why in a
  -- top-level `cmdline_reason` string (noice's Router.add only reads filter/opts/view,
  -- so the extra key is inert).
  -- Returns nil when the route is fine, else a short reason.
  local function event_problem(r)
    local ev = r.filter and r.filter.event
    if ev == nil or (type(ev) == "table" and #ev == 0) then
      return "names no event (it also matches the cmdline)"
    end
    local events = type(ev) == "table" and ev or { ev }
    if vim.tbl_contains(events, "cmdline") then
      if type(r.cmdline_reason) ~= "string" or vim.trim(r.cmdline_reason) == "" then
        return "touches event 'cmdline' without a `cmdline_reason`"
      end
    end
    return nil
  end

  -- The checker itself: it must flag what the task is about.
  eq(
    event_problem({ filter = { find = "x" }, view = "mini" }) ~= nil,
    true,
    "checker flags an event-less view route"
  )
  eq(
    event_problem({ filter = { find = "x" }, opts = { skip = true } }) ~= nil,
    true,
    "checker flags an event-less skip route"
  )
  eq(
    event_problem({ filter = { event = {}, find = "x" }, view = "mini" }) ~= nil,
    true,
    "checker flags an empty event list"
  )
  eq(
    event_problem({ filter = { event = { "msg_show", "cmdline" } }, view = "mini" }) ~= nil,
    true,
    "checker flags a cmdline route without a reason"
  )
  eq(
    event_problem({
      filter = { event = "cmdline" },
      view = "mini",
      cmdline_reason = "deliberate",
    }),
    nil,
    "checker accepts a cmdline route with a reason"
  )
  eq(
    event_problem({ filter = { event = { "msg_show", "notify" } }, view = "mini" }),
    nil,
    "checker accepts an event list without cmdline"
  )

  for i, r in ipairs(routes) do
    eq(event_problem(r), nil, "route #" .. i .. " names its event (else it can catch the cmdline)")
  end

  -- noice appends the routes of every enabled preset right behind these and in front of
  -- its own `event = "cmdline"` route, so they see the cmdline as well. Checked against
  -- noice's own preset table when lazy.nvim has it, merged the way preset.load() does.
  local noice_dir = vim.fn.stdpath("data") .. "/lazy/noice.nvim"
  if vim.fn.isdirectory(noice_dir) == 1 then
    vim.opt.rtp:append(noice_dir)
    local loaded, presets = pcall(function()
      return require("noice.config.preset").presets
    end)
    vim.opt.rtp:remove(noice_dir)
    for name in pairs(package.loaded) do
      if name == "noice" or name:sub(1, 6) == "noice." then
        package.loaded[name] = nil
      end
    end
    eq(loaded and type(presets), "table", "noice's preset table loads: " .. tostring(presets))

    for name, p in pairs(require("config.noice").presets or {}) do
      if p ~= false then
        local preset =
          vim.tbl_deep_extend("force", {}, presets[name] or {}, type(p) == "table" and p or {})
        if preset.enabled ~= false then
          for i, r in ipairs(preset.routes or {}) do
            local what = ("preset %s route #%d"):format(name, i)
            eq(event_problem(r), nil, what .. " names its event (else it can catch the cmdline)")
          end
        end
      end
    end
  end
end
