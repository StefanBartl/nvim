---@module 'usrcmds.live_grep'

local config = require("usrcmds.live_grep.config")
local search = require("usrcmds.live_grep.search")
local picker = require("usrcmds.live_grep.picker")

local M = {}

---@param opts? LiveGrepConfig
function M.setup(opts)
  config.setup(opts)

  vim.api.nvim_create_user_command(
    "LiveGrep",
    function()
      vim.ui.input({
        prompt = "Search: ",
      }, function(input)
        if not input or input == "" then
          return
        end

        local files = search.search(input)

        local backend = picker.detect()

        require("usrcmds.live_grep." .. backend)
          .open(files, input)
      end)
    end,
    {}
  )

  vim.keymap.set(
    "n",
    config.options.keymap,
    "<cmd>LiveGrep<CR>",
    {
      desc = "File intersection search",
    }
  )
end

return M
