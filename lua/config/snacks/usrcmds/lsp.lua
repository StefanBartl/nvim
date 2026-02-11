---@module 'config.snacks.usrcmds.lsp'
---@brief LSP-related snacks usercommands
---@description
--- This module provides usercommands for LSP-related snacks.nvim picker features
--- like definitions, references, implementations, and symbols.

local usercmd = require("lib.usercmd")
local notify = require("lib.notify").create("[config.snacks.usrcmds.lsp]")

local M = {}

---@type config.snacks.usrcmds.LspOpts
M.default_opts = {
  enabled = true,
  definitions = true,
  declarations = true,
  references = true,
  implementations = true,
  type_definitions = true,
  incoming_calls = true,
  outgoing_calls = true,
  symbols = true,
  workspace_symbols = true,
}

---Safely call a snacks picker function
---@param picker_name string Name of the picker (e.g., "lsp_definitions")
---@param args? table Optional arguments to pass to the picker
---@return boolean success
---@private
local function safe_picker_call(picker_name, args)
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    notify.error("snacks.nvim not available")
    return false
  end

  if type(snacks.picker) ~= "table" then
    notify.error("snacks.picker not available")
    return false
  end

  local picker_fn = snacks.picker[picker_name]
  if type(picker_fn) ~= "function" then
    notify.error(("snacks.picker.%s is not a function"):format(picker_name))
    return false
  end

  local call_ok, err = pcall(picker_fn, args)
  if not call_ok then
    notify.error(("snacks.picker.%s failed: %s"):format(picker_name, err))
    return false
  end

  return true
end

---Register LSP-related commands
---@param opts config.snacks.usrcmds.LspOpts
function M.register(opts)
  opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})

  if not opts.enabled then
    return
  end

  -- Definitions
  if opts.definitions then
    usercmd.create("SnacksLspDefinitions", function()
      safe_picker_call("lsp_definitions")
    end, {
      desc = "[snacks] LSP definitions picker",
      nargs = 0,
    })
  end

  -- Declarations
  if opts.declarations then
    usercmd.create("SnacksLspDeclarations", function()
      safe_picker_call("lsp_declarations")
    end, {
      desc = "[snacks] LSP declarations picker",
      nargs = 0,
    })
  end

  -- References
  if opts.references then
    usercmd.create("SnacksLspReferences", function()
      safe_picker_call("lsp_references")
    end, {
      desc = "[snacks] LSP references picker",
      nargs = 0,
    })
  end

  -- Implementations
  if opts.implementations then
    usercmd.create("SnacksLspImplementations", function()
      safe_picker_call("lsp_implementations")
    end, {
      desc = "[snacks] LSP implementations picker",
      nargs = 0,
    })
  end

  -- Type Definitions
  if opts.type_definitions then
    usercmd.create("SnacksLspTypeDefinitions", function()
      safe_picker_call("lsp_type_definitions")
    end, {
      desc = "[snacks] LSP type definitions picker",
      nargs = 0,
    })
  end

  -- Incoming Calls
  if opts.incoming_calls then
    usercmd.create("SnacksLspIncomingCalls", function()
      safe_picker_call("lsp_incoming_calls")
    end, {
      desc = "[snacks] LSP incoming calls picker",
      nargs = 0,
    })
  end

  -- Outgoing Calls
  if opts.outgoing_calls then
    usercmd.create("SnacksLspOutgoingCalls", function()
      safe_picker_call("lsp_outgoing_calls")
    end, {
      desc = "[snacks] LSP outgoing calls picker",
      nargs = 0,
    })
  end

  -- Symbols
  if opts.symbols then
    usercmd.create("SnacksLspSymbols", function()
      safe_picker_call("lsp_symbols")
    end, {
      desc = "[snacks] LSP symbols picker",
      nargs = 0,
    })
  end

  -- Workspace Symbols
  if opts.workspace_symbols then
    usercmd.create("SnacksLspWorkspaceSymbols", function()
      safe_picker_call("lsp_workspace_symbols")
    end, {
      desc = "[snacks] LSP workspace symbols picker",
      nargs = 0,
    })
  end
end

return M
