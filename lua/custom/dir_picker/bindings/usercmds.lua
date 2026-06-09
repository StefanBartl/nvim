---@module 'custom.dir_picker.bindings.usercmds'
---@brief User command registration for dir_picker.

local M = {}

--- Registers the :DirPicker user command.
---@return nil
function M.enable()
  local ok, lib_usercmd = pcall(require, "lib.usercmd")
  local create = (ok and lib_usercmd and lib_usercmd.create)
    or vim.api.nvim_create_user_command

  create("DirPicker", function(opts)
    local args = opts.fargs   -- already split by Neovim

    -- Scan all tokens for path=, depth, and engine so that order is flexible:
    --   :DirPicker 2 telescope
    --   :DirPicker path=c:\tools telescope
    --   :DirPicker telescope path=/srv
    local depth_arg  = nil
    local engine_arg = nil

    local engine_names = { telescope = true, fzf = true, ["fzf-lua"] = true, fzf_lua = true }

    for _, token in ipairs(args) do
      local lower = token:lower()
      if lower:match("^path=") then
        -- handled inside core.pick via raw_args pass-through
      elseif engine_names[lower] then
        engine_arg = lower
      elseif not depth_arg then
        -- first unrecognised token is treated as depth / alias
        depth_arg = token
      end
    end

    -- Pass the full raw arg list so core can do path= extraction itself
    require("custom.dir_picker.core").pick(depth_arg, engine_arg, args)
  end, {
    nargs = "*",
    desc  = "Open a file picker. Usage: :DirPicker [depth|alias|path=<dir>] [telescope|fzf]",

    ---@param arg_lead string
    ---@param cmd_line string
    ---@return string[]
    complete = function(arg_lead, cmd_line, _)
      -- Count how many space-separated tokens precede the current word
      local before_cursor = cmd_line:gsub("%s+$", "")
      local words = vim.split(before_cursor, "%s+", { trimempty = true })
      -- words[1] is always "DirPicker"
      local token_index = #words + (arg_lead == "" and 1 or 0)

      -- Build the candidate list depending on what is already present
      local line_lower = cmd_line:lower()
      local has_engine = line_lower:match("telescope") or line_lower:match("fzf")
      local has_depth  = line_lower:match("%s+%d") or line_lower:match("%s+%a")
      local has_path   = line_lower:match("path=")

      -- path= prefix completion: offer path= hint on first or second token
      if arg_lead:lower():match("^path=") then
        -- After typing `path=` just let the shell/OS handle further completion;
        -- return the prefix itself so Neovim keeps it as-is.
        return { arg_lead }
      end

      local candidates = {}

      if not has_engine and not has_path then
        -- Suggest depth aliases, numeric hints, and the path= prefix
        if not has_depth then
          local aliases = require("custom.dir_picker.core").alias_names()
          candidates = { "0", "1", "2", "3", "path=" }
          for _, a in ipairs(aliases) do
            candidates[#candidates + 1] = a
          end
        else
          candidates = { "telescope", "fzf" }
        end
      elseif not has_engine then
        candidates = { "telescope", "fzf" }
      elseif not has_depth and not has_path then
        local aliases = require("custom.dir_picker.core").alias_names()
        candidates = { "0", "1", "2", "path=" }
        for _, a in ipairs(aliases) do
          candidates[#candidates + 1] = a
        end
      end

      return vim.tbl_filter(function(c)
        return c:find("^" .. vim.pesc(arg_lead)) ~= nil
      end, candidates)
    end,
  })
end

return M
