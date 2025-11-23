---@module 'config.neotree.keymaps.filesystem'
-- Filesystem-Source-specific extra mappings (unchanged) =========

---@return table<string, any>
return {
    ["d"] = "noop",
    ["/"] = "noop",
    ["f"] = "filter_on_submit",
    ["F"] = "fuzzy_finder",
    ["<C-c>"] = "clear_filter",
}
