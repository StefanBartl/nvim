---@meta

---@class LiveGrepRgConfig
---@field binary string
---@field hidden boolean
---@field follow boolean
---@field smart_case boolean
---@field glob string[]

---@class LiveGrepTelescopeConfig
---@field preview boolean

---@class LiveGrepFzfConfig
---@field preview boolean

---@class LiveGrepConfig
---@field picker? "telescope"|"fzf"
---@field keymap? string
---@field separator? string
---@field cwd? string
---@field prompt? string
---@field rg LiveGrepRgConfig
---@field telescope LiveGrepTelescopeConfig
---@field fzf LiveGrepFzfConfig
