---@module 'autocmds.markdown.gofile_cases.p4_local'
--- Case 4: Treat path as a local file relative to buffer or absolute.
--- Opens the file via :edit and returns true.
local M = {}

--- @param node userdata|nil
--- @param bufnr integer
--- @param cfg table
--- @param ts_utils table
--- @param logger table
--- @param path_in string
--- @return boolean
function M.call(node, bufnr, cfg, ts_utils, logger, path_in)
  -- LSP requirement for 'unused-params'
  node = node
  bufnr = bufnr
  cfg = cfg
  ts_utils = ts_utils

  local path = path_in
  if not path or path == "" then
    if logger and logger.debug then
      logger.debug("p4_local: empty path")
    end
    return false
  end

  if logger and logger.debug then
    logger.debug("p4_local: initial path", { path = path })
  end

  local cwd = vim.fn.expand("%:p:h")
  if not path:match("^/") and not path:match("^[A-Za-z]:[\\/]") then
    path = cwd .. "/" .. path
    if logger and logger.debug then
      logger.debug("p4_local: combined relative with cwd", { cwd = cwd, path = path })
    end
  end

  local target = vim.fn.fnamemodify(path, ":p")
  if logger and logger.info then
    logger.info("p4_local: opening file", { target = target })
  end
  vim.cmd("edit " .. vim.fn.fnameescape(target))
  return true
end

return M
