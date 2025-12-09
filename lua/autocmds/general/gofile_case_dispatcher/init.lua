---@modules 'autocmds.general.gofile_case_dispatcher'

local logger_mod = require("autocmds.general.gofile_logger")
local resolve_tilde_helper = require("autocmds.general.gofile_cases.helper.resolve_tilde")
local normalize_helper = require("autocmds.general.gofile_cases.helper.normalize_path")

--- Central dispatcher: iterate ordered cases; allow cases to either:
---  - return true (handled), or
---  - return false, path_string (path to handle by dispatcher)
--- The dispatcher logs inputs and each case result.
--- If no case handles the input, try alternate resolution before final fallback.
--- @param node TSNode|nil
--- @param bufnr integer
--- @param ts_utils table
--- @param cfg table
--- @param cases table[] loaded case modules
--- @return boolean handled
return function(node, bufnr, ts_utils, cfg, cases)
  local logger = logger_mod(cfg)

  vim.notify("DISPATCHER: Starting with " .. #cases .. " cases", vim.log.levels.INFO)

  logger.debug("dispatcher:start", {
    bufnr = bufnr,
    node_type = (node and pcall(function()
      return node:type()
    end) and node:type()),
    cases_count = #cases,
  })

  -- Track the last attempted path for alternate resolution
  local last_attempted_path = nil

  for idx, case_mod in ipairs(cases) do
    local name = case_mod._NAME or ("case#" .. idx)
    logger.debug("dispatcher:invoke", { idx = idx, name = name })

    local ok, first_ret, second_ret = pcall(function()
      return case_mod.call(node, bufnr, cfg, ts_utils, logger)
    end)

    if not ok then
      logger.warn(("dispatcher: case %s errored"):format(name), { err = first_ret })
      goto continue
    end

    -- If case returned true directly (handled)
    if first_ret == true then
      logger.info(("dispatcher: case %s handled the input"):format(name), { name = name })
      return true
    end

    -- Extract path from either legacy single-string return or (false, path) style
    local returned_path = nil
    if type(first_ret) == "string" then
      returned_path = first_ret
    elseif first_ret == false and type(second_ret) == "string" then
      returned_path = second_ret
    end

    if returned_path then
      logger.debug("dispatcher: case returned path", { name = name, path = returned_path })

      -- Store original path for alternate resolution
      last_attempted_path = returned_path

      -- If path begins with "~/", attempt resolution/expansion before further handling.
      if returned_path:match("^~[/\\]") then
        logger.debug("dispatcher: path starts with ~/, attempting resolve_tilde", { path = returned_path })
        local resolved = resolve_tilde_helper(returned_path, logger)
        if resolved then
          logger.info("dispatcher: resolve_tilde succeeded", { original = returned_path, resolved = resolved })
          returned_path = resolved
          last_attempted_path = resolved
        else
          logger.debug("dispatcher: resolve_tilde failed, will continue with original path", { original = returned_path })
        end
      end

      -- Normalize path (convert modules, backslashes etc.)
      local normalized = normalize_helper(returned_path)
      last_attempted_path = normalized

      -- Try URL handler module first
      local url_mod = require("autocmds.general.gofile_cases.p3_url")
      local opened = url_mod.call(node, bufnr, cfg, ts_utils, logger, normalized)
      if opened then
        logger.info("dispatcher: url opened via url module", { path = normalized })
        return true
      end

      -- Try local file module (now returns false if file doesn't exist)
      local local_mod = require("autocmds.general.gofile_cases.p4_local")
      local handled = local_mod.call(node, bufnr, cfg, ts_utils, logger, normalized)
      if handled then
        logger.info("dispatcher: local file opened successfully", { path = normalized })
        return true
      end

      -- If we reach here, file doesn't exist - store full path for alternate
      local cwd = vim.fn.expand("%:p:h")
      if not normalized:match("^/") and not normalized:match("^[A-Za-z]:[/\\]") then
        last_attempted_path = vim.fn.fnamemodify(cwd .. "/" .. normalized, ":p")
      else
        last_attempted_path = vim.fn.fnamemodify(normalized, ":p")
      end

      logger.debug("dispatcher: file not found, stored path for alternate", { path = last_attempted_path })
    end

    -- Not handled, continue
    logger.debug(("dispatcher: case %s did not handle input"):format(name), { name = name })
    ::continue::
  end

  -- NEW: If no case matched, try extracting <cfile> as fallback
  if not last_attempted_path then
    local cfile = vim.fn.expand("<cfile>")
    if cfile and cfile ~= "" then
      logger.info("dispatcher: no case matched, using <cfile> fallback", { cfile = cfile })

      -- Normalize and resolve cfile
      local normalized = normalize_helper(cfile)
      local cwd = vim.fn.expand("%:p:h")

      if not normalized:match("^/") and not normalized:match("^[A-Za-z]:[/\\]") then
        last_attempted_path = vim.fn.fnamemodify(cwd .. "/" .. normalized, ":p")
      else
        last_attempted_path = vim.fn.fnamemodify(normalized, ":p")
      end

      logger.debug("dispatcher: cfile resolved to", { path = last_attempted_path })

      -- Try to open if exists
      local local_mod = require("autocmds.general.gofile_cases.p4_local")
      local handled = local_mod.call(node, bufnr, cfg, ts_utils, logger, normalized)
      if handled then
        logger.info("dispatcher: cfile opened successfully", { path = last_attempted_path })
        return true
      end

      -- File doesn't exist, last_attempted_path is already set for alternate
    end
  end

  -- If we have a path that failed to resolve, try alternate resolution
  if last_attempted_path then
    logger.info("dispatcher: attempting alternate resolution", { path = last_attempted_path })
    local alternate_mod = require("autocmds.general.gofile_alternate")
    local alternate_handled = alternate_mod(last_attempted_path, cfg, logger)
    if alternate_handled then
      logger.info("dispatcher: alternate resolution succeeded")
      return true
    end
  end

  logger.debug("dispatcher: no case matched and no alternate found")
  return false
end
