---@module 'wkdoptions.commands.register'
--- Central user command registration with autocompletion.
--- All commands are created via vim.api.nvim_create_user_command with proper completion.

local lazy = require("lib.lua.lazy")
local C = lazy.require("wkdoptions.config")
local notify = lazy.require("lib.nvim.notify").create("[Commands]")
local trim = lazy.require("lib.lua.strings.core").trim
local usercmd = lazy.require("lib.nvim.bindings.usercmd")

local M = {}

--- Safe command deletion
---@param name string
---@return nil
local function safe_delete_cmd(name)
  pcall(vim.api.nvim_del_user_command, name)
end

--- Create completion function for keys
---@nodiscard
---@param keys_fn fun(): string[]
---@return fun(ArgLead: string, CmdLine: string, CursorPos: integer): string[]
local function make_complete(keys_fn)
  return function(ArgLead, _, _)
    ArgLead = ArgLead or ""

    local ok, keys = pcall(keys_fn)
    if not ok or type(keys) ~= "table" then
      return {}
    end

    if ArgLead == "" then
      return keys
    end

    local pat = "^" .. vim.pesc(ArgLead)
    local matches = {}
    for i = 1, #keys do
      local k = keys[i]
      if type(k) == "string" and k:find(pat) then
        matches[#matches + 1] = k
      end
    end

    return matches
  end
end

--- Parse command arguments into key + value
---@nodiscard
---@param args string[]
---@return string|nil key
---@return string|nil value_str
local function parse_args(args)
  if type(args) ~= "table" or #args == 0 then
    return nil, nil
  end

  local key = trim(args[1] or "")
  if key == "" then
    return nil, nil
  end

  -- Concatenate remaining args as value
  local value_parts = {}
  for i = 2, #args do
    value_parts[#value_parts + 1] = args[i]
  end

  local value_str = table.concat(value_parts, " ")
  value_str = trim(value_str)

  return key, value_str
end

--- Register highlight commands
---@param spec WKDOptions.Commands.HL_Spec
---@return nil
function M.register_highlight(spec)
  local names = vim.tbl_extend(
    "force",
    { set = "WKDHighlightSet", show = "WKDHighlightShow", list = "WKDHighlightList" },
    spec.names or {}
  )

  -- :WKDHighlightSet
  safe_delete_cmd(names.set)
  usercmd.create(names.set, function(opts)
    local key, value_str = parse_args(opts.fargs)

    if not key then
      notify.info(("Usage: :%s {keypath} {value}"):format(names.set))
      return
    end

    local toggle = (opts.bang == true) and (value_str == nil or value_str == "")
    local value = C.parse(value_str)

    local ok, err = C.set("highlight", key, value, toggle)
    if not ok then
      notify.error(("%s: %s"):format(names.set, tostring(err or "unknown error")))
      return
    end

    if type(spec.after_set) == "function" then
      pcall(spec.after_set, key)
    end

    local msg = toggle and ("toggled " .. key) or (key .. " = " .. vim.inspect(value))
    notify.info(("%s: %s"):format(names.set, msg))
  end, {
    bang = true,
    nargs = "+",
    complete = make_complete(function()
      return C.keys("highlight")
    end),
    desc = "Set highlight config value",
  })

  -- :WKDHighlightShow
  safe_delete_cmd(names.show)
  usercmd.create(names.show, function(opts)
    local key = opts.fargs[1]
    if not key or key == "" then
      notify.info(vim.inspect(spec.show_table))
      return
    end

    local node = C.get("highlight", key)
    if node == nil then
      notify.warn(("%s: unknown key '%s'"):format(names.show, key))
      return
    end

    notify.info(("%s = %s"):format(key, vim.inspect(node)))
  end, {
    nargs = "?",
    complete = make_complete(function()
      return C.keys("highlight")
    end),
    desc = "Show highlight config value",
  })

  -- :WKDHighlightList
  safe_delete_cmd(names.list)
  usercmd.create(names.list, function()
    local keys = C.keys("highlight")
    local lines = { "Highlight keys:" }
    for i = 1, #keys do
      lines[#lines + 1] = "  " .. keys[i]
    end
    notify.info(table.concat(lines, "\n"))
  end, {
    desc = "List all highlight config keys",
  })
end

--- Register options commands
---@param spec WKDOptions.Commands.Opt_Spec
---@return nil
function M.register_options(spec)
  local names = vim.tbl_extend(
    "force",
    { set = "WKDOptSet", show = "WKDOptShow", list = "WKDOptList" },
    spec.names or {}
  )

  -- :WKDOptSet
  safe_delete_cmd(names.set)
  usercmd.create(names.set, function(opts)
    local key, value_str = parse_args(opts.fargs)

    if not key then
      notify.info(("Usage: :%s {keypath} {value}"):format(names.set))
      return
    end

    local toggle = (opts.bang == true) and (value_str == nil or value_str == "")
    local value = C.parse(value_str)

    local ok, err = C.set("options", key, value, toggle)
    if not ok then
      notify.error(("%s: %s"):format(names.set, tostring(err or "unknown error")))
      return
    end

    if type(spec.after_set) == "function" then
      pcall(spec.after_set, key)
    end

    local msg = toggle and ("toggled " .. key) or (key .. " = " .. vim.inspect(value))
    notify.info(("%s: %s"):format(names.set, msg))
  end, {
    bang = true,
    nargs = "+",
    complete = make_complete(function()
      return C.keys("options")
    end),
    desc = "Set options config value",
  })

  -- :WKDOptShow
  safe_delete_cmd(names.show)
  usercmd.create(names.show, function(opts)
    local key = opts.fargs[1]
    if not key or key == "" then
      notify.info(vim.inspect(spec.show_table))
      return
    end

    local node = C.get("options", key)
    if node == nil then
      notify.warn(("%s: unknown key '%s'"):format(names.show, key))
      return
    end

    notify.info(("%s = %s"):format(key, vim.inspect(node)))
  end, {
    nargs = "?",
    complete = make_complete(function()
      return C.keys("options")
    end),
    desc = "Show options config value",
  })

  -- :WKDOptList
  safe_delete_cmd(names.list)
  usercmd.create(names.list, function()
    local keys = C.keys("options")
    local lines = { "Options keys:" }
    for i = 1, #keys do
      lines[#lines + 1] = "  " .. keys[i]
    end
    notify.info(table.concat(lines, "\n"))
  end, {
    desc = "List all options config keys",
  })
end

--- Register diff profile command
---@return nil
function M.register_diff_profile()
  local selector = require("wkdoptions.set_diff_profile.selector")
  local profiles = require("wkdoptions.set_diff_profile.profiles")

  safe_delete_cmd("WKDDiffProfile")
  usercmd.create("WKDDiffProfile", function(opts)
    local profile = opts.fargs[1]

    if not profile or profile == "" then
      notify.info("Available profiles: " .. table.concat(vim.tbl_keys(profiles), ", "))
      return
    end

    local ok, err = pcall(selector, profile)
    if not ok then
      notify.error(("Failed to set diff profile '%s': %s"):format(profile, tostring(err)))
      return
    end

    notify.info(("Diff profile set to '%s'"):format(profile))
  end, {
    nargs = 1,
    complete = function(ArgLead)
      local keys = vim.tbl_keys(profiles)
      table.sort(keys)

      if ArgLead == "" then
        return keys
      end

      local pat = "^" .. vim.pesc(ArgLead)
      local matches = {}
      for i = 1, #keys do
        if keys[i]:find(pat) then
          matches[#matches + 1] = keys[i]
        end
      end

      return matches
    end,
    desc = "Set diff profile (minimal/context/review/strict)",
  })
end

--- Register debug command
---@param opts WKDOptions.Commands.Debug_Opts|nil
---@return nil
function M.register_debug(opts)
  opts = opts or {}
  local names = opts.names or {}
  local name_debug = names.debug or "WKDHighlightDebugCtx"

  local mod = opts.mod or require("wkdoptions.hl_config.breadcrumbs.ctx")

  local function default_sepfn()
    local hc = C.get_cfg().highlight
    local s = hc.breadcrumbs_separator
    if type(s) == "string" and s ~= "" then
      return s
    end
    local hex = hc.breadcrumbs_nerd_hex
    if type(hex) == "string" and hex ~= "" then
      local n = tonumber(hex, 16)
      if n then
        return " " .. vim.fn.nr2char(n) .. " "
      end
    end
    return (vim.o.columns >= 100) and " ⟶ " or " › "
  end

  local get_sep = opts.sepfn or default_sepfn

  local function safe_call(fn)
    if type(fn) ~= "function" then
      return "<unavailable>"
    end

    local ok, val = pcall(fn)
    if ok then
      return tostring(val or "<nil>")
    else
      return "<error: " .. tostring(val) .. ">"
    end
  end

  safe_delete_cmd(name_debug)
  usercmd.create(name_debug, function()
    local hc = C.get_cfg().highlight
    local bctx = hc.breadcrumbs_ctx or {}

    local p = {
      lsp_func = safe_call(mod._ctx_lsp_func),
      ts_symbol = safe_call(mod._ctx_ts_symbol),
      lang_extra = safe_call(mod._ctx_lang_extra),
      word = safe_call(mod._ctx_word_fallback),
    }

    local base = safe_call(mod._ctx_base_token)

    local container_input = (p.ts_symbol ~= "<unavailable>" and p.ts_symbol ~= "<nil>")
        and p.ts_symbol
      or (base ~= "<unavailable>" and base ~= "<nil>") and base
      or nil

    p.container = (type(mod._ctx_with_container) == "function" and container_input)
        and safe_call(function()
          return mod._ctx_with_container(container_input)
        end)
      or "<unavailable>"

    local chosen = safe_call(mod._build_context)

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
    local line = (chosen ~= "<unavailable>" and chosen ~= "<nil>") and (rel .. sep .. chosen) or rel

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
      ("  prefer_owner_on_member_access  = %s"):format(
        tostring(bctx.prefer_owner_on_member_access)
      ),
      ("  dedupe_containers              = %s"):format(tostring(bctx.dedupe_containers)),
      ("  container_join                 = %s"):format(tostring(bctx.container_join)),
      ("  container_max_depth            = %s"):format(tostring(bctx.container_max_depth)),
      ("  breadcrumbs_separator          = %s"):format(tostring(hc.breadcrumbs_separator)),
      ("  breadcrumbs_nerd_hex           = %s"):format(tostring(hc.breadcrumbs_nerd_hex)),
      "",
      "provider results:",
      ("  base       → %s"):format(base),
      ("  lsp_func   → %s"):format(p.lsp_func),
      ("  ts_symbol  → %s"):format(p.ts_symbol),
      ("  container  → %s"):format(p.container),
      ("  lang_extra → %s"):format(p.lang_extra),
      ("  word       → %s"):format(p.word),
      "",
      ("chosen: %s"):format(chosen),
      ("preview line: %s"):format(line),
    }

    notify.info(table.concat(lines, "\n"))
  end, {
    desc = "Debug breadcrumb context providers",
  })
end

--- Register all commands
---@return nil
function M.register_all()
  -- Highlight commands
  M.register_highlight({
    after_set = function(key)
      local hl_config = require("wkdoptions.hl_config")
      if type(hl_config.after_set) == "function" then
        pcall(hl_config.after_set, key)
      end
    end,
    show_table = require("wkdoptions.config").get_cfg().highlight,
  })

  -- Options commands
  M.register_options({
    after_set = function(key)
      local opt_config = require("wkdoptions.options_config")
      if type(opt_config.after_set) == "function" then
        pcall(opt_config.after_set, key)
      end
    end,
    show_table = require("wkdoptions.config").get_cfg().options,
  })

  -- Diff profile command
  M.register_diff_profile()

  -- Debug command
  M.register_debug()
end

return M
