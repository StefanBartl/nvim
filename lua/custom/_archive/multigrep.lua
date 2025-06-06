-- THX to TeeJ
-- https://github.com/tjdevries/advent-of-nvim/blob/master/nvim/lua/config/telescope/multigrep.lua

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local conf = require "telescope.config".values

local M = {}

function M.live_multigrep(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end

      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }
      if pieces[1] then
        table.insert(args, "-e")
        table.insert(args, pieces[1])
      end

      if pieces[2] then
        table.insert(args, "-g")
        table.insert(args, pieces[2])
      end

      print("rg args:", vim.inspect(args))

      local merged_args = vim.deepcopy(args)
      vim.list_extend(merged_args, {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case"
      })

      return merged_args
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }
  --hidden for hidden files
  --L for Symlinks

  pickers.new(opts, {
    debounce = 100,
    prompt_title = "Multi Grep",
    finder = finder,
    previewer = conf.grep_previewer(opts),
    sorter = require("telescope.sorters").empty(),
  }):find()
end

M.setup = function()
  vim.keymap.set("n", "<leader>fg", require("custom.multigrep").live_multigrep)
end

vim.api.nvim_create_user_command("Multigrep", function(opts)
  local arg = opts.fargs[1] or vim.fn.getcwd()
  require("custom.multigrep").live_multigrep({ cwd = arg })
end, {
  nargs = "?",
  desc = "Multigrep in project dir with syntax <NAME>  <*.ext>.",
})

return M
