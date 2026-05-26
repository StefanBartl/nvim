---@module 'config.renderMarkdown'
local M = {}

---Kern-Logik zum Setzen des Render-Zustands
---@param state "on"|"off"|"toggle"
function M.toggle_render(state)
  local lib_ok, lib = pcall(require, "lib")
  local notify = lib_ok and lib.notify or vim.notify

  -- Lazy-Check entfällt hier implizit, da der Command das Plugin ohnehin lädt.
  -- Dennoch sichern wir den API-Call ab:
  local rm_ok, rm = pcall(require, "render-markdown")
  if not rm_ok then
    notify("render-markdown.nvim konnte nicht geladen werden!", vim.log.levels.ERROR)
    return
  end

  -- Wir nutzen das State-API des Plugins anstelle einer eigenen Variable
  local state_manager = require("render-markdown.state")
  -- Falls das Plugin-API den State anders hält, fragen wir ab, ob es aktiv ist:
  local is_active = state_manager.enabled

  if state == "on" or (state == "toggle" and not is_active) then
    vim.cmd("RenderMarkdown enable")
    notify("Markdown Rendering: AN", vim.log.levels.INFO)
  elseif state == "off" or (state == "toggle" and is_active) then
    vim.cmd("RenderMarkdown disable")
    notify("Markdown Rendering: AUS", vim.log.levels.INFO)
  end
end

---Setup-Funktion für den eigenständigen Usercommand
function M.setup()
  vim.api.nvim_create_user_command("MarkdownRender", function(opts)
    local arg = opts.args:lower()
    if arg == "on" or arg == "off" or arg == "toggle" then
      M.toggle_render(arg)
    elseif arg == "" then
      M.toggle_render("toggle")
    else
      vim.notify("Ungültiges Argument. Erlaubt: on, off, toggle", vim.log.levels.WARN)
    end
  end, {
    nargs = "?",
    complete = function()
      return { "on", "off", "toggle" }
    end,
    desc = "Markdown Rendering steuern",
  })
end

return M
