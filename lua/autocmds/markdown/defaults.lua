---@module 'autocmds.markdown.defaults'

---@type MdAutoCmdsCfg
local defaults = {
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
