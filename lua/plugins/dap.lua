---@module 'plugins.dap'
--- DAP plugin specification with comprehensive configuration

---@type LazyPluginSpec[]
return {
  -- Core DAP plugin
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "jbyuki/one-small-step-for-vimkind",
    },
    lazy = true,
    keys = {
      { "<leader>dc", function() require("dap").continue() end, desc = "[DAP] Continue" },
      { "<leader>ds", function() require("dap").step_over() end, desc = "[DAP] Step Over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "[DAP] Step Into" },
      { "<leader>do", function() require("dap").step_out() end, desc = "[DAP] Step Out" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "[DAP] Terminate" },
      { "<leader>dr", function() require("dap").restart() end, desc = "[DAP] Restart" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "[DAP] Toggle Breakpoint" },
    },
    config = function()
      local dap = require("dap")

      -- Setup Signs first, before any listeners or configurations
      vim.fn.sign_define("DapBreakpoint", {
        text = "●",
        texthl = "DapBreakpoint",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapBreakpointCondition", {
        text = "◆",
        texthl = "DapBreakpointCondition",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapBreakpointRejected", {
        text = "○",
        texthl = "DapBreakpointRejected",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapLogPoint", {
        text = "◉",
        texthl = "DapLogPoint",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapStopped", {
        text = "→",
        texthl = "DapStopped",
        linehl = "DapStoppedLine",
        numhl = "",
      })

      -- Setup Highlights
      vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
      vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#ffcc00" })
      vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#888888" })
      vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
      vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
      vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#3e4451" })

      -- Setup Lua adapter
      local ok_osv, _ = pcall(require, "osv")
      if ok_osv then
        dap.adapters.nlua = function(callback, config)
          callback({
            type = "server",
            host = config.host or "127.0.0.1",
            port = config.port or 8086,
          })
        end

        dap.configurations.lua = {
          {
            type = "nlua",
            request = "attach",
            name = "Attach to running Neovim instance",
            host = function()
              return vim.fn.input("Host [127.0.0.1]: ", "127.0.0.1")
            end,
            port = function()
              return tonumber(vim.fn.input("Port [8086]: ", "8086")) or 8086
            end,
          },
        }
      end

      -- Setup JavaScript/TypeScript adapter
      local mason_pkg = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
      local adapter_script = mason_pkg .. "/js-debug/src/dapDebugServer.js"

      if vim.fn.filereadable(adapter_script) == 1 then
        dap.adapters["pwa-node"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args = { adapter_script, "${port}" },
          },
        }

        for _, lang in ipairs({ "javascript", "typescript" }) do
          dap.configurations[lang] = {
            {
              type = "pwa-node",
              request = "launch",
              name = "Launch file",
              program = "${file}",
              cwd = "${workspaceFolder}",
            },
          }
        end
      end

      -- Setup Go adapter
      local dlv = vim.fn.exepath("dlv")
      if dlv ~= "" then
        dap.adapters.go = {
          type = "server",
          port = "${port}",
          executable = {
            command = dlv,
            args = { "dap", "-l", "127.0.0.1:${port}" },
          },
        }

        dap.configurations.go = {
          {
            type = "go",
            name = "Debug",
            request = "launch",
            program = "${file}",
          },
        }
      end

      -- Setup Python adapter
      local debugpy = vim.fn.exepath("debugpy")
      if debugpy ~= "" then
        dap.adapters.python = {
          type = "executable",
          command = debugpy,
          args = { "-m", "debugpy.adapter" },
        }

        dap.configurations.python = {
          {
            type = "python",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            pythonPath = function()
              local venv = vim.env.VIRTUAL_ENV
              if venv then
                return venv .. "/bin/python"
              else
                return "python3"
              end
            end,
          },
        }
      end
    end,
  },

  -- DAP UI
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    keys = {
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "[DAP] Toggle UI",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        desc = "[DAP] Evaluate",
        mode = { "n", "v" },
      },
    },
    config = function()
      local dapui = require("dapui")
      local dap = require("dap")

      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            size = 10,
            position = "bottom",
          },
        },
      })

      -- Auto-open/close UI when debugging starts/stops
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

  -- Virtual Text
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      enabled = true,
      commented = true,
      virt_text_pos = "eol",
      all_frames = false,
      highlight_changed_variables = true,
      highlight_new_as_changed = true,
      show_stop_reason = true,
      only_first_definition = true,
    },
  },
}
