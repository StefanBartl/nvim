---@module 'mappings.markdown'
--- Keymaps for Markdown buffers. Wires a visual "**" toggle and
--- heading/folding helpers from utility modules. Robust against missing globals.

---@class MdMappingsCfg
---@field keep_inner_selection? boolean  -- true: reselect inner text; false: reselect outer incl. markers
---@field restrict_to_markdown? boolean  -- true: only operate in markdown buffers
---@field map_double_asterisk? boolean   -- true: in Visual mode, "**" toggles bold

local M = {}

local api = vim.api
local md_mappings_utils = require("mappings.utils.markdown")
local md_utils = require("utils.markdown")


--- Attach per-buffer markdown integrations.
---@param bufnr integer
local function on_markdown(bufnr)
  local ok, mdh = pcall(require, "utils.markdown_headings")
  if ok then
    mdh.setup_keymaps(bufnr)
  end
end

--- Public setup: create a single autocommand for markdown buffers.
local function MD_Headings_Setup()
  local aug = api.nvim_create_augroup("UtilsMarkdownSetup", { clear = true })
  api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = { "markdown" },
    callback = function(ev)
      on_markdown(ev.buf)
    end,
    desc = "Attach markdown utilities (keymaps, etc.)",
  })
end

---@type MdMappingsCfg
M.cfg = {
  keep_inner_selection = true,
  restrict_to_markdown = true,
  map_double_asterisk = true,
}

--- Toggle bold (`**…**`) around visual selection.
--- @return nil
local function _toggle_visual_bold()
  local did_unwrap = (type(md_mappings_utils.try_unwrap_asterisks) == "function")
      and md_mappings_utils.try_unwrap_asterisks(2)
      or false

  if not did_unwrap and type(md_mappings_utils.wrap_with_asterisks) == "function" then
    md_mappings_utils.wrap_with_asterisks(2, { keep_inner = M.cfg.keep_inner_selection })
  end
end

--- Setup mappings. Idempotent; can be called from ftplugin/markdown.lua.
--- @return nil
function M.setup()
	local map = vim.g.__map_helper

  if M.cfg.map_double_asterisk then
    map("x", "**", _toggle_visual_bold, { desc = "Markdown: Toggle ** around visual selection" })
  end


  -- Heading/folding/navigation
  map("n", "zf", function() md_utils.toggle_fold_under_cursor() end, { desc = "[Markdown] Toggle fold under cursor" })
  map({ "n", "v" }, "mk", function() md_utils.goto_prev_heading() end, { desc = "[Markdown] Prev heading (H2+)" })
  map({ "n", "v" }, "mj", function() md_utils.goto_next_heading() end, { desc = "[Markdown] Next heading (H2+)" })
  map("n", "zu", function() md_utils.unfold_all_then_center() end, { desc = "[Markdown] Unfold all (and center)" })
  map("n", "zi",  function() md_utils.fold_prev_heading_then_center() end, { desc = "[Markdown] Fold previous heading" })
  map("n", "zk", function() md_utils.fold_markdown_headings({ 6, 5, 4, 3, 2 }) end, { desc = "[Markdown] Fold H2+" })
	map("n", "<leader>mtt", function () md_utils.update_markdown_toc("## Contents", "### Table of contents") end, { desc = "[Markdown] Update TOC (markdown-toc)" })

  MD_Headings_Setup()
end

return M
