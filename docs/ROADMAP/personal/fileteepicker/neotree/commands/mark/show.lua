---@module 'config.neotree.commands.mark.show'
--- Display all currently marked nodes in a floating window

local notify = require("lib.nvim.notify").create("[neotree.commands.mark.show]")

local M = {}

--- Show all marked nodes in a floating window
---@param state Cfg.NeoTree.State
---@return nil
function M.show_marked_nodes(state)
  local marks = state.explicitly_marked_node_ids

  if not marks or vim.tbl_isempty(marks) then
    notify.info("No marked nodes")
    return
  end

  -- Collect marked node paths
  local marked_paths = {}
  for node_id, _ in pairs(marks) do
    table.insert(marked_paths, node_id)
  end

  -- Sort for consistent display
  table.sort(marked_paths)

  -- Count
  local count = #marked_paths

  -- Build display lines
  local lines = {
    string.format("Marked Nodes (%d):", count),
    string.rep("─", 50),
  }

  for i, path in ipairs(marked_paths) do
    -- Shorten path for display (relative to cwd if possible)
    local cwd = vim.fn.getcwd()
    local display_path = path

    if vim.startswith(path, cwd) then
      display_path = path:sub(#cwd + 2) -- +2 to skip trailing slash
    end

    table.insert(lines, string.format("%2d. %s", i, display_path))
  end

  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  -- Calculate window size
  local width = 80
  local height = math.min(#lines + 2, 20)

  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    notify.error("No UI available")
    return
  end

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - height) / 2),
    border = "rounded",
    style = "minimal",
    title = " Marked Nodes ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Set buffer-local keymaps to close
  local close_win = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<CR>", close_win, { buffer = buf, nowait = true })

  -- Set highlighting
  vim.api.nvim_buf_add_highlight(buf, -1, "Title", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 1, 0, -1)

  for i = 3, #lines do
    vim.api.nvim_buf_add_highlight(buf, -1, "Directory", i - 1, 4, -1)
  end
end

return M
