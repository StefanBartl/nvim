---@module 'autocmds.general.gofile_cases.p3_url'
--- Case 3: Handle URL-like targets. Attempts to open via system opener.
--- Returns true if opened, false otherwise.

require("@tyoes.tsnode")

local M = {}

local function is_url_like(s)
  if not s or s == "" then
    return false
  end
  if s:match("^https?://") or s:match("^file://") then
    return true
  end
  if s:match("^www%.") then
    return true
  end
  if s:match("^[A-Za-z0-9%-_]+%.[A-Za-z]+") then
    return true
  end
  return false
end

local function open_url(url, cfg)
  local opener ---@type string[]|nil

  if vim.fn.has("macunix") == 1 then
    opener = cfg.open_cmd_mac or { "open", url }
  elseif vim.fn.has("unix") == 1 then
    opener = cfg.open_cmd_unix or { "xdg-open", url }
  elseif cfg.enable_windows_opener and vim.fn.has("win32") == 1 then
    opener = { "cmd.exe", "/c", "start", "", url }
  end

  if not opener then
    return false
  end

  for i, v in ipairs(opener) do
    if v == "<url>" then
      opener[i] = url
    end
  end

  vim.fn.jobstart(opener, { detach = true })
  return true
end

--- @param node TSNode|nil
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
  ts_utils = ts_utils

  local path = path_in
  if not path then
    if logger and logger.debug then
      logger.debug("p3_url: no path provided")
    end
    return false
  end

  if is_url_like(path) then
    -- Auto prefix if needed
    if path:match("^www%.") or (not path:match("^%w[%w+.-]*:") and path:match("^[A-Za-z0-9%-_]+%.[A-Za-z]+")) then
      path = "http://" .. path
      if logger and logger.debug then
        logger.debug("p3_url: applied http prefix", { path = path })
      end
    end

    if open_url(path, cfg.goto_file) then
      if logger and logger.info then
        logger.info("p3_url: opened URL", { path = path })
      end
      return true
    end

    if logger and logger.warn then
      logger.warn("p3_url: open attempt failed", { path = path })
    end
    return false
  end

  if logger and logger.debug then
    logger.debug("p3_url: path not url-like", { path = path })
  end
  return false
end

return M
