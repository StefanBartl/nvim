local M = {}

-- Funktion für die Keymap-Suche
--- Führt eine grep-Suche nur in mappings.lua durch
M.search_keymaps = function()
  local telescope = require("telescope.builtin")
  local mappings_path = vim.fn.stdpath("config") .. "/lua/mappings.lua"

  telescope.live_grep({
    prompt_title = "Suche in mappings.lua",
    search_dirs = { mappings_path },
  })
end

vim.api.nvim_create_user_command("FindMapppings", function()
  require("custom.mappings_search").search_keymaps()
end, {
  desc = "Search keymaps in mappings.lua",
})

return M
