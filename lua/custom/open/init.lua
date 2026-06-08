---@module 'custom.open'
---@brief Entry point for the :Open user command.
---@description
--- Registers the :Open [target] user command with tab-completion over the
--- registered handler names.  Resolution order for the target path is
--- documented in custom.open.context.

local M = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Dispatch to the appropriate handler.
---@param target string  Handler key, e.g. "filemanager", "browser", "notepad".
---@param ctx    Open.Context
---@return nil
local function dispatch(target, ctx)
  local ok_reg, registry = pcall(require, "custom.open.registry")
  if not ok_reg then
    require("lib.notify").create("[custom.open]").error("Registry not available")
    return
  end

  local handler = registry.get(target)
  if not handler then
    require("lib.notify").create("[custom.open]").error(
      string.format("Unknown target: '%s'  (available: %s)",
        target, table.concat(registry.list(), ", "))
    )
    return
  end

  local ok, err = pcall(handler.open, ctx)
  if not ok then
    require("lib.notify").create("[custom.open]").error(
      string.format("Handler '%s' failed: %s", target, tostring(err))
    )
  end
end

--- Default handler when no target argument is given.
--- Uses "filemanager" when coming from a tree buffer, "browser" otherwise.
---@param ctx Open.Context
---@return string target
local function default_target(ctx)
  if ctx.source == "tree" then
    return "filemanager"
  end
  -- Heuristic: looks like a URL → browser; otherwise filemanager.
  local p = ctx.path or ""
  if p:match("^https?://") or p:match("^ftp://") then
    return "browser"
  end
  return "filemanager"
end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

--- Register all handlers and create the :Open user command.
---@return nil
function M.setup()
  -- Register handlers (order does not matter).
  local ok_reg, registry = pcall(require, "custom.open.registry")
  if not ok_reg then
    return
  end

  -- Handlers are registered by their own modules; just ensure they are loaded.
  local handler_modules = {
    "custom.open.filemanager",
    "custom.open.browser",
    "custom.open.notepad",
  }
  for i = 1, #handler_modules do
    pcall(require, handler_modules[i])
  end

  -- -------------------------------------------------------------------------
  -- :Open [target]
  --
  -- Tab-completion enumerates the registered handler names so the user can
  -- press <Tab> after :Open to cycle through "filemanager", "browser", etc.
  -- -------------------------------------------------------------------------
  vim.api.nvim_create_user_command("Open", function(opts)
    local ctx = require("custom.open.context").resolve(nil)
    if not ctx then
      require("lib.notify").create("[custom.open]").warn("Nothing to open")
      return
    end

    -- The first fargs entry is treated as the target/handler name.
    -- Additional fargs (if any) could be a path override – kept for future use.
    local target = (opts.fargs and opts.fargs[1]) or default_target(ctx)
    target = target:lower()

    -- Allow the second arg to override the path (power-user escape hatch).
    if opts.fargs and opts.fargs[2] then
      ctx = { path = opts.fargs[2], source = "arg" }
    end

    dispatch(target, ctx)
  end, {
    nargs   = "*",
    desc    = "Open path/URL with the specified handler (filemanager | browser | notepad)",

    --- Tab-completion: first arg → handler name, second arg → path (file completion).
    ---@param arg_lead string   The text typed so far in the current argument position.
    ---@param cmd_line string   The full command line text.
    ---@param cursor_pos integer Byte position of the cursor in cmd_line.
    ---@return string[] candidates
    complete = function(arg_lead, cmd_line, cursor_pos)
      -- Count how many space-separated tokens precede the cursor.
      -- Token 0 is the command name itself; token 1 is the first argument.
      local before_cursor = cmd_line:sub(1, cursor_pos)
      local tokens = {}
      for tok in before_cursor:gmatch("%S+") do
        tokens[#tokens + 1] = tok
      end

      -- If the line ends with whitespace, we are starting a new token.
      local starting_new = before_cursor:match("%s$") ~= nil
      -- arg_index: how many complete args have been typed (not counting the cmd).
      local arg_index = #tokens - 1 + (starting_new and 1 or 0)

      if arg_index <= 1 then
        -- Complete the handler/target name.
        local ok_r, reg = pcall(require, "custom.open.registry")
        if not ok_r then
          return {}
        end
        local names = reg.list()
        local candidates = {}
        for i = 1, #names do
          if names[i]:sub(1, #arg_lead) == arg_lead then
            candidates[#candidates + 1] = names[i]
          end
        end
        return candidates
      else
        -- Second argument: fall back to built-in file/path completion.
        return vim.fn.getcompletion(arg_lead, "file")
      end
    end,
  })
end

return M
