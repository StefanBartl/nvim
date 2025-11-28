---@module 'mappings.harpoon'
--- Version-agnostic Harpoon keymaps (v1 und v2 kompatibel)

local M = {}

function M.setup()
  local map = vim.g.__map_helper
  local harpoon = require("harpoon")
  if not harpoon then
    vim.notify("[harpoon] not installed", vim.log.levels.WARN)
    return
  end
  -- Safe setup: enable immediate persistence on every change.
  -- In Harpoon v2, this writes to storage on add/remove/toggle operations.
  pcall(function()
    -- Both method-style and function-style setup are supported in the wild.
    if type(harpoon.setup) == "function" then
      local info = debug.getinfo(harpoon.setup, "u")
      if info and info.nparams and info.nparams >= 2 then
        harpoon:setup({
          settings = {
            save_on_change = true,
            save_on_toggle = true,
          },
        })
      else
        harpoon.setup({
          settings = {
            save_on_change = true,
            save_on_toggle = true,
          },
        })
      end
    end
  end)

  map("n", "<leader>h", function()
    local list = harpoon:list()
    list:add()
  end, { desc = "[HARPOON] Add current file (append)" })

  map("n", "<C-e>", function()
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end, { desc = "[HARPOON] Open harpoon window (default)." })
  --
  -- map("n", "<leader>1", function()
  --   harpoon:list():select(1)
  -- end, { desc = "[HARPOON] Select item 1." })
  -- map("n", "<leader>2", function()
  --   harpoon:list():select(2)
  -- end, { desc = "[HARPOON] Select item 2." })
  -- map("n", "<leader>3", function()
  --   harpoon:list():select(3)
  -- end, { desc = "[HARPOON] Select item 3." })
  -- map("n", "<leader>4", function()
  --   harpoon:list():select(4)
  -- end, { desc = "[HARPOON] Select item 4." })
  --
  -- basic telescope configuration
  local conf = require("telescope.config").values
  local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
      table.insert(file_paths, item.value)
    end

    require("telescope.pickers")
      .new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({
          results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
      })
      :find()
  end

  map("n", "<leader>ht", function()
    toggle_telescope(harpoon:list())
  end, { desc = "[HARPOON] Open harpoon window with telescope." })
end

return M
