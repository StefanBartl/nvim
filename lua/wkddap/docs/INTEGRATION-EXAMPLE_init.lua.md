-- ============================================================================
-- EXAMPLE: Integrating DAP into your init.lua
-- ============================================================================

-- Add to your existing init.lua after plugin setup:

-- Load DAP module
require("wkddap").setup({
  -- Languages to enable (empty = all available)
  languages = {
    "lua",
    "javascript",
    "typescript",
    "go",
    "python",
    "rust",
    "c",
    "cpp",
  },

  -- UI configuration
  ui = {
    enable = true,
    virtual_text = true,
    signs = true,
    highlights = true,
  },

  -- Keymap configuration
  keymaps = {
    enable = true,
    prefix = "<leader>d", -- Change to your preference
  },

  -- Commands and autocommands
  commands = {
    enable = true,
    autocmds = true,
  },

  -- Mason auto-install (set to true to automatically install missing adapters)
  auto_install = false,

  -- Logging level
  log_level = vim.log.levels.WARN,
})

-- ============================================================================
-- Optional: Custom Commands
-- ============================================================================

-- Quick access to DAP log
vim.api.nvim_create_user_command("DapLog", function()
  vim.cmd("edit " .. require("wkddap.config").get_log_path())
end, { desc = "[DAP] Open debug log" })

-- Registry statistics
vim.api.nvim_create_user_command("DapInfo", function()
  local stats = require("wkddap.registry").stats()
  local enabled = require("wkddap.registry").enabled_languages()

  print(string.format([[
DAP Status:
  Available languages: %d
  Registered: %d
  Enabled: %d

Enabled languages:
  %s
]], stats.available, stats.registered, stats.enabled, table.concat(enabled, ", ")))
end, { desc = "[wkdDAP] Show DAP information" })

-- ============================================================================
-- Optional: Language-Specific Customization
-- ============================================================================

-- Example: Custom Lua debugging server command
vim.api.nvim_create_user_command("DapLuaServer", function()
  require("wkddap.adapters.lua").launch_server()
end, { desc = "[wkdDAP] Start Lua debug server" })

-- Example: Python venv detection override
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    local dap = require("dap")

    -- Override Python path detection
    if dap.configurations.python then
      for _, config in ipairs(dap.configurations.python) do
        if config.pythonPath then
          config.pythonPath = function()
            -- Try poetry
            local poetry_env = vim.fn.system("poetry env info --path"):gsub("\n", "")
            if vim.v.shell_error == 0 then
              return poetry_env .. "/bin/python"
            end

            -- Try pipenv
            local pipenv_env = vim.fn.system("pipenv --venv"):gsub("\n", "")
            if vim.v.shell_error == 0 then
              return pipenv_env .. "/bin/python"
            end

            -- Fallback to system python
            return "python3"
          end
        end
      end
    end
  end,
})

-- ============================================================================
-- Optional: Custom Highlights (Dark Theme Example)
-- ============================================================================

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Custom DAP colors (adjust to your theme)
    vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e06c75" })
    vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#e5c07b" })
    vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
    vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
    vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#31353f" })
  end,
})

-- ============================================================================
-- Optional: Custom Keymaps (if not using default)
-- ============================================================================

-- Only needed if you disabled default keymaps
local map = vim.keymap.set
local dap = require("dap")

-- Session control
map("n", "<F5>", dap.continue, { desc = "DAP: Continue" })
map("n", "<F10>", dap.step_over, { desc = "DAP: Step Over" })
map("n", "<F11>", dap.step_into, { desc = "DAP: Step Into" })
map("n", "<F12>", dap.step_out, { desc = "DAP: Step Out" })

-- Breakpoints
map("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })
map("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Condition: "))
end, { desc = "DAP: Conditional Breakpoint" })

-- UI toggle
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "DAP: Toggle UI" })

-- ============================================================================
-- Validation
-- ============================================================================

-- Verify DAP setup on startup (optional)
vim.defer_fn(function()
  local ok, err = pcall(function()
    local valid, errors = require("wkddap.registry").validate()
    if not valid then
      vim.notify(
        string.format("[DAP] Validation warnings:\n%s", table.concat(errors, "\n")),
        vim.log.levels.WARN
      )
    end
  end)

  if not ok then
    vim.notify("[DAP] Initialization check failed: " .. err, vim.log.levels.ERROR)
  end
end, 100)
