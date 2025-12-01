---@module 'autocmds.markdown.defaults'

local M = {}

---@type MdAutoCmdsCfg
M.defaults = {
  wrap_key = {
    enable = true,
    key = "<leader>[",
    description = "Wrap current word in Markdown link syntax",
    pattern = "markdown",
    only_modifiable = true,
  },
  goto_file = {
    enable = true,
    debug = true,
    pattern = "markdown",
    enable_windows_opener = false, -- keep Linux/macOS default per project policy
    open_cmd_mac = nil, -- e.g., { "open", "<url>" }
    open_cmd_unix = nil, -- e.g., { "xdg-open", "<url>" }
  },
}

return M
