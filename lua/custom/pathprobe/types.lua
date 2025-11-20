---@meta
---@module 'custom.pathprobe.types'

---@class PathProbeOpts
---@field max_components? integer          # maximum number of trailing components to try (default 6)
---@field search_roots string[]|nil       # custom roots; if nil, roots are auto-guessed
---@field open_cmd '"vsplit"'|'"split"'|'"edit"'  # how to open the match (default "vsplit")
---@field ask_on_ambiguous boolean        # offer selector when multiple matches (default true)
