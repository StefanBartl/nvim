-- TESTS/noice/routes_spec.lua -- noice's router stops at the first matching route, so the generic
-- `event = "notify"` -> mini route must not sit in front of the notify skip rules.

return function(H)
  local eq = H.eq
  local routes = require("config.noice").routes

  -- Minimal model of noice's filter: event / kind equality, `find` as a Lua pattern.
  -- Only these keys are modelled; any other key (`any`, `not`, `cond`, ...) errors so the
  -- model can never silently disagree with noice -- extend it when a route needs one.
  local modelled = { event = true, kind = true, find = true, any = true }
  local matches
  function matches(filter, msg)
    for k in pairs(filter) do
      if not modelled[k] then
        error("routes_spec model does not support filter key '" .. k .. "'")
      end
    end
    if filter.event and filter.event ~= msg.event then
      return false
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
  local function route(msg)
    for _, r in ipairs(routes) do
      if matches(r.filter, msg) then
        if r.opts and r.opts.skip then
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
end
