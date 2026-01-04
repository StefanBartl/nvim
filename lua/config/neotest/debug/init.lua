---@module 'config.neotest.debug'

local neotest = require("neotest")
local map = require("lib.map")
local notify = require("lib.notify").create("[neotest.debug] ")

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command
local str_fmt = string.format

---@return nil
function M.keymaps()
  map("n", "<leader>ntr", function()
    if neotest.state then
      pcall(neotest.state.clear)
    end
    notify.info("Forcing test discovery...")
    vim.defer_fn(function()
      local tree = neotest.state.positions()
      if tree then
        notify.info("Tests found: " .. vim.tbl_count(tree))
      else
        notify.warn("No tests discovered")
      end
    end, 1000)
  end, {
    desc = "Refresh test discovery",
  })

  map("n", "<leader>ntD", function()
    local adapters = neotest.config.adapters or {}
    local msg = "Loaded adapters:\n"
    for i, adapter in ipairs(adapters) do
      local name = type(adapter) == "table" and adapter.name or tostring(adapter)
      msg = msg .. str_fmt("[%d] %s\n", i, name)
    end
    notify.info(msg)
  end, {
    desc = "Show loaded adapters",
  })
end

---@return nil
function M.usercommands()
  nvim_create_user_command("NeotestDebugAdapters", function()
    if not neotest.config or not neotest.config.adapters then
      notify.warn("No adapters configured")
      return
    end

    local lines = { "=== Neotest Adapters ===" }
    for i, adapter in ipairs(neotest.config.adapters) do
      local name = type(adapter) == "table" and adapter.name or tostring(adapter)
      table.insert(lines, str_fmt("[%d] %s", i, name))
    end

    notify.info(table.concat(lines, "\n"))
  end, { desc = "[NeoTest Debug] Show adapter status" })

  nvim_create_user_command("NeotestDebugTree", function()
    local tree = neotest.state.positions()
    if not tree then
      notify.warn("No test tree available")
      return
    end

    local lines = { "=== Test Tree ===" }
    local function dump(node, indent)
      indent = indent or 0
      local prefix = string.rep("  ", indent)
      table.insert(lines, prefix .. "- " .. (node.name or "?"))
      if node.children then
        for _, child in ipairs(node.children) do
          dump(child, indent + 1)
        end
      end
    end
    dump(tree)

    notify.info(table.concat(lines, "\n"))
  end, { desc = "[NeoTest Debug] Show test tree" })
end

---@return nil
function M.setup_all()
  M.keymaps()
  M.usercommands()
end

return M
