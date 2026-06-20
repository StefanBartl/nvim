---@module 'custom.find_in_folder.usercmds'
---@brief Registers the :FindInFolder user command.
---@description
--- Usage:
---   :FindInFolder                     → interactive folder select, Telescope
---   :FindInFolder /some/path          → search in /some/path, Telescope
---   :FindInFolder . fzf               → search in CWD, fzf-lua
---   :FindInFolder /some/path telescope

local M = {}

---Parse raw command args string into opts.
---@param args string  vim.api raw args string from the command callback
---@return FindInFolder.Opts
local function parse_args(args)
  local parts = vim.split(vim.trim(args), "%s+", { plain = false, trimempty = true })

  ---@type FindInFolder.Opts
  local opts = {}

  for _, part in ipairs(parts) do
    local lower = part:lower()
    if lower == "fzf" or lower == "telescope" then
      ---@type FindInFolder.Picker
      opts.picker = lower == "fzf" and "fzf" or "telescope"
    else
      -- Anything else is treated as a path
      opts.folder = vim.fn.expand(part)
    end
  end

  return opts
end

---Register :FindInFolder user command.
function M.setup()
  vim.api.nvim_create_user_command("FindInFolder", function(cmd_args)
    local opts = parse_args(cmd_args.args)
    require("custom.find_in_folder.core").run(opts)
  end, {
    nargs = "*",
    desc  = "Fuzzy-find files in a folder  [path] [telescope|fzf]",
    complete = function(arg_lead, _, _)
      -- Offer picker names if the word looks like one, else dir completion
      local pickers = { "telescope", "fzf" }
      local completions = {}

      for _, p in ipairs(pickers) do
        if vim.startswith(p, arg_lead:lower()) then
          completions[#completions + 1] = p
        end
      end

      if #completions > 0 then
        return completions
      end

      -- Fall back to directory completion
      return vim.fn.getcompletion(arg_lead, "dir")
    end,
  })
end

return M
