---@module 'custom.markdown.ui.keymaps'
local M = {}

local function map(modes, lhs, rhs, desc, opts)
  local o = { noremap = true, silent = true, desc = desc }
  if opts then for k, v in pairs(opts) do o[k] = v end end
  vim.keymap.set(modes, lhs, rhs, o)
end

-- all bindings in one place; pass { buffer = bufnr } for buffer-local
local function apply_keymaps(bufnr)
  local cfg       = require("custom.markdown.config").get
  local fold      = require("custom.markdown.core.fold")
  local fold_prev = require("custom.markdown.core.fold_prev")
  local fold_lvls = require("custom.markdown.core.fold_levels")
  local headings  = require("custom.markdown.core.headings")
  local wrap      = require("custom.markdown.core.wrap")
  local toc       = require("custom.markdown.core.toc")

  local o = bufnr and { buffer = bufnr } or nil

  if cfg().map_double_asterisk ~= false then
    map("x", "**", wrap.toggle_visual_bold, "[Markdown] Toggle ** around selection", o)
  end

  map({ "n", "v" }, "mk", headings.goto_prev_heading, "[Markdown] Previous heading (H2+)", o)
  map({ "n", "v" }, "mj", headings.goto_next_heading, "[Markdown] Next heading (H2+)", o)

  map("n", "<localleader>f", function() fold.toggle_under_cursor() end,
      "[Markdown] Toggle fold under cursor & center", o)

  if cfg().use_zf_override then
    map("n", "zf", function() fold.toggle_under_cursor() end,
        "[Markdown] Toggle fold under cursor & center (override)", vim.tbl_extend("force", o or {}, { nowait = true }))
  end

  map("n", "zu", fold.unfold_all_center, "[Markdown] Unfold all & center", o)
  map("n", "zi", fold_prev.fold_prev_heading_then_center, "[Markdown] Fold previous heading & center", o)
  map("n", "zk", function() fold_lvls.fold_levels({ 2, 3, 4, 5, 6 }) end,
      "[Markdown] Fold H2+ (keep H1 open)", o)

  map("n", "<leader>toc", function() toc.update_markdown_toc("## Table of content") end,
      "[Markdown] Insert/Refresh TOC", o)
end

function M.setup()
  local cfg = require("custom.markdown.config").get
  if not cfg().enable_keymaps then return end

  if cfg().ft_only then
    -- Buffer-local on FileType=markdown (idempotent via augroup clear)
    local aug = vim.api.nvim_create_augroup("CustomMarkdownKeymaps", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = aug,
      pattern = { "markdown", "markdown.mdx", "mdx" }, -- add variants you use
      callback = function(ev)
        apply_keymaps(ev.buf)
      end,
      desc = "Install buffer-local Markdown keymaps",
    })
  else
    -- Global maps once
    if vim.g.__custom_markdown_keymaps_installed then return end
    apply_keymaps(nil)
    vim.g.__custom_markdown_keymaps_installed = true
  end
end

return M
