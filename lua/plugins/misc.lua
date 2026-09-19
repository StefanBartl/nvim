---@module 'plugins.misc'
--- Small plugins with no group of their own, and whatever else lands here
--- rather than earning its own file. `plugins.control.mode` lets a repo be
--- disabled centrally instead of `enabled = false` scattered per-spec.
---
--- harpoon (`ThePrimeagen/harpoon`) lived here until 2026-09-19, when it was
--- cut over to sessions.nvim's `marks` feature (plugins/personal/init.lua) --
--- see docs/ROADMAP/reports/Externe-Plugins-Nachbau-Analyse.md, 7.4.

local plugins = require("plugins.control.mode").new()

-- Disable repos centrally here (basename -> "disabled"), instead of setting
-- `enabled = false` in each individual spec below.
plugins.modes({})

plugins.add({})

return plugins.export()
