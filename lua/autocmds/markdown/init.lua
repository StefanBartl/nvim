---@module 'autocmds.markdown'
--- Markdown-focused autocommands with modular gofile_cases.
--- Exposes `enable(cfg)` to wire features.
---@class MdAutoCmds
local M = {}

-- Helpers ---------------------------------------------------------------------

--- Create/clear a namespaced augroup.
--- @param name string
--- @return integer
local function augroup(name)
  return vim.api.nvim_create_augroup("markdown_autocmds_" .. name, { clear = true })
end

--- Normalize a FileType autocmd pattern field.
--- @param pat any
--- @return string|string[]
local function norm_pattern(pat)
  if pat == nil then
    return "markdown"
  end
  return pat
end

-- Dispatcher & Wiring --------------------------------------------------------

local gofile_loader = require("autocmds.markdown.gofile_cases")
local logger_mod = require("autocmds.markdown.gofile_logger")

local resolve_tilde_helper = require("autocmds.markdown.gofile_cases.helper.resolve_tilde")
local normalize_helper = require("autocmds.markdown.gofile_cases.helper.normalize_path")

--- Central dispatcher: iterate ordered cases; allow cases to either:
---  - return true (handled), or
---  - return false, path_string (path to handle by dispatcher)
--- The dispatcher logs inputs and each case result.
--- @param node TSNode|nil
--- @param bufnr integer
--- @param ts_utils table
--- @param cfg table
--- @param cases table[] loaded case modules
--- @return boolean handled
local function dispatch_cases(node, bufnr, ts_utils, cfg, cases)
  local logger = logger_mod(cfg)

  logger.debug("dispatcher:start", { bufnr = bufnr, node_type = (node and pcall(function() return node:type() end) and node:type()) })

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

      -- If path begins with "~/", attempt resolution/expansion before further handling.
      if returned_path:match("^~[/\\]") then
        logger.debug("dispatcher: path starts with ~/, attempting resolve_tilde", { path = returned_path })
        local resolved = resolve_tilde_helper(returned_path, logger)
        if resolved then
          logger.info("dispatcher: resolve_tilde succeeded", { original = returned_path, resolved = resolved })
          returned_path = resolved
        else
          logger.debug("dispatcher: resolve_tilde failed, will continue with original path", { original = returned_path })
          -- keep returned_path as-is and continue to normal handling; dispatcher may try URL/local handling
        end
      end

      -- Normalize path (convert modules, backslashes etc.)
      local normalized = normalize_helper(returned_path)

      -- Try URL handler module first
      local url_mod = require("autocmds.markdown.gofile_cases.p3_url")
      local opened = url_mod.call(node, bufnr, cfg, ts_utils, logger, normalized)
      if opened then
        logger.info("dispatcher: url opened via url module", { path = normalized })
        return true
      end

      -- Otherwise treat as local file
      local local_mod = require("autocmds.markdown.gofile_cases.p4_local")
      local_mod.call(node, bufnr, cfg, ts_utils, logger, normalized)
      return true
    end

    -- Not handled, continue
    logger.debug(("dispatcher: case %s did not handle input"):format(name), { name = name })
    ::continue::
  end

  logger.debug("dispatcher: no case matched")
  return false
end

-- Public API -----------------------------------------------------------------

--- Enable Markdown-related autocommands per feature.
--- @param cfg table|nil
function M.enable(cfg)
  local defaults = require("autocmds.markdown.defaults")
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(defaults), cfg or {})

  -- 1) Buffer-local wrap mapping (unchanged)
  if cfg.wrap_key.enable then
    vim.api.nvim_create_autocmd("FileType", {
      group = augroup("wrap_key"),
      pattern = norm_pattern(cfg.wrap_key.pattern),
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if cfg.wrap_key.only_modifiable ~= false and not vim.bo[buf].modifiable then
          vim.notify("Markdown wrap: buffer is not modifiable", vim.log.levels.WARN)
          return
        end

        local key = cfg.wrap_key.key
        local description = cfg.wrap_key.description

        local handler = function()
          if vim.bo.filetype ~= "markdown" then
            return
          end
          local word = vim.fn.expand("<cword>")
          if not word or word == "" then
            return
          end
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          vim.cmd("normal! ciw[" .. word .. "]()")
          local new_col = col + 2 + #word + 1
          vim.api.nvim_win_set_cursor(0, { row, new_col })
        end

        vim.keymap.set("n", key or "<leader>[", handler, {
          desc = description,
          buffer = buf,
          noremap = true,
          silent = true,
        })
      end,
      desc = "Markdown: buffer-local keymap to wrap <cword> as [word]()",
    })
  end

  -- 2) Markdown-aware gf override with modular cases
  if cfg.goto_file.enable then
    vim.api.nvim_create_autocmd("FileType", {
      group = augroup("goto_file"),
      pattern = norm_pattern(cfg.goto_file.pattern),
      callback = function()
        -- Validate Treesitter availability; otherwise, keep default behavior.
        local ok_ts = pcall(require, "nvim-treesitter.ts_utils")
        if not ok_ts then
          return
        end
        local ts_utils = require("nvim-treesitter.ts_utils")

        -- Preload ordered case modules
        local cases = gofile_loader.load_ordered_cases(cfg)
        local logger = logger_mod(cfg)

        vim.keymap.set("n", "gf", function()
          local node = ts_utils.get_node_at_cursor()
          local bufnr = vim.api.nvim_get_current_buf()

          logger.debug("enable: gf invoked", { buf = bufnr, node_type = (node and pcall(function() return node:type() end) and node:type()) })

          local handled = dispatch_cases(node, bufnr, ts_utils, cfg, cases)
          if not handled then
            logger.info("enable: falling back to builtin gf")
            vim.cmd("normal! gf")
          end
        end, { buffer = true, desc = "Markdown-aware gf with modular resolver" })
      end,
      desc = "Markdown: override gf to follow links/URLs with fallback",
    })
  end
end

return M
