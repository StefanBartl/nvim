---@module 'config.neotree.helper.hide_preview_safe'

-- Safe hide of Neo-tree's floating preview, ignoring errors.
---@param _ any
return function (_)
  pcall(function()
    require("neo-tree.sources.common.preview").hide()
  end)
end
