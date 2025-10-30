---@module 'custom.markdown.tableview.mappings'
--- Buffer-local keymaps for TableView features.

local api = vim.api
local M = {}

local function with(o, extra)
  local out = {}
  if o then for k,v in pairs(o) do out[k]=v end end
  if extra then for k,v in pairs(extra) do out[k]=v end end
  return out
end

--- Apply buffer-local keymaps for a markdown buffer
---@param bufnr integer
---@return nil
function M.apply(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()

  -- guard: only apply to markdown filetypes
  local ft = vim.bo[bufnr].filetype
  if not ft or not ft:match("markdown") then return end

  local opts = { buffer = bufnr, noremap = true, silent = true }

  -- Toggle preview at cursor
  vim.keymap.set({ "n" }, "<leader>tvt", function() vim.cmd("TableViewToggle") end, with(opts, { desc = "[Custom.Markdown.TableView] Toggle table preview at cursor" }))

  -- Select table
  vim.keymap.set({ "n" }, "<leader>tvs", function() vim.cmd("TableViewSelect") end, with(opts, { desc = "[Custom.Markdown.TableView] Select and preview table" }))

  -- Open in browser
  vim.keymap.set({ "n" }, "<leader>tvb", function() vim.cmd("TableViewOpenBrowser") end, with(opts, { desc = "[Custom.Markdown.TableView] Open table in browser" }))

  -- Close view
  vim.keymap.set({ "n" }, "<leader>tvc", function() vim.cmd("TableViewClose") end, with(opts, { desc = "[Custom.Markdown.TableView] Close TableView" }))
end

return M
