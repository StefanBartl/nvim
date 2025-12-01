---@module 'autocmds.markdown.gofile_cases.helper.resolve_tilde'
--- Helper: resolve leading ~ in a path.
--- Behavior:
---  1. If path starts with "~/", expand to user's home directory and return if the file exists.
---  2. If expanded path does not exist, try to locate the target under the home directory using `fd`, then `rg`, then `find` (in that order).
---  3. Return the first found absolute path or nil if nothing could be resolved.
--- Notes:
---  - This helper uses shell utilities when available; it falls back gracefully if they are not present.
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

local function _run_cmd_capture(cmd)
  -- Use vim.fn.systemlist which is portable across platforms supported by Neovim.
  -- Return nil on errors or empty results.
  local ok = pcall(vim.fn.systemlist, cmd)
  if not ok then
    return nil
  end
  local out = vim.fn.systemlist(cmd)
  if not out or #out == 0 then
    return nil
  end
  return out
end

local function _find_with_fd(name, home, logger)
  -- prefer fd if available: fd -HI --hidden --type f -g <pattern>
  local cmd = string.format('fd -HI --type f -g "%s" %s 2>/dev/null', name, vim.fn.shellescape(home))
  if logger and logger.debug then
    logger.debug("resolve_tilde: trying fd", { cmd = cmd })
  end
  return _run_cmd_capture(cmd)
end

local function _find_with_rg(name, home, logger)
  -- ripgrep has --files and globbing -- use a simple find-like approach
  -- We try: rg --hidden --files -g <name> <home>
  local cmd = string.format('rg --hidden --files -g "%s" %s 2>/dev/null', name, vim.fn.shellescape(home))
  if logger and logger.debug then
    logger.debug("resolve_tilde: trying rg", { cmd = cmd })
  end
  return _run_cmd_capture(cmd)
end

local function _find_with_find(name, home, logger)
  -- POSIX find fallback; may be slow on large home dirs.
  local cmd = string.format('find %s -type f -name "%s" 2>/dev/null', vim.fn.shellescape(home), name)
  if logger and logger.debug then
    logger.debug("resolve_tilde: trying find", { cmd = cmd })
  end
  return _run_cmd_capture(cmd)
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

  local home = uv.os_homedir()
  if not home or home == "" then
    if logger and logger.warn then
      logger.warn("resolve_tilde: could not determine home directory")
    end
    return nil
  end

  -- Expand ~ to HOME
  local expanded = path:gsub("^~", home)
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

  -- Try fd -> rg -> find
  local probes = {
    _find_with_fd,
    _find_with_rg,
    _find_with_find,
  }

  for _, probe in ipairs(probes) do
    local res = probe(name, home, logger)
    if res and #res > 0 then
      -- Prefer the first result that is under the expanded parent path (best-effort)
      for _, candidate in ipairs(res) do
        if type(candidate) == "string" and candidate ~= "" then
          -- If candidate is relative, convert to absolute (system cmds return absolute usually).
          local cand = candidate
          -- Validate existence
          if _file_exists(cand) then
            if logger and logger.info then
              logger.info("resolve_tilde: search found candidate", { candidate = cand })
            end
            return cand
          end
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
