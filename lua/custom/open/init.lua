---@module 'custom.open'
---@brief Entry point for the :Open user command.
---@description
--- Registers the :Open [target] [scope] user command with tab-completion
--- over the registered handler names (1st arg) and explicit scope tokens
--- (2nd arg).
---
--- Target resolution (1st arg):
---   Explicit handler key (e.g. "filemanager") or, if omitted, an automatic
---   choice based on the current context (tree buffer → "filemanager",
---   URL-like cfile/cword → "browser", otherwise "filemanager").
---
--- Scope resolution (2nd arg), see custom.open.context for full details:
---   "%"            → current buffer path
---   "cfile"        → <cfile> under the cursor
---   "path=<path>"  → literal path given after "path="
---   (omitted)      → target-aware default (tree node → cfile-if-valid → %,
---                    or visual/cWORD → % for non-path targets)
---@see custom.open.context
---@see custom.open.registry

local M = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Dispatch to the appropriate handler.
---@param target string             Handler key, e.g. "filemanager", "browser", "notepad".
---@param ctx    Custom.Open.Context
---@return nil
local function dispatch(target, ctx)
  local ok_reg, registry = pcall(require, "custom.open.registry")
  if not ok_reg then
    require("lib.nvim.notify").create("[custom.open]").error("Registry not available")
    return
  end

  local handler = registry.get(target)
  if not handler then
    require("lib.nvim.notify").create("[custom.open]").error(
      string.format("Unknown target: '%s'  (available: %s)",
        target, table.concat(registry.list_keys(), ", "))
    )
    return
  end

  local ok, err = pcall(handler.run, ctx)
  if not ok then
    require("lib.nvim.notify").create("[custom.open]").error(
      string.format("Handler '%s' failed: %s", target, tostring(err))
    )
  end
end

--- Default handler when no target argument is given.
--- Uses "filemanager" when coming from a tree buffer or when nothing
--- URL-like is under the cursor; "browser" when the cursor sits on
--- something that looks like a URL.
---@param signals Custom.Open.Signals
---@return string target
local function default_target(signals)
  if signals.tree_path then
    return "filemanager"
  end

  local probe = signals.cfile or signals.cword or signals.buffer_path or ""
  if probe:match("^https?://") or probe:match("^ftp://") then
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
  local ok_reg, registry = pcall(require, "custom.open.registry")
  if not ok_reg then
    return
  end

  -- Handler modules export M.register_all(register_fn); requiring them is
  -- not enough, register_all must be invoked explicitly.
  local handler_modules = {
    "custom.open.handlers.filemanager",
    "custom.open.handlers.browser",
    "custom.open.handlers.notepad",
    "custom.open.handlers.nvim_internal",
  }
  for i = 1, #handler_modules do
    local ok_mod, mod = pcall(require, handler_modules[i])
    if ok_mod and type(mod) == "table" and type(mod.register_all) == "function" then
      pcall(mod.register_all, registry.register)
    end
  end

  -- -------------------------------------------------------------------------
  -- :Open [target] [scope]
  --
  -- Tab-completion: 1st arg enumerates registered handler names; 2nd arg
  -- offers explicit scope tokens ("%", "cfile", "path=") plus file completion.
  -- -------------------------------------------------------------------------
  vim.api.nvim_create_user_command("Open", function(opts)
    local context = require("custom.open.context")
    local signals  = context.gather()

    local target = (opts.fargs and opts.fargs[1]) or default_target(signals)
    target = target:lower()

    local scope = opts.fargs and opts.fargs[2]
    local ctx   = context.resolve(scope, target, signals)

    if not ctx then
      require("lib.nvim.notify").create("[custom.open]").warn("Nothing to open")
      return
    end

    dispatch(target, ctx)
  end, {
    nargs = "*",
    desc  = "Open path/URL with the specified handler (filemanager | browser | notepad | ...)",

    --- Tab-completion: 1st arg → handler name, 2nd arg → scope token or path.
    ---@param arg_lead string   The text typed so far in the current argument position.
    ---@param cmd_line string   The full command line text.
    ---@param cursor_pos integer Byte position of the cursor in cmd_line.
    ---@return string[] candidates
    complete = function(arg_lead, cmd_line, cursor_pos)
      local before_cursor = cmd_line:sub(1, cursor_pos)
      local tokens = {}
      for tok in before_cursor:gmatch("%S+") do
        tokens[#tokens + 1] = tok
      end

      local starting_new = before_cursor:match("%s$") ~= nil
      local arg_index = #tokens - 1 + (starting_new and 1 or 0)

      if arg_index <= 1 then
        -- Complete the handler/target name.
        local ok_r, reg = pcall(require, "custom.open.registry")
        if not ok_r then
          return {}
        end
        local names = reg.list_keys()
        local candidates = {}
        for i = 1, #names do
          if names[i]:sub(1, #arg_lead) == arg_lead then
            candidates[#candidates + 1] = names[i]
          end
        end
        return candidates
      end

      -- Second argument: explicit scope tokens, then file/path completion.
      if arg_lead:sub(1, 5) == "path=" then
        local rest        = arg_lead:sub(6)
        local file_matches = vim.fn.getcompletion(rest, "file")
        local candidates   = {}
        for i = 1, #file_matches do
          candidates[#candidates + 1] = "path=" .. file_matches[i]
        end
        return candidates
      end

      local candidates = {}
      local scopes = { "%", "cfile", "path=" }
      for i = 1, #scopes do
        if scopes[i]:sub(1, #arg_lead) == arg_lead then
          candidates[#candidates + 1] = scopes[i]
        end
      end

      local file_matches = vim.fn.getcompletion(arg_lead, "file")
      for i = 1, #file_matches do
        candidates[#candidates + 1] = file_matches[i]
      end

      return candidates
    end,
  })
end

return M
