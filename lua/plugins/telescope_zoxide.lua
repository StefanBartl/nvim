-- lua/plugins/telescope-zoxide.lua
-- All code is in English; comments are explicit and explanatory.

---@type LazyPluginSpec
return {
  -- Core dependency: telescope.nvim
  "nvim-telescope/telescope.nvim",
  dependencies = {
    -- Required by telescope
    "nvim-lua/plenary.nvim",
    -- The zoxide extension itself
    {
      "jvgrootveld/telescope-zoxide",
      -- Optional: pin to latest release if you prefer stability
      -- tag = "2.1",
      config = function()
        -- Import Telescope safely
        local ok_telescope, telescope = pcall(require, "telescope")
        if not ok_telescope then
          vim.notify("telescope not found", vim.log.levels.ERROR)
          return
        end

        -- Utilities from the extension to build simple actions (split, vsplit, edit)
        local z_utils = require("telescope._extensions.zoxide.utils")
        local builtin = require("telescope.builtin")

        -- Extend Telescope setup with the zoxide extension configuration
        telescope.setup({
          -- NOTE: keep your other telescope options here as usual
          extensions = {
            zoxide = {
              -- Shown as the picker title
              prompt_title = "[ Zoxide List ]",
              -- Command used to retrieve zoxide DB with scores; default matches README
              -- Keep it if you want to keep scores visible.
              list_command = "zoxide query -ls",
              -- Per-picker mappings (apply inside the zoxide picker buffer)
              mappings = {
                -- <CR> is the default action; here we leave it as "cd" (see defaults)
                default = {
                  -- Optional: post-action notification
                  after_action = function(selection)
                    -- selection.path and selection.z_score are available
                    vim.notify("Directory changed to " .. selection.path)
                  end,
                },
                -- Open selected entry in a horizontal split
                ["<C-s>"] = { action = z_utils.create_basic_command("split") },
                -- Open selected entry in a vertical split
                ["<C-v>"] = { action = z_utils.create_basic_command("vsplit") },
                -- Edit the directory (opens netrw or your file explorer plugin)
                ["<C-e>"] = { action = z_utils.create_basic_command("edit") },
                -- Chain into Telescope find_files rooted at the chosen directory
                ["<C-f>"] = {
                  keepinsert = true, -- remain in insert mode when switching pickers
                  action = function(selection)
                    builtin.find_files({ cwd = selection.path })
                  end,
                },
                -- Change working directory for the current tab
                ["<C-t>"] = {
                  action = function(selection)
                    vim.cmd.tcd(selection.path)
                  end,
                },
              },
            },
          },
        })

        -- Load the zoxide extension (must be after telescope.setup)
        telescope.load_extension("zoxide")

        -- Keymaps to launch the picker from normal mode
        -- <leader>sd = "smart directory" quick jump using zoxide database
        vim.keymap.set("n", "<leader>sd", function()
          telescope.extensions.zoxide.list()
        end, { desc = "Telescope Zoxide: jump to directory" })

        -- Optional: open zoxide list and immediately chain into find_files on <CR>
        -- Keep default <CR> behavior ("cd") if you prefer; this is just an example.
        -- To customize default <CR>, set a custom default.action as in README.
      end,
    },
  },
}

