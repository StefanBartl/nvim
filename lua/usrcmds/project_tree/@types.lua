---@meta
---@module 'usrcmds.project_tree.@types'

---@class ProjectTreeConfig
---@field exclude_patterns string[]           -- e.g. { "*/.git/*", "*/node_modules/*" }
---@field outdir FilePath                     -- e.g. $XDG_STATE_HOME/nvim/project-tree or ~/.local/state/nvim/project-tree
---@field outfile_fmt string                  -- printf-like; %s replaced by project name (default: "%s-tree.txt")
---@field notify_prefix string                -- prefix added to messages returned by functions
---@field use_system_clipboard boolean        -- true => try setreg("+", content) before shell fallback

---@class ProjectTreeModule
---@field setup function
---@field opts ProjectTreeConfig
