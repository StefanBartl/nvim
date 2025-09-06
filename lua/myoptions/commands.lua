---@module 'myoptions.commands'
--- Centralized user-command registration for MyOptions.
--- This module defines the commands only; each feature module is responsible
--- for calling the registration functions during its own enable() lifecycle.
---
--- Usage (inside myoptions/Highlight_Cfg/init.lua):
---   local Commands = require("myoptions.commands")
---   Commands.register_highlight_commands({
---     after_set  = after_set,         -- function(key) ... end
---     show_table = cfg,               -- the live highlight cfg table
---     names      = { set="MyHlSet", show="MyHlShow", list="MyHlList" }, -- optional
---   })
---
--- Usage (inside myoptions/Options_Cfg/init.lua):
---   local Commands = require("myoptions.commands")
---   Commands.register_options_commands({
---     after_set  = after_set,         -- function(key) ... end
---     show_table = ocfg,              -- the live options cfg table
---     names      = { set="MyOptSet", show="MyOptShow", list="MyOptList" }, -- optional
---   })
---
--- Notes
--- * Commands are idempotent: existing commands with the same name are removed
---   before re-definition to allow reloads (:luafile %).
--- * Completion is dynamic via myoptions.config keys().
--- * Values are parsed as boolean/number/string via myoptions.config.parse().

local M = {}

local C = require("myoptions.config")

--- Safely (re)define a user command by removing any previous definition.
--- @param name string
--- @param rhs  fun(opts:{fargs:string[], bang:boolean})
--- @param opts table
local function define_cmd(name, rhs, opts)
	pcall(vim.api.nvim_del_user_command, name)
	vim.api.nvim_create_user_command(name, rhs, opts or {})
end

--- Resolve a dot-path on a table (read-only).
--- @param root table
--- @param path string
--- @return any value_or_nil
local function get_by_path(root, path)
	local node = root
	for seg in string.gmatch(path, "[^%.]+") do
		if type(node) ~= "table" then return nil end
	node = node[seg]
	end
	return node
end

--- Build a completion function for a namespace.
--- @param ns '"highlight"'|'"options"'
--- @return fun(ArgLead:string, CmdLine:string, CursorPos:integer):string[]
local function make_complete(ns)
	return function(ArgLead, _, _)
		local keys = C.keys(ns)
		local pat = "^" .. vim.pesc(ArgLead)
		return vim.tbl_filter(function(k) return k:find(pat) ~= nil end, keys)
	end
end

--------------------------------------------------------------------------------
-- Highlight commands
--------------------------------------------------------------------------------

--- Register highlight-related user commands.
--- Commands:
---   :MyHlSet {key} {value}   | With ! toggles booleans when {value} is omitted
---   :MyHlShow [key]           | Shows either the full highlight table or a single leaf
---   :MyHlList                 | Lists all configurable highlight keys (dot-paths)
--- @param spec MyCommandsHLSpec
function M.register_highlight_commands(spec)
	assert(type(spec) == "table", "register_highlight_commands: spec required")
	assert(type(spec.show_table) == "table", "register_highlight_commands: spec.show_table must be a table")
	local names = vim.tbl_extend("force", { set = "MyHlSet", show = "MyHlShow", list = "MyHlList" }, spec.names or {})

	-- :MyHlSet
	define_cmd(names.set, function(opts)
		local args = opts.fargs
		if #args == 0 then
			vim.notify(("Usage: :%s {keypath} {value}"):format(names.set), vim.log.levels.INFO)
			return
		end
		local key = args[1]
		local value_str = table.concat(vim.list_slice(args, 2), " ")
		local toggle = (opts.bang == true) and (value_str == nil or value_str == "")
		local value = C.parse(value_str)

		local ok, err = C.set("highlight", key, value, toggle)
		if not ok then
			vim.notify(names.set .. ": " .. (err or "unknown error"), vim.log.levels.ERROR)
			return
		end

		if type(spec.after_set) == "function" then
			pcall(spec.after_set, key)
		end

		local msg = toggle and ("toggled " .. key) or (key .. " = " .. vim.inspect(value))
		vim.notify(("%s: %s"):format(names.set, msg), vim.log.levels.INFO)
	end, { bang = true, nargs = "+", complete = make_complete("highlight") })

	-- :MyHlShow
	define_cmd(names.show, function(opts)
		local key = opts.fargs[1]
		if not key then
			vim.notify(vim.inspect(spec.show_table), vim.log.levels.INFO)
			return
		end
		local node = get_by_path(spec.show_table, key)
		if node == nil then
			vim.notify(names.show .. (": unknown key '%s'"):format(key), vim.log.levels.WARN)
			return
		end
		vim.notify(("%s = %s"):format(key, vim.inspect(node)), vim.log.levels.INFO)
	end, { nargs = "?" })

	-- :MyHlList
	define_cmd(names.list, function()
		local lines = { "Highlight keys:" }
		for _, k in ipairs(C.keys("highlight")) do
			lines[#lines + 1] = "  " .. k
		end
		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
	end, {})
end

--------------------------------------------------------------------------------
-- Options commands
--------------------------------------------------------------------------------

--- Register option-related user commands.
--- Commands:
---   :MyOptSet {key} {value}  | With ! toggles booleans when {value} is omitted
---   :MyOptShow [key]          | Shows either the full options table or a single leaf
---   :MyOptList                | Lists all configurable option keys (dot-paths)
--- @param spec MyCommandsOptSpec
function M.register_options_commands(spec)
	assert(type(spec) == "table", "register_options_commands: spec required")
	assert(type(spec.show_table) == "table", "register_options_commands: spec.show_table must be a table")
	local names = vim.tbl_extend("force", { set = "MyOptSet", show = "MyOptShow", list = "MyOptList" }, spec.names or {})

	-- :MyOptSet
	define_cmd(names.set, function(opts)
		local args = opts.fargs
		if #args == 0 then
			vim.notify("Usage: :" .. names.set .. " {keypath} {value}", vim.log.levels.INFO)
			return
		end
		local key = args[1]
		local value_str = table.concat(vim.list_slice(args, 2), " ")
		local toggle = (opts.bang == true) and (value_str == nil or value_str == "")
		local value = C.parse(value_str)

		local ok, err = C.set("options", key, value, toggle)
		if not ok then
			vim.notify(names.set .. ": " .. (err or "unknown error"), vim.log.levels.ERROR)
			return
		end

		if type(spec.after_set) == "function" then
			pcall(spec.after_set, key)
		end

		local msg = toggle and ("toggled " .. key) or (key .. " = " .. vim.inspect(value))
		vim.notify(names.set .. ": " .. msg, vim.log.levels.INFO)
	end, { bang = true, nargs = "+", complete = make_complete("options") })

	-- :MyOptShow
	define_cmd(names.show, function(opts)
		local key = opts.fargs[1]
		if not key then
			vim.notify(vim.inspect(spec.show_table), vim.log.levels.INFO)
			return
		end
		local node = get_by_path(spec.show_table, key)
		if node == nil then
			vim.notify(("%s: unknown key '%s'"):format(names.show, key), vim.log.levels.WARN)
	return
		end
		vim.notify(("%s = %s"):format(key, vim.inspect(node)), vim.log.levels.INFO)
	end, { nargs = "?" })

	-- :MyOptList
	define_cmd(names.list, function()
		local lines = { "Options keys:" }
		for _, k in ipairs(C.keys("options")) do
			lines[#lines + 1] = "  " .. k
		end
		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
	end, {})
end


--------------------------------------------------------------------------------
-- Debug command
--------------------------------------------------------------------------------

--- Register a debug user command for inspecting breadcrumb context providers.
--- The command prints per-provider outputs, active flags, and the final chosen context.
---
--- Parameters:
---   opts.names.debug  (optional)  Custom command name, default: "MyHighlightDebugCtx"
---   opts.mod          (optional)  Module exposing provider functions
---   opts.sepfn        (optional)  Function returning the effective breadcrumb separator
---
--- Defaults:
---   If 'opts' is nil, sensible defaults are used.
---   If 'opts.names' or 'opts.names.debug' is nil, "MyHighlightDebugCtx" is used.
---   If 'opts.mod' is nil, require("myoptions.Highlight_Cfg.breadcrumbs.ctx") is used.
---   If 'opts.sepfn' is nil, a minimal internal resolver is used.
---
--- Notes:
---   • The module 'opts.mod' is expected to expose the provider functions listed in
---     'MyBreadcrumbsCtxModule' below (all optional; missing ones are handled gracefully).
---   • The separator function should return a short, single-cell string if possible.
---
---
---@param opts MyHighlightDebugOpts|nil
---@return nil
function M.register_highlight_debug_command(opts)
  opts = opts or {}
  local names = opts.names or {}
  local name_debug = names.debug or "MyHighlightDebugCtx"
  local mod = opts.mod or require("myoptions.Highlight_Cfg.breadcrumbs.ctx")

  -- Optional separator resolver hook
  local get_sep = opts.sepfn or function()
    -- Fall back to simple logic if your project uses a dedicated separator resolver:
    local hc = C.cfg.highlight
    local s = hc.breadcrumbs_separator
    if type(s) == "string" and s ~= "" then return s end
    -- Minimal Nerd-Font fallback (single-cell check omitted for brevity)
    local hex = hc.breadcrumbs_nerd_hex
    if type(hex) == "string" and hex ~= "" then
      local n = tonumber(hex, 16)
      if n then return " " .. vim.fn.nr2char(n) .. " " end
    end
    return (vim.o.columns >= 100) and " ⟶ " or " › "
  end

  vim.api.nvim_create_user_command(name_debug, function()
    local hc = C.cfg.highlight
    local ctx = hc.breadcrumbs_ctx or {}

    -- Probe providers individually (guard each call)
    local function safe(f)
      local ok, val = pcall(f)
      return ok and val or ("<error: " .. tostring(val) .. ">")
    end

    local p = {}
    p.lsp_func   = (mod._ctx_lsp_func     and safe(mod._ctx_lsp_func))     or "<n/a>"
    p.ts_symbol  = (mod._ctx_ts_symbol    and safe(mod._ctx_ts_symbol))    or "<n/a>"
    -- container augments a base symbol; feed ts_symbol into it for inspection
    p.container  = (mod._ctx_with_container and safe(function() return mod._ctx_with_container(p.ts_symbol ~= "<n/a>" and p.ts_symbol or nil) end)) or "<n/a>"
    p.lang_extra = (mod._ctx_lang_extra   and safe(mod._ctx_lang_extra))   or "<n/a>"
    p.word       = (mod._ctx_word_fallback and safe(mod._ctx_word_fallback)) or "<n/a>"

    local chosen = (mod._build_context and safe(mod._build_context)) or "<n/a>"

    local info = {
      "Breadcrumbs Debug",
      ("file: %s"):format(vim.api.nvim_buf_get_name(0)),
      ("separator: %s"):format(get_sep()),
      ("providers_order: %s"):format(vim.inspect(ctx.providers_order or {})),
      "flags:",
      ("  prefer_lsp_function        = %s"):format(tostring(ctx.prefer_lsp_function)),
      ("  use_treesitter_symbol      = %s"):format(tostring(ctx.use_treesitter_symbol)),
      ("  use_container_chain        = %s"):format(tostring(ctx.use_container_chain)),
      ("  fallback_object_when_empty = %s"):format(tostring(ctx.fallback_object_when_empty)),
      ("  fallback_word_when_empty   = %s"):format(tostring(ctx.fallback_word_when_empty)),
      ("  use_lang_specific          = %s"):format(tostring(ctx.use_lang_specific)),
      ("  container_join             = %s"):format(tostring(ctx.container_join)),
      ("  container_max_depth        = %s"):format(tostring(ctx.container_max_depth)),
      "",
      "provider results:",
      ("  lsp_func   → %s"):format(vim.inspect(p.lsp_func)),
      ("  ts_symbol  → %s"):format(vim.inspect(p.ts_symbol)),
      ("  container  → %s"):format(vim.inspect(p.container)),
      ("  lang_extra → %s"):format(vim.inspect(p.lang_extra)),
      ("  word       → %s"):format(vim.inspect(p.word)),
      "",
      ("chosen: %s"):format(vim.inspect(chosen)),
    }
    vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
  end, { desc = "Debug breadcrumb context providers" })
end

return M
