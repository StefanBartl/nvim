---@module 'autocmds.markdown.gofile_logger'
--- Central logger for markdown gofile dispatcher.
--- This module provides a small logger API that respects cfg.goto_file.debug.

--- Create a logger bound to a specific config.
--- Returns a table with methods: info, debug, warn, error.
--- @param cfg table
--- @return table
return function (cfg)
  -- Decide whether debug-level notifications are enabled.
  local debug_enabled = cfg and cfg.goto_file and cfg.goto_file.debug

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
    vim.notify(out, level, { title = "md-gf" })
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
