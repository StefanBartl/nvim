---@module 'config.neotree.commands.markdown.links'
--- Bridge between Neo-tree nodes and custom Markdown link generator.

local M = {}

local notify = require("lib.nvim.notify").create("[neo-tree.markdown]")
local node_utils = require("config.neotree.utils.node")

--- Convert node into markdown links (non-recursive)
---@param state Cfg.NeoTree.State
function M.from_node(state)
  local node = node_utils.get_current(state)

  if not node then
    notify.warn("No node under cursor")
    return
  end

  local path = node_utils.get_path(node)

  if not path or path == "" then
    notify.warn("Invalid node path")
    return
  end

  require("markdown_nvim.commands.markdown_links").run({ path })
end

--- Convert node into markdown links (recursive)
---@param state Cfg.NeoTree.State
function M.from_node_recursive(state)
  local node = node_utils.get_current(state)

  if not node then
    notify.warn("No node under cursor")
    return
  end

  local path = node_utils.get_path(node)

  if not path or path == "" then
    notify.warn("Invalid node path")
    return
  end

  require("markdown_nvim.commands.markdown_links").run({ "-r", path })
end

--- Generate markdown links for all explicitly marked nodes.
--- Falls back to current node when no marks are set.
---@param state Cfg.NeoTree.State
function M.from_marked_nodes(state)
  local marks = state.explicitly_marked_node_ids

  if not marks or vim.tbl_isempty(marks) then
    notify.info("No marked nodes — using current node")
    M.from_node(state)
    return
  end

  local paths = {}
  for node_id, _ in pairs(marks) do
    table.insert(paths, node_id)
  end
  table.sort(paths)

  local md_links = require("markdown_nvim.commands.markdown_links")
  local clipboard = require("markdown_nvim.util.clipboard")

  local result = md_links.for_paths(paths)
  if result == "" then
    notify.warn("No links generated for marked nodes")
    return
  end

  clipboard.copy(result)
  print(result)
  notify.info(string.format("%d node(s) → links copied to clipboard", #paths))

  require("config.neotree.commands.mark").clear_all_marks(state)
end

return M
