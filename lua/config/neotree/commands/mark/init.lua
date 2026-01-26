---@module 'config.neotree.commands.mark'
---@brief Neo-tree marking system with visual feedback and batch operation support
---@description
--- Enhanced marking system that provides:
--- - Visual feedback via sign column
--- - Generic batch operations (delete, copy, move, rename)
--- - Persistent marks across refreshes
--- - Smart cursor advancement

---@nodiscard
local notify = require("lib.notify").create("[neotree.mark]")

local renderer = require("config.neotree.helper.renderer")
local node_utils = require("config.neotree.utils.node")

local M = {}

-- ============================================================================
-- Sign Definition
-- ============================================================================

local MARK_SIGN = "NeoTreeMark"
local MARK_NS = vim.api.nvim_create_namespace("neo_tree_marks")

---Initialize sign column marks
---@private
local function init_signs()
  pcall(vim.fn.sign_define, MARK_SIGN, {
    text = "●",
    texthl = "DiagnosticWarn",
    linehl = "",
    numhl = "",
  })
end

-- Initialize on load
init_signs()

-- ============================================================================
-- State Management
-- ============================================================================

---@class MarkState
---@field marks table<string, boolean> Node IDs that are marked
---@field extmarks table<integer, integer> Map of line -> extmark ID

---@type table<integer, MarkState>
local buffer_states = setmetatable({}, { __mode = "k" })

---Get or create mark state for buffer
---@param bufnr integer
---@return MarkState
local function get_state(bufnr)
  if not buffer_states[bufnr] then
    buffer_states[bufnr] = {
      marks = {},
      extmarks = {},
    }
  end
  return buffer_states[bufnr]
end

-- ============================================================================
-- Visual Feedback
-- ============================================================================

---Update visual marks in sign column
---@param state Cfg.NeoTree.State
---@private
local function update_visual_marks(state)
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local mark_state = get_state(bufnr)

  -- Clear existing extmarks
  vim.api.nvim_buf_clear_namespace(bufnr, MARK_NS, 0, -1)
  mark_state.extmarks = {}

  -- Get tree
  local tree = state.tree
  if not tree then
    return
  end

  -- Add marks for marked nodes
  local marks = state.explicitly_marked_node_ids or {}
  for node_id, _ in pairs(marks) do
    local node = tree:get_node(node_id)
    if node then
      -- Find line number for this node
      local line = node_utils.get_line_number(state, node_id)
      if line then
        local mark_id = vim.api.nvim_buf_set_extmark(bufnr, MARK_NS, line - 1, 0, {
          sign_text = "●",
          sign_hl_group = "DiagnosticWarn",
        })
        mark_state.extmarks[line] = mark_id
      end
    end
  end
end

-- ============================================================================
-- Core Marking Functions
-- ============================================================================

---Toggle mark on current node
---@param state Cfg.NeoTree.State
---@param auto_advance? boolean Move cursor down after marking (default: true)
---@return nil
function M.toggle_mark(state, auto_advance)
  if auto_advance == nil then
    auto_advance = true
  end

  local node = node_utils.get_current(state)
  if not node then
    notify.warn("No node under cursor")
    return
  end

  local node_id = node.id
  local marks = state.explicitly_marked_node_ids or {}
  local is_marked = marks[node_id] ~= nil

  -- Toggle mark
  if is_marked then
    marks[node_id] = nil
    notify.info("✗ Unmarked: " .. (node.name or "<unknown>"))
  else
    marks[node_id] = true
    notify.info("✓ Marked: " .. (node.name or "<unknown>"))
  end

  state.explicitly_marked_node_ids = marks

  -- Update visuals
  renderer.redraw(state)
  update_visual_marks(state)

  -- Auto-advance cursor
  if auto_advance then
    vim.schedule(function()
      vim.cmd("normal! j")
    end)
  end
end

---Mark all files in current directory
---@param state Cfg.NeoTree.State
---@return nil
function M.mark_all_in_directory(state)
  local tree = state.tree
  if not tree then
    notify.warn("No tree available")
    return
  end

  local current = tree:get_node()
  if not current then
    notify.warn("No node under cursor")
    return
  end

  -- Find parent directory
  local parent = current.type == "directory" and current
    or tree:get_node(current:get_parent_id())

  ---@cast parent any

  if not parent then
    notify.warn("No parent directory found")
    return
  end

  -- Get children
  local children = tree:get_nodes(parent:get_id())
  if not children or #children == 0 then
    notify.warn("Directory is empty")
    return
  end

  -- Mark all files (not directories)
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
  update_visual_marks(state)

  notify.info(("Marked %d files"):format(count))
end

---Unmark all files in current directory
---@param state Cfg.NeoTree.State
---@return nil
function M.unmark_all_in_directory(state)
  local tree = state.tree
  if not tree then
    notify.warn("No tree available")
    return
  end

  local current = tree:get_node()
  if not current then
    notify.warn("No node under cursor")
    return
  end

  -- Find parent directory
  local parent = current.type == "directory" and current
    or tree:get_node(current:get_parent_id())

  if not parent then
    notify.warn("No parent directory found")
    return
  end

  -- Get children
  local children = tree:get_nodes(parent:get_id())
  if not children or #children == 0 then
    notify.warn("Directory is empty")
    return
  end

  -- Unmark all files
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
  update_visual_marks(state)

  notify.info(("Unmarked %d files"):format(count))
end

---Clear all marks globally
---@param state Cfg.NeoTree.State
---@return nil
function M.clear_all_marks(state)
  if state.explicitly_marked_node_ids then
    state.explicitly_marked_node_ids = {}

    renderer.redraw(state)
    update_visual_marks(state)

    notify.info("Cleared all marks")
  else
    notify.info("No marks to clear")
  end
end

-- ============================================================================
-- Batch Operations
-- ============================================================================

---Get marked nodes or current node
---@param state Cfg.NeoTree.State
---@return table[] nodes
---@nodiscard
function M.get_marked_or_current(state)
  local marks = state.explicitly_marked_node_ids or {}
  local nodes = {}

  -- Collect marked nodes
  if next(marks) then
    local tree = state.tree
    if tree then
      for node_id, _ in pairs(marks) do
        local node = tree:get_node(node_id)
        if node then
          table.insert(nodes, node)
        end
      end
    end
  end

  -- Fallback to current node
  if #nodes == 0 and state.tree then
    local current = state.tree:get_node()
    if current then
      return { current }
    end
  end

  return nodes
end

---Execute batch operation on marked nodes
---@param state Cfg.NeoTree.State
---@param operation fun(nodes: table[]): boolean, string|nil
---@param operation_name string
---@return boolean success
---@return string|nil message
function M.execute_batch(state, operation, operation_name)
  local nodes = M.get_marked_or_current(state)

  if #nodes == 0 then
    notify.warn("No nodes selected")
    return false, "No nodes selected"
  end

  notify.info(("Executing %s on %d node(s)..."):format(operation_name, #nodes))

  -- Execute operation
  local ok, msg = operation(nodes)

  -- Clear marks on success
  if ok and #nodes > 1 then
    state.explicitly_marked_node_ids = {}
    renderer.redraw(state)
    update_visual_marks(state)
  end

  return ok, msg
end

-- ============================================================================
-- Autocommands
-- ============================================================================

---Setup autocommands for mark persistence
function M.setup_autocommands()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "neo-tree",
    ---@diagnostic disable-next-line: unused-local
    callback = function(ev)
      -- Restore visual marks after refresh
      vim.schedule(function()
        local ok, state = pcall(require("neo-tree.sources.manager").get_state, "filesystem")
        if ok and state then
          update_visual_marks(state)
        end
      end)
    end,
  })
end

-- Initialize autocommands
M.setup_autocommands()

return M
