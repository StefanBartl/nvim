---@module 'config.neotree.sources.icons'
---Centralized icon and display-name definitions for neo-tree sources.
---Supports multiple icon families, variants, and name lengths.
---This module does NOT decide which sources are enabled; it only formats them.

local M = {}

---@type table<string, Cfg.NeoTree.Sources.IconSet>
local ICONS = {

    common = {
        v1 = {
            filesystem       = { icon = "[DIR]", long = "File System",      short = "DIR" },
            buffers          = { icon = "[BUF]", long = "Buffers",          short = "BUF" },
            git_status       = { icon = "[GIT]", long = "Git Status",       short = "GIT" },
            document_symbols = { icon = "[SYM]", long = "Document Symbols", short = "SYM" },
            netman           = { icon = "[NET]", long = "Network",          short = "NET" },
            tests            = { icon = "[TST]", long = "Test Cases",       short = "TST" },
            diagnostics      = { icon = "[DIAG]", long = "Diagnostics",      short = "DIAG" },
        },
        v2 = {
            filesystem       = { icon = "[F]", long = "File System",      short = "F" },
            buffers          = { icon = "[B]", long = "Buffers",          short = "B" },
            git_status       = { icon = "[G]", long = "Git Status",       short = "G" },
            document_symbols = { icon = "[D]", long = "Document Symbols", short = "D" },
            netman           = { icon = "[N]", long = "Network",          short = "N" },
            tests            = { icon = "[T]", long = "Test Cases",       short = "T" },
            diagnostics      = { icon = "[Dx]", long = "Diagnostics",      short = "Dx" },
        },
    },

    nerd = {
        v1 = {
            filesystem       = { icon = "", long = "File System",      short = "FS" },
            buffers          = { icon = "", long = "Buffers",          short = "Buf" },
            git_status       = { icon = "", long = "Git Status",       short = "Git" },
            document_symbols = { icon = "", long = "Document Symbols", short = "Sym" },
            netman           = { icon = "", long = "Network",          short = "Net" },
            tests            = { icon = "⏱", long = "Test Cases",       short = "Tst" },
            diagnostics      = { icon = "", long = "Diagnostics",      short = "Diag" },
        },
        v2 = {
            filesystem       = { icon = "", long = "File System",      short = "FS" },
            buffers          = { icon = "", long = "Buffers",          short = "Buf" },
            git_status       = { icon = "", long = "Git Status",       short = "Git" },
            document_symbols = { icon = "", long = "Document Symbols", short = "Sym" },
            netman           = { icon = "", long = "Network",          short = "Net" },
            tests            = { icon = "", long = "Test Cases",       short = "Tst" },
            diagnostics      = { icon = "", long = "Diagnostics",      short = "Diag" },
        },
    },

    codicons = {
        v1 = {
            filesystem       = { icon = "", long = "File System",      short = "FS" },
            buffers          = { icon = "", long = "Buffers",          short = "Buf" },
            git_status       = { icon = "", long = "Git Status",       short = "Git" },
            document_symbols = { icon = "", long = "Document Symbols", short = "Sym" },
            netman           = { icon = "", long = "Network",          short = "Net" },
            tests            = { icon = "", long = "Test Cases",       short = "Tst" },
            diagnostics      = { icon = "", long = "Diagnostics",      short = "Diag" },
        },
        v2 = {
            filesystem       = { icon = "", long = "File System",      short = "FS" },
            buffers          = { icon = "", long = "Buffers",          short = "Buf" },
            git_status       = { icon = "", long = "Git Status",       short = "Git" },
            document_symbols = { icon = "", long = "Document Symbols", short = "Sym" },
            netman           = { icon = "", long = "Network",          short = "Net" },
            tests            = { icon = "", long = "Test Cases",       short = "Tst" },
            diagnostics      = { icon = "", long = "Diagnostics",      short = "Diag" },
        },
    },
}

---Formats a display name for neo-tree source selector.
---@param family string   -- common | nerd | codicons
---@param variant string  -- v1 | v2
---@param key string      -- filesystem | buffers | git_status | document_symbols | netman | tests
---@param length string   -- long | short
---@return string
function M.format(family, variant, key, length)
    local entry = ICONS[family][variant][key]
    return " " .. entry.icon .. " " .. entry[length]
end

---@type table<string, Cfg.NeoTree.Sources.IconVariant>
local icon_cache = {}

---Get icon for source (lazy generate)
---@param source_name string
---@param family Cfg.NeoTree.IconFamily
---@param variant Cfg.NeoTree.IconVariant
---@return string icon
function M.get_icon(source_name, family, variant)
  local cache_key = string.format("%s:%s:%s", source_name, family, variant)

  if icon_cache[cache_key] then
    return icon_cache[cache_key]
  end

  -- Generate icon on-demand
  local icon_set = ICONS[family][variant][source_name]
  local icon = icon_set and icon_set.icon or "?"

  icon_cache[cache_key] = icon
  return icon
end

return M

