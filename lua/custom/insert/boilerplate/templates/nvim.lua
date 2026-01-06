---@module 'custom.insert.boilerplate.templates.nvim'
---@brief Neovim-specific template generators

local M = {}

---Generate Neovim autocommand template
---@param group_name string
---@return string[]
function M.autocmd(group_name)
  return {
    string.format('local augroup = vim.api.nvim_create_augroup("%s", { clear = true })', group_name),
    "",
    "vim.api.nvim_create_autocmd({ TODO: events }, {",
    "  group = augroup,",
    '  pattern = "TODO: pattern",',
    "  callback = function()",
    "    -- TODO: Implementation",
    "  end,",
    '  desc = "TODO: Description",',
    "})",
  }
end

---Generate Neovim keymap template
---@return string[]
function M.keymap()
  return {
    'vim.keymap.set("n", "<leader>TODO", function()',
    "  -- TODO: Implementation",
    'end, { desc = "TODO: Description" })',
  }
end

return M
