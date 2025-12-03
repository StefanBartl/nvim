---@module 'custom.markdown.setup.usercmds'
--- Create buffer-local usercommands for Markdown buffers:
--- 1. OpenWithSystemApplication - Opens files/URLs under cursor
--- 2. EnsureMarkdownHeadlines - Adds separator after H2+ headings
--- 3. PreviewMarkdownHeadlines - Shows what would change without modifying

local M = {}
local api = vim.api
local handler = require("custom.markdown.handler")
local cfg = require("custom.markdown.config")

-- Attempt to load headline_spacing module
local ok_hs, hs_mod = pcall(require, "custom.markdown.core.headline_spacing")
local headline_spacing = nil
if ok_hs and type(hs_mod) == "table" and type(hs_mod.ensure_buffer) == "function" then
  headline_spacing = hs_mod
end

--- Create all buffer-local usercommands for a Markdown buffer
---@param args table Autocmd args table (must contain buf field)
function M.apply(args)
  -- Validate input arguments
  if type(args) ~= "table" or type(args.buf) ~= "number" then
    return
  end

  local bufnr = args.buf

  -- Ensure buffer is valid and loaded
  if not (api.nvim_buf_is_valid(bufnr) and api.nvim_buf_is_loaded(bufnr)) then
    return
  end

  -- Get existing buffer commands to avoid duplicates
  local ok, cmds = pcall(api.nvim_buf_get_commands, bufnr, { builtin = false })
  if not ok then
    cmds = {}
  end

  -- Create OpenWithSystemApplication command if not exists
  if not cmds["OpenWithSystemApplication"] then
    pcall(function()
      api.nvim_buf_create_user_command(bufnr, "OpenWithSystemApplication", function()
        handler.handle_cursor_action()
      end, {
        desc = "[Custom.Markdown] Open image/url/file under cursor with system app",
        nargs = 0,
      })
    end)
  end

  -- Check if headline spacing feature is enabled in config
  local enabled = cfg.ensure_headline_spacing == nil and true or cfg.ensure_headline_spacing

  if not enabled then
    return
  end

  -- Warn if headline_spacing module failed to load
  if not headline_spacing then
    vim.notify(
      "[custom.markdown] headline_spacing module not loaded; commands not created",
      vim.log.levels.WARN,
      { title = "custom.markdown" }
    )
    return
  end

  -- Create EnsureMarkdownHeadlines command
  if not cmds["EnsureMarkdownHeadlines"] then
    pcall(function()
      api.nvim_buf_create_user_command(bufnr, "EnsureMarkdownHeadlines", function()
        -- Execute with error handling
        local ok_exec, result = pcall(function()
          return headline_spacing.ensure_buffer(bufnr, { notify = true })
        end)

        -- Show error if execution failed
        if not ok_exec then
          vim.notify(
            "[custom.markdown] EnsureMarkdownHeadlines failed: " .. tostring(result),
            vim.log.levels.ERROR,
            { title = "custom.markdown" }
          )
        end
      end, {
        desc = "[Custom.Markdown] Add separator after all H2+ heading sections",
        nargs = 0,
      })
    end)
  end

  -- Create PreviewMarkdownHeadlines command
  if not cmds["PreviewMarkdownHeadlines"] then
    pcall(function()
      api.nvim_buf_create_user_command(bufnr, "PreviewMarkdownHeadlines", function()
        -- Execute preview with error handling
        local ok_exec, sections = pcall(function()
          return headline_spacing.preview(bufnr)
        end)

        if not ok_exec then
          vim.notify(
            "[custom.markdown] PreviewMarkdownHeadlines failed: " .. tostring(sections),
            vim.log.levels.ERROR,
            { title = "custom.markdown" }
          )
          return
        end

        -- Display preview results
        if #sections == 0 then
          vim.notify(
            "All H2+ sections already have proper separators",
            vim.log.levels.INFO,
            { title = "headline_spacing" }
          )
        else
          local msg = string.format("Would modify %d sections at lines: ", #sections)
          local lines = {}
          for _, section in ipairs(sections) do
            table.insert(lines, tostring(section.heading_idx))
          end
          msg = msg .. table.concat(lines, ", ")

          vim.notify(msg, vim.log.levels.INFO, { title = "headline_spacing" })
        end
      end, {
        desc = "[Custom.Markdown] Preview which sections would be modified",
        nargs = 0,
      })
    end)
  end
end

return M
