---@module 'custom.repo_pickers.types'
--- Central type aliases and small shared records for repo_pickers.
--- Keeping types separate reduces annotation noise and improves clarity.

---@alias RepoDir string  -- Absolute path to a repository root directory

---@alias RepoSelector
---| "auto"       # Prefer Telescope, then fzf-lua, else fallback to vim.ui.select
---| "telescope"  # Force Telescope-based selection
---| "fzf"        # Force fzf-lua-based selection
---| "vim_select" # Use vim.ui.select

---@alias RepoEngine
---| "auto"       # Prefer fzf-lua actions, then Telescope
---| "telescope"  # Actions executed via Telescope
---| "fzf"        # Actions executed via fzf-lua

---@class RepoPickersUsrCmdNames
---@field find_files_telescope? string  -- Default: "RepoFilesTelescope"
---@field grep_telescope?       string  -- Default: "RepoGrepTelescope"
---@field find_files_fzf?       string  -- Default: "RepoFilesFzf"
---@field grep_fzf?             string  -- Default: "RepoGrepFzf"

---@class RepoPickersKeymaps
---@field repo_files? string  -- e.g. "<leader>rf"
---@field repo_grep?  string  -- e.g. "<leader>rg"

---@class RepoPickersConfig
---@field repos_dir? string                 -- Base dir to scan; defaults to vim.env.REPOS_DIR
---@field only_git? boolean                 -- If true, list only directories with a .git entry
---@field selector? RepoSelector            -- UI to select a repository
---@field engine? RepoEngine                -- Engine for the action (files/grep)
---@field show_relative? boolean            -- Show basename or repos_dir-relative labels
---@field usercmd_names? RepoPickersUsrCmdNames  -- Map to existing usr_pickers user-commands
---@field keymaps_lhs? RepoPickersKeymaps        -- Keymap LHS definitions (optional)

---@class RepoPickersEnable
---@field usercmds? boolean  -- Register user commands
---@field keymaps?  boolean  -- Register keymaps
