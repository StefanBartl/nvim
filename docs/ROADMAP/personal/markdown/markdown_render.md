## Variante A: Modular mit separater Konfigurationsdatei

Diese Struktur trennt die Plugin-Deklaration sauber von der Logik. Da das Plugin mit `enabled = false` startet, laden wir es erst dynamisch (`lib.lazy`), sobald der User den Render-Befehl tatsächlich triggert.

### 1. Die Konfigurationsdatei

Erstelle die Datei `/nvim/lua/config/renderMarkdown/init.lua`:

```lua
---@module 'config.renderMarkdown'
local M = {}

-- Interner Zustand für das Toggling (da opts.enabled = false als Startwert gilt)
local is_enabled = false

---Kern-Logik zum Setzen des Render-Zustands
---@param state "on"|"off"|"toggle"
function M.toggle_render(state)
  -- Falls das Plugin noch gar nicht geladen ist, erzwinge das Laden über Lazy
  if not packer_plugins or not packer_plugins["render-markdown.nvim"] or not packer_plugins["render-markdown.nvim"].loaded then
    local ok, lazy = pcall(require, "lazy")
    if ok then
      lazy.load({ plugins = { "render-markdown.nvim" } })
    end
  end

  local rm = pcall(require, "render-markdown")
  if not rm then
    local lib_ok, lib = pcall(require, "lib.notify")
    local notify = lib_ok and lib.notify or vim.notify
    notify("render-markdown.nvim konnte nicht geladen werden!", vim.log.levels.ERROR)
    return
  end

  -- Zustand evaluieren
  if state == "on" then
    is_enabled = true
  elseif state == "off" then
    is_enabled = false
  else
    is_enabled = not is_enabled
  end

  -- API des Plugins aufrufen
  if is_enabled then
    vim.cmd("RenderMarkdown enable")
  else
    vim.cmd("RenderMarkdown disable")
  end
end

---Setup-Funktion für den eigenständigen Usercommand
function M.setup()
  local lib_ok, lib = pcall(require, "lib")
  local usercmd = lib_ok and lib.usercmd or vim.api.nvim_create_user_command

  usercmd("MarkdownRender", function(opts)
    local arg = opts.args:lower()
    if arg == "on" or arg == "off" or arg == "toggle" then
      M.toggle_render(arg)
    elseif arg == "" then
      M.toggle_render("toggle")
    else
      local notify = lib_ok and lib.notify or vim.notify
      notify("Ungültiges Argument. Erlaubt: on, off, toggle", vim.log.levels.WARN)
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

```

### 2. Integration in `plugins/markdown.lua`

Hier binden wir die obige Datei über das `config`-Feld ein:

```lua
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    cmd = { "RenderMarkdown", "MarkdownRender" },
    opts = {
      enabled = false,
    },
    config = function()
      require("config.renderMarkdown").setup()
    end,
  },

```

### 3. Einbindung in deinen bestehenden `:Markdown` Usercommand

In deiner zentralen Befehlsdatei, wo du den `:Markdown` Command verwaltest, kannst du das Sub-Argument `render` jetzt extrem einfach abfangen und an das Modul delegieren:

```lua
-- Innerhalb deiner bestehenden :Markdown Command Logik:
local args = vim.split(opts.args, "%s+")
local sub_cmd = args[1]
local sub_arg = args[2] or "toggle"

if sub_cmd == "render" then
  -- Verhindert Startup-Ladelast: Lädt die Config-Datei erst beim Aufruf
  require("config.renderMarkdown").toggle_render(sub_arg)
end

```

---

## Variante B: Alles direkt in `plugins/markdown.lua` (Inlined)

Wenn du keine extra Datei im `config`-Ordner anlegen möchtest, kannst du die gesamte Logik (inklusive der global exportierten Funktion für deinen `:Markdown` Hauptbefehl) direkt in der Plugin-Spezifikation verankern.

Hierzu nutzen wir eine globale Zuweisung oder lagern es temporär in den `_G`-Namespace aus, damit du von überall darauf zugreifen kannst:

```lua
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    cmd = { "RenderMarkdown", "MarkdownRender" },
    opts = {
      enabled = false,
    },
    config = function()
      local lib_ok, lib = pcall(require, "lib")
      local usercmd = lib_ok and lib.usercmd or vim.api.nvim_create_user_command
      local notify = lib_ok and lib.notify or vim.notify

      local is_enabled = false

      -- 1. Die Toggle-Funktion global/zentral verfügbar machen für deinen :Markdown Befehl
      _G.markdown_render_toggle = function(state)
        -- Falls Plugin durch 'cmd' getriggert wurde aber noch nicht voll geladen ist
        if not packer_plugins or not packer_plugins["render-markdown.nvim"] or not packer_plugins["render-markdown.nvim"].loaded then
          local lazy_ok, lazy = pcall(require, "lazy")
          if lazy_ok then lazy.load({ plugins = { "render-markdown.nvim" } }) end
        end

        if state == "on" then is_enabled = true
        elseif state == "off" then is_enabled = false
        else is_enabled = not is_enabled end

        if is_enabled then
          vim.cmd("RenderMarkdown enable")
        else
          vim.cmd("RenderMarkdown disable")
        end
      end

      -- 2. Den dedizierten :MarkdownRender Command registrieren
      usercmd("MarkdownRender", function(opts)
        local arg = opts.args:lower()
        if arg == "on" or arg == "off" or arg == "toggle" then
          _G.markdown_render_toggle(arg)
        elseif arg == "" then
          _G.markdown_render_toggle("toggle")
        else
          notify("Ungültiges Argument. Erlaubt: on, off, toggle", vim.log.levels.WARN)
        end
      end, {
        nargs = "?",
        complete = function() return { "on", "off", "toggle" } end,
        desc = "Markdown Rendering steuern",
      })
    end,
  },

```

### Einbindung in `:Markdown` (bei Variante B):

In deinem `:Markdown` Hauptbefehl rufst du die Funktion dann einfach so auf:

```lua
if sub_cmd == "render" and _G.markdown_render_toggle then
  _G.markdown_render_toggle(sub_arg)
end

```
