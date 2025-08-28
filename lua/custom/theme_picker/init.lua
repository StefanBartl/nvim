--if exist, apply persistent theme selecion
require("custom.theme_picker.themes_picker").apply_persisted()
vim.api.nvim_create_user_command("ThemePicker", function()
  require("custom.themes_picker").pick()
end, {})
vim.keymap.set("n", "<leader>tp", function()
  require("csutom.theme_picker.themes_picker").pick()
end, { desc = "Unified theme picker (fzf-lua)" })

-- optional tuning
require("custom.theme_picker.themes_picker").setup({
  disable_base46_when_colorscheme = true,  -- recommended for mixed operation
  prompt = "Themes❯ ",
  height = 0.55,
  width  = 0.32,
  preview_window = "nohidden:right:0",
  -- persist_dir = vim.fn.stdpath("data") .. "/my_theme_prefs",
})
