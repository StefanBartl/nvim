---@module 'autocmds.markdown.defaults'

---@type MdAutoCmdsCfg
local defaults = {
  wrap_key = {
    enable = true,
    key = "<leader>[",
    description = "Wrap current word in Markdown link syntax",
    pattern = "*",
    only_modifiable = true,
  },
  goto_file = {
    enable = true,
    debug = false,
    pattern = "*",
    enable_windows_opener = false,
    open_cmd_mac = nil,
    open_cmd_unix = nil,
    alternate_similarity_threshold = 75,
  },
}

-- Return the defaults table directly, not wrapped in M.defaults
return defaults
