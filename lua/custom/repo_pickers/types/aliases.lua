---@meta
---@module 'custom.repo_pickers.types.aliases'
--- Central type aliases for repo_pickers.

---@alias RepoDir string

---@alias RepoSelector
---| "auto"        # Match selection UI to the effective engine (fzf/Telescope); fallback = vim.ui.select
---| "telescope"   # Force Telescope for selection (fallback = vim.ui.select)
---| "fzf"         # Force fzf-lua for selection (fallback = vim.ui.select)
---| "vim_select"  # Always use vim.ui.select

---@alias RepoEngine
---| "auto"       # Prefer fzf-lua actions if available, else Telescope
---| "telescope"  # Force Telescope actions
---| "fzf"        # Force fzf-lua actions
