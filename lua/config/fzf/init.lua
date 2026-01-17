---@module 'config.fzf'
---Composed fzf-lua configuration with custom actions

local keymaps = require("config.fzf.keymaps")
local fzf_opts = require("config.fzf.fzf_opts")
local grep_cfg = require("config.fzf.grep")
local files_cfg = require("config.fzf.files")
local create_file = require("config.fzf.actions.create_file")
local open_badd = require("config.fzf.actions.open_badd")

local M = {}

---@return table
function M.get()
  local fzf_actions = require("fzf-lua").actions
  -- Temporäres Debug-Kommando
  -- Füge das in deine init.lua oder eine temporäre Datei ein

  vim.api.nvim_create_user_command("FzfDebug", function()
    local config = require("config.fzf").get()

    print("=== fzf-lua Config Debug ===")
    print("Actions configured:")

    if config.actions then
      for key, action in pairs(config.actions) do
        local action_type = type(action)
        print(string.format("  [%s] = %s", key, action_type))

        if action_type == "function" then
          print("    ✓ Direct function")
        elseif action_type == "table" then
          print("    ✓ Table with fn:", type(action.fn))
          if action.desc then
            print("    ✓ Description:", action.desc)
          end
        end
      end
    else
      print("  ⚠ No actions found!")
    end

    print("\n=== Testing Actions ===")

    -- Test if actions are callable
    local test_selected = "lua/init.lua"
    local test_opts = {}

    if config.actions["ctrl-a"] then
      print("Testing ctrl-a...")
      local ok, result = pcall(config.actions["ctrl-a"], test_selected, test_opts)
      print("  Result:", ok and "SUCCESS" or "FAILED", result)
    end

    if config.actions["ctrl-o"] then
      print("Testing ctrl-o...")
      local ok, result = pcall(config.actions["ctrl-o"], test_selected, test_opts)
      print("  Result:", ok and "SUCCESS" or "FAILED", result)
    end
  end, {})

  print("Run :FzfDebug to test configuration")

  return {
    -- Builtin keymaps
    keymap = keymaps.get(),

    -- fzf command-line options
    fzf_opts = fzf_opts.get(),

    -- Picker-specific configs
    grep = grep_cfg.get(fzf_actions),
    files = files_cfg.get(),

    -- Global actions (apply to all pickers)
    actions = {
      -- Default actions
      ["default"] = fzf_actions.file_edit,
      ["ctrl-s"] = fzf_actions.file_split,
      ["ctrl-v"] = fzf_actions.file_vsplit,
      ["ctrl-t"] = fzf_actions.file_tabedit,

      -- Custom actions - direct function references
      ["ctrl-a"] = create_file.create_file,
      ["shift-enter"] = open_badd.open_badd,
      ["ctrl-o"] = open_badd.open_badd,
    },
  }
end

return M
