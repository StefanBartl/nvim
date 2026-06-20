---@module 'mappings.harpoon'
--- Version-agnostic Harpoon keymaps (v1 und v2 kompatibel)

local notify = require("lib.notify").create("[mappings.harpoon]")

local M = {}

function M.setup()
  local map = vim.g.__map_helper
  local harpoon = require("harpoon")
  if not harpoon then
    notify.warn("[harpoon] not installed")
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
    -- harpoon:add() fills the FIRST nil gap in items (1.._length+1), so if a
    -- persisted/pinned slot was removed earlier the new file lands in that hole
    -- near the top. Compact the holes away first so add() always appends at the
    -- real end of the list.
    local items = list.items or {}
    local len = list._length or #items
    local compact = {}
    for i = 1, len do
      if items[i] ~= nil then
        compact[#compact + 1] = items[i]
      end
    end
    list.items = compact
    list._length = #compact
    list:add()
  end, { desc = "[HARPOON] Add current file (append at end)" })

  map("n", "<C-e>", function()
    vim.cmd("HarpoonPersistPathsReload")
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
