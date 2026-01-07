---@module 'config.neotree.commands.get_telescope_opts'
--- Provides telescope options for launching find/grep from a neo-tree context.
--- Handles both directory and file selections, and makes the attach_mapping
--- resilient against different telescope entry shapes.

---@param state Cfg.NeoTree.State -- neo-tree state table (opaque)
---@param path string -- path provided by neo-tree (may be a directory or file)
---@return table -- telescope picker options
return function(state, path)
  -- Helper to determine if a path is a directory.
  -- Uses vim.fn.isdirectory which returns 1 for dirs, 0 otherwise.
  local function is_dir(p)
    -- p might be nil; guard against that.
    if p == nil then
      return false
    end
    return vim.fn.isdirectory(p) == 1
  end

  -- If path is a directory, use it as cwd. If it's a file, use its parent dir.
  local cwd = nil
  if is_dir(path) then
    cwd = path
  else
    -- ':h' gives the head (directory) part of the path
    cwd = vim.fn.fnamemodify(path, ':h')
  end

  -- search_dirs is what telescope will restrict the search to.
  -- If caller passed a file path, pass the file path so rg can be restricted to that file.
  ---@type string[]
  local search_dirs = { path }

  return {
    cwd = cwd,
    search_dirs = search_dirs,
    attach_mappings = function(prompt_bufnr, _)
      -- require here to avoid loading when module is required but not used
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      -- Replace default selection action: open selection in neo-tree without triggering
      -- neo-tree auto-close side-effects where possible.
      actions.select_default:replace(function()
        -- Close the telescope prompt first
        actions.close(prompt_bufnr)

        -- Get the selected entry in a robust way.
        local selection = action_state.get_selected_entry()
        -- Possible fields that contain the file path:
        -- - selection.path (common)
        -- - selection.filename (sometimes used)
        -- - selection[1] or selection.value as fallback
        local filename = nil
        if selection == nil then
          return
        end
        if selection.path ~= nil then
          filename = selection.path
        elseif selection.filename ~= nil then
          -- selection.filename might be a name only; try to turn into full path if cwd known
          local maybe = selection.filename
          if vim.fn.filereadable(maybe) == 1 then
            filename = maybe
          else
            -- join with cwd if available
            filename = vim.fn.fnamemodify(vim.fn.resolve(cwd .. "/" .. maybe), ":p")
          end
        elseif selection.value ~= nil then
          filename = selection.value
        elseif selection[1] ~= nil then
          filename = selection[1]
        else
          -- give up if no sensible field found
          return
        end

        -- Finally, attempt to open via neo-tree navigation API.
        -- If neo-tree expects a path relative to state.path or similar, pass absolute path.
        -- Use pcall to avoid uncaught errors from neo-tree plugin internals.
        local ok, _ = pcall(function()
          require("neo-tree.sources.filesystem").navigate(state, state.path, filename)
        end)
        if not ok then
          -- fallback: use the builtin edit if neo-tree navigation fails
          vim.cmd("edit " .. vim.fn.fnameescape(filename))
        end
      end)

      return true
    end,
  }
end
