---@module 'config.neotree.commands.mark'
--- Neo-tree marking commands: toggle mark on nodes for batch operations

local notify = require("lib.nvim.notify").create("[neotree.commands.mark]")

local renderer = require("config.neotree.helper.renderer")
local node_utils = require("config.neotree.utils.node")

local M = {}

--- Define custom highlight for marked nodes
local function setup_highlights()
  -- Only setup once
  if vim.g.neotree_mark_highlights_setup then
    return
  end

  vim.api.nvim_set_hl(0, "NeoTreeMarked", {
    fg = "#FFD700", -- Gold
    bold = true,
  })

  vim.g.neotree_mark_highlights_setup = true
end

--- Get mark icon/indicator
---@return string
local function get_mark_icon()
  -- Try to use nerd fonts, fallback to simple indicator
  if vim.g.have_nerd_font or vim.fn.has("gui_running") == 1 then
    return "✓" -- Check mark
  else
    return "*" -- Simple asterisk
  end
end

--- Toggle mark on the current node
---@param state Cfg.NeoTree.State
---@param auto_advance? boolean Move cursor down after marking (default: true)
---@return nil
function M.toggle_mark(state, auto_advance)
  setup_highlights()

  if auto_advance == nil then
    auto_advance = true
  end

  local node = node_utils.get_current(state)
  if not node then
    notify.warn("no node under cursor")
    return
  end

  local node_id = node.id
  local marks = state.explicitly_marked_node_ids or {}
  local is_marked = marks[node_id] ~= nil

  if is_marked then
    marks[node_id] = nil
    notify.info("✗ Unmarked: " .. (node.name or "<unknown>"))
  else
    marks[node_id] = true
    notify.info("✓ Marked: " .. (node.name or "<unknown>"))
  end

  state.explicitly_marked_node_ids = marks

  -- Force UI update
  renderer.redraw(state)

  -- Move cursor down for multi-selection convenience
  if auto_advance then
    vim.schedule(function()
      vim.cmd("normal! j")
    end)
  end
end

--- Clear all marks
---@param state Cfg.NeoTree.State
---@return nil
function M.clear_all_marks(state)
  if state.explicitly_marked_node_ids then
    local count = vim.tbl_count(state.explicitly_marked_node_ids)
    state.explicitly_marked_node_ids = {}

    -- Refresh to update visuals
    renderer.redraw(state)

    notify.info(string.format("Cleared %d marks", count))
  else
    notify.info("No marks to clear")
  end
end

--- Mark all files in the current directory node
---@param state Cfg.NeoTree.State
---@return nil
function M.mark_all_in_directory(state)
  setup_highlights()

  local tree = state.tree
  if not tree then
    notify.warn("No tree available")
    return
  end

  local current_node = tree:get_node()
  if not current_node then
    notify.warn("No node under cursor")
    return
  end

  -- Find parent directory
  local parent = current_node.type == "directory" and current_node
                 or tree:get_node(current_node:get_parent_id())
  ---@cast parent any

  if not parent then
    notify.warn("No parent directory found")
    return
  end

  -- Get children using tree:get_nodes() instead of parent.children
  local children = tree:get_nodes(parent:get_id())

  if not children or #children == 0 then
    notify.warn("Directory is empty")
    return
  end

  -- Mark all children (files only)
  local marks = state.explicitly_marked_node_ids or {}
  local count = 0

  for _, child in ipairs(children) do
    if child.type ~= "directory" then
      marks[child.id] = true
      count = count + 1
    end
  end

  state.explicitly_marked_node_ids = marks
  renderer.redraw(state)
  notify.info(string.format("Marked %d files", count))
end

--- Unmark all files in the current directory node
---@param state Cfg.NeoTree.State
---@return nil
function M.unmark_all_in_directory(state)
  local tree = state.tree
  if not tree then
    notify.warn("No tree available")
    return
  end

  local current_node = tree:get_node()
  if not current_node then
    notify.warn("No node under cursor")
    return
  end

  -- Find parent directory
  local parent = current_node.type == "directory" and current_node
                 or tree:get_node(current_node:get_parent_id())
  ---@cast parent any

  if not parent then
    notify.warn("No parent directory found")
    return
  end

  -- Get children using tree:get_nodes()
  local children = tree:get_nodes(parent:get_id())

  if not children or #children == 0 then
    notify.warn("Directory is empty")
    return
  end

  -- Unmark all children (files only)
  local marks = state.explicitly_marked_node_ids or {}
  local count = 0

  for _, child in ipairs(children) do
    if child.type ~= "directory" and marks[child.id] then
      marks[child.id] = nil
      count = count + 1
    end
  end

  state.explicitly_marked_node_ids = marks
  renderer.redraw(state)
  notify.info(string.format("Unmarked %d files", count))
end

--- Show all marked nodes in floating window
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

  local count = #marked_paths
  local icon = get_mark_icon()

  -- Build display lines
  local lines = {
    string.format("%s Marked Nodes (%d):", icon, count),
    string.rep("─", 50),
  }

  for i, path in ipairs(marked_paths) do
    local cwd = vim.fn.getcwd()
    local display_path = path

    if vim.startswith(path, cwd) then
      display_path = path:sub(#cwd + 2)
    end

    table.insert(lines, string.format(" %s %2d. %s", icon, i, display_path))
  end

  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

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
    title = string.format(" %s Marked Nodes ", icon),
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

  -- Highlighting
  vim.api.nvim_buf_add_highlight(buf, -1, "Title", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 1, 0, -1)

  for i = 3, #lines do
    -- Highlight icon
    vim.api.nvim_buf_add_highlight(buf, -1, "NeoTreeMarked", i - 1, 1, 2)
    -- Highlight path
    vim.api.nvim_buf_add_highlight(buf, -1, "Directory", i - 1, 6, -1)
  end
end

return M
