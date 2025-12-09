---@module 'autocmds.general.gofile_cases.p0_gopath'
--- Case 0: Attempt to resolve using user's gopath helper.
--- Contract: exports `call(node, bufnr, cfg, ts_utils, logger)` -> boolean [, path]
--- Return true if the case handled opening; false, path if path was found but not opened.

local M = {}

--- Safe helper: get canonical buffer name for comparison
local function _current_bufname()
  local buf = vim.api.nvim_get_current_buf()
  local ok, name = pcall(vim.api.nvim_buf_get_name, buf)
  if not ok then
    return nil
  end
  if name == "" then
    return nil
  end
  return name
end

--- Check if file exists at given path
---@param path string
---@return boolean
local function _file_exists(path)
  if not path or path == "" then
    return false
  end
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil and stat.type == "file"
end

--- Try to resolve via gopath.resolve and open with synchronous open implementation.
--- @param node TSNode|nil
--- @param bufnr integer
--- @param cfg table
--- @param ts_utils table
--- @param logger table
--- @return boolean success True if file was opened
--- @return string|nil path Path if found but not opened
function M.call(node, bufnr, cfg, ts_utils, logger)
  -- LSP requirement for 'unused-params'
  cfg = cfg
  ts_utils = ts_utils

  -- Debug context
  if logger and logger.debug then
    local ntype = nil
    pcall(function() ntype = node and node:type() end)
    logger.debug("p0_gopath: called", { node_type = ntype, bufnr = bufnr })
  end

  -- Snapshot buffer name before resolution
  local before = _current_bufname()

  -- Attempt to call resolver directly so we can inspect result
  local ok_resolve, res, err = pcall(function()
    local resolve = require("gopath.resolve")
    return resolve.resolve_at_cursor({})
  end)

  if not ok_resolve then
    if logger and logger.warn then
      logger.warn("p0_gopath: resolver raised an error", { err = res })
    end
    return false
  end

  -- `res` may be nil and `err` a string per gopath.resolve API
  if not res then
    if logger and logger.debug then
      logger.debug("p0_gopath: no result from resolver", { err = err })
    end
    return false
  end

  -- If res.path is present and starts with ~, expand it
  if type(res.path) == "string" and res.path:match("^~[/\\]") then
    local expanded = vim.fn.expand(res.path)
    if expanded and expanded ~= "" then
      if logger and logger.debug then
        logger.debug("p0_gopath: expanded tilde in path", { original = res.path, expanded = expanded })
      end
      res.path = expanded
    else
      if logger and logger.debug then
        logger.debug("p0_gopath: expand returned empty, keeping original path", { original = res.path })
      end
    end
  end

  -- If path still empty or nil, bail out
  if not (res.path and res.path ~= "") then
    if logger and logger.warn then
      logger.warn("p0_gopath: resolved result has no path", { result = res })
    end
    return false
  end

  -- Check if file exists BEFORE attempting to open
  if not _file_exists(res.path) then
    if logger and logger.debug then
      logger.debug("p0_gopath: resolved path does not exist, returning path for dispatcher", { path = res.path })
    end
    -- Return path for dispatcher to handle (e.g., alternate resolution)
    return false, res.path
  end

  -- Use the synchronous open implementation for 'edit'
  local ok_open, open_err = pcall(function()
    local opener = require("gopath.open.edit")
    opener.open(res)
  end)

  if not ok_open then
    if logger and logger.warn then
      logger.warn("p0_gopath: open raised an error", { err = open_err, result = res })
    end
    return false, res.path
  end

  -- Snapshot after call
  local after = _current_bufname()

  -- If buffer changed -> success
  if after and after ~= before then
    if logger and logger.info then
      logger.info("p0_gopath: handled (buffer switched)", { before = before, after = after, path = res.path })
    end
    return true
  end

  -- If we reach here, file exists but buffer didn't change (unusual case)
  if logger and logger.info then
    logger.info("p0_gopath: file opened (no buffer switch detected)", { path = res.path })
  end
  return true
end

return M
