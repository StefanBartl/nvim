---@class NeoTreeWslFM
---@field _cfg WslOpenConfig
---@field setup any
---@field open any

---@class WslOpenConfig
---@field backend "explorer"|"wslview"|"auto" # which launcher to use (default: "explorer")
---@field silent boolean                      # reduce notifications (default: true)

---@alias UnixPath string
---@alias WinPath string

---@class NeoTreeKeymaps
---@field window fun(): table<string, any>                 -- window.mappings
---@field filesystem fun(): table<string, any>             -- filesystem.window.mappings
---@field buffers fun(): table<string, any>                -- buffers.window.mappings
---@field git_status fun(): table<string, any>             -- git_status.window.mappings
---@field document_symbols fun(): table<string, any>       -- document_symbols.window.mappings
---@field setup_autocmds fun()

---@class NeoTreeFzf
---@field live_grep_node_dir fun(state: table): nil
