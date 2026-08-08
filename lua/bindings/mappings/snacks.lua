---@module 'bindings.mappings.snacks'
--- Centralized key mappings for folke/snacks.nvim.
--- Active mappings are defined normally, inactive mappings are kept commented
--- at their original logical positions for easy activation later.
---@description
--- NOT currently wired up: bindings.mappings.init.setup() doesn't require
--- this module, so M.setup() below is never called and every mapping in
--- here — "active"-looking or not — is dead. Likely superseded by
--- pickers.nvim's own snacks integration (see config/snacks/picker/init.lua)
--- for the picker-related ones; git.lua/lsp.lua/fzf.lua/telescope.lua may
--- already cover the rest. Before wiring this back in, check for overlap
--- with those instead of assuming it's a simple oversight.

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  ---------------------------------------------------------------------------
  -- Top Pickers & Explorer
  ---------------------------------------------------------------------------

  -- map("n", "<leader><space>", function()
  --   require("snacks").picker.smart()
  -- end, { desc = "[snacks] Smart Find Files" })

  -- map("n", "<leader>,", function()
  --   require("snacks").picker.buffers()
  -- end, { desc = "[snacks] Buffers" })

  -- map("n", "<leader>/", function()
  --   require("snacks").picker.grep()
  -- end, { desc = "[snacks] Grep" })

  map("n", "<leader>:", function()
    require("snacks").picker.command_history()
  end, { desc = "[snacks] Command History" })

  map("n", "<leader>N", function()
    require("snacks").picker.notifications()
  end, { desc = "[snacks] Notification History" })

  map("n", "<leader>F", function()
    require("snacks").explorer()
  end, { desc = "[snacks] File Explorer" })

  ---------------------------------------------------------------------------
  -- Find
  ---------------------------------------------------------------------------

  -- map("n", "<leader>fb", function()
  --   require("snacks").picker.buffers()
  -- end, { desc = "[snacks] Buffers" })

  -- map("n", "<leader>fc", function()
  --   require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
  -- end, { desc = "[snacks] Find Config File" })

  -- map("n", "<leader>ff", function()
  --   require("snacks").picker.files()
  -- end, { desc = "[snacks] Find Files" })

  -- map("n", "<leader>fg", function()
  --   require("snacks").picker.git_files()
  -- end, { desc = "[snacks] Find Git Files" })

  -- map("n", "<leader>fp", function()
  --   require("snacks").picker.projects()
  -- end, { desc = "[snacks] Projects" })

  -- map("n", "<leader>fr", function()
  --   require("snacks").picker.recent()
  -- end, { desc = "[snacks] Recent Files" })

  ---------------------------------------------------------------------------
  -- Git
  ---------------------------------------------------------------------------

  map("n", "<leader>gb", function()
    require("snacks").picker.git_branches()
  end, { desc = "[snacks] Git Branches" })

  map("n", "<leader>gl", function()
    require("snacks").picker.git_log()
  end, { desc = "[snacks] Git Log" })

  map("n", "<leader>gL", function()
    require("snacks").picker.git_log_line()
  end, { desc = "[snacks] Git Log Line" })

  map("n", "<leader>gs", function()
    require("snacks").picker.git_status()
  end, { desc = "[snacks] Git Status" })

  map("n", "<leader>gS", function()
    require("snacks").picker.git_stash()
  end, { desc = "[snacks] Git Stash" })

  map("n", "<leader>gd", function()
    require("snacks").picker.git_diff()
  end, { desc = "[snacks] Git Diff (Hunks)" })

  map("n", "<leader>gf", function()
    require("snacks").picker.git_log_file()
  end, { desc = "[snacks] Git Log File" })

  ---------------------------------------------------------------------------
  -- GitHub
  ---------------------------------------------------------------------------

  map("n", "<leader>gi", function()
    require("snacks").picker.gh_issue()
  end, { desc = "[snacks] GitHub Issues (open)" })

  map("n", "<leader>gI", function()
    require("snacks").picker.gh_issue({ state = "all" })
  end, { desc = "[snacks] GitHub Issues (all)" })

  map("n", "<leader>gp", function()
    require("snacks").picker.gh_pr()
  end, { desc = "[snacks] GitHub Pull Requests (open)" })

  map("n", "<leader>gP", function()
    require("snacks").picker.gh_pr({ state = "all" })
  end, { desc = "[snacks] GitHub Pull Requests (all)" })

  ---------------------------------------------------------------------------
  -- Grep
  ---------------------------------------------------------------------------

  -- map("n", "<leader>sb", function()
  --   require("snacks").picker.lines()
  -- end, { desc = "[snacks] Buffer Lines" })

  -- map("n", "<leader>sB", function()
  --   require("snacks").picker.grep_buffers()
  -- end, { desc = "[snacks] Grep Open Buffers" })

  -- map("n", "<leader>sg", function()
  --   require("snacks").picker.grep()
  -- end, { desc = "[snacks] Grep" })

  -- map({ "n", "x" }, "<leader>sw", function()
  --   require("snacks").picker.grep_word()
  -- end, { desc = "[snacks] Grep Word / Selection" })

  ---------------------------------------------------------------------------
  -- Search
  ---------------------------------------------------------------------------

  -- map("n", '<leader>s"', function()
  --   require("snacks").picker.registers()
  -- end, { desc = "[snacks] Registers" })

  -- map("n", "<leader>s/", function()
  --   require("snacks").picker.search_history()
  -- end, { desc = "[snacks] Search History" })

  -- map("n", "<leader>sa", function()
  --   require("snacks").picker.autocmds()
  -- end, { desc = "[snacks] Autocmds" })

  -- map("n", "<leader>sc", function()
  --   require("snacks").picker.command_history()
  -- end, { desc = "[snacks] Command History" })

  -- map("n", "<leader>sC", function()
  --   require("snacks").picker.commands()
  -- end, { desc = "[snacks] Commands" })

  -- map("n", "<leader>sd", function()
  --   require("snacks").picker.diagnostics()
  -- end, { desc = "[snacks] Diagnostics" })

  -- map("n", "<leader>sD", function()
  --   require("snacks").picker.diagnostics_buffer()
  -- end, { desc = "[snacks] Buffer Diagnostics" })

  map("n", "<leader>sh", function()
    require("snacks").picker.help()
  end, { desc = "[snacks] Help Pages" })

  -- map("n", "<leader>sH", function()
  --   require("snacks").picker.highlights()
  -- end, { desc = "[snacks] Highlights" })

  -- map("n", "<leader>si", function()
  --   require("snacks").picker.icons()
  -- end, { desc = "[snacks] Icons" })

  -- map("n", "<leader>sj", function()
  --   require("snacks").picker.jumps()
  -- end, { desc = "[snacks] Jumps" })

  -- map("n", "<leader>sk", function()
  --   require("snacks").picker.keymaps()
  -- end, { desc = "[snacks] Keymaps" })

  -- map("n", "<leader>sl", function()
  --   require("snacks").picker.loclist()
  -- end, { desc = "[snacks] Location List" })

  -- map("n", "<leader>sm", function()
  --   require("snacks").picker.marks()
  -- end, { desc = "[snacks] Marks" })

  map("n", "<leader>sM", function()
    require("snacks").picker.man()
  end, { desc = "[snacks] Man Pages" })

  -- map("n", "<leader>sp", function()
  --   require("snacks").picker.lazy()
  -- end, { desc = "[snacks] Plugin Specs" })

  -- map("n", "<leader>sq", function()
  --   require("snacks").picker.qflist()
  -- end, { desc = "[snacks] Quickfix List" })

  -- map("n", "<leader>sR", function()
  --   require("snacks").picker.resume()
  -- end, { desc = "[snacks] Resume Picker" })

  -- Undo History -> config/snacks/mappings/standard.lua's builtin("undo"),
  -- same pattern as gb/gl/gs/sM/GD/... below (routed through pickers.nvim,
  -- not a raw snacks call). This file isn't required anywhere from
  -- bindings.mappings.init.setup() either way (see its module comment
  -- above), so anything added here never takes effect regardless.

  map("n", "<leader>ch", function()
    require("snacks").picker.colorschemes()
  end, { desc = "[snacks] Colorschemes" })

  ---------------------------------------------------------------------------
  -- LSP
  ---------------------------------------------------------------------------

  map("n", "GD", function()
    require("snacks").picker.lsp_definitions()
  end, { desc = "[snacks] Goto Definition" })

  map("n", "GD", function()
    require("snacks").picker.lsp_declarations()
  end, { desc = "[snacks] Goto Declaration" })

  map("n", "GR", function()
    require("snacks").picker.lsp_references()
  end, { desc = "[snacks] References", nowait = true })

  map("n", "GI", function()
    require("snacks").picker.lsp_implementations()
  end, { desc = "[snacks] Goto Implementation" })

  map("n", "GY", function()
    require("snacks").picker.lsp_type_definitions()
  end, { desc = "[snacks] Goto Type Definition" })

  map("n", "GAI", function()
    require("snacks").picker.lsp_incoming_calls()
  end, { desc = "[snacks] Calls Incoming" })

  map("n", "GAO", function()
    require("snacks").picker.lsp_outgoing_calls()
  end, { desc = "[snacks] Calls Outgoing" })

  map("n", "<leader>SS", function()
    require("snacks").picker.lsp_symbols()
  end, { desc = "[snacks] LSP Symbols" })

  map("n", "<leader>sS", function()
    require("snacks").picker.lsp_workspace_symbols()
  end, { desc = "[snacks] LSP Workspace Symbols" })
end

return M

