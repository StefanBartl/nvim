---@module 'wkdoptions.commands'
--- Centralized user-command registration for wkdoptions.
--- This module defines the commands only; each feature module is responsible
--- for calling the registration functions during its own enable() lifecycle.
---
--- Usage (inside wkdoptions/hl_config/init.lua):
---   local Commands = require("wkdoptions.commands")
---   Commands.register_highlight_commands({
---     after_set  = after_set,         -- function(key) ... end
---     show_table = cfg,               -- the live highlight cfg table
---     names      = { set="MyHlSet", show="MyHlShow", list="MyHlList" }, -- optional
---   })
---
--- Usage (inside wkdoptions/options_config/init.lua):
---   local Commands = require("wkdoptions.commands")
---   Commands.register_options_commands({
---     after_set  = after_set,         -- function(key) ... end
---     show_table = ocfg,              -- the live options cfg table
---     names      = { set="MyOptSet", show="MyOptShow", list="MyOptList" }, -- optional
---   })
---
--- Notes
--- * Commands are idempotent: existing commands with the same name are removed
---   before re-definition to allow reloads (:luafile %).
--- * Completion is dynamic via wkdoptions.config keys().
--- * Values are parsed as boolean/number/string via wkdoptions.config.parse().

local C = require("wkdoptions.config")
local notify = require("lib.notify").create("[wkdoptions.Commands]")

local M = {}

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
    if type(node) ~= "table" then
      return nil
    end
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
    return vim.tbl_filter(function(k)
      return k:find(pat) ~= nil
    end, keys)
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
--- @param spec WKDOptions.Commands.HLSpec
function M.register_highlight_commands(spec)
  assert(type(spec) == "table", "register_highlight_commands: spec required")
  assert(type(spec.show_table) == "table", "register_highlight_commands: spec.show_table must be a table")
  local names = vim.tbl_extend("force", { set = "MyHlSet", show = "MyHlShow", list = "MyHlList" }, spec.names or {})

  -- :MyHlSet
  define_cmd(names.set, function(opts)
    local args = opts.fargs
    if #args == 0 then
      notify.info(("Usage: :%s {keypath} {value}"):format(names.set))
      return
    end
    local key = args[1]
    local value_str = table.concat(vim.list_slice(args, 2), " ")
    local toggle = (opts.bang == true) and (value_str == nil or value_str == "")
    local value = C.parse(value_str)

    local ok, err = C.set("highlight", key, value, toggle)
    if not ok then
      notify.error(names.set .. ": " .. (err or "unknown error"))
      return
    end

    if type(spec.after_set) == "function" then
      pcall(spec.after_set, key)
    end

    local msg = toggle and ("toggled " .. key) or (key .. " = " .. vim.inspect(value))
    notify.info(("%s: %s"):format(names.set, msg))
  end, { bang = true, nargs = "+", complete = make_complete("highlight") })

  -- :MyHlShow
  define_cmd(names.show, function(opts)
    local key = opts.fargs[1]
    if not key then
      notify.info(vim.inspect(spec.show_table))
      return
    end
    local node = get_by_path(spec.show_table, key)
    if node == nil then
      notify.warn(names.show .. (": unknown key '%s'"):format(key))
      return
    end
    notify.info(("%s = %s"):format(key, vim.inspect(node)))
  end, { nargs = "?" })

  -- :MyHlList
  define_cmd(names.list, function()
    local lines = { "Highlight keys:" }
    for _, k in ipairs(C.keys("highlight")) do
      lines[#lines + 1] = "  " .. k
    end
    notify.info(table.concat(lines, "\n"))
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
--- @param spec WKDOptions.Commands.OptSpec
function M.register_options_commands(spec)
  assert(type(spec) == "table", "register_options_commands: spec required")
  assert(type(spec.show_table) == "table", "register_options_commands: spec.show_table must be a table")
  local names = vim.tbl_extend("force", { set = "MyOptSet", show = "MyOptShow", list = "MyOptList" }, spec.names or {})

  -- :MyOptSet
  define_cmd(names.set, function(opts)
    local args = opts.fargs
    if #args == 0 then
      notify.info("Usage: :" .. names.set .. " {keypath} {value}")
      return
    end
    local key = args[1]
    local value_str = table.concat(vim.list_slice(args, 2), " ")
    local toggle = (opts.bang == true) and (value_str == nil or value_str == "")
    local value = C.parse(value_str)

    local ok, err = C.set("options", key, value, toggle)
    if not ok then
      notify.error(names.set .. ": " .. (err or "unknown error"))
      return
    end

    if type(spec.after_set) == "function" then
      pcall(spec.after_set, key)
    end

    local msg = toggle and ("toggled " .. key) or (key .. " = " .. vim.inspect(value))
    notify.info(names.set .. ": " .. msg)
  end, { bang = true, nargs = "+", complete = make_complete("options") })

  -- :MyOptShow
  define_cmd(names.show, function(opts)
    local key = opts.fargs[1]
    if not key then
      notify.info(vim.inspect(spec.show_table))
      return
    end
    local node = get_by_path(spec.show_table, key)
    if node == nil then
      notify.warn(("%s: unknown key '%s'"):format(names.show, key))
      return
    end
    notify.info(("%s = %s"):format(key, vim.inspect(node)))
  end, { nargs = "?" })

  -- :MyOptList
  define_cmd(names.list, function()
    local lines = { "Options keys:" }
    for _, k in ipairs(C.keys("options")) do
      lines[#lines + 1] = "  " .. k
    end
    notify.info(table.concat(lines, "\n"))
  end, {})
end

--------------------------------------------------------------------------------
-- Debug command
--------------------------------------------------------------------------------

--- Registriert den Debug-Command für Breadcrumb-Kontexte.
--- Aufruf (Beispiel):
---   require('wkdoptions.commands').register_highlight_debug_command()
--- oder mit Optionen:
---   require('wkdoptions.commands').register_highlight_debug_command({
---     names = { debug = "MyHlDbg" },
---     sepfn = function() return " ⟶ " end,
---   })
---@param opts WKDOptions.HL.DebugOpts|nil
---@return nil
function M.register_highlight_debug_command(opts)
  opts = opts or {}
  local names = opts.names or {}
  local name_debug = names.debug or "WKDOptions.HL.DebugCtx"

  -- Kontext-Modul (Provider) laden oder vom Aufrufer injiziert bekommen
  local mod = opts.mod or require("wkdoptions.hl_config.breadcrumbs.ctx")

  -- Optionaler Separator-Resolver
  local function default_sepfn()
    local hc = C.cfg.highlight
    local s = hc.breadcrumbs_separator
    if type(s) == "string" and s ~= "" then
      return s
    end
    local hex = hc.breadcrumbs_nerd_hex
    if type(hex) == "string" and hex ~= "" then
      local n = tonumber(hex, 16)
      if n then
        -- bewusst kompakt; Einzelzellen-Prüfung kann projektseitig ergänzt werden
        return " " .. vim.fn.nr2char(n) .. " "
      end
    end
    return (vim.o.columns >= 100) and " ⟶ " or " › "
  end
  local get_sep = opts.sepfn or default_sepfn

  -- Sicherer Wrapper, damit einzelne Provider-Aufrufe nicht die Anzeige sprengen
  local function safe_call(f)
    local ok, val = pcall(f)
    if ok then
      return val
    else
      return "<error: " .. tostring(val) .. ">"
    end
  end

  vim.api.nvim_create_user_command(name_debug, function()
    local hc = C.cfg.highlight
    local bctx = hc.breadcrumbs_ctx or {}

    -- Einzelne Provider abfragen (so vorhanden)
    local has = function(x)
      return type(x) == "function"
    end
    local p = {}

    p.lsp_func = has(mod._ctx_lsp_func) and safe_call(mod._ctx_lsp_func) or "<n/a>"
    p.ts_symbol = has(mod._ctx_ts_symbol) and safe_call(mod._ctx_ts_symbol) or "<n/a>"
    p.lang_extra = has(mod._ctx_lang_extra) and safe_call(mod._ctx_lang_extra) or "<n/a>"
    p.word = has(mod._ctx_word_fallback) and safe_call(mod._ctx_word_fallback) or "<n/a>"

    -- Basis-Token (unter Cursor) – nur wenn angeboten
    local base = has(mod._ctx_base_token) and safe_call(mod._ctx_base_token) or "<n/a>"

    -- Container-Augmenter separat inspizieren: bevorzugt TS-Symbol, sonst Base
    local container_input
    if type(p.ts_symbol) == "string" and p.ts_symbol ~= "<n/a>" then
      container_input = p.ts_symbol
    elseif type(base) == "string" and base ~= "<n/a>" then
      container_input = base
    end
    p.container = (has(mod._ctx_with_container) and container_input)
        and safe_call(function()
          return mod._ctx_with_container(container_input)
        end)
      or "<n/a>"

    -- Finalen Kontext nach der echten Orchestrierung bestimmen
    local chosen = has(mod._build_context) and safe_call(mod._build_context) or "<n/a>"

    -- Zusätzlich: wie sähe die Winbar-Zeile aus?
    local rel = (function(path)
      if path == "" then
        return "[No Name]"
      end
      local dir = vim.fn.fnamemodify(path, ":h")
      local gitdir = vim.fs.find(".git", { upward = true, path = dir })[1]
      if gitdir then
        local root = vim.fn.fnamemodify(gitdir, ":h")
        local relp = vim.fn.fnamemodify(path, (":~:%s"):format(root))
        if relp == path then
          return vim.fn.fnamemodify(path, ":t")
        end
        relp = relp:gsub("^%./", ""):gsub("^/", "")
        return relp
      else
        return vim.fn.fnamemodify(path, ":~:.")
      end
    end)(vim.api.nvim_buf_get_name(0))

    local sep = get_sep()
    local line = (type(chosen) == "string" and chosen ~= "" and chosen ~= "<n/a>") and (rel .. sep .. chosen) or rel

    -- Ausgabe
    local lines = {
      "Breadcrumbs Debug",
      ("file: %s"):format(vim.api.nvim_buf_get_name(0)),
      ("separator: %s"):format(sep),
      ("providers_order: %s"):format(vim.inspect(bctx.providers_order or {})),
      "flags:",
      ("  prefer_lsp_function            = %s"):format(tostring(bctx.prefer_lsp_function)),
      ("  use_treesitter_symbol          = %s"):format(tostring(bctx.use_treesitter_symbol)),
      ("  use_container_chain            = %s"):format(tostring(bctx.use_container_chain)),
      ("  use_lang_specific              = %s"):format(tostring(bctx.use_lang_specific)),
      ("  fallback_object_when_empty     = %s"):format(tostring(bctx.fallback_object_when_empty)),
      ("  fallback_word_when_empty       = %s"):format(tostring(bctx.fallback_word_when_empty)),
      ("  prefer_owner_in_literals       = %s"):format(tostring(bctx.prefer_owner_in_literals)),
      ("  prefer_owner_on_member_access  = %s"):format(tostring(bctx.prefer_owner_on_member_access)),
      ("  dedupe_containers              = %s"):format(tostring(bctx.dedupe_containers)),
      ("  container_join                 = %s"):format(tostring(bctx.container_join)),
      ("  container_max_depth            = %s"):format(tostring(bctx.container_max_depth)),
      ("  breadcrumbs_separator          = %s"):format(tostring(hc.breadcrumbs_separator)),
      ("  breadcrumbs_nerd_hex           = %s"):format(tostring(hc.breadcrumbs_nerd_hex)),
      "",
      "provider results:",
      ("  base       → %s"):format(vim.inspect(base)),
      ("  lsp_func   → %s"):format(vim.inspect(p.lsp_func)),
      ("  ts_symbol  → %s"):format(vim.inspect(p.ts_symbol)),
      ("  container  → %s"):format(vim.inspect(p.container)),
      ("  lang_extra → %s"):format(vim.inspect(p.lang_extra)),
      ("  word       → %s"):format(vim.inspect(p.word)),
      "",
      ("chosen: %s"):format(vim.inspect(chosen)),
      ("preview line: %s"):format(line),
    }

    notify.info(table.concat(lines, "\n"))
  end, { desc = "Debug breadcrumb context providers" })
end
return M
