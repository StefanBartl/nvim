---@meta
---@module 'autocmds.terminals.types'

---@class AutoCmds.Terminals
---@field enable fun(cfg: AutoCmds.Term.Cfg|nil): nil # Enable terminal-related autocommands per feature.

---@class AutoCmds.Term.NumbersCfg
---@field enable boolean                 -- Disable 'number' and 'relativenumber' in terminal buffers (local options).
---@field events? string[]|nil            -- Events to apply on (defaults to {"TermOpen"}).

---@class AutoCmds.Term.KittyCfg
---@field enable boolean                 -- Enable Kitty padding/margin tweaks on VimEnter/VimLeavePre.
---@field enter_padding? integer          -- Kitty window padding to set on VimEnter.
---@field enter_margin? integer           -- Kitty window margin to set on VimEnter.
---@field leave_padding? integer          -- Kitty window padding to restore on VimLeavePre.
---@field leave_margin? integer           -- Kitty window margin to restore on VimLeavePre.

---@class AutoCmds.Term.AutoInsertCfg
---@field enable boolean                 -- Enter Insert mode automatically when a terminal opens or is entered.
---@field events? string[]|nil            -- Events to trigger on (defaults to {"TermOpen"}).

---@class AutoCmds.Term.Cfg
---@field numbers AutoCmds.Term.NumbersCfg
---@field kitty AutoCmds.Term.KittyCfg
---@field auto_insert AutoCmds.Term.AutoInsertCfg

return {}
