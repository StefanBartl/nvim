---@module 'custom.insert'
---@brief Unified insertion command interface for Neovim
---@description
--- This module provides a central :Insert command with subcommands for various
--- insertion operations. Each subcommand has its own completion and argument handling.
---
--- Available subcommands:
---   :Insert filepath [mode] [format] [depth]  -- Insert file paths
---   :Insert module                            -- Insert @module annotation
---   :Insert timestamp [format] [--utc]        -- Insert timestamps
---   :Insert uuid [format]                     -- Insert UUIDs
---   :Insert boilerplate <template> [name]     -- Insert code templates
---
--- Use :h insert.txt for full documentation.

-- Legacy modules
-- require("usrcmds.insertfilepath").enable()
-- require("usrcmds.lua_module_annotation").enable()

local M = {}

local api = vim.api

---@type Custom.Insert.Config
local config = {
  enable_legacy_commands = true,
  default_subcommand = nil,
}

---@type Custom.Insert.Registry
local registry = {
  subcommands = {},
}

---Safe wrapper for function calls with error reporting
---@param fn function
---@param ... any
---@return boolean success, any result_or_error
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    vim.notify(
      string.format("[custom.insert] Error: %s", tostring(result)),
      vim.log.levels.ERROR
    )
  end
  return ok, result
end

---Register a subcommand
---@param name Custom.Insert.SubcommandName
---@param def Custom.Insert.SubcommandDef
---@return nil
local function register_subcommand(name, def)
  if registry.subcommands[name] then
    vim.notify(
      string.format("[custom.insert] Warning: Subcommand '%s' already registered", name),
      vim.log.levels.WARN
    )
    return
  end

  if type(def.handler) ~= "function" then
    error(string.format("Subcommand '%s': handler must be a function", name))
  end

  if def.complete and type(def.complete) ~= "function" then
    error(string.format("Subcommand '%s': complete must be a function", name))
  end

  registry.subcommands[name] = def
end

---Parse command line into subcommand and arguments
---@param cmdline string
---@return Custom.Insert.SubcommandName|nil subcommand, string[] args
local function parse_command_line(cmdline)
  local args_str = cmdline:match("^%s*Insert%s+(.*)$") or cmdline:match("^%s*(.*)$") or ""
  local tokens = {}
  for token in args_str:gmatch("%S+") do
    table.insert(tokens, token)
  end

  if #tokens == 0 then
    return nil, {}
  end

  local subcommand = tokens[1]
  local args = {}
  for i = 2, #tokens do
    table.insert(args, tokens[i])
  end

  return subcommand, args
end

---Custom completion function
---@param arg_lead string
---@param cmdline string
---@param cursor_pos integer
---@return string[]
local function insert_complete(arg_lead, cmdline, cursor_pos)
  local subcommand, _ = parse_command_line(cmdline)

  -- Complete subcommand names
  if not subcommand or subcommand == arg_lead then
    local completions = {}
    for name, _ in pairs(registry.subcommands) do
      if vim.startswith(name, arg_lead) then
        table.insert(completions, name)
      end
    end
    table.sort(completions)
    return completions
  end

  -- Delegate to subcommand completion
  local def = registry.subcommands[subcommand]
  if def and def.complete then
    local ok, result = safe_call(def.complete, arg_lead, cmdline, cursor_pos)
    if ok and result then
      return result
    end
  end

  return {}
end

---Main handler for :Insert command
---@param opts table
---@return nil
local function insert_handler(opts)
  local args = opts.fargs or {}

  if #args == 0 then
    if config.default_subcommand then
      args = { config.default_subcommand }
    else
      vim.notify(
        "[custom.insert] Usage: :Insert <subcommand> [args...]\n"
          .. "Available subcommands: "
          .. table.concat(vim.tbl_keys(registry.subcommands), ", "),
        vim.log.levels.INFO
      )
      return
    end
  end

  local subcommand = args[1]
  local subargs = {}
  for i = 2, #args do
    table.insert(subargs, args[i])
  end

  local def = registry.subcommands[subcommand]
  if not def then
    vim.notify(
      string.format(
        "[custom.insert] Unknown subcommand: '%s'\nAvailable: %s",
        subcommand,
        table.concat(vim.tbl_keys(registry.subcommands), ", ")
      ),
      vim.log.levels.ERROR
    )
    return
  end

  safe_call(def.handler, subargs)
end

---Setup filepath subcommand
---@return nil
local function setup_filepath()
  local ok, filepath = pcall(require, "custom.insert.filepath.core")
  if not ok then
    return
  end

  register_subcommand("filepath", {
    handler = function(args)
      local opts = filepath.parse_args(args, 0)
      filepath.insert_path(opts)
    end,
    complete = function(arg_lead)
      local candidates = {
        "cwd",
        "abs",
        "absolute",
        "system",
        "win",
        "windows",
        "unix",
        "linux",
        "lua",
        "0",
        "1",
        "2",
        "3",
      }
      local matches = {}
      for _, c in ipairs(candidates) do
        if vim.startswith(c, arg_lead) then
          table.insert(matches, c)
        end
      end
      return matches
    end,
    nargs = "*",
    desc = "Insert file path: filepath [mode] [format] [depth]",
  })

  if config.enable_legacy_commands then
    api.nvim_create_user_command("InsertFilePath", function(cmd_opts)
      local opts = filepath.parse_args(cmd_opts.fargs or {}, cmd_opts.count or 0)
      safe_call(filepath.insert_path, opts)
    end, {
      nargs = "*",
      count = true,
      desc = "[legacy] Use :Insert filepath instead",
    })
  end
end

---Setup annotation subcommand
---@return nil
local function setup_annotation()
  local ok, annotation = pcall(require, "custom.insert.annotation.core")
  if not ok then
    return
  end

  register_subcommand("module", {
    ---@diagnostic disable-next-line: unused-local
    handler = function(args)
      annotation.insert_module_annotation()
    end,
    complete = function()
      return {}
    end,
    nargs = "0",
    desc = "Insert @module annotation",
  })

  register_subcommand("class", {
    handler = function(args)
      local name = args[1]
      annotation.insert_class_annotation(name)
    end,
    complete = function()
      return {}
    end,
    nargs = "*",
    desc = "Insert @class annotation: class [name]",
  })

  register_subcommand("function", {
    ---@diagnostic disable-next-line: unused-local
    handler = function(args)
      annotation.insert_function_annotation()
    end,
    complete = function()
      return {}
    end,
    nargs = "0",
    desc = "Insert function annotation block",
  })

  if config.enable_legacy_commands then
    api.nvim_create_user_command("LuaModuleAnnotations", function()
      safe_call(annotation.insert_module_annotation)
    end, {
      nargs = 0,
      desc = "[legacy] Use :Insert module instead",
    })
  end
end

---Setup timestamp subcommand
---@return nil
local function setup_timestamp()
  local ok, timestamp = pcall(require, "custom.insert.timestamp.core")
  if not ok then
    return
  end

  register_subcommand("timestamp", {
    handler = function(args)
      local opts = timestamp.parse_args(args)
      timestamp.insert_timestamp(opts)
    end,
    complete = function(arg_lead)
      local formats = {
        "iso",
        "iso-date",
        "iso-time",
        "unix",
        "human",
        "short",
        "log",
        "filename",
        "--utc",
        "-u",
      }
      local matches = {}
      for _, f in ipairs(formats) do
        if vim.startswith(f, arg_lead) then
          table.insert(matches, f)
        end
      end
      return matches
    end,
    nargs = "*",
    desc = "Insert timestamp: timestamp [format] [--utc]",
  })
end

---Setup UUID subcommand
---@return nil
local function setup_uuid()
  local ok, uuid = pcall(require, "custom.insert.uuid.core")
  if not ok then
    return
  end

  register_subcommand("uuid", {
    handler = function(args)
      local opts = uuid.parse_args(args)
      uuid.insert_uuid(opts)
    end,
    complete = function(arg_lead)
      local formats = { "standard", "compact", "upper", "braced", "v4" }
      local matches = {}
      for _, f in ipairs(formats) do
        if vim.startswith(f, arg_lead) then
          table.insert(matches, f)
        end
      end
      return matches
    end,
    nargs = "*",
    desc = "Insert UUID: uuid [format]",
  })
end

---Setup boilerplate subcommand
---@return nil
local function setup_boilerplate()
  local ok, boilerplate = pcall(require, "custom.insert.boilerplate.core")
  if not ok then
    return
  end

  register_subcommand("boilerplate", {
    handler = function(args)
      if #args == 0 then
        vim.notify(
          "[custom.insert.boilerplate] Usage: boilerplate <template> [name]",
          vim.log.levels.ERROR
        )
        return
      end

      local template = args[1]
      local name = args[2]
      boilerplate.insert_template(template, name)
    end,
    complete = function(arg_lead, cmdline)
      local _, args = parse_command_line(cmdline)
      if #args <= 1 then
        local templates = require("custom.insert.boilerplate.templates.core").list_templates()
        local matches = {}
        for _, t in ipairs(templates) do
          if vim.startswith(t, arg_lead) then
            table.insert(matches, t)
          end
        end
        return matches
      end
      return {}
    end,
    nargs = "+",
    desc = "Insert boilerplate: boilerplate <template> [name]",
  })
end

---Setup the insert module
---@param opts Custom.Insert.Config|nil
---@return nil
function M.setup(opts)
  if opts and type(opts) == "table" then
    config = vim.tbl_extend("force", config, opts)
  end

  setup_filepath()
  setup_annotation()
  setup_timestamp()
  setup_uuid()
  setup_boilerplate()

  api.nvim_create_user_command("Insert", insert_handler, {
    nargs = "*",
    complete = insert_complete,
    desc = "Unified insertion command with subcommands",
  })
end

return M
