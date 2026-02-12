---@module 'config.snacks.mappings.standard'
--- Keymap definitions for folke/snacks.nvim.

local M = {}

--- Safely require snacks and call a picker/explorer function.
--- @param fn fun(snacks: table)
local function call(fn)
  return function()
    local ok, snacks = pcall(require, "snacks")
    if not ok then
      return
    end
    fn(snacks)
  end
end

--- Return keymap table compatible with lazy.nvim `keys = ...`.
--- Each entry follows: { lhs, rhs, mode?, desc?, ... }
--- @return table[]
function M.keys()
  ---@type table[]
  local maps = {}

  ---------------------------------------------------------------------------
  -- Top Pickers & Explorer
  ---------------------------------------------------------------------------

  -- maps[#maps + 1] = {
  --   "<leader><space>",
  --   call(function(snacks)
  --     snacks.picker.smart()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Smart Find Files",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>,",
  --   call(function(snacks)
  --     snacks.picker.buffers()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Buffers",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>/",
  --   call(function(snacks)
  --     snacks.picker.grep()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Grep",
  -- }

  maps[#maps + 1] = {
    "<leader>:",
    call(function(snacks)
      snacks.picker.command_history()
    end),
    mode = "n",
    desc = "[snacks] Command History",
  }

  maps[#maps + 1] = {
    "<leader>N",
    call(function(snacks)
      snacks.picker.notifications()
    end),
    mode = "n",
    desc = "[snacks] Notification History",
  }

  maps[#maps + 1] = {
    "<leader>F",
    call(function(snacks)
      snacks.explorer()
    end),
    mode = "n",
    desc = "[snacks] File Explorer",
  }

  ---------------------------------------------------------------------------
  -- Find
  ---------------------------------------------------------------------------

  -- maps[#maps + 1] = {
  --   "<leader>fb",
  --   call(function(snacks)
  --     snacks.picker.buffers()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Buffers",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>fc",
  --   call(function(snacks)
  --     snacks.picker.files({ cwd = vim.fn.stdpath("config") })
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Find Config File",
  -- }

  maps[#maps + 1] = {
    "<leader>ff",
    -- "<leader>ff",
    call(function(snacks)
      snacks.picker.files()
    end),
    mode = "n",
    desc = "[snacks] Find Files",
  }

  -- maps[#maps + 1] = {
  -- "<leader>git",
  -- -- "<leader>fg",
  -- call(function(snacks)
  -- snacks.picker.git_files()
  -- end),
  -- mode = "n",
  -- desc = "[snacks] Find Git Files",
  -- }

  maps[#maps + 1] = {
    "<leader>pro",
    -- "<leader>fp",
    call(function(snacks)
      local projects_config = {
        finder = "recent_projects",
        dev = vim.fn.has("win32") == 1 and "E:\\repos" or "~/repos",
        patterns = { ".git", "package.json", "Makefile" },
        recent = true,
        max_depth = 2,
        win = {
          preview = { minimal = true },
        },
      }
      snacks.picker.projects(projects_config)
    end),
    mode = "n",
    desc = "[snacks] Projects",
  }

  maps[#maps + 1] = {
    "<leader>old",
    -- "<leader>fr",
    call(function(snacks)
      snacks.picker.recent()
    end),
    mode = "n",
    desc = "[snacks] Recent Files",
  }

  ---------------------------------------------------------------------------
  -- Git
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "<leader>gb",
    call(function(snacks)
      snacks.picker.git_branches()
    end),
    mode = "n",
    desc = "[snacks] Git Branches",
  }

  maps[#maps + 1] = {
    "<leader>gl",
    call(function(snacks)
      snacks.picker.git_log()
    end),
    mode = "n",
    desc = "[snacks] Git Log",
  }

  maps[#maps + 1] = {
    "<leader>gL",
    call(function(snacks)
      snacks.picker.git_log_line()
    end),
    mode = "n",
    desc = "[snacks] Git Log Line",
  }

  maps[#maps + 1] = {
    "<leader>gs",
    call(function(snacks)
      snacks.picker.git_status()
    end),
    mode = "n",
    desc = "[snacks] Git Status",
  }

  maps[#maps + 1] = {
    "<leader>gS",
    call(function(snacks)
      snacks.picker.git_stash()
    end),
    mode = "n",
    desc = "[snacks] Git Stash",
  }

  maps[#maps + 1] = {
    "<leader>gd",
    call(function(snacks)
      snacks.picker.git_diff()
    end),
    mode = "n",
    desc = "[snacks] Git Diff (Hunks)",
  }

  maps[#maps + 1] = {
    "<leader>gf",
    call(function(snacks)
      snacks.picker.git_log_file()
    end),
    mode = "n",
    desc = "[snacks] Git Log File",
  }

  ---------------------------------------------------------------------------
  -- GitHub
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "<leader>gi",
    call(function(snacks)
      snacks.picker.gh_issue()
    end),
    mode = "n",
    desc = "[snacks] GitHub Issues (open)",
  }

  maps[#maps + 1] = {
    "<leader>gI",
    call(function(snacks)
      snacks.picker.gh_issue({ state = "all" })
    end),
    mode = "n",
    desc = "[snacks] GitHub Issues (all)",
  }

  maps[#maps + 1] = {
    "<leader>gp",
    call(function(snacks)
      snacks.picker.gh_pr()
    end),
    mode = "n",
    desc = "[snacks] GitHub Pull Requests (open)",
  }

  maps[#maps + 1] = {
    "<leader>gP",
    call(function(snacks)
      snacks.picker.gh_pr({ state = "all" })
    end),
    mode = "n",
    desc = "[snacks] GitHub Pull Requests (all)",
  }

  ---------------------------------------------------------------------------
  -- Grep
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "<leader>cb",
    -- "<leader>sb",
    call(function(snacks)
      snacks.picker.lines()
    end),
    mode = "n",
    desc = "[snacks] Buffer Lines",
  }

  maps[#maps + 1] = {
    "<leader>cB",
    -- "<leader>sB",
    call(function(snacks)
      snacks.picker.grep_buffers()
    end),
    mode = "n",
    desc = "[snacks] Grep Open Buffers",
  }

  maps[#maps + 1] = {
    "<leader><leader>",
    -- "<leader>sg",
    call(function(snacks)
      snacks.picker.grep()
    end),
    mode = "n",
    desc = "[snacks] Grep",
  }

  -- maps[#maps + 1] = {
  --   "<leader>sw",
  --   call(function(snacks)
  --     snacks.picker.grep_word()
  --   end),
  --   mode = { "n", "x" },
  --   desc = "[snacks] Grep Word / Selection",
  -- }

  ---------------------------------------------------------------------------
  -- Search
  ---------------------------------------------------------------------------

  -- maps[#maps + 1] = {
  --   '<leader>s"',
  --   call(function(snacks)
  --     snacks.picker.registers()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Registers",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>s/",
  --   call(function(snacks)
  --     snacks.picker.search_history()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Search History",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>sa",
  --   call(function(snacks)
  --     snacks.picker.autocmds()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Autocmds",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>sc",
  --   call(function(snacks)
  --     snacks.picker.command_history()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Command History",
  -- }

  maps[#maps + 1] = {
    "<leader>com",
    -- "<leader>sC",
    call(function(snacks)
      snacks.picker.commands()
    end),
    mode = "n",
    desc = "[snacks] Commands",
  }

  -- maps[#maps + 1] = {
  --   "<leader>sd",
  --   call(function(snacks)
  --     snacks.picker.diagnostics()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Diagnostics",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>sD",
  --   call(function(snacks)
  --     snacks.picker.diagnostics_buffer()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Buffer Diagnostics",
  -- }

  maps[#maps + 1] = {
    "<leader>help",
    -- "<leader>sh",
    call(function(snacks)
      snacks.picker.help()
    end),
    mode = "n",
    desc = "[snacks] Help Pages",
  }

  -- maps[#maps + 1] = {
  --   "<leader>sH",
  --   call(function(snacks)
  --     snacks.picker.highlights()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Highlights",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>si",
  --   call(function(snacks)
  --     snacks.picker.icons()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Icons",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>sj",
  --   call(function(snacks)
  --     snacks.picker.jumps()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Jumps",
  -- }

  maps[#maps + 1] = {
    "<leader>fk",
    -- "<leader>sk",
    call(function(snacks)
      snacks.picker.keymaps()
    end),
    mode = "n",
    desc = "[snacks] Keymaps",
  }

  -- maps[#maps + 1] = {
  --   "<leader>sl",
  --   call(function(snacks)
  --     snacks.picker.loclist()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Location List",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>sm",
  --   call(function(snacks)
  --     snacks.picker.marks()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Marks",
  -- }

  maps[#maps + 1] = {
    "<leader>sM",
    call(function(snacks)
      snacks.picker.man()
    end),
    mode = "n",
    desc = "[snacks] Man Pages",
  }

  -- maps[#maps + 1] = {
  --   "<leader>sp",
  --   call(function(snacks)
  --     snacks.picker.lazy()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Plugin Specs",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>sq",
  --   call(function(snacks)
  --     snacks.picker.qflist()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Quickfix List",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>sR",
  --   call(function(snacks)
  --     snacks.picker.resume()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Resume Picker",
  -- }

  -- maps[#maps + 1] = {
  --   "<leader>su",
  --   call(function(snacks)
  --     snacks.picker.undo()
  --   end),
  --   mode = "n",
  --   desc = "[snacks] Undo History",
  -- }

  maps[#maps + 1] = {
    "<leader>ch",
    call(function(snacks)
      snacks.picker.colorschemes()
    end),
    mode = "n",
    desc = "[snacks] Colorschemes",
  }

  ---------------------------------------------------------------------------
  -- LSP
  ---------------------------------------------------------------------------

  maps[#maps + 1] = {
    "GD",
    call(function(snacks)
      snacks.picker.lsp_definitions()
    end),
    mode = "n",
    desc = "[snacks] Goto Definition",
  }

  maps[#maps + 1] = {
    "gD",
    call(function(snacks)
      snacks.picker.lsp_declarations()
    end),
    mode = "n",
    desc = "[snacks] Goto Declaration",
  }

  maps[#maps + 1] = {
    "GR",
    call(function(snacks)
      snacks.picker.lsp_references()
    end),
    mode = "n",
    desc = "[snacks] References",
    nowait = true,
  }

  maps[#maps + 1] = {
    "GI",
    call(function(snacks)
      snacks.picker.lsp_implementations()
    end),
    mode = "n",
    desc = "[snacks] Goto Implementation",
  }

  maps[#maps + 1] = {
    "GY",
    call(function(snacks)
      snacks.picker.lsp_type_definitions()
    end),
    mode = "n",
    desc = "[snacks] Goto Type Definition",
  }

  maps[#maps + 1] = {
    "GAI",
    call(function(snacks)
      snacks.picker.lsp_incoming_calls()
    end),
    mode = "n",
    desc = "[snacks] Calls Incoming",
  }

  maps[#maps + 1] = {
    "GAO",
    call(function(snacks)
      snacks.picker.lsp_outgoing_calls()
    end),
    mode = "n",
    desc = "[snacks] Calls Outgoing",
  }

  maps[#maps + 1] = {
    "<leader>SS",
    call(function(snacks)
      snacks.picker.lsp_symbols()
    end),
    mode = "n",
    desc = "[snacks] LSP Symbols",
  }

  maps[#maps + 1] = {
    "<leader>sS",
    call(function(snacks)
      snacks.picker.lsp_workspace_symbols()
    end),
    mode = "n",
    desc = "[snacks] LSP Workspace Symbols",
  }

  return maps
end

return M
