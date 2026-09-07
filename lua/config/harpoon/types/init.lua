---@meta
---@module 'config.harpoon.types'
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

--- A hand-written stand-in for harpoon's own `HarpoonList`, so this config
--- type-checks whether or not the plugin is on the runtimepath. Keep it in
--- sync with what `lua/config/harpoon/` actually calls -- a stand-in that
--- omits a member the callers use reports the CALLER as wrong, not itself
--- as incomplete.
---@class Cfg.Harpoon.List
---@field items (Cfg.Harpoon.Item|Cfg.Harpoon.ItemLegacy|string)[]  -- allow union
---@field _length integer  -- harpoon's own count; `#items` disagrees with it after a remove_at, which only nils the slot
---@field add fun(self: Cfg.Harpoon.List, item?: Cfg.Harpoon.Item|string): Cfg.Harpoon.List
---@field append fun(self: Cfg.Harpoon.List, item?: Cfg.Harpoon.Item|string): Cfg.Harpoon.List
---@field prepend fun(self: Cfg.Harpoon.List, item?: Cfg.Harpoon.Item|string): Cfg.Harpoon.List
---@field remove fun(self: Cfg.Harpoon.List, item?: Cfg.Harpoon.Item|string): Cfg.Harpoon.List
---@field remove_at fun(self: Cfg.Harpoon.List, index: integer): Cfg.Harpoon.List
---@field save fun(self: Cfg.Harpoon.List)

---@class Cfg.Harpoon.PersistPathsOpts
---@field target_specs string[][]|nil  -- list of path segments per target; first segment can be a variable like "$REPOS_DIR" or "$HOME"

---@class Cfg.Harpoon.HardeningState
---@field wrapped_ui boolean             -- has ui.toggle_quick_menu been wrapped already
---@field handle Lib.Debounce.Handle|nil -- reusable lib.nvim.debounce handle
---@field debounce_ms integer            -- current debounce interval (ms)
---@field pending boolean                -- whether there is pending work
---@field augroup integer|nil            -- HarpoonHardening augroup id

---@class Cfg.Harpoon.HardeningOpts
---@field debounce_ms integer|nil        -- default: 200; coalesces bursty save
---    triggers into a single write. Tuning guidance (SSD vs. network filesystems,
---    when to raise it): docs/NOTES/Harpoon.md §6.
---@field autocmd_events string[]|nil    -- default: { "BufLeave", "FocusLost" }
---    Which editor events trigger a debounced save. Extending this list (e.g.
---    "WinLeave", "FocusGained"): docs/NOTES/Harpoon.md §6.

--- CDX: never wired to a @param/@cast anywhere in this repo (normkey is an
--- external lib.nvim function); kept as local doc for its `realpath` option.
--- Wire it up or drop it?
---@class Cfg.Harpoon.NormKeyOpts
---@field realpath boolean|nil  -- default true (use fs_realpath if available)

return {}
