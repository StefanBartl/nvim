vim.api.nvim_create_user_command("FindKeymap", function()
  require("custom.run_mappings").find_keymap()
end, {})
