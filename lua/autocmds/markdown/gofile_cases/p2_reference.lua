---@module 'autocmds.markdown.gofile_cases.p2_reference'
--- Case 2: Resolve reference-style links [label] and find definition lines in the same buffer.
--- Returns boolean, path
local M = {}

local find_parent = require("autocmds.markdown.gofile_cases.helper.find_parent")
local ts_text = function(node, bufnr)
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  return ok and text or nil
end

--- Search buffer lines for a reference definition like: [label]: dest
--- @param label string
--- @param bufnr integer
--- @return string|nil
local function find_reference_target(label, bufnr)
  local total = vim.api.nvim_buf_line_count(bufnr)
  for lnum = 1, total do
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
    if line then
      local pat = "^%[" .. vim.pesc(label) .. "%]%s*:%s*(.+)$"
      local m = line:match(pat)
      if m then
        return m
      end
    end
  end
  return nil
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
    logger.debug("p2_reference: entering", { node_type = (node and node:type()) })
  end

  local ref = find_parent(node, { "link_reference" })
  if not ref then
    if logger and logger.debug then
      logger.debug("p2_reference: no reference node found")
    end
    return false
  end

  local label = ts_text(ref, bufnr) or ""
  label = label:gsub("^%[", ""):gsub("%]$", "")
  if logger and logger.info then
    logger.info("p2_reference: reference label detected", { label = label })
  end

  local target = find_reference_target(label, bufnr)
  if target then
    if logger and logger.info then
      logger.info("p2_reference: found reference target", { target = target })
    end
    return false, target
  end

  if logger and logger.debug then
    logger.debug("p2_reference: no reference definition found in buffer", { label = label })
  end
  return false
end

return M
