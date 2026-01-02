---@module 'config.neotree.sources.icons'
---Centralized icon and display-name definitions for neo-tree sources.
---Supports multiple icon families, variants, and name lengths.
---This module does NOT decide which sources are enabled; it only formats them.

---@class NeoTreeSourceIcon
---@field icon string        -- Icon glyph (can be empty for common/text mode)
---@field long string        -- Long display name
---@field short string       -- Short display name

---@class NeoTreeIconVariant
---@field filesystem NeoTreeSourceIcon
---@field buffers NeoTreeSourceIcon
---@field git_status NeoTreeSourceIcon
---@field document_symbols NeoTreeSourceIcon
---@field netman NeoTreeSourceIcon
---@field tests NeoTreeSourceIcon

---@class NeoTreeIconSet
---@field v1 NeoTreeIconVariant
---@field v2 NeoTreeIconVariant

local M = {}

---@type table<string, NeoTreeIconSet>
local ICONS = {

    common = {
        v1 = {
            filesystem       = { icon = "[DIR]", long = "File System",      short = "DIR" },
            buffers          = { icon = "[BUF]", long = "Buffers",          short = "BUF" },
            git_status       = { icon = "[GIT]", long = "Git Status",       short = "GIT" },
            document_symbols = { icon = "[SYM]", long = "Document Symbols", short = "SYM" },
            netman           = { icon = "[NET]", long = "Network",          short = "NET" },
            tests            = { icon = "[TST]", long = "Test Cases",       short = "TST" },
        },
        v2 = {
            filesystem       = { icon = "[F]", long = "File System",      short = "F" },
            buffers          = { icon = "[B]", long = "Buffers",          short = "B" },
            git_status       = { icon = "[G]", long = "Git Status",       short = "G" },
            document_symbols = { icon = "[D]", long = "Document Symbols", short = "D" },
            netman           = { icon = "[N]", long = "Network",          short = "N" },
            tests            = { icon = "[T]", long = "Test Cases",       short = "T" },
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
        },
        v2 = {
            filesystem       = { icon = "", long = "File System",      short = "FS" },
            buffers          = { icon = "", long = "Buffers",          short = "Buf" },
            git_status       = { icon = "", long = "Git Status",       short = "Git" },
            document_symbols = { icon = "", long = "Document Symbols", short = "Sym" },
            netman           = { icon = "", long = "Network",          short = "Net" },
            tests            = { icon = "", long = "Test Cases",       short = "Tst" },
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
        },
        v2 = {
            filesystem       = { icon = "", long = "File System",      short = "FS" },
            buffers          = { icon = "", long = "Buffers",          short = "Buf" },
            git_status       = { icon = "", long = "Git Status",       short = "Git" },
            document_symbols = { icon = "", long = "Document Symbols", short = "Sym" },
            netman           = { icon = "", long = "Network",          short = "Net" },
            tests            = { icon = "", long = "Test Cases",       short = "Tst" },
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

return M

