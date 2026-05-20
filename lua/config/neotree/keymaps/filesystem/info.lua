---@module 'config.neotree.keymaps.filesystem.info'

local notify = require("lib.notify").create("[cfg.neotree.keymaps.fs.info] ")

local node_utils = require("config.neotree.utils.node")
local line_counter = require("config.neotree.utils.line_count")
local to_require = require("config.neotree.actions.path.to_require")
local node_info = require("config.neotree.actions.info.node")

---@type table<string, any>
return {
  ["I"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      -- Resolve node via canonical utility (never direct state access)
      local node = node_utils.get_current(state)
      if not node then
        notify.warn("No node under cursor")
        return
      end

      -- Count lines lazily, on-demand only for text/source files
      -- Result is passed as a plain value — no side effects on the node object
      local line_count = nil
      if node.type == "file" then
        local path = node.path
        if type(path) == "nil" then
          notify.warn("path is nil")
          return
        end
        local raw_ext = vim.fn.fnamemodify(path, ":e")
        local ext = (raw_ext ~= "") and raw_ext or nil

        if type(path) == "string" and path ~= "" then
          line_count = line_counter.count(path, ext)
        end
      end

      -- Delegate display; carry computed metadata via opts (pure data flow)
      node_info.show_from_neotree(state, { line_count = line_count })
    end,
    desc = "Show file or directory information (hover with line count)",
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
