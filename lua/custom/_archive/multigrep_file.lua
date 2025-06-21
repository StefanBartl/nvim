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

  local fname = "  " .. vim.fn.expand("%:t")
  opts.default_text = opts.default_text or fname

  pickers.new(opts, {
    debounce = 100,
    prompt_title = "Multi Grep for File",
    finder = finder,
    previewer = conf.grep_previewer(opts),
    sorter = require("telescope.sorters").empty(),
    default_text = opts.default_text,
  }):find()

  vim.schedule(function()
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_cursor(win, { 1, 0 }) -- ← Cursor ganz vorne (vor den Leerzeichen)
    end
  end)
end

vim.api.nvim_create_user_command("MultigrepFile", function(opts)
  local arg = opts.fargs[1] or vim.fn.getcwd()
  require("custom.multigrep_file").live_multigrep({ cwd = arg })
end, {
  nargs = "?",
  desc = "Multigrep in project dir with syntax <NAME>  <*.ext>.",
})

return M
