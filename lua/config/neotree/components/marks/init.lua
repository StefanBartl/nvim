---@module 'config.neotree.components.marks'
--- Custom component to display mark indicators in Neo-tree

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

--- Component function that shows mark indicator
---@param config table
---@param node table
---@param state table
---@return table
---@diagnostic disable-next-line: unused-local
function M.mark_indicator(config, node, state)
  if not state.explicitly_marked_node_ids then
    return {}
  end

  local is_marked = state.explicitly_marked_node_ids[node.id] ~= nil

  if not is_marked then
    return {}
  end

  return {
    text = get_mark_icon(),
    highlight = "NeoTreeMarked",
  }
end

return M
