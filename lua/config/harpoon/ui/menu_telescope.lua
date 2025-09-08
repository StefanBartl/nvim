---@module 'config.harpoon.ui.menu_telescope'

local M = {}

local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
  return M
end

local pickers     = require("telescope.pickers")
local finders     = require("telescope.finders")
local conf        = require("telescope.config").values
local actions     = require("telescope.actions")
local action_state= require("telescope.actions.state")
local label       = require("config.harpoon.utils.path_label")

---@return nil
function M.open()
  local ok_hp, harpoon = pcall(require, "harpoon")
  if not ok_hp then return end
  local list = harpoon:list()
  if type(list) ~= "table" or type(list.items) ~= "table" then return end

  local entries = {} ---@type string[]
  for i = 1, #list.items do
    local it = list.items[i]
    local p  = (type(it) == "table") and it.value or tostring(it)
    entries[#entries+1] = (label.to_label(p) .. "\0" .. p)
  end

  pickers.new({}, {
    prompt_title = "Harpoon",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(line)
        local lbl, path = line:match("^(.-)%z(.*)$")
        return {
          value   = path,
          display = lbl,
          ordinal = (lbl .. " " .. path),
          path    = path,
        }
      end,
    }),
    sorter   = conf.generic_sorter({}),
    previewer= conf.file_previewer({}),
    attach_mappings = function(pb, map)
      local function open_with(cmd)
        return function()
          local e = action_state.get_selected_entry()
          actions.close(pb)
          vim.cmd(cmd .. " " .. vim.fn.fnameescape(e.path))
        end
      end
      map("i", "<CR>",   open_with("edit"))
      map("i", "<C-v>",  open_with("vsplit"))
      map("i", "<C-x>",  open_with("split"))
      map("i", "<C-t>",  open_with("tabedit"))
      map("n", "<CR>",   open_with("edit"))
      map("n", "<C-v>",  open_with("vsplit"))
      map("n", "<C-x>",  open_with("split"))
      map("n", "<C-t>",  open_with("tabedit"))
      return true
    end,
  }):find()
end

return M
