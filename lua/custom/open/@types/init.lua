---@module 'custom.open.@types'
---@brief Type definitions for the :Open command module.
---@description
--- Pure annotation target — no executable code.
--- Defines shared types used across all sub-modules.

-- ---------------------------------------------------------------------------
-- Handler keys
-- ---------------------------------------------------------------------------

---@alias Custom.Open.HandlerKey
---| '"browser"'        # System default browser
---| '"chrome"'         # Google Chrome / Chromium
---| '"chromium"'       # Chromium
---| '"edge"'           # Microsoft Edge
---| '"firefox"'        # Mozilla Firefox
---| '"safari"'         # Safari (macOS only)
---| '"filemanager"'    # System file manager
---| '"notepad"'        # System default text editor
---| '"editor"'         # Alias for notepad
---| '"split"'          # Open file in Neovim horizontal split
---| '"vsplit"'         # Open file in Neovim vertical split
---| '"tab"'            # Open file in Neovim new tab
---| string             # User-registered extension key

-- ---------------------------------------------------------------------------
-- Platform descriptor
-- ---------------------------------------------------------------------------

---Platform flags determined once at startup and cached for the session.
---@class Custom.Open.Platform
---@field is_win   boolean  True on native Windows (win32 or win64 build)
---@field is_mac   boolean  True on macOS
---@field is_wsl   boolean  True when running inside WSL (Linux kernel, Windows host)
---@field is_linux boolean  True on any Linux (including WSL)

-- ---------------------------------------------------------------------------
-- Context
-- ---------------------------------------------------------------------------

---Text and metadata extracted from the cursor position or visual selection.
---Passed to every handler's run() function.
---@class Custom.Open.Context
---@field text    string   Raw text: WORD under cursor (normal) or visual selection
---@field is_url  boolean  True when text matches a URL heuristic (http/https/ftp/www)
---@field is_path boolean  True when text matches a path heuristic or exists on disk

-- ---------------------------------------------------------------------------
-- Handler contract
-- ---------------------------------------------------------------------------

---A handler registered in the Open registry.
---@class Custom.Open.Handler
---@field key  string                                  Unique completion key, e.g. "chrome"
---@field desc string                                  Human-readable one-line description
---@field run  fun(ctx: Custom.Open.Context): boolean  Returns true when dispatch succeeded

-- ---------------------------------------------------------------------------
-- Config
-- ---------------------------------------------------------------------------

---@class Custom.Open.Config
---@field default_handler string|nil  Handler used when :Open is called without args

return {}
