---@module 'usrcmds.live_grep.telescope'

local M = {}

---@param files string[]
---@param title string
function M.open(files, title)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  pickers.new({}, {
    prompt_title = title,

    finder = finders.new_table({
      results = files,
    }),

    sorter = conf.file_sorter({}),
    previewer = conf.file_previewer({}),
  }):find()
end

return M
