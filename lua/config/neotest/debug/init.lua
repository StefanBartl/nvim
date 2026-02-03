---@module 'config.neotest.debug'

local notify = require("lib.notify").create("[neotest.debug]")

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command

----------------------------------------------------------------------
-- User Commands
----------------------------------------------------------------------

function M.usercommands()
  nvim_create_user_command("NeotestDebugAdapters", function()
    local ok, neotest = pcall(require, "neotest")
    if not ok then
      notify.error("Neotest not loaded")
      return
    end

    local adapters = neotest.state.adapter_ids()

    local lines = { "=== Neotest Adapters ===" }
    lines[#lines + 1] = ""

    local count = 0
    for id, _ in pairs(adapters or {}) do
      count = count + 1
      lines[#lines + 1] = string.format("[%d] %s", count, id)
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("Total: %d", count)

    notify.info(table.concat(lines, "\n"))
  end, { desc = "[NeoTest Debug] Show adapter status" })

  nvim_create_user_command("NeotestDebugState", function()
    local ok, neotest = pcall(require, "neotest")
    if not ok then
      notify.error("Neotest not loaded")
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    -- Adapter-IDs
    local adapters = neotest.state.adapter_ids()

    -- Test-Tree für aktuellen Buffer
    local tree_ok, tree = pcall(neotest.state.positions, bufname)

    local lines = { "=== Neotest Debug State ===" }
    lines[#lines + 1] = ""

    -- Registered Adapters
    lines[#lines + 1] = "Registered Adapters:"
    local adapter_count = 0
    for id, _ in pairs(adapters or {}) do
      adapter_count = adapter_count + 1
      lines[#lines + 1] = string.format("  • %s", id)
    end
    if adapter_count == 0 then
      lines[#lines + 1] = "  (none)"
    end
    lines[#lines + 1] = ""

    -- Current Buffer
    lines[#lines + 1] = "Current Buffer:"
    lines[#lines + 1] = string.format("  Path: %s", bufname)
    lines[#lines + 1] = string.format("  Filetype: %s", vim.bo[bufnr].filetype)
    lines[#lines + 1] = ""

    -- Test Tree
    lines[#lines + 1] = "Test Tree:"
    if tree_ok and tree then
      lines[#lines + 1] = "  Found: YES"
      local name = tree.name or "?"
      lines[#lines + 1] = string.format("  Root: %s", name)
    else
      lines[#lines + 1] = "  Found: NO"
    end

    notify.info(table.concat(lines, "\n"))
  end, { desc = "[NeoTest Debug] Show current state" })

  nvim_create_user_command("NeotestDebugTree", function()
    local ok, neotest = pcall(require, "neotest")
    if not ok then
      notify.error("Neotest not loaded")
      return
    end

    local tree_ok, tree = pcall(neotest.state.positions)
    if not tree_ok or not tree then
      notify.warn("No test tree available")
      return
    end

    local lines = { "=== Test Tree ===" }

    local function dump(node, indent)
      indent = indent or 0
      local prefix = string.rep("  ", indent)

      local name = node.name or "?"
      local type_info = node.type or "unknown"

      lines[#lines + 1] = string.format("%s- %s (%s)", prefix, name, type_info)

      if node.children then
        for _, child in ipairs(node.children) do
          dump(child, indent + 1)
        end
      end
    end

    dump(tree)
    notify.info(table.concat(lines, "\n"))
  end, { desc = "[NeoTest Debug] Show test tree" })

  nvim_create_user_command("NeotestDebugFile", function()
    local bufname = vim.api.nvim_buf_get_name(0)

    if bufname == "" then
      notify.warn("No file in current buffer")
      return
    end

    local ok, neotest = pcall(require, "neotest")
    if not ok then
      notify.error("Neotest not loaded")
      return
    end

    local adapters = neotest.state.adapter_ids()

    local lines = { "=== File Test Status ===" }
    lines[#lines + 1] = string.format("File: %s", vim.fn.fnamemodify(bufname, ":t"))
    lines[#lines + 1] = string.format("Path: %s", bufname)

    local has_adapter = false
    for id, _ in pairs(adapters or {}) do
      if bufname:match(id:match("[^:]+$")) then
        lines[#lines + 1] = string.format("Adapter: %s", id)
        has_adapter = true
        break
      end
    end

    if not has_adapter then
      lines[#lines + 1] = "Adapter: NONE"
    end

    notify.info(table.concat(lines, "\n"))
  end, { desc = "[NeoTest Debug] Show file test status" })
end

----------------------------------------------------------------------
-- Keymaps
----------------------------------------------------------------------

function M.keymaps()
  local map = require("lib.map")

  map("n", "<leader>ntr", function()
    local ok, neotest = pcall(require, "neotest")
    if not ok then
      notify.error("Neotest not loaded")
      return
    end

    if neotest.state and type(neotest.state.clear) == "function" then
      pcall(neotest.state.clear)
    end

    notify.info("Forcing test discovery...")

    vim.defer_fn(function()
      local tree_ok, tree = pcall(neotest.state.positions)
      if tree_ok and tree then
        local count = 0
        local function count_tests(node)
          if node.type == "test" then
            count = count + 1
          end
          if node.children then
            for _, child in ipairs(node.children) do
              count_tests(child)
            end
          end
        end
        count_tests(tree)

        notify.info(string.format("Discovery complete: %d tests found", count))
      else
        notify.warn("No tests discovered")
      end
    end, 1000)
  end, {
    desc = "Refresh test discovery",
  })

  map("n", "<leader>ntD", function()
    local ok, neotest = pcall(require, "neotest")
    if not ok then
      notify.error("Neotest not loaded")
      return
    end

    local adapters = neotest.state.adapter_ids()

    local lines = { "Loaded adapters:" }
    for id, _ in pairs(adapters or {}) do
      lines[#lines + 1] = string.format("  • %s", id)
    end

    notify.info(table.concat(lines, "\n"))
  end, {
    desc = "Show loaded adapters",
  })
end

----------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------

function M.setup_all()
  M.keymaps()
  M.usercommands()
end

return M
