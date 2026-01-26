---@module 'config.neotree.keymaps.filesystem.filter'
--- Filter-related mappings for the Neo-tree filesystem source.

---@type table<string, any>
return {
  ["/"] = "noop",
  ["f"] = "filter_on_submit",
  ["F"] = "fuzzy_finder",
  ["<C-c>"] = "clear_filter",
}
