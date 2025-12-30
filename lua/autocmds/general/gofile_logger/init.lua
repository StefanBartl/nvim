---@module 'autocmds.general.gofile_logger'
--- Central logger for markdown gofile dispatcher.
--- This module provides a small logger API that respects cfg.goto_file.debug.
--- AUDIT: lib.notify anstatt diuesen logger ???
local notify = require("lib.notify").create("[autocmds.general.gofile_logger]")

--- Create a logger bound to a specific config.
--- Returns a table with methods: info, debug, warn, error.
--- @param cfg table
--- @return table
return function(cfg)
  -- Decide whether debug-level notifications are enabled.
  local debug_enabled = cfg and cfg.goto_file and cfg.goto_file.debug
  debug_enabled = false -- AUDIT: warum wird geloggt wenn man in defaults und init false hat und hier exrta false setzen muss?

  local function notify_with_level(prefix, level, msg, ctx)
    -- Compose message and safely serialize context (avoid heavy inspect in non-debug).
    local out = ("[md-gf][%s] %s"):format(prefix, msg or "")
    if ctx then
      -- Use pcall to prevent inspect from erroring on exotic tables.
      local ok, s = pcall(vim.inspect, ctx)
      if ok and s and s ~= "" then
        out = out .. " | " .. s
      end
    end

    if level == vim.log.levels.info then
      notify.info(out)
    elseif level == vim.log.levels.debug then
      notify.debug(out)
    elseif level == vim.log.levels.warn then
      notify.warn(out)
    else
      notify.error(out)
    end
  end

  return {
    info = function(msg, ctx)
      notify_with_level("INFO", vim.log.levels.INFO, msg, ctx)
    end,
    debug = function(msg, ctx)
      if debug_enabled then
        notify_with_level("DEBUG", vim.log.levels.DEBUG, msg, ctx)
      end
    end,
    warn = function(msg, ctx)
      notify_with_level("WARN", vim.log.levels.WARN, msg, ctx)
    end,
    error = function(msg, ctx)
      notify_with_level("ERROR", vim.log.levels.ERROR, msg, ctx)
    end,
  }
end
