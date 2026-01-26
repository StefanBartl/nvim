---@module 'config.neotree.keymaps.filesystem.info'

local notify = require("lib.notify").create("[cfg.neotree.keymaps.fs.info] ")

local node_utils = require("config.neotree.utils.node")
local to_require = require("config.neotree.actions.path.to_require")
local node_info = require("config.neotree.actions.info.node")

---@type table<string, any>
return {
  ["I"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      node_info.show_from_neotree(state)
    end,
    desc = "Show file or directory information (hover)",
  },

  ["<leader>fm"] = {
    function(state)
      local ok, filemanager = pcall(require, "config.neotree.open.filemanager")
      if not ok then
        notify.error("File manager module not loaded")
        return
      end

      local success = filemanager.open_from_neotree(state)
      if not success then
        notify.warn("Failed to open in file manager")
      end
    end,
    desc = "Open in system file manager",
  },

  ["<leader>sm"] = {
    function(state)
      require("config.neotree.open.system_app").open_from_neotree(state)
    end,
    desc = "Open with System Application",
  },

  ["rq"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      to_require.copy_as_require(node, {
        relative = true,
        show_preview = true,
      })
    end,
    desc = "Copy Lua require() string(s)",
  },
}
