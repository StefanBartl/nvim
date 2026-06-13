---@module 'config.neotree.commands.markdown.links'
--- Bridge between Neo-tree nodes and custom Markdown link generator.

local M = {}

local notify = require("lib.notify").create("[neo-tree.markdown]")
local node_utils = require("config.neotree.utils.node")

local markdown_links = require("custom.markdown.commands.markdown_links")

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

  markdown_links.run({ path })
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

  -- reuse CLI flag
  markdown_links.run({ "-r", path })
end

return M
