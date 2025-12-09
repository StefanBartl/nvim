---@module 'autocmds.general.gofile_cases.p1_inline'
--- Case 1: Resolve inline link destinations, e.g. [text](dest).
--- Returns boolean, path (path returned if not opened directly).
local M = {}

local find_parent = require("autocmds.general.gofile_cases.helper.find_parent")
local ts_text = function(node, bufnr)
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  return ok and text or nil
end

--- @param node TSNode|nil
--- @param bufnr integer
--- @param cfg table
--- @param ts_utils table
--- @param logger table
--- @return boolean, string|nil
function M.call(node, bufnr, cfg, ts_utils, logger)
  -- LSP requirement for 'unused-params'
  cfg = cfg
  ts_utils = ts_utils

  if logger and logger.debug then
    logger.debug("p1_inline: entering", { node_type = (node and node:type()) })
  end

  local dest = find_parent(node, { "link_destination" })
  if dest and dest:type() == "link_destination" then
    local path = ts_text(dest, bufnr)
    if logger and logger.info then
      logger.info("p1_inline: found inline destination", { path = path })
    end
    return false, path
  end

  if logger and logger.debug then
    logger.debug("p1_inline: no inline link destination found")
  end
  return false
end

return M
