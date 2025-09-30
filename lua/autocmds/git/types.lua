---@class GitAutoCmdsConflictsQfCfg
---@field enable boolean
---@field events string[]|nil
---@field diff_filter string|nil
---@field open_qf boolean|nil
---@field notify boolean|nil
---@field git_cmd string|nil

---@class GitAutoCmdsCommitFtCfg
---@field enable boolean
---@field spell boolean|nil
---@field textwidth integer|nil
---@field colorcolumn string|nil
---@field formatoptions string|nil
---@field start_in_insert boolean|nil

---@class GitAutoCmdsConflictMarksCfg
---@field enable boolean
---@field hl_a string|nil
---@field hl_b string|nil
---@field hl_c string|nil

---@class GitAutoCmdsGitsignsRefreshCfg
---@field enable boolean
---@field events string[]|nil

---@class GitAutoCmdsBlameOnHoldCfg
---@field enable boolean
---@field delay integer|nil
---@field virt boolean|nil
---@field ignore_buftypes string[]|nil

---@class GitAutoCmdsLineDiffOnHoldCfg
---@field enable boolean                 -- Show how the current line differs (inline) when the cursor rests.
---@field delay integer|nil              -- Extra debounce in ms (added to 'updatetime'); default 0.
---@field hl_prev string|nil             -- Highlight group for “previous” text; default "Comment".
---@field virt_priority integer|nil      -- Virtual text priority; default 1000.
---@field max_len integer|nil            -- Truncate previous-line preview to this many chars; default 160.
---@field git_cmd string|nil             -- Git executable; default "git".
---@field ignore_buftypes string[]|nil   -- Skip these buftypes; default { "nofile", "prompt", "terminal" }.

---@class GitAutoCmdsCfg
---@field conflicts_qf GitAutoCmdsConflictsQfCfg
---@field commit_ft GitAutoCmdsCommitFtCfg
---@field conflict_marks GitAutoCmdsConflictMarksCfg
---@field gitsigns_refresh GitAutoCmdsGitsignsRefreshCfg
---@field blame_on_hold GitAutoCmdsBlameOnHoldCfg
---@field line_diff_on_hold GitAutoCmdsLineDiffOnHoldCfg
