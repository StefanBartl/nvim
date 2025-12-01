---@module 'autocmds.markdown.gofile_cases.p0_gopath'
--- Case 0: Attempt to resolve using user's gopath helper.
--- Contract: exports `call(node, bufnr, cfg, ts_utils, logger)` -> boolean [, path]
--- Return true if the case handled opening; false otherwise.
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

--- Try to resolve via gopath.resolve and open with synchronous open implementation.
--- This avoids relying on gopath.commands.resolve_and_open returning a truthy value.
--- @param node TSNode|nil
--- @param bufnr integer
--- @param cfg table
--- @param ts_utils table
--- @param logger table
--- @return boolean
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
    -- call with default opts (same as gopath.commands)
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

  -- If res.path is present and starts with ~, expand it (vim.fn.expand handles ~ and env vars).
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

  -- Use the synchronous open implementation for 'edit' (mirrors gopath.open.edit.open)
  local ok_open, open_err = pcall(function()
    local opener = require("gopath.open.edit")
    opener.open(res)
  end)

  if not ok_open then
    if logger and logger.warn then
      logger.warn("p0_gopath: open raised an error", { err = open_err, result = res })
    end
    return false
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

  -- If no buffer switch, still treat as handled if path exists on disk (best-effort)
  local stat_ok, st = pcall(vim.loop.fs_stat, res.path)
  if stat_ok and st then
    if logger and logger.info then
      logger.info("p0_gopath: opened file (no buffer switch detected but file exists)", { path = res.path })
    end
    return true
  end

  -- Not handled
  if logger and logger.debug then
    logger.debug("p0_gopath: did not handle input after open attempt", { before = before, after = after, path = res.path })
  end
  return false
end

return M
