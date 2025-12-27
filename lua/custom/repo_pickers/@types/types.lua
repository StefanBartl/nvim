---@meta
---@module 'custom.repo_pickers.types.types'
--- Central types and  fields documentation for repo_pickers.
require("custom.repo_pickers.@types.aliases")

---@class RepoPickers.UsrCmdNames
---@field find_files_telescope? string  -- Default when exposed: "RepoFindFilesTelescope"
---@field grep_telescope?       string  -- Default when exposed: "RepoGrepTelescope"
---@field find_files_fzf?       string  -- Default when exposed: "RepoFindFilesFzf"
---@field grep_fzf?             string  -- Default when exposed: "RepoGrepFzf"

---@class RepoPickers.Keymaps
---@field repo_files? string   -- Normal mode LHS to trigger RepoFiles flow (e.g. "<leader>rf")
---@field repo_grep?  string   -- Normal mode LHS to trigger RepoGrep flow (e.g. "<leader>rg")
---@field wkdbook_find? string -- Normal mode LHS to trigger WkdBookFind flow (e.g. "<leader>wf")
---@field wkdbook_grep? string -- Normal mode LHS to trigger WkdBookGrep flow (e.g. "<leader>wg")

---@class RepoPickers.Config
---@field repos_dir? string                             -- Base dir to scan; defaults to vim.env.REPOS_DIR
---@field only_git? boolean                             -- If true, list only directories with a ".git" entry (dir or file)
---@field selector? RepoPickers.RepoSelector            -- Selection UI ("auto" matches the effective engine)
---@field engine? RepoPickers.RepoEngine                -- Action engine for files/grep
---@field show_relative? boolean                        -- Repository labels shown relative to repos_dir (or basename)
---@field usercmd_names? RepoPickers.UsrCmdNames        -- Names of engine-specific commands (if exposed)
---@field keymaps_lhs? RepoPickers.Keymaps              -- Optional keymap LHS strings
---@field wkdbooks_dir? string   -- Base dir for WKDBooks; defaults to vim.env.REPOS_DIR/WKDBooks
---@field wkdbook_prefix? string -- Prefix filter for WKDBook directories (default: "wkdbook-")
---@field expose_engine_cmds? boolean                   -- If true, also register engine-specific commands
---                                                     --   RepoFindFilesFzf, RepoGrepFzf, RepoFindFilesTelescope, RepoGrepTelescope
---                                                     --   (and their short aliases RepoFilesFzf/RepoFilesTelescope). Default: false.

---@class RepoPickers.Enable
---@field usercmds? boolean  -- Register user commands (RepoFiles, RepoGrep; plus engine-specific if enabled)
---@field keymaps?  boolean  -- Register keymaps from keymaps_lhs

return {}
