---@module 'config.markdown_render'

local notify = require("lib.nvim.notify").create("[markdown_render]")
local map    = require("lib.nvim.map")

local M = {}

local is_enabled = false

--- Initialisiert render-markdown mit disabled-Startzustand
function M.setup()
  require("render-markdown").setup({
    enabled = false,  -- explizit deaktiviert beim Start
  })

  require("lib.nvim.usercmd").create("MarkdownRender", function(opts)
    local arg = opts.args:lower()
    if arg == "on" then
      M.set(true)
    elseif arg == "off" then
      M.set(false)
    elseif arg == "" or arg == "toggle" then
      M.set(not is_enabled)
    else
      notify.warn("Ungültiges Argument. Erlaubt: on, off, toggle")
    end
  end, {
    nargs = "?",
    complete = function() return { "on", "off", "toggle" } end,
    desc = "Markdown Rendering steuern (on/off/toggle)",
  })

  map("n", "<leader>mr", function() M.set(not is_enabled) end,
    nil, "Toggle Markdown Rendering")
end

--- Setzt den Render-Zustand
---@param state boolean
function M.set(state)
  is_enabled = state
  if is_enabled then
    vim.cmd("RenderMarkdown enable")
    notify.info("Markdown rendering aktiviert")
  else
    vim.cmd("RenderMarkdown disable")
    notify.info("Markdown rendering deaktiviert")
  end
end

return M
