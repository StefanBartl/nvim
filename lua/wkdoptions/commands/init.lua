---@module 'wkdoptions.commands'
--- User command registration system for WKDOptions.
--- Provides commands for runtime config manipulation and debugging.
---
--- Available commands:
---   Highlight: WKDHighlightSet, WKDHighlightShow, WKDHighlightList
---   Options:   WKDOptSet, WKDOptShow, WKDOptList
---   Debug:     WKDHighlightDebugCtx
---
--- Architecture:
---   - core: Shared utilities (define_cmd, get_by_path, make_complete, parse_args)
---   - highlight: Highlight config commands
---   - options: Options config commands
---   - debug: Breadcrumb context debug command
---
--- Type definitions: wkdoptions.commands.@types

local M = {}

-- Lazy-load submodules to reduce startup cost
local highlight_mod, options_mod, debug_mod

--- Register highlight-related user commands.
--- Commands: :WKDHighlightSet, :WKDHighlightShow, :WKDHighlightList
---@param spec WKDOptions.Commands.HL_Spec
---@return nil
function M.register_highlight_commands(spec)
  if not highlight_mod then
    highlight_mod = require("wkdoptions.commands.highlight")
  end
  highlight_mod.register(spec)
end

--- Register options-related user commands.
--- Commands: :WKDOptSet, :WKDOptShow, :WKDOptList
---@param spec WKDOptions.Commands.Opt_Spec
---@return nil
function M.register_options_commands(spec)
  if not options_mod then
    options_mod = require("wkdoptions.commands.options")
  end
  options_mod.register(spec)
end

--- Register debug command for breadcrumb context.
--- Command: :WKDHighlightDebugCtx
---@param opts WKDOptions.Commands.Debug_Opts|nil
---@return nil
function M.register_highlight_debug_command(opts)
  if not debug_mod then
    debug_mod = require("wkdoptions.commands.debug")
  end
  debug_mod.register(opts)
end

---@type WKDOptions.Commands
return M
