---@module 'config.neotree.keymaps.filesystem.path'

local notify = require("lib.notify").create("[cfg.neotree.keymaps.fs.path] ")

local node_utils = require("config.neotree.utils.node")
local copy_entries = require("config.neotree.actions.copy.entries")
local copy_folders = require("config.neotree.actions.copy.folders")
local fn = vim.fn

---@type table<string, any>
return {
  ["[a"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local path, _ = node_utils.get_path(node)
      if path == "" then
        notify.info("no path")
        return
      end

      fn.setreg("+", path, "c")
      notify.info(("copied: %s"):format(path))
    end,
    desc = "Copy absolute path (+)",
  },

  ["]a"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local path, is_dir = node_utils.get_path(node)
      if path == "" then
        notify.info("no path")
        return
      end

      local base = is_dir and path or fn.fnamemodify(path, ":h")
      fn.setreg("+", base, "c")
      notify.info(("copied: %s"):format(base))
    end,
    desc = "Copy base (dir) absolute path (+)",
  },

  ["[f"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_entries(state, {
        relative_to_cwd = false,
        preview_limit = 20,
        quote_paths = false,
        format = "list",
      })
      if not success then
        notify.warn("Failed to copy file list")
      end
    end,
    desc = "Copy absolute file path (file node) or recursive file list (folder node) to clipboard (reg +)",
  },

  ["]f"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_entries(state, {
        relative_to_cwd = true,
        preview_limit = 20,
        quote_paths = false,
        format = "list",
      })
      if not success then
        notify.warn("Failed to copy file list")
      end
    end,
    desc = "Copy relative file path (file node) or recursive file list (folder node) to clipboard (reg +) (relative to cwd)",
  },

  ["[F"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_folders(state, { relative_to_cwd = false, preview_limit = 20 })
      if not success then
        notify.warn("Failed to copy folder list")
      end
    end,
    desc = "Copy absolute folder path (file node) or recursive folder list (folder node) to clipboard (reg +)",
  },

  ["]F"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_folders(state, { relative_to_cwd = true, preview_limit = 20 })
      if not success then
        notify.warn("Failed to copy folder list")
      end
    end,
    desc = "Copy relative folder path (file node) or recursive folder list (folder node) to clipboard (reg +) (relative to cwd)",
  },
}
