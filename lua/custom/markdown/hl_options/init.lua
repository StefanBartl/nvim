---@module 'custom.markdown.hl_options'
--- Orchestrates all Markdown-specific highlight groups.
--- Owns the shared augroup; delegates autocmd registration to each hl_group module.

local M = {}

local blockquote = require("custom.markdown.hl_options.hl_groups.blockquote")
-- -- TODO: Implement?
-- local headings   = require("custom.markdown.hl_options.hl_groups.headings")
-- local code       = require("custom.markdown.hl_options.hl_groups.code")
-- local links      = require("custom.markdown.hl_options.hl_groups.links")

local _opts = {}

---@param opts Custom.MD.Config|nil
function M.setup(opts)
  _opts = opts or {}

  -- Shared augroup — cleared on every setup() call (e.g. re-source).
  local aug = vim.api.nvim_create_augroup("CustomMarkdownHL", { clear = true })

  -- Let each module register its own buffer/window autocmds.
  blockquote.setup_autocmds(aug)

  -- Apply highlights now (defines the hl group + seeds open buffers).
  blockquote.apply(_opts)

  -- Re-define the hl group after :colorscheme changes.
  -- matchadd references the group by name, so the color update is automatic.
  vim.api.nvim_create_autocmd("ColorScheme", {
    group    = aug,
    pattern  = "*",
    callback = function()
      blockquote.apply(_opts)
    end,
  })
end

return M
