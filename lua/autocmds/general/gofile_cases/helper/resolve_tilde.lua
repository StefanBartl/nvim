---@module 'autocmds.general.gofile_cases.helper.resolve_tilde'
--- Helper: resolve leading ~ in a path.
--- Behavior:
---  1. If path starts with "~/", expand to user's home directory and return if the file exists.
---  2. If expanded path does not exist, try to locate the target under the home directory using `fd`, then `rg`, then `find` (in that order).
---  3. Return the first found absolute path or nil if nothing could be resolved.
--- Notes:
---  - This helper uses shell utilities when available; it falls back gracefully if they are not present.
---  - Cross-platform compatible (Linux, macOS, Windows)
---  - Caller should provide a logger table to receive debug/info/warn messages.
--- @return string|nil resolved_absolute_path

local uv = vim.loop

local function _file_exists(p)
  if type(p) ~= "string" or p == "" then
    return false
  end
  local st = uv.fs_stat(p)
  return st ~= nil
end

--- Detect if running on Windows
---@return boolean
local function _is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

--- Build null device path for stderr redirect (cross-platform)
---@return string
local function _null_device()
  return _is_windows() and "NUL" or "/dev/null"
end

--- Execute command and capture output (cross-platform safe)
---@param cmd string
---@return string[]|nil
local function _run_cmd_capture(cmd)
  local ok, out = pcall(vim.fn.systemlist, cmd)
  if not ok or not out or #out == 0 then
    return nil
  end
  -- Filter out empty lines
  local filtered = {}
  for _, line in ipairs(out) do
    if line and line ~= "" then
      table.insert(filtered, line)
    end
  end
  return #filtered > 0 and filtered or nil
end

local function _find_with_fd(name, home, logger)
  local null = _null_device()
  local cmd = string.format('fd -HI --type f -g "%s" "%s" 2>%s', name, home, null)
  if logger and logger.debug then
    logger.debug("resolve_tilde: trying fd", { cmd = cmd })
  end
  return _run_cmd_capture(cmd)
end

local function _find_with_rg(name, home, logger)
  local null = _null_device()
  local cmd = string.format('rg --hidden --files -g "%s" "%s" 2>%s', name, home, null)
  if logger and logger.debug then
    logger.debug("resolve_tilde: trying rg", { cmd = cmd })
  end
  return _run_cmd_capture(cmd)
end

local function _find_with_find(name, home, logger)
  local null = _null_device()
  local cmd
  if _is_windows() then
    -- Windows: use `where` or PowerShell Get-ChildItem
    -- Simple fallback: use vim.fn.glob which works cross-platform
    if logger and logger.debug then
      logger.debug("resolve_tilde: using vim.fn.glob on Windows", { name = name, home = home })
    end
    local pattern = home .. "/**/" .. name
    local results = vim.fn.glob(pattern, false, true)
    return results and #results > 0 and results or nil
  else
    -- Unix: use find command
    cmd = string.format('find "%s" -type f -name "%s" 2>%s', home, name, null)
    if logger and logger.debug then
      logger.debug("resolve_tilde: trying find", { cmd = cmd })
    end
    return _run_cmd_capture(cmd)
  end
end

--- Main resolve function
--- @param path string
--- @param logger table|nil
--- @return string|nil
local function resolve_tilde(path, logger)
  if type(path) ~= "string" then
    return nil
  end

  -- Quick exit if no leading ~/
  if not path:match("^~[/\\]") then
    return nil
  end

  ---@diagnostic disable-next-line lib.uv
  local home = uv.os_homedir()
  if not home or home == "" then
    if logger and logger.warn then
      logger.warn("resolve_tilde: could not determine home directory")
    end
    return nil
  end

  -- Expand ~ to HOME (handle both / and \ separators)
  local separator = path:match("^~([/\\])")
  local expanded = home .. separator .. path:sub(3)

  if _file_exists(expanded) then
    if logger and logger.info then
      logger.info("resolve_tilde: expanded path exists", { original = path, expanded = expanded })
    end
    return expanded
  end

  if logger and logger.debug then
    logger.debug("resolve_tilde: expanded path does not exist, attempting search", { expanded = expanded })
  end

  -- Derive filename to search for
  local name = expanded:match("([^/\\]+)$")
  if not name or name == "" then
    if logger and logger.debug then
      logger.debug("resolve_tilde: no filename extracted for search", { expanded = expanded })
    end
    return nil
  end

  -- Try fd -> rg -> find/glob
  local probes = {
    _find_with_fd,
    _find_with_rg,
    _find_with_find,
  }

  for _, probe in ipairs(probes) do
    local res = probe(name, home, logger)
    if res and #res > 0 then
      -- Return first valid result
      for _, candidate in ipairs(res) do
        if type(candidate) == "string" and candidate ~= "" and _file_exists(candidate) then
          if logger and logger.info then
            logger.info("resolve_tilde: search found candidate", { candidate = candidate })
          end
          return candidate
        end
      end
    end
  end

  if logger and logger.debug then
    logger.debug("resolve_tilde: no candidate found via search for", { name = name })
  end

  return nil
end

return resolve_tilde
