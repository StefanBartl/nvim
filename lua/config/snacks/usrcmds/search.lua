---@module 'config.snacks.usrcmds.search'
---@brief Search-related snacks usercommands
---@description
--- This module provides usercommands for search-related snacks.nvim picker features
--- like registers, history, autocmds, commands, diagnostics, help, and more.

local usercmd = require("lib.nvim.usercmd")
local notify = require("lib.nvim.notify").create("[config.snacks.usrcmds.search]")

local M = {}

---@type config.snacks.usrcmds.SearchOpts
M.default_opts = {
  enabled = true,
  registers = true,
  history = true,
  autocmds = true,
  commands = true,
  command_history = true,
  diagnostics = true,
  diagnostics_buffer = true,
  help = true,
  highlights = true,
  icons = true,
  jumps = true,
  keymaps = true,
  loclist = true,
  marks = true,
  man = true,
  lazy = true,
  qflist = true,
  resume = true,
  undo = true,
  colorschemes = true,
}

---Safely call a snacks picker function
---@param picker_name string Name of the picker
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

---Register search-related commands
---@param opts config.snacks.usrcmds.SearchOpts
function M.register(opts)
  opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})

  if not opts.enabled then
    return
  end

  -- Registers
  if opts.registers then
    usercmd.create("SnacksSearchRegisters", function()
      safe_picker_call("registers")
    end, {
      desc = "[snacks] Registers picker",
      nargs = 0,
    })
  end

  -- Search History
  if opts.history then
    usercmd.create("SnacksSearchHistory", function()
      safe_picker_call("search_history")
    end, {
      desc = "[snacks] Search history picker",
      nargs = 0,
    })
  end

  -- Autocmds
  if opts.autocmds then
    usercmd.create("SnacksSearchAutocmds", function()
      safe_picker_call("autocmds")
    end, {
      desc = "[snacks] Autocmds picker",
      nargs = 0,
    })
  end

  -- Commands
  if opts.commands then
    usercmd.create("SnacksSearchCommands", function()
      safe_picker_call("commands")
    end, {
      desc = "[snacks] Commands picker",
      nargs = 0,
    })
  end

  -- Command History
  if opts.command_history then
    usercmd.create("SnacksSearchCommandHistory", function()
      safe_picker_call("command_history")
    end, {
      desc = "[snacks] Command history picker",
      nargs = 0,
    })
  end

  -- Diagnostics
  if opts.diagnostics then
    usercmd.create("SnacksSearchDiagnostics", function()
      safe_picker_call("diagnostics")
    end, {
      desc = "[snacks] Diagnostics picker",
      nargs = 0,
    })
  end

  -- Buffer Diagnostics
  if opts.diagnostics_buffer then
    usercmd.create("SnacksSearchDiagnosticsBuffer", function()
      safe_picker_call("diagnostics_buffer")
    end, {
      desc = "[snacks] Buffer diagnostics picker",
      nargs = 0,
    })
  end

  -- Help Pages
  if opts.help then
    usercmd.create("SnacksSearchHelp", function()
      safe_picker_call("help")
    end, {
      desc = "[snacks] Help pages picker",
      nargs = 0,
    })
  end

  -- Highlights
  if opts.highlights then
    usercmd.create("SnacksSearchHighlights", function()
      safe_picker_call("highlights")
    end, {
      desc = "[snacks] Highlights picker",
      nargs = 0,
    })
  end

  -- Icons
  if opts.icons then
    usercmd.create("SnacksSearchIcons", function()
      safe_picker_call("icons")
    end, {
      desc = "[snacks] Icons picker",
      nargs = 0,
    })
  end

  -- Jumps
  if opts.jumps then
    usercmd.create("SnacksSearchJumps", function()
      safe_picker_call("jumps")
    end, {
      desc = "[snacks] Jumps picker",
      nargs = 0,
    })
  end

  -- Keymaps
  if opts.keymaps then
    usercmd.create("SnacksSearchKeymaps", function()
      safe_picker_call("keymaps")
    end, {
      desc = "[snacks] Keymaps picker",
      nargs = 0,
    })
  end

  -- Location List
  if opts.loclist then
    usercmd.create("SnacksSearchLoclist", function()
      safe_picker_call("loclist")
    end, {
      desc = "[snacks] Location list picker",
      nargs = 0,
    })
  end

  -- Marks
  if opts.marks then
    usercmd.create("SnacksSearchMarks", function()
      safe_picker_call("marks")
    end, {
      desc = "[snacks] Marks picker",
      nargs = 0,
    })
  end

  -- Man Pages
  if opts.man then
    usercmd.create("SnacksSearchMan", function()
      safe_picker_call("man")
    end, {
      desc = "[snacks] Man pages picker",
      nargs = 0,
    })
  end

  -- Plugin Specs (Lazy)
  if opts.lazy then
    usercmd.create("SnacksSearchLazy", function()
      safe_picker_call("lazy")
    end, {
      desc = "[snacks] Plugin specs picker",
      nargs = 0,
    })
  end

  -- Quickfix List
  if opts.qflist then
    usercmd.create("SnacksSearchQflist", function()
      safe_picker_call("qflist")
    end, {
      desc = "[snacks] Quickfix list picker",
      nargs = 0,
    })
  end

  -- Resume Picker
  if opts.resume then
    usercmd.create("SnacksSearchResume", function()
      safe_picker_call("resume")
    end, {
      desc = "[snacks] Resume last picker",
      nargs = 0,
    })
  end

  -- Undo History
  if opts.undo then
    usercmd.create("SnacksSearchUndo", function()
      safe_picker_call("undo")
    end, {
      desc = "[snacks] Undo history picker",
      nargs = 0,
    })
  end

  -- Colorschemes
  if opts.colorschemes then
    usercmd.create("SnacksSearchColorschemes", function()
      safe_picker_call("colorschemes")
    end, {
      desc = "[snacks] Colorschemes picker",
      nargs = 0,
    })
  end
end

return M
