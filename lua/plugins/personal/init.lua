---@module 'plugins.personal'
--- Personal and local development plugins - the SPEC ENTRY POINT.
---
--- The specs themselves live one file per category in plugins/personal/specs/,
--- using the same categories as the plugin website (wkd registry):
---   foundation, ai, edit, navigate, inspect, project, view
--- (the website's eighth category, "desktop", is a standalone app with no
--- Neovim spec.) This file only collects those lists and exports them.
---
--- All source control (which repo loads locally / remotely / not at all, the
--- global OVERRIDE switch, machine-role handling and the per-repo mode table)
--- lives in plugins.personal.core.source. To turn a repo off or switch it
--- local/remote, edit plugins/personal/core/source.lua, not these files.

local plugins = require("plugins.personal.core.source")

-- foundation first: lib.nvim is a hard dependency of nearly everything below,
-- and `plugins.personal.core.list` documents it as the first entry.
local CATEGORIES = { "foundation", "ai", "edit", "navigate", "inspect", "project", "view" }

for _, category in ipairs(CATEGORIES) do
  plugins.add(require("plugins.personal.specs." .. category))
end

return plugins.export()
