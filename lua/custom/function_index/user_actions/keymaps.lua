---@module 'custom.function_index.user_actions.keymaps'
---@brief Keymap definitions for function_index

local M = {}

---Register keymaps for function index
---@param keymaps table<string, string> Keymap configuration
function M.setup(keymaps)
  local function_index = require("custom.function_index")

  if keymaps.telescope then
    vim.keymap.set("n", keymaps.telescope, function()
      function_index.telescope_functions_index()
    end, {
      noremap = true,
      silent = true,
      desc = "[Function Index] Telescope picker",
    })
  end

  if keymaps.fzf then
    vim.keymap.set("n", keymaps.fzf, function()
      function_index.fzf_functions_index()
    end, {
      noremap = true,
      silent = true,
      desc = "[Function Index] fzf-lua picker",
    })
  end
end

return M
