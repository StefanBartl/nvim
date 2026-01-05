---@meta
---@module 'types.harpoon'
-- Add these or adapt your existing type file accordingly.

---@alias Cfg.Harpoon.Value string

---@class Cfg.Harpoon.Context
---@field row integer  -- 1-based
---@field col integer  -- 0-based

---@class Cfg.Harpoon.Item
---@field value Cfg.Harpoon.Value
---@field context Cfg.Harpoon.Context|nil

--- Legacy or non-standard item shapes sometimes found in older setups:
---@class Cfg.Harpoon.ItemLegacy
---@field path string|nil         -- legacy field; may be present
---@field value string|nil        -- might be missing; normalize it
---@field context Cfg.Harpoon.Context|nil

---@class Cfg.Harpoon.List
---@diagnostic disable-next-line duplicate field
---@field items (Cfg.Harpoon.Item|Cfg.Harpoon.ItemLegacy|string)[]  -- allow union
---@field remove fun(self: Cfg.Harpoon.List, index: integer)
---@field save fun(self: Cfg.Harpoon.List)

---@class Cfg.Harpoon.Api
---@field list fun(self: Cfg.Harpoon.Api): Cfg.Harpoon.List
---@field save fun(self: Cfg.Harpoon.Api)
---@field setup fun(self: Cfg.Harpoon.Api, opts: table)

---@class Cfg.Harpoon.PersistPathsOpts
---@field target_specs string[][]|nil  -- list of path segments per target; first segment can be a variable like "$REPOS_DIR" or "$HOME"

---@type uv uv

---@class Cfg.Harpoon.HardeningState
---@field timer uv.uv_timer_t|nil        -- reusable libuv timer handle
---@field debounce_ms integer            -- current debounce interval (ms)
---@field pending boolean                -- whether there is pending work

---@class Cfg.Harpoon.HardeningOpts
---@field debounce_ms integer|nil        -- default: 200
---    Coalesce multiple "save" triggers into a single write. Prevents IO bursts
---    when you quickly switch buffers, toggle the quick menu, or alt-tab a lot.
---  Good defaults:
---    150–300 on local SSDs; 300–600 on network/remote filesystems (SMB/NFS/SSHFS).
---  Tips:
---    - If you still see frequent writes, increase by +100ms steps.
---    - If the last change occasionally isn't persisted when you quit very fast,
---      keep debounce_ms moderate (<= 400) — final flush on VimLeavePre is handled.
---
---@field autocmd_events string[]|nil    -- default: { "BufLeave", "FocusLost" }
---    Which editor events should trigger a debounced save.
---  Typical choices:
---    { "BufLeave", "FocusLost" }              -- fast and quiet; great default
---  When to extend:
---    - Add "WinLeave"     : if you hop between windows constantly (splits/tabs)
---    - Add "FocusGained"  : if you want a save even when returning to Neovim
---    - Add "BufHidden"    : for setups that hide buffers instead of unloading
---    - Add "CmdlineLeave" : if your workflow edits harpoon from custom commands
---  Notes:
---    - More events = more chances to save, but also more timer restarts.
---    - You don't need a quit event; a non-debounced final flush runs on VimLeavePre.

---@class Cfg.Harpoon.NormKeyOpts
---@field realpath boolean|nil  -- default true (use fs_realpath if available)

return {}
