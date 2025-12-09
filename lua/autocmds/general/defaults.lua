---@module 'autocmds.general.defaults'

---@type GeneralAutoCmdConfig
local defaults = {
  group_name = "custom_autocmds",

  auto_mkdir = {
    enable = true,
    skip_remote = true,
    -- Matches e.g. "xx://", "ssh://", "http://", "file://", on both slash styles
    detect_remote_pattern = "^%w%w+:[\\/][\\/]",
  },

  kitty = {
    enable = false, -- Disabled by default; only meaningful inside Kitty
    enter_padding = 0,
    enter_margin = 0,
    leave_padding = 20,
    leave_margin = 10,
  },

  nvdash = {
    enable = true,
    cmd = "Nvdash",
    is_listed_only = true, -- Consider only listed buffers when deciding "last buffer"
  },

  cursorline = {
    enable = true,
    show_events = { "InsertLeave", "WinEnter" },
    hide_events = { "InsertEnter", "WinLeave" },
  },

  last_loc = {
    enable = true,
    exclude = { "gitcommit", "commit", "gitrebase" },
    mark = '"',
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

return defaults
