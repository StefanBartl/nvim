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

    -- KORREKTUR: adapter_ids() gibt Array zurück, nicht Map
    local adapters = neotest.state.adapter_ids() or {}

    local lines = { "=== Neotest Adapters ===" }
    lines[#lines + 1] = ""

    -- KRITISCH: Richtige Iteration über Array
    for i = 1, #adapters do
      lines[#lines + 1] = string.format("[%d] %s", i, adapters[i])
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("Total: %d", #adapters)

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

    -- KORREKTUR: adapter_ids() gibt Array zurück
    local adapters = neotest.state.adapter_ids() or {}

    -- Test-Tree für aktuellen Buffer
    local tree_ok, tree = pcall(neotest.state.positions, bufname)

    local lines = { "=== Neotest Debug State ===" }
    lines[#lines + 1] = ""

    -- Registered Adapters
    lines[#lines + 1] = "Registered Adapters:"
    if #adapters == 0 then
      lines[#lines + 1] = "  (none)"
    else
      for i = 1, #adapters do
        lines[#lines + 1] = string.format("  • %s", adapters[i])
      end
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

  nvim_create_user_command("NeotestDebugRoot", function()
    local bufname = vim.api.nvim_buf_get_name(0)

    if bufname == "" then
      notify.warn("No file in current buffer")
      return
    end

    -- Test root detection
    local ts_config = require("config.neotest.adapters.typescript")
    local root = nil

    if ts_config and ts_config.adapter and ts_config.adapter.root then
      local ok, result = pcall(ts_config.adapter.root, bufname)
      if ok then
        root = result
      end
    end

    local lines = { "=== Root Detection Debug ===" }
    lines[#lines + 1] = string.format("File: %s", bufname)
    lines[#lines + 1] = string.format("Detected Root: %s", root or "NONE")

    -- Check for config files
    if root then
      local markers = { "vitest.config.ts", "package.json", "tsconfig.json" }
      lines[#lines + 1] = ""
      lines[#lines + 1] = "Found markers:"
      for _, marker in ipairs(markers) do
        local path = root .. "/" .. marker
        if vim.fn.filereadable(path) == 1 then
          lines[#lines + 1] = string.format("  ✓ %s", marker)
        end
      end
    end

    notify.info(table.concat(lines, "\n"))
  end, { desc = "[NeoTest Debug] Test root detection" })

  nvim_create_user_command("NeotestDebugFramework", function()
    local cwd = vim.fn.getcwd()

    local lines = { "=== Framework Detection ===" }
    lines[#lines + 1] = string.format("CWD: %s", cwd)
    lines[#lines + 1] = ""

    -- List all files in CWD
    lines[#lines + 1] = "Files in CWD root:"
    local files = vim.fn.glob(cwd .. "/*", false, true)
    for _, file in ipairs(files) do
      local name = vim.fn.fnamemodify(file, ":t")
      if name:match("^vitest%.config") or name:match("^jest%.config") or name == "package.json" then
        lines[#lines + 1] = string.format("  ✓ %s", name)
      end
    end
    lines[#lines + 1] = ""

    -- Check Vitest configs explicitly
    local vitest_configs = {
      "vitest.config.ts",
      "vitest.config.js",
      "vitest.config.mjs",
      "vitest.config.json",
    }

    lines[#lines + 1] = "Vitest config check:"
    local has_vitest = false
    for _, config in ipairs(vitest_configs) do
      local path = cwd .. "/" .. config
      local readable = vim.fn.filereadable(path)
      if readable == 1 then
        lines[#lines + 1] = string.format("  ✓ %s (EXISTS)", config)
        has_vitest = true
      else
        lines[#lines + 1] = string.format("  ✗ %s (not found)", config)
      end
    end
    lines[#lines + 1] = ""

    -- Check package.json
    local pkg_path = cwd .. "/package.json"
    lines[#lines + 1] = "package.json check:"
    if vim.fn.filereadable(pkg_path) == 1 then
      lines[#lines + 1] = "  ✓ EXISTS"

      local ok, pkg_lines = pcall(vim.fn.readfile, pkg_path)
      if ok and pkg_lines then
        local pkg_text = table.concat(pkg_lines, "\n")
        lines[#lines + 1] = string.format("  Size: %d bytes", #pkg_text)

        if pkg_text:match('"vitest"') then
          lines[#lines + 1] = '  ✓ Contains "vitest"'
        end
        if pkg_text:match('"jest"') then
          lines[#lines + 1] = '  ✓ Contains "jest"'
        end
      else
        lines[#lines + 1] = "  ✗ Cannot read file"
      end
    else
      lines[#lines + 1] = "  ✗ NOT FOUND"
    end

    notify.info(table.concat(lines, "\n"))
  end, { desc = "[NeoTest Debug] Framework detection details" })
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
