---@module 'wkdnvchad.config.statusline.custom'
--- Enhanced custom statusline with button-style segments

local lazy = require("lib.lazy")
local render_module = lazy.require("wkdnvchad.ui.statusline.cursor_ctl.renderer")
local progr_calc_module = lazy.require("wkdnvchad.ui.statusline.cursor_ctl.progress_calculators")
local hl_module = lazy.require("wkdnvchad.ui.statusline.modules.highlighting")
local lsp_module = lazy.require("wkdnvchad.ui.statusline.modules.lsp")
local cursor_module = lazy.require("wkdnvchad.ui.statusline.cursor_ctl")

local M = {}

-- ============================================================================
-- Helper: Button-style segment wrapper
-- ============================================================================

---@param group string Highlight group
---@param content string Segment content
---@param icon string|nil Optional icon
---@return string
local function button_segment(group, content, icon)
  if not content or content == "" then
    return ""
  end

  local sep_left = "" -- Nerd Font:
  local sep_right = "" -- Nerd Font:

  local parts = {}

  -- Opening separator with background
  parts[#parts + 1] = "%#" .. group .. "Sep#" .. sep_left

  -- Content with icon
  parts[#parts + 1] = "%#" .. group .. "#"
  if icon then
    parts[#parts + 1] = " " .. icon .. " "
  else
    parts[#parts + 1] = " "
  end
  parts[#parts + 1] = content .. " "

  -- Closing separator
  parts[#parts + 1] = "%#" .. group .. "Sep#" .. sep_right

  return table.concat(parts, "")
end

-- ============================================================================
-- Module Configuration
-- ============================================================================

M.ui = {
  statusline = {
    theme = "vscode_colored",

    order = {
      "mode",
      "git",
      "%=",
      "breadcrumbs",
      "%=",
      "diagnostics",
      "lsp",
      "cursor",
    },

    modules = {
      --- Mode indicator with button style
      --- @return string
      mode = function()
        local ok_utils, utils = pcall(require, "nvchad.stl.utils")
        if not ok_utils then
          return ""
        end

        local m = vim.api.nvim_get_mode().mode
        local mode_name = (utils.modes[m] and utils.modes[m][1]) or "NORMAL"
        local mode_group = (utils.modes[m] and utils.modes[m][2]) or "Normal"

        return button_segment("St_" .. mode_group .. "mode", mode_name)
      end,

      --- Git status with button style
      --- @return string
      git = function()
        local ok_utils, utils = pcall(require, "nvchad.stl.utils")
        if not ok_utils then
          return ""
        end

        local git_status = utils.git()
        if not git_status or git_status == "" then
          return ""
        end

        -- Extract content without existing highlights
        local content = hl_module.stl_strip_hl(git_status)
        return button_segment("St_gitIcons", content, "")
      end,

      --- LSP-aware breadcrumbs with enhanced styling
      --- @return string
      breadcrumbs = function()
        local band = lsp_module.mode_band_group()
        local content = lsp_module.render_breadcrumbs_inherit_lspfirst(band)

        if not content or content == "" then
          return ""
        end

        -- Breadcrumbs use mode band coloring
        return hl_module.hl_open(band) .. " " .. content .. " "
      end,

      --- Diagnostics with button style
      --- @return string
      diagnostics = function()
        local ok_utils, utils = pcall(require, "nvchad.stl.utils")
        if not ok_utils then
          return ""
        end

        local diag = utils.diagnostics()
        if not diag or diag == "" then
          return ""
        end

        local content = hl_module.stl_strip_hl(diag)
        local band = hl_module.mode_band_group()

        return button_segment(band, content)
      end,

      --- LSP status with button style
      --- @return string
      lsp = function()
        local ok_utils, utils = pcall(require, "nvchad.stl.utils")
        if not ok_utils then
          return ""
        end

        local lsp_status = utils.lsp()
        if not lsp_status or lsp_status == "" then
          return ""
        end

        local content = hl_module.stl_strip_hl(lsp_status)
        local band = hl_module.mode_band_group()

        return button_segment(band, content, "")
      end,

      --- Cursor with progress (button style)
      --- @return string
      cursor = function()
        local band = hl_module.mode_band_group()
        local mode = cursor_module.get_mode()

        if mode == "off" then
          return ""
        end

        local pieces = { render_module.cursor_classic() }

        if mode == "row_progress" then
          pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_row_pct(), "R")
        elseif mode == "col_progress" then
          pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_col_pct(), "C")
        elseif mode == "rows_cols_progress" then
          pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_row_pct(), "R")
          pieces[#pieces + 1] = render_module.pct_token(progr_calc_module.compute_col_pct(), "C")
        end

        local content = table.concat(pieces, "")
        return button_segment(band, content, "")
      end,
    },
  },
}

-- ============================================================================
-- Highlight Groups Setup
-- ============================================================================

---@param config table
function M.setup(config)
  -- Define separator highlights for button effect
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("WkdNvChadCustomStl", { clear = true }),
    callback = function()
      -- Get base colors
      local colors = dofile(vim.g.base46_cache .. "colors") or {}

      -- Define separator highlights
      local groups = {
        "St_Normalmode",
        "St_Insertmode",
        "St_Visualmode",
        "St_Replacemode",
        "St_Confirmmode",
        "St_Commandmode",
        "St_Terminalmode",
        "St_gitIcons",
        "St_cwd",
      }

      for _, group in ipairs(groups) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
        if ok and hl and hl.bg then
          vim.api.nvim_set_hl(0, group .. "Sep", {
            fg = hl.bg,
            bg = colors.statusline_bg or colors.black,
          })
        end
      end
    end,
    desc = "Setup statusline separator highlights",
  })

  -- Trigger initial setup
  vim.cmd("doautocmd ColorScheme")
end

return M
