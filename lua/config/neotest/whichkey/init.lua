---@module 'config.neotest.whichkey'
--- Which-key integration for Neotest actions (new spec)

local M = {}

function M.setup()
  local ok, wk = pcall(require, "which-key")
  if not ok then
    return
  end

  wk.add({
    { "<leader>nt", group = "Tests" },

    {
      "<leader>ntt",
      function()
        require("config.neotest.actions").run_nearest()
      end,
      desc = "Run nearest test",
    },
    {
      "<leader>ntf",
      function()
        require("config.neotest.actions").run_file()
      end,
      desc = "Run file tests",
    },
    {
      "<leader>nta",
      function()
        require("config.neotest.actions").run_all()
      end,
      desc = "Run all tests",
    },
    {
      "<leader>ntd",
      function()
        require("config.neotest.actions").debug_nearest()
      end,
      desc = "Debug nearest test",
    },

    {
      "<leader>nts",
      function()
        require("config.neotest.actions").toggle_summary()
      end,
      desc = "Toggle summary",
    },
    {
      "<leader>nto",
      function()
        require("config.neotest.actions").open_output()
      end,
      desc = "Show output",
    },
    {
      "<leader>ntO",
      function()
        require("config.neotest.actions").toggle_output_panel()
      end,
      desc = "Toggle output panel",
    },

    {
      "<leader>ntS",
      function()
        require("config.neotest.actions").stop_tests()
      end,
      desc = "Stop tests",
    },
    {
      "<leader>ntw",
      function()
        require("config.neotest.actions").toggle_watch()
      end,
      desc = "Toggle watch mode",
    },
  })
end

return M
