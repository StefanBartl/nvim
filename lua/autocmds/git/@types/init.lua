---@meta
---@module 'autocmds.git.@types'
--- Strongly-typed, LSP-friendly configuration contracts for Git-related autocmd modules.
--- This file documents every field with purpose, defaults, allowed values and side effects.
--- It mirrors the shape expected by `require('autocmds.git').enable(cfg)`.

---@class AutoCmds.Git
---@field enable fun(cfg: AutoCmds.Git.Cfg|boolean|nil): nil # Enable git-related autocommands per feature.

--------------------------------------------------------------------------------
-- Module: commit_ft
--------------------------------------------------------------------------------

---@class AutoCmds.Git.CommitFtCfg
---@field enable boolean
--- Enable this feature. Applies only to buffers with `filetype=gitcommit`.
---
---@field spell? boolean|nil
--- Enable local spell checking in commit messages. Default: true.
---
---@field textwidth? integer|nil
--- Soft line wrap width via `textwidth`. Default: 72 (common Git convention).
---
---@field colorcolumn? string|nil
--- Comma-separated columns for visual ruler(s). Default: "73".
--- Example: "73,100" to show two rulers.
---
---@field formatoptions? string|nil
--- Local `formatoptions`. Default: "tcqj".
--- Typical meanings: t=auto-wrap, c=auto-wrap comments, q=gq formats comments, j=remove comment leader on join.
---
---@field start_in_insert? boolean|nil
--- When true, enters Insert mode after opening a commit buffer. Default: false.

--------------------------------------------------------------------------------
-- Module: gitsigns_refresh
--------------------------------------------------------------------------------

---@class AutoCmds.Git.GitsignsRefreshCfg
---@field enable boolean
--- Enable gitsigns refresh hooks (safe no-op when gitsigns is absent).
---
---@field events? Autocmds.Event[]|nil
--- Events used to refresh hunks. Default: { "BufEnter", "FocusGained" }.
--- Add/remove events to balance freshness vs. overhead.

--------------------------------------------------------------------------------
-- Module: blame_on_hold
--------------------------------------------------------------------------------

---@class AutoCmds.Git.BlameOnHoldCfg
---@field enable boolean
--- Enable inline blame display on idle cursor (requires gitsigns).
---
---@field delay? integer|nil
--- Extra debounce in milliseconds added on top of `updatetime` before showing blame.
--- Default: 0 (immediate after CursorHold). Example: 300–1000 for calmer UX.
---
---@field virt? boolean|nil
--- Request virtual-text overlay for blame when supported. Default: true.
---
---@field ignore_buftypes? Git.BufType[]|nil
--- Skip blame on these buffer types. Default: { "nofile", "prompt" }.

--------------------------------------------------------------------------------
-- Optional commands: health/spec (registered by orchestrator when enabled)
--------------------------------------------------------------------------------

---@class AutoCmds.Git.HealthCfg
---@field enable boolean
--- Enable registration of a health-check user command.
---
---@field cmd_name? string|nil
--- Name of the user command for health checks. Default: "GitAutocmdsHealth".
---
---@field open_win? boolean|nil
--- When true, render results into a scratch window; otherwise print/log.
--- Default: true.

---@class AutoCmds.Git.Spec.Cfg
---@field enable boolean
--- Enable registration of a lightweight spec/test command for helper functions.
---
---@field cmd_name? string|nil
--- Name of the user command for specs. Default: "GitAutocmdsSpec".

--------------------------------------------------------------------------------
-- Root configuration passed to `require('autocmds.git').enable(cfg)`
--------------------------------------------------------------------------------

--- Unresolved-conflict quickfix population is not here: it lives in
--- project-insight.nvim (`conflicts`), configured via its setup() spec.
---@class AutoCmds.Git.Cfg
---@field commit_ft? AutoCmds.Git.CommitFtCfg
--- Settings for `gitcommit` buffers (spelling, wrapping, rulers, etc.).
---
---@field gitsigns_refresh? AutoCmds.Git.GitsignsRefreshCfg
--- Settings for gitsigns refresh hooks.
---
---@field blame_on_hold? AutoCmds.Git.BlameOnHoldCfg
--- Settings for inline blame on idle cursor.
---
---@field health? AutoCmds.Git.HealthCfg|nil
--- Optional: user command for dependency/repo health diagnostics.
---
---@field spec? AutoCmds.Git.Spec.Cfg|nil
--- Optional: user command for unit-like specs of helper functions.

return {}
