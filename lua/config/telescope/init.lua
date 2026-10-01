---@module 'config.telescope'
--- Modularized Telescope setup.
--- History is owned by pickers.nvim (history.fzf_scope = "patch" in its setup()),
--- which patches telescope's defaults.history itself — see StefanBartl/pickers.nvim.
--- Preview-scroll (<PageUp>/<PageDown>) and history-nav (<C-p>/<C-n>) keys are
--- also owned by pickers.nvim (lua/pickers/keys/), patched globally into
--- telescope's defaults.mappings — do not rebind them here, see
--- pickers.nvim's docs/KEYMAPS.md. Horizontal preview scroll
--- (<M-Left>/<M-Right>) is configured via pickers.setup({ keys = {
--- preview_scroll_left/right = ... } }) in plugins/personal/specs/navigate.lua, same
--- reason. This module merges the `?` -> which_key mapping (core telescope.actions,
--- not tied to any extension -- the `config.telescope.file_browser.keymaps` path
--- predates telescope-file-browser.nvim's removal, 2026-10-01) into
--- defaults.mappings, sets UI highlights, and loads extensions safely.

local M = {}

local actions = require("telescope.actions")
local fb_keymaps = require("config.telescope.file_browser.keymaps")

local notify = require("lib.nvim.notify").create("[telescope.cfg]")

-- Returns merged default options for telescope.setup
---@return table opts
function M.defaults()
  -- pickers.nvim patches its entry actions (create_file/open_background/
  -- cheatsheet/path_copy) into defaults.mappings itself.
  local km = fb_keymaps.get(actions)

  return {
    -- file_ignore_patterns: patched in by pickers.nvim (`find.exclude`).
    -- sorting_strategy / prompt position / cycling: pickers.nvim `display.*`.
    -- path shortening: pickers.nvim `display.path_adaptive`.
    -- PDF text preview: pickers.nvim `images.pdf_text`.
    mappings = km,
  }
end

-- Returns extension configuration table. telescope-file-browser.nvim's own
-- `file_browser = {...}` opts left on 2026-10-01 with the plugin itself --
-- its only caller (<leader>,) was never used, see plugins/telescope.lua.
---@return table extensions
function M.extensions()
  return {}
end

-- Returns list of extensions to load
---@return string[] extensions
function M.extensions_list()
  return { "fzf" }
end

-- Apply Telescope setup
---@param opts table|nil optional override options
---@return table opts effective options
function M.setup(opts)
  opts = opts or {}
  local telescope = require("telescope")

  -- Merge defaults and extensions
  opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, M.defaults())
  opts.extensions = vim.tbl_deep_extend("force", opts.extensions or {}, M.extensions())
  opts.extensions_list = opts.extensions_list or M.extensions_list()

  telescope.setup(opts)

  -- Load extensions safely
  for _, ext in ipairs(opts.extensions_list or {}) do
    local ok, err = pcall(telescope.load_extension, ext)
    if not ok then
      notify.warn(string.format("Failed to load telescope extension '%s': %s", ext, err))
    end
  end

  return opts
end

return M
