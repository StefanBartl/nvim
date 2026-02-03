---@module 'config.neotest.debug'

--[[
:NeotestDebugAdapter -> Show adapter status
:NeotestDebugState -> Show current state
:NeotestDebugTree -> Show test tree
:NeotestDebugFile -> Show file test status

<leader>ntr -> Refresh test discovery
<leader>ntD -> Show loaded adapters
--]]--

local notify = require("lib.notify").create("[neotest.debug]")

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command
local str_fmt = string.format

----------------------------------------------------------------------
-- Helper: Sichere Adapter-Abfrage
----------------------------------------------------------------------

--- Extrahiert Adapter-Informationen aus der Neotest-Konfiguration
---@return table<string, any>
local function get_adapter_info()
  local ok, neotest = pcall(require, "neotest")
  if not ok or not neotest.config then
    return {}
  end

  local info = {
    adapters = {},
    count = 0,
  }

  -- Adapter aus config.adapters extrahieren
  if neotest.config.adapters then
    for i, adapter in ipairs(neotest.config.adapters) do
      local adapter_name = "unknown"

      -- Versuche Name zu extrahieren
      if type(adapter) == "table" then
        if adapter.name then
          adapter_name = tostring(adapter.name)
        elseif adapter._adapter_name then
          adapter_name = tostring(adapter._adapter_name)
        elseif getmetatable(adapter) and getmetatable(adapter).__index then
          local mt = getmetatable(adapter).__index
          if type(mt) == "table" and mt.name then
            adapter_name = tostring(mt.name)
          end
        end
      end

      info.adapters[i] = {
        index = i,
        name = adapter_name,
        type = type(adapter),
      }
      info.count = info.count + 1
    end
  end

  return info
end

--- Versucht Adapter für spezifische Datei zu identifizieren
---@param filepath string
---@return string|nil adapter_name
local function find_adapter_for_file(filepath)
  local ok, neotest = pcall(require, "neotest")
  if not ok or not neotest.config or not neotest.config.adapters then
    return nil
  end

  -- Durchsuche alle Adapter
  for _, adapter in ipairs(neotest.config.adapters) do
    if type(adapter) == "table" and type(adapter.is_test_file) == "function" then
      local is_test = pcall(adapter.is_test_file, filepath)
      if is_test then
        -- Extrahiere Name
        if adapter.name then
          return tostring(adapter.name)
        elseif adapter._adapter_name then
          return tostring(adapter._adapter_name)
        end
        return "matched_adapter"
      end
    end
  end

  return nil
end

----------------------------------------------------------------------
-- User Commands
----------------------------------------------------------------------

function M.usercommands()
  nvim_create_user_command("NeotestDebugAdapters", function()
    local info = get_adapter_info()

    if info.count == 0 then
      notify.warn("No adapters configured")
      return
    end

    local lines = { "=== Neotest Adapters ===" }
    lines[#lines + 1] = str_fmt("Total: %d", info.count)
    lines[#lines + 1] = ""

    for _, adapter in ipairs(info.adapters) do
      lines[#lines + 1] = str_fmt("[%d] %s (%s)",
        adapter.index,
        adapter.name,
        adapter.type
      )
    end

    notify.info(table.concat(lines, "\n"))
  end, { desc = "[NeoTest Debug] Show adapter status" })

  nvim_create_user_command("NeotestDebugState", function()
    local ok, neotest = pcall(require, "neotest")
    if not ok then
      notify.error("Neotest not loaded")
      return
    end

    -- Adapter-Info sammeln
    local adapter_info = get_adapter_info()

    -- Buffer-Info
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    -- Test-Tree prüfen
    local tree_ok, tree = pcall(neotest.state.positions, bufname)

    -- Adapter für Datei finden
    local adapter_name = find_adapter_for_file(bufname)

    -- Output zusammenstellen
    local lines = { "=== Neotest Debug State ===" }
    lines[#lines + 1] = ""

    -- Registered Adapters
    lines[#lines + 1] = "Registered Adapters:"
    if adapter_info.count > 0 then
      for _, adapter in ipairs(adapter_info.adapters) do
        lines[#lines + 1] = str_fmt("  • %s", adapter.name)
      end
    else
      lines[#lines + 1] = "  (none)"
    end
    lines[#lines + 1] = ""

    -- Current Buffer
    lines[#lines + 1] = "Current Buffer:"
    lines[#lines + 1] = str_fmt("  Path: %s", bufname)
    lines[#lines + 1] = str_fmt("  Filetype: %s", vim.bo[bufnr].filetype)
    lines[#lines + 1] = ""

    -- Test Tree
    lines[#lines + 1] = "Test Tree:"
    if tree_ok and tree then
      lines[#lines + 1] = "  Found: YES"
      lines[#lines + 1] = str_fmt("  Root: %s", tree.name or "?")
    else
      lines[#lines + 1] = "  Found: NO"
    end
    lines[#lines + 1] = ""

    -- Adapter for file
    lines[#lines + 1] = "Adapter for file:"
    lines[#lines + 1] = str_fmt("  %s", adapter_name or "NONE")

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

      lines[#lines + 1] = str_fmt("%s- %s (%s)", prefix, name, type_info)

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

    local adapter_name = find_adapter_for_file(bufname)

    local lines = { "=== File Test Status ===" }
    lines[#lines + 1] = str_fmt("File: %s", vim.fn.fnamemodify(bufname, ":t"))
    lines[#lines + 1] = str_fmt("Path: %s", bufname)
    lines[#lines + 1] = str_fmt("Adapter: %s", adapter_name or "NONE")

    if adapter_name then
      lines[#lines + 1] = ""
      lines[#lines + 1] = "✓ File is recognized as test file"
    else
      lines[#lines + 1] = ""
      lines[#lines + 1] = "✗ File is NOT recognized as test file"
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

    -- Clear all state
    if neotest.state then
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

        notify.info(str_fmt("Discovery complete: %d tests found", count))
      else
        notify.warn("No tests discovered")
      end
    end, 1000)
  end, {
    desc = "Refresh test discovery",
  })

  map("n", "<leader>ntD", function()
    local info = get_adapter_info()

    if info.count == 0 then
      notify.warn("No adapters loaded")
      return
    end

    local lines = { "Loaded adapters:" }
    for _, adapter in ipairs(info.adapters) do
      lines[#lines + 1] = str_fmt("  • %s", adapter.name)
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
