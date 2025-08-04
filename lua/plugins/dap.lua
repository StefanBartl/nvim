<<<<<<< HEAD
---@module 'plugins.dap'
--- Debug Adapter Protocol setup using nvim-dap, dap-ui, and extensions.

---@type LazyPluginSpec[]
return {

  -- nvim-dap: Core Debug Adapter Protocol implementation
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    config = function()
      require("configs.dap.init")
    end,
  },

  -- nvim-dap-ui: Visual debugging interface (scopes, breakpoints, etc.)
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap, dapui = require("configs.dap.init"), require("dapui")

      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end

      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end

      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },

  -- nvim-dap-view: Lightweight view component for focused debug states
  {
    "igorlfs/nvim-dap-view",
    opts = {},
  },

}
=======
---@module 'plugins.dap'
--- Debug Adapter Protocol setup using nvim-dap, dap-ui, and extensions.

---@type LazyPluginSpec[]
return {

  -- nvim-dap: Core Debug Adapter Protocol implementation
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    config = function()
      require("configs.dap.init")
    end,
  },

  -- nvim-dap-ui: Visual debugging interface (scopes, breakpoints, etc.)
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap, dapui = require("configs.dap.init"), require("dapui")

      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end

      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end

      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },

  -- nvim-dap-view: Lightweight view component for focused debug states
  {
    "igorlfs/nvim-dap-view",
    opts = {},
  },

}
>>>>>>> d71f64e (d)
