---@module 'autocmds.markdown'
--- Markdown-focused autocommands with modular gofile_cases.
--- Exposes `enable(cfg)` to wire features.

--- FIX: gf soll aus markdown raus, es funktioniert in allen ft

---@class MdAutoCmds
local M = {}

local api = vim.api

-- Helpers ---------------------------------------------------------------------

--- Create/clear a namespaced augroup.
--- @param name string
--- @return integer
local function augroup(name)
  return api.nvim_create_augroup("markdown_autocmds_" .. name, { clear = true })
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

-- Public API -----------------------------------------------------------------

--- Enable Markdown-related autocommands per feature.
--- @param cfg table|nil
function M.enable(cfg)
  local defaults = require("autocmds.markdown.defaults")
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(defaults), cfg or {})

  -- Verify config
  if cfg.goto_file and cfg.goto_file.debug then
    vim.notify("md-gf: debug enabled, config loaded", vim.log.levels.INFO, { title = "md-gf" })
  end

  -- 1) Buffer-local wrap mapping (unchanged)
  if cfg.wrap_key.enable then
    api.nvim_create_autocmd("FileType", {
      group = augroup("wrap_key"),
      pattern = norm_pattern(cfg.wrap_key.pattern),
      callback = function()
        local buf = api.nvim_get_current_buf()
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
          local row, col = unpack(api.nvim_win_get_cursor(0))
          vim.cmd("normal! ciw[" .. word .. "]()")
          local new_col = col + 2 + #word + 1
          api.nvim_win_set_cursor(0, { row, new_col })
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
    api.nvim_create_autocmd("FileType", {
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
          local dispatch_cases = require("autocmds.markdown.gofile_case_dispatcher")
          local node = ts_utils.get_node_at_cursor()
          local bufnr = api.nvim_get_current_buf()

          logger.debug("enable: gf invoked", {
            buf = bufnr,
            node_type = (node and pcall(function()
              return node:type()
            end) and node:type()),
          })

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
