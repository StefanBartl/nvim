---@module 'autocmds.git.defaults'

-- AUDIT: Optionen beschreiben

---@type AutoCmds.Git.Cfg
local AUTOCMDS_GIT_DEFAULTS = {
  conflicts_qf = {
    enable = true,
    events = { "VimEnter" },
    diff_filter = "U",
    open_qf = true,
    notify = true,
    git_cmd = "git",
  },
  commit_ft = {
    enable = true,
    spell = true,
    textwidth = 72,
    colorcolumn = "73",
    formatoptions = "tcqj",
    start_in_insert = false,
  },
  conflict_marks = {
    enable = true,
    hl_a = "DiffDelete",
    hl_b = "DiffChange",
    hl_c = "DiffAdd",
  },
  gitsigns_refresh = {
    enable = true,
    events = { "BufEnter", "FocusGained" },
  },
  blame_on_hold = {
    enable = false,
    delay = 0,
    virt = true,
    ignore_buftypes = { "nofile", "prompt" },
  },
  line_diff_on_hold = {
    enable = true, -- master switch for this feature
    modes = "n", -- run in Normal+Visual; omit Insert (use "i" to include)
    delay = 3000, -- extra debounce (ms) beyond 'updatetime' before running
    hl_prev = "Comment", -- highlight group for fallback EOL preview text
    virt_priority = 1000, -- extmark virt_text priority
    max_len = 160, -- truncate fallback preview to this many characters
    git_cmd = "git", -- git executable to use
    ignore_buftypes = { "nofile", "prompt", "terminal" }, -- skip on these buftypes

    -- Filters and presentation tweaks
    only_tracked = true, -- only run on git-tracked files (skip new/untracked)
    require_clean_buffer = false, -- when true, skip if buffer has unsaved changes
    prefix = "previous: ", -- prefix before fallback EOL preview text
    right_align = false, -- when true, place virt_text with 'right_align' instead of 'eol'

    -- Event control
    -- events_override = { "CursorHold", "CursorHoldI" }, -- uncomment to fully override auto-mapped events

    -- Inline preview behavior and stability
    prefer_inline = true, -- prefer gitsigns.preview_hunk_inline() when available
    restore_view = true, -- save/restore winsaveview()+cursor to avoid scroll jumps
    throttle_ms = 1200, -- min time (ms) between triggers per window to reduce re-renders
  },
}

local M = {}

---@return AutoCmds.Git.Cfg
function M.get_defaults()
  return AUTOCMDS_GIT_DEFAULTS
end

return M

