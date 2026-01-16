-- lua/config/neotree/sources/switcher.lua
---@module 'config.neotree.sources.switcher'
---@description Hover-based source switcher for Neo-tree using hover-select v2

local registry = require("config.neotree.sources.registry")
local ICONS = require("config.neotree.sources.icons")
local hover_select = require("lib.hover_select")

local M = {}

---Show Neo-tree source picker in a hover-select floating window
function M.show_picker()
  -- Retrieve available sources from the registry
  local sources = registry.list()

  -- Determine the currently active source for the window
  local state = require("neo-tree.sources.manager").get_state_for_window()
  local current = state and state.name or nil

  ---@type string[]
  local items = {}

  -- Build display items while keeping source order stable
  for i, name in ipairs(sources) do
    local icon = ICONS.get_icon(name, "nerd", "v1")
    local loaded = registry.is_loaded(name) and "●" or "○"
    local is_current = (name == current) and " ←" or ""

    -- Compose visible line; index mapping is preserved via `sources`
    items[i] = string.format("%s %s %s%s", loaded, icon, name, is_current)
  end

  -- Open hover-select UI
  hover_select.open({
    title = "Select Neo-tree Source",
    items = items,

    -- Automatically size window to longest line (icons + markers)
    auto_width = true,

    -- Optional but ergonomic for quick cycling
    use_tab_navigation = true,

    ---Handle selection
    ---@param _ string      -- Display string (unused, mapping via index)
    ---@param index integer -- 1-based index into `sources`
    on_select = function(_, index)
      local source_name = sources[index]
      if not source_name then
        return
      end

      -- Load source on demand
      if not registry.is_loaded(source_name) then
        vim.notify(
          string.format("Loading %s...", source_name),
          vim.log.levels.INFO
        )
        registry.load(source_name)
      end

      -- Switch Neo-tree to the selected source
      require("neo-tree.command").execute({
        source = source_name,
        action = "show",
        position = require("config.neotree").get_default_position(),
      })
    end,
  })
end

return M

