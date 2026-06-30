---@module 'config.neotree.components.marks'
---@brief Mark indicator component for Neo-tree

local M = {}

--- Get mark icon/indicator
---@return string
local function get_mark_icon()
  if vim.g.have_nerd_font or vim.fn.has("gui_running") == 1 then
    return "✓ " -- Check mark with space
  else
    return "* " -- Asterisk with space
  end
end

--- Mark indicator component for Neo-tree renderer
---@param config table Component config
---@param node Cfg.NeoTree.Node
---@param state Cfg.NeoTree.State
---@return table
---@diagnostic disable-next-line: unused-local
function M.mark_indicator(config, node, state)
  local marks = state.explicitly_marked_node_ids or {}
  local is_marked = marks[node.id] ~= nil

  if is_marked then
    return {
      text = get_mark_icon(),
      highlight = "NeoTreeMarked",
    }
  end

  -- Empty space to maintain alignment
  return {
    text = "  ",
    highlight = "NeoTreeIndent",
  }
end

--- Attach mark component to Neo-tree options
---@param opts table Neo-tree setup options
---@return table Modified options
function M.attach(opts)
  opts = opts or {}

  -- Ensure filesystem table exists
  opts.filesystem = opts.filesystem or {}
  opts.filesystem.components = opts.filesystem.components or {}

  -- Add mark indicator component
  opts.filesystem.components.mark_indicator = function(config, node, state)
    return M.mark_indicator(config, node, state)
  end

  -- Update renderers
  opts.filesystem.renderers = opts.filesystem.renderers or {}

  -- File renderer
  opts.filesystem.renderers.file = {
    { "indent" },
    { "icon" },
    { "mark_indicator" },
    { "name", use_git_status_colors = true },
    { "git_status" },
  }

  -- Directory renderer
  opts.filesystem.renderers.directory = {
    { "indent" },
    { "icon" },
    { "mark_indicator" },
    { "current_filter" },
    { "name" },
    { "git_status" },
  }

  return opts
end

return M

