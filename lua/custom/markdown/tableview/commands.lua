---@module 'custom.markdown.tableview.commands'
--- Provide buffer-local usercommands for TableView (preview / select / close).
--- English comments in code per project conventions.
--- Full EmmyLua annotations included at top as requested.

local notify = require("lib.notify").create("[custom.markdown.tableview.commands]")

local M = {}

local api = vim.api
local create_user_command = api.nvim_buf_create_user_command
local ui = require("custom.markdown.tableview.renderer")
local parser = require("custom.markdown.tableview.parser")
local browser_view_basic = require("custom.markdown.tableview.views.browser_basic")
local browser_view_niceified = require("custom.markdown.tableview.views.browser_niceified")
local table_selector = require("custom.markdown.tableview.views.table_selector")

--- Create buffer-local usercommands for the tableview features.
--- Intended to be called from a FileType autocmd handler with event table.
--- Example usage from autocmd: require('custom.markdown.tableview.commands').apply(ev)
---@param ev table Autocmd event table (expects ev.buf)
---@return nil
function M.apply(ev)
  if type(ev) ~= "table" or type(ev.buf) ~= "number" then
    return
  end
  local bufnr = ev.buf
  if not (api.nvim_buf_is_valid(bufnr) and api.nvim_buf_is_loaded(bufnr)) then
    return
  end

  -- avoid duplicate registration
  local ok, existing = pcall(api.nvim_buf_get_commands, bufnr, { builtin = false })
  if ok and existing and existing["TableViewToggle"] then
    return
  end

  -- Toggle (preview table at cursor)
  create_user_command(bufnr, "TableViewToggle", function(_)
    -- determine table at cursor
    local line = api.nvim_win_get_cursor(0)[1]
    local tables = parser.get_tables(bufnr)
    -- find table that contains current line
    local chosen = nil
    for _, t in ipairs(tables) do
      if t.start_line <= line and line <= (t.end_line or t.start_line) then
        chosen = t
        break
      end
    end
    if not chosen then
      notify.info("[Custom.Markdown.TableView] No table under cursor")
      return
    end
    ui.toggle_table(chosen, { floating = true })
  end, { desc = "[Custom.Markdown.TableView] Toggle preview for table under cursor", nargs = 0 })

  -- Select from all tables in buffer
  create_user_command(bufnr, "TableViewSelect", function()
    local tables = parser.get_tables(bufnr)
    if #tables == 0 then
      notify.info("[Custom.Markdown.TableView] No tables found in buffer")
      return
    end

    if #tables == 1 then
      ui.render_table(tables[1], { floating = true })
      return
    end

    table_selector(tables)
  end, { desc = "[Custom.Markdown.TableView] Select and preview table", nargs = 0 })

  -- Close persistent view
  create_user_command(bufnr, "TableViewClose", function()
    ui.close()
  end, { desc = "[Costum.Markdown.TableView] Close persistent table preview", nargs = 0 })

  -- open in browser (minimal HTML export / basic behavior)
  create_user_command(bufnr, "TableViewOpenBrowser", function()
    browser_view_basic(bufnr)
  end, { desc = "[Costum.Markdown.TableView] Open table under cursor in browser (simple HTML)", nargs = 0 })

  create_user_command(bufnr, "TableViewOpenBrowserNice", function()
    browser_view_niceified(bufnr)
  end, { desc = "[Costum.Markdown.TableView] Open table under cursor in browser (nice HTML)", nargs = 0 })
end

return M
