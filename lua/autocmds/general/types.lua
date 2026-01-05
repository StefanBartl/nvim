---@meta
---@module 'autocmds.general.types'

---@class AutoCmds.General.Kitty.SpacingCfg
---@field enable boolean                  -- Enable kitty spacing tweaks on VimEnter/VimLeavePre
---@field enter_padding integer           -- Padding (pixels) to set on VimEnter
---@field enter_margin integer            -- Margin (pixels) to set on VimEnter
---@field leave_padding integer           -- Padding (pixels) to set on VimLeavePre
---@field leave_margin integer            -- Margin (pixels) to set on VimLeavePre

---@class AutoCmds.General.Cursorline.Cfg
---@field enable boolean                  -- Toggle cursorline only for the active window
---@field show_events string[]            -- Events that enable cursorline (e.g. { "InsertLeave", "WinEnter" })
---@field hide_events string[]            -- Events that disable cursorline (e.g. { "InsertEnter", "WinLeave" })

---@class AutoCmds.General.JumpLastLoc.Cfg
---@field enable boolean                  -- Jump to last cursor position on buffer read
---@field exclude string[]                -- Filetypes to exclude (e.g. { "gitcommit", "commit", "gitrebase" })
---@field mark? string                     -- Mark to jump to (usually the last-position mark: '"')

---@class AutoCmds.General.AutoMkdir.Cfg
---@field enable boolean                  -- Auto-create directories on BufWritePre
---@field skip_remote boolean             -- Skip remote/URL-style buffers (e.g. scheme://)
---@field detect_remote_pattern? string    -- Lua pattern to detect remote buffers (default: "^%w%w+:[\\/][\\/]")

---@class AutoCmds.General.MD.GotoFile.Cfg
---@field enable boolean                 -- Enable Markdown-aware "gf" override for links/URLs.
---@field debug boolean?                  -- Emit verbose debug via vim.notify while resolving links.
---@field pattern string|string[]|nil?    -- FileType pattern(s) to attach on; defaults to "markdown".
---@field enable_windows_opener boolean?  -- Allow Windows opener branch (default false; Linux/macOS preferred).
---@field open_cmd_mac string[]|nil?     -- Override opener argv for macOS; default { "open", "<url>" }.
---@field open_cmd_unix string[]|nil?     -- Override opener argv for Linux/Unix; default { "xdg-open", "<url>" }.

---@class AutoCmds.General.Cfg
---@field group_name? string               -- Basename for augroups created by this module
---@field auto_mkdir AutoCmds.General.AutoMkdir.Cfg?  -- Configure auto mkdir on save
---@field kitty AutoCmds.General.Kitty.SpacingCfg?    -- Configure kitty terminal spacing
---@field cursorline AutoCmds.General.Cursorline.Cfg? -- Configure active-window-only cursorline
---@field last_loc AutoCmds.General.JumpLastLoc.Cfg?  -- Configure jump-to-last-location on open
---@field goto_file AutoCmds.General.MD.GotoFile.Cfg

return {}
