---@module 'config.neotree.init.default_component_config'

return {
  indent = {
    with_expanders = false,
  },
  icon = {
    folder_empty = "",
    folder_empty_open = "",
    default = "",
    folder_closed = "",
    folder_open = "",
    highlight = "NeoTreeFileIcon",
  },
  modified = {
    symbol = "[+]",
    highlight = "NeoTreeModified",
  },
  name = {
    trailing_slash = true,
    use_git_status_colors = false,
    highlight_opened_files = true,
    highlight = "NeoTreeFileName",
  },
  git_status = {
    symbols = {
      added = "A",
      deleted = "D",
      modified = "M",
      renamed = "R",
      unstaged = "✗",
      staged = "✓",
      untracked = "★",
      ignored = "◌",
      conflict = "C",
    },
  },
}
