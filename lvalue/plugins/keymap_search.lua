local M = {}

-- Funktion für die Keymap-Suche
M.search_keymaps = function()
    local telescope = require("telescope.builtin")
    telescope.find_files({
        prompt_title = "Suche in Keymaps",
        cwd = vim.fn.stdpath("config") .. "/lua/custom",
        find_command = { "rg", "--files", "--iglob", "*.lua", "--hidden" },
        search_dirs = { vim.fn.stdpath("config") .. "/lua/custom/keymaps.lua" },
    })
end

return M
