---@module 'mappings.harpoon'
--- Version-agnostic Harpoon keymaps (v1 und v2 kompatibel)

local M = {}


function M.setup()
  local map = vim.g.__map_helper
  local harpoon = require("harpoon")
  harpoon:setup({})

  map("n", "<leader>h", function()
    local list = harpoon:list()
    list:add()
  end, { desc = "[HARPOON] Add current file (append)" })

  map("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
    { desc = "[HARPOON] Open harpoon window (default)." })

  map("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "[HARPOON] Select item 1." })
  map("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "[HARPOON] Select item 2." })
  map("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "[HARPOON] Select item 3." })
  map("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "[HARPOON] Select item 4." })

  -- basic telescope configuration
  local conf = require("telescope.config").values
  local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
      table.insert(file_paths, item.value)
    end

    require("telescope.pickers").new({}, {
      prompt_title = "Harpoon",
      finder = require("telescope.finders").new_table({
        results = file_paths,
      }),
      previewer = conf.file_previewer({}),
      sorter = conf.generic_sorter({}),
    }):find()
  end

  map("n", "<leader>ht", function() toggle_telescope(harpoon:list()) end,
    { desc = "[HARPOON] Open harpoon window with telescope." })
end

return M
