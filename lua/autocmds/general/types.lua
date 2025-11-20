---@meta
---@module 'autocmds.general.types'

---@class GeneralAutoCmdKittySpacingCfg
---@field enable boolean                  -- Enable kitty spacing tweaks on VimEnter/VimLeavePre
---@field enter_padding integer           -- Padding (pixels) to set on VimEnter
---@field enter_margin integer            -- Margin (pixels) to set on VimEnter
---@field leave_padding integer           -- Padding (pixels) to set on VimLeavePre
---@field leave_margin integer            -- Margin (pixels) to set on VimLeavePre

---@class GeneralGeneralAutoCmdCursorlineCfgcwd
---@field enable boolean                  -- Toggle cursorline only for the active window
---@field show_events string[]            -- Events that enable cursorline (e.g. { "InsertLeave", "WinEnter" })
---@field hide_events string[]            -- Events that disable cursorline (e.g. { "InsertEnter", "WinLeave" })

---@class GeneralAutoCmdJumpLastLocCfg
---@field enable boolean                  -- Jump to last cursor position on buffer read
---@field exclude string[]                -- Filetypes to exclude (e.g. { "gitcommit", "commit", "gitrebase" })
---@field mark? string                     -- Mark to jump to (usually the last-position mark: '"')

---@class GeneralAutoCmdAutoMkdirCfg
---@field enable boolean                  -- Auto-create directories on BufWritePre
---@field skip_remote boolean             -- Skip remote/URL-style buffers (e.g. scheme://)
---@field detect_remote_pattern? string    -- Lua pattern to detect remote buffers (default: "^%w%w+:[\\/][\\/]")

---@class GeneralAutoCmdConfig
---@field group_name? string               -- Basename for augroups created by this module
---@field auto_mkdir GeneralAutoCmdAutoMkdirCfg?  -- Configure auto mkdir on save
---@field kitty GeneralAutoCmdKittySpacingCfg?    -- Configure kitty terminal spacing
---@field cursorline GeneralGeneralAutoCmdCursorlineCfgcwd? -- Configure active-window-only cursorline
---@field last_loc GeneralAutoCmdJumpLastLocCfg?  -- Configure jump-to-last-location on open
