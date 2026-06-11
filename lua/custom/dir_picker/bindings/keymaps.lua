---@module 'custom.dir_picker.bindings.keymaps'
---@brief Interactive keymap for dir_picker with depth, alias, and explicit path input.

local M = {}

--- Registers the <leader>fd keymap in normal mode.
---@return nil
function M.enable()
  local map = (vim.g.__map_helper) or require("lib.map")

  map("n", "<leader>dp", function()
    vim.ui.input({
      -- Inform the user about all accepted input forms in the prompt itself
      prompt = "Depth / alias / path=… (default: cwd): ",
    }, function(raw_input)
      if raw_input == nil then return end

      -- Determine whether the user typed a path= argument or a depth/alias
      local is_path = raw_input:lower():match("^path=") ~= nil
      local depth_arg  = not is_path and (raw_input ~= "" and raw_input or "cwd") or nil
      local raw_args   = { raw_input }   -- pass through for path= extraction in core

      local engines = { "telescope", "fzf" }

      local function dispatch(choice)
        require("custom.dir_picker.core").pick(depth_arg, choice, raw_args)
      end

      local ok, hover = pcall(require, "lib.ui.hover_select")
      if ok and hover and type(hover.open) == "function" then
        hover.open({ title = "Picker Engine", items = engines, on_select = dispatch })
      else
        vim.ui.select(engines, { prompt = "Picker Engine:" }, dispatch)
      end
    end)
  end, { desc = "[dir_picker] Open picker at depth, alias, or explicit path" })
end

return M
