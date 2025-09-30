---@module 'custom.repo_pickers.types'
--- Central type aliases and rich field documentation for repo_pickers.

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

---@class RepoPickersUsrCmdNames
---@field find_files_telescope? string  -- Default when exposed: "RepoFindFilesTelescope"
---@field grep_telescope?       string  -- Default when exposed: "RepoGrepTelescope"
---@field find_files_fzf?       string  -- Default when exposed: "RepoFindFilesFzf"
---@field grep_fzf?             string  -- Default when exposed: "RepoGrepFzf"

---@class RepoPickersKeymaps
---@field repo_files? string  -- Normal mode LHS to trigger RepoFiles flow (e.g. "<leader>rf")
---@field repo_grep?  string  -- Normal mode LHS to trigger RepoGrep flow (e.g. "<leader>rg")

---@class RepoPickersConfig
---@field repos_dir? string                 -- Base dir to scan; defaults to vim.env.REPOS_DIR
---@field only_git? boolean                 -- If true, list only directories with a ".git" entry (dir or file)
---@field selector? RepoSelector            -- Selection UI ("auto" matches the effective engine)
---@field engine? RepoEngine                -- Action engine for files/grep
---@field show_relative? boolean            -- Repository labels shown relative to repos_dir (or basename)
---@field usercmd_names? RepoPickersUsrCmdNames  -- Names of engine-specific commands (if exposed)
---@field keymaps_lhs? RepoPickersKeymaps        -- Optional keymap LHS strings
---@field expose_engine_cmds? boolean            -- If true, also register engine-specific commands
---                                             --   RepoFindFilesFzf, RepoGrepFzf, RepoFindFilesTelescope, RepoGrepTelescope
---                                             --   (and their short aliases RepoFilesFzf/RepoFilesTelescope). Default: false.

---@class RepoPickersEnable
---@field usercmds? boolean  -- Register user commands (RepoFiles, RepoGrep; plus engine-specific if enabled)
---@field keymaps?  boolean  -- Register keymaps from keymaps_lhs
return {}
