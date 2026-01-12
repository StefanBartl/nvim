---@module 'ui.command'
---Provides :UI usercommand for runtime UI configuration (Base46, editor UI).
local M = {}
local api = vim.api

-- Import theme management odule
local theme = require("ui.command.themes")

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

---Filter list based on argument
---@param arg string
---@param list string[]
---@return string[]
local function filter(arg, list)
  if not arg or arg == "" then
    return list
  end

  local filtered = {}
  local lower_arg = arg:lower()

  for _, item in ipairs(list) do
    if item:lower():find(lower_arg, 1, true) == 1 then
      table.insert(filtered, item)
    end
  end

  return filtered
end

-----------------------------------------------------------------------
-- Actions
-----------------------------------------------------------------------

---Handle transparency command
---@param args string[]
local function ui_transparency(args)
  local action = args[2]

  if action == "on" then
    local success = theme.set_transparency(false)
    if success then
      vim.notify("✨ Transparenz aktiviert", vim.log.levels.INFO)
    end
    return
  end

  if action == "off" then
    local success = theme.set_transparency(true)
    if success then
      vim.notify("🎨 Transparenz deaktiviert", vim.log.levels.INFO)
    end
    return
  end

  -- Toggle
  local new_state = theme.toggle_transparency()
  vim.notify(
    string.format("✨ Transparenz %s", new_state and "aktiviert" or "deaktiviert"),
    vim.log.levels.INFO
  )
end

---Handle theme command
---@param args string[]
local function ui_theme(args)
  local theme_name = args[2]

  if not theme_name or theme_name == "" then
    -- Show current theme if no argument
    local current = theme.get_current_theme()
    if current then
      vim.notify(
        string.format("Aktuelles Theme: %s\nNutze :UI theme <name> zum Ändern", current),
        vim.log.levels.INFO
      )
    else
      vim.notify("Kein Theme konfiguriert", vim.log.levels.WARN)
    end
    return
  end

  -- Validate theme exists
  if not theme.theme_exists(theme_name) then
    local available = theme.list_themes()
    local available_str = table.concat(available, ", ")
    vim.notify(
      string.format(
        "Theme '%s' nicht gefunden.\n\nVerfügbare Themes:\n%s",
        theme_name,
        available_str
      ),
      vim.log.levels.ERROR
    )
    return
  end

  -- Load theme
  local success = theme.load_theme(theme_name)

  if success then
    vim.notify(
      string.format("🎨 Theme geändert zu: %s", theme_name),
      vim.log.levels.INFO
    )
  else
    vim.notify(
      string.format("Fehler beim Laden von Theme '%s'", theme_name),
      vim.log.levels.ERROR
    )
  end
end

---Handle themes list command
---@param args string[]
---@diagnostic disable-next-line: unused-local
local function ui_themes(args)
  local themes = theme.list_themes()
  local current = theme.get_current_theme()

  if #themes == 0 then
    vim.notify("Keine Themes gefunden!", vim.log.levels.ERROR)
    return
  end

  -- Format themes list with current marker
  local lines = { string.format("Verfügbare Themes (%d):", #themes), "" }

  for _, theme_name in ipairs(themes) do
    local marker = (theme_name == current) and "✓ " or "  "
    table.insert(lines, marker .. theme_name)
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

---Handle status command
---@param args string[]
---@diagnostic disable-next-line: unused-local
local function ui_status(args)
  local info = theme.get_info()

  local lines = {
    "╭─ UI Status ─────────────────╮",
    string.format("│ Theme:        %-15s │", info.theme or "none"),
    string.format("│ Transparenz:  %-15s │", info.transparency and "an" or "aus"),
  }

  if info.toggle_themes and #info.toggle_themes > 0 then
    local toggle_str = table.concat(info.toggle_themes, ", ")
    if #toggle_str > 15 then
      toggle_str = toggle_str:sub(1, 12) .. "..."
    end
    lines[#lines + 1] = string.format("│ Toggle:       %-15s │", toggle_str)
  end

  lines[#lines + 1] = "╰─────────────────────────────╯"

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

---Toggle between configured themes
---@param args string[]
---@diagnostic disable-next-line: unused-local
local function ui_toggle(args)
  local next_theme = theme.toggle_theme()

  if next_theme then
    vim.notify(
      string.format("🎨 Theme geändert zu: %s", next_theme),
      vim.log.levels.INFO
    )
  else
    vim.notify(
      "Kein theme_toggle in chadrc konfiguriert.\n" ..
      "Füge mindestens 2 Themes zu theme_toggle hinzu.",
      vim.log.levels.WARN
    )
  end
end

---Show help information
---@param args string[]
---@diagnostic disable-next-line: unused-local
local function ui_help(args)
  local help_text = [[
╭─ UI Command Hilfe ──────────────────────────────────╮
│                                                      │
│  :UI transparency           Transparenz umschalten   │
│  :UI transparency on        Transparenz aktivieren   │
│  :UI transparency off       Transparenz deaktivieren │
│                                                      │
│  :UI theme                  Aktuelles Theme zeigen   │
│  :UI theme <name>           Theme setzen             │
│  :UI themes                 Alle Themes auflisten    │
│  :UI toggle                 Zwischen Themes wechseln │
│                                                      │
│  :UI status                 Aktuelle Config zeigen   │
│  :UI help                   Diese Hilfe anzeigen     │
│                                                      │
╰──────────────────────────────────────────────────────╯

Siehe auch: README-THEMES.md für technische Details
]]
  vim.notify(help_text, vim.log.levels.INFO)
end

-----------------------------------------------------------------------
-- Dispatcher
-----------------------------------------------------------------------

---@param opts table
local function dispatcher(opts)
  local args = vim.split(vim.trim(opts.args or ""), "%s+")

  -- Handle empty command
  if #args == 0 or args[1] == "" then
    ui_help({})
    return
  end

  local sub = args[1]

  local actions = {
    transparency = ui_transparency,
    theme = ui_theme,
    themes = ui_themes,
    toggle = ui_toggle,
    status = ui_status,
    help = ui_help,
  }

  local action = actions[sub]

  if action then
    local ok, err = pcall(action, args)
    if not ok then
      vim.notify(
        string.format("UI %s Fehler: %s", sub, tostring(err)),
        vim.log.levels.ERROR
      )
    end
  else
    vim.notify(
      string.format(
        "Unbekannter Befehl: '%s'\nNutze :UI help für Hilfe",
        sub
      ),
      vim.log.levels.ERROR
    )
  end
end

-----------------------------------------------------------------------
-- Completion
-----------------------------------------------------------------------

---@param arglead string
---@param cmdline string
---@param cursorpos number
---@return string[]
local function complete(arglead, cmdline, cursorpos)
  -- Split the command line into parts
  local parts = {}
  for part in cmdline:gmatch("%S+") do
    table.insert(parts, part)
  end

  -- Count how many arguments we have (excluding the command itself)
  local num_args = #parts - 1

  -- If the line ends with a space, we're completing the next argument
  if cmdline:match("%s$") then
    num_args = num_args + 1
    arglead = ""
  end

  -- Complete first argument (subcommands)
  if num_args == 1 then
    local subcommands = {
      "transparency",
      "theme",
      "themes",
      "toggle",
      "status",
      "help",
    }
    return filter(arglead, subcommands)
  end

  -- Complete second argument based on subcommand
  if num_args == 2 then
    local subcmd = parts[2]

    if subcmd == "transparency" then
      return filter(arglead, { "on", "off" })
    end

    if subcmd == "theme" then
      return filter(arglead, theme.list_themes())
    end
  end

  return {}
end

-----------------------------------------------------------------------
-- Setup
-----------------------------------------------------------------------

function M.setup()
  api.nvim_create_user_command("UI", dispatcher, {
    nargs = "*",
    complete = complete,
    desc = "UI Kontrolle (Base46, Transparenz, Themes)",
  })

  -- Optional: Create shorter aliases
  api.nvim_create_user_command("Theme", function(opts)
    dispatcher({ args = "theme " .. opts.args })
  end, {
    nargs = "?",
    complete = function(arglead, cmdline, cursorpos)
      return filter(arglead, theme.list_themes())
    end,
    desc = "Theme ändern (Shortcut für :UI theme)",
  })
end

return M
