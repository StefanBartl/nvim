---@module 'wkdnvchad.ui.statusline.modules.custom'
--- Module with helper function for custom nvchad/ui/statusline

--- CDX: this whole subtree (init.lua, breadcrumbs/helpers.lua,
--- breadcrumbs/render.lua) has zero requires anywhere in lua/ or the plugin
--- repos — matches README.md's "currently unreferenced ... pending a closer
--- look". If it is revived, note that breadcrumbs/render.lua is also broken:
--- it calls M.repo_relative / M.symbol_context / M.ellipsize_middle /
--- M.stl_escape on its own module table but never requires breadcrumbs/
--- helpers.lua where those live, so render_breadcrumbs() nil-calls.

local M = {}

return M
