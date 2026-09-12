---@meta
---@module 'autocmds.general.@types'

---@class AutoCmds.General
---@field enable fun(cfg: AutoCmds.General.Cfg|nil|nil): nil # Enable general autocommands per feature.

---@class AutoCmds.General.Cursorline.Cfg
---@field enable boolean                             -- Toggle cursorline only for the active window
---@field show_events? string[]                      -- Events that enable cursorline (e.g. { "InsertLeave", "WinEnter" })
---@field hide_events? string[]                      -- Events that disable cursorline (e.g. { "InsertEnter", "WinLeave" })

---@class AutoCmds.General.NoNameGuard.Cfg
---@field enable boolean  -- After a buffer is deleted/wiped or a window closes, redirect any window
-- left showing a spurious empty [No Name] buffer to a real, named buffer
-- instead — but only when one actually exists. Never touches a [No Name]
-- buffer that wasn't just left behind by a close (e.g. a deliberate `:enew`,
-- or a plugin's own scratch buffer), and never fabricates a replacement —
-- if no other named buffer is open, the [No Name] buffer is left alone
-- (e.g. the last file buffer closes, or a tree plugin is the only window
-- left with `close_if_last_window = false`).

---@class AutoCmds.General.MD.GotoFile.Cfg
---@field enable boolean                             -- Enable Markdown-aware "gf" override for links/URLs.
---@field debug? boolean                             -- Emit verbose debug via vim.notify while resolving links.
---@field pattern? string|string[]|nil               -- FileType pattern(s) to attach on; defaults to "markdown".
---@field enable_windows_opener? boolean             -- Allow Windows opener branch (default false; Linux/macOS preferred).
---@field open_cmd_mac? string[]|nil                 -- Override opener argv for macOS; default { "open", "<url>" }.
---@field open_cmd_unix? string[]|nil                -- Override opener argv for Linux/Unix; default { "xdg-open", "<url>" }.

---@class AutoCmds.General.Cfg
---@field group_name? string                          -- Basename for augroups created by this module
---@field cursorline AutoCmds.General.Cursorline.Cfg -- Configure active-window-only cursorline
---@field no_name_guard AutoCmds.General.NoNameGuard.Cfg -- Configure the spurious [No Name] buffer guard

return {}
