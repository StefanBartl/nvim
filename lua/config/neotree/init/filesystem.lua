---@module 'config.neotree.init.filesystem'

local FILESYSTEM = require("config.neotree.keymaps.filesystem")

return {
  bind_to_cwd = true,
  find_by_full_path_words = true,
  -- Automatically expand all parent nodes required to reveal the currently active buffer.
  follow_current_file = {
    enabled = true,
    -- When true, Neo-tree focuses the tree and selects the file.
    -- When false, the tree updates silently in the background.
    leave_dirs_open = false,
  },
  group_empty_dirs = true,
  use_libuv_file_watcher = true,
  window = {
    position = require("config.neotree").get_default_position(),
    mappings = FILESYSTEM,
  },
  filtered_items = {
    visible = true,
    hide_dotfiles = false,
    hide_gitignored = false,
    hide_hidden = false,
    hide_by_pattern = {},
    hide_by_name = require("lib.fs.ignore.list").as_neotree_names(),
    never_show = {},
    never_show_by_pattern = {},
  },
}
