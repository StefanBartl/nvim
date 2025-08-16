Kurzbeschreibung und vollständige, robust kommentierte Lazy.nvim-Integration für nvim-dap + one-small-step-for-vimkind (OSV), inkl. Keymaps, User-Commands und Workflows.

```lua
---=============================================================================
--- @module 'plugins.debug.lua'
--- Debug setup for Lua code running inside Neovim using:
---   - nvim-dap: Debug Adapter Protocol client
---   - one-small-step-for-vimkind (OSV): Lua DAP adapter for Neovim runtime
---   - optional: nvim-dap-ui for a nicer UI
---
--- This module configures:
---   * an 'nlua' adapter that attaches to an OSV server
---   * Lua-specific DAP configurations
---   * helper user commands for starting/stopping OSV
---   * keymaps for common debug actions
---
--- Design goals:
---   - Safe requires with helpful notifications
---   - Clear separation of OSV (target) and DAP (client) responsibilities
---   - Sensible defaults with overridable port/host
---
--- Versioning & types:
--- @version 1.0.0
--- @alias Dap any
--- @alias Osv any
--- @alias DapUI any
--- @class DebugConfig
--- @field host string|nil        -- Host for OSV server (default "127.0.0.1")
--- @field port integer|nil       -- Port for OSV server (default 8086)
--- @field auto_open_ui boolean   -- Auto open dap-ui on start (default true)
--- @field mappings_enabled boolean -- Install default keymaps (default true)
--- @field create_commands boolean -- Create :LuaDebug* user commands (default true)
--- @field notify boolean         -- Use vim.notify for status (default true)
--- @field adapters table|nil     -- Extra/override DAP adapters (optional)
--- @field configurations table|nil -- Extra/override DAP configurations (optional)
--- @nodiscard
---=============================================================================

---@type LazyPluginSpec[]
return {
  -- Core DAP client
  {
    "mfussenegger/nvim-dap",
    lazy = false,
    dependencies = {
      -- OSV: Lua DAP adapter for Neovim
      "jbyuki/one-small-step-for-vimkind",
      -- Optional but recommended: UI for DAP
      { "rcarriga/nvim-dap-ui", optional = true },
      -- Optional: nice virtual text for variables (comment out if not wanted)
      { "theHamsta/nvim-dap-virtual-text", optional = true },
    },
    config = function()
      ---------------------------------------------------------------------------
      -- Safe requires
      ---------------------------------------------------------------------------
      local function req(mod)
        local ok, m = pcall(require, mod)
        if not ok then
          vim.notify("debug: failed to require '" .. mod .. "'", vim.log.levels.WARN)
          return nil
        end
        return m
      end

      ---@type Dap
      local dap = req("dap")
      if not dap then return end

      ---@type Osv|nil
      local osv = req("osv") -- provided by one-small-step-for-vimkind

      ---@type DapUI|nil
      local dapui = req("dapui")

      local vt = req("nvim-dap-virtual-text")
      if vt and vt.setup then
        vt.setup({
          -- Keep defaults moderate; override as needed
          enabled = true,
          enabled_commands = true,
          highlight_changed_variables = true,
          highlight_new_as_changed = false,
          show_stop_reason = true,
        })
      end

      if dapui and dapui.setup then
        dapui.setup({})
      end

      ---------------------------------------------------------------------------
      -- Defaults (can be adjusted below)
      ---------------------------------------------------------------------------
      ---@type DebugConfig
      local cfg = {
        host = "127.0.0.1",
        port = 8086,
        auto_open_ui = true,
        mappings_enabled = true,
        create_commands = true,
        notify = true,
      }

      ---------------------------------------------------------------------------
      -- Adapter: 'nlua' connects to an OSV TCP server running in a Neovim target
      -- OSV can pick a port automatically; here we default to cfg.port.
      ---------------------------------------------------------------------------
      ---@param callback fun(adapter: table)
      ---@param conf table
      dap.adapters.nlua = function(callback, conf)
        callback({
          type = "server",
          host = (conf and conf.host) or cfg.host,
          port  = (conf and conf.port) or cfg.port,
        })
      end

      ---------------------------------------------------------------------------
      -- DAP configurations for Lua files
      -- "attach" connects to an already running OSV server in a Neovim target.
      ---------------------------------------------------------------------------
      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Lua: Attach to running Neovim (OSV)",
          host = cfg.host,
          port = cfg.port,
        },
      }

      ---------------------------------------------------------------------------
      -- DAP UI auto open/close
      ---------------------------------------------------------------------------
      if dapui and cfg.auto_open_ui then
        dap.listeners.after.event_initialized["dapui_config"] = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
          dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
          dapui.close()
        end
      end

      ---------------------------------------------------------------------------
      -- Helper notifications
      ---------------------------------------------------------------------------
      local function info(msg)
        if cfg.notify then vim.notify("debug: " .. msg) end
      end
      local function error(msg)
        vim.notify("debug: " .. msg, vim.log.levels.ERROR)
      end

      ---------------------------------------------------------------------------
      -- User commands
      -- :LuaDebugLaunch [port]
      --   Start OSV server in *this* Neovim (target). Optional numeric port; if 0,
      --   OSV chooses a free port and prints it in :messages.
      --
      -- :LuaDebugAttach [host] [port]
      --   Attach from *this* Neovim (client) to a running OSV server.
      --
      -- :LuaDebugStop
      --   Stop the DAP session (client-side). OSV server continues until killed.
      --
      -- :LuaDebugRunThis
      --   Evaluate the current buffer (or selection) in the target via OSV (handy
      --   for quick experiments). Requires OSV in the target.
      ---------------------------------------------------------------------------
      if cfg.create_commands then
        vim.api.nvim_create_user_command("LuaDebugLaunch", function(params)
          if not osv then
            return error("OSV not available; is 'jbyuki/one-small-step-for-vimkind' installed?")
          end
          local port = tonumber(params.fargs[1]) or cfg.port
          -- If port == 0, OSV will select a free port and echo it
          osv.launch({ host = cfg.host, port = port })
          info("OSV launch on " .. cfg.host .. ":" .. tostring(port))
        end, {
          desc = "Start OSV server in this Neovim (target). Usage: :LuaDebugLaunch [port]",
          nargs = "?",
        })

        vim.api.nvim_create_user_command("LuaDebugAttach", function(params)
          local host = params.fargs[1] or cfg.host
          local port = tonumber(params.fargs[2] or cfg.port)
          -- Run a one-off attach config without polluting dap.configurations
          dap.run({
            type = "nlua",
            request = "attach",
            name = "Attach (ad-hoc)",
            host = host,
            port = port,
          })
          info("DAP attach to " .. host .. ":" .. port)
        end, {
          desc = "Attach to OSV from this Neovim (client). Usage: :LuaDebugAttach [host] [port]",
          nargs = "*",
        })

        vim.api.nvim_create_user_command("LuaDebugStop", function()
          dap.terminate()
          info("DAP terminated")
        end, {
          desc = "Terminate current DAP session",
        })

        vim.api.nvim_create_user_command("LuaDebugRunThis", function()
          if not osv then
            return error("OSV not available; cannot run current chunk")
          end
          -- Runs current buffer on the target side (requires OSV server there)
          osv.run_this()
        end, {
          desc = "Evaluate current buffer (or selection) in target via OSV",
        })
      end

      ---------------------------------------------------------------------------
      -- Keymaps (opinionated but minimal; adapt to your leader)
      ---------------------------------------------------------------------------
      if cfg.mappings_enabled then
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { desc = desc, noremap = true, silent = true })
        end

        -- Start/attach/stop
        map("<leader>dl", "<cmd>LuaDebugLaunch<CR>", "OSV: launch server (target)")
        map("<leader>da", "<cmd>LuaDebugAttach<CR>", "DAP: attach to OSV (client)")
        map("<leader>dX", "<cmd>LuaDebugStop<CR>",   "DAP: terminate")

        -- Breakpoints and stepping
        map("<leader>db", function() dap.toggle_breakpoint() end, "DAP: toggle breakpoint")
        map("<leader>dB", function()
          vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
            if cond and #cond > 0 then
              dap.set_breakpoint(cond)
            else
              dap.toggle_breakpoint()
            end
          end)
        end, "DAP: conditional breakpoint")
        map("<leader>dc", function() dap.continue() end,    "DAP: continue")
        map("<leader>do", function() dap.step_over() end,   "DAP: step over")
        map("<leader>di", function() dap.step_into() end,   "DAP: step into")
        map("<leader>dO", function() dap.step_out() end,    "DAP: step out")

        -- UI toggles (if dap-ui present)
        if dapui then
          map("<leader>du", function() dapui.toggle() end, "DAP UI: toggle")
        end
      end
    end,
  },
}
```

Empfohlene Workflows in der Praxis

1. Single-Instance, Self-Debug
   Ziel: die eigene Neovim-Instanz (in der man arbeitet) debuggen.
   Ablauf:
   • \:LuaDebugLaunch 0
   OSV startet und wählt einen freien Port; in \:messages steht der Port.
   • \:LuaDebugAttach 127.0.0.1 <port>
   DAP verbindet sich; Breakpoints in laufendem Code greifen sofort.
   Hinweis: Port 0 ist praktisch, wenn Ports häufig belegt sind.

2. Zwei Instanzen (sauber getrennt)
   Ziel: Instanz A ist der Debug-Client, Instanz B ist das Ziel (Target).
   Ablauf:
   • In Instanz B: \:LuaDebugLaunch 8086
   • In Instanz A: \:LuaDebugAttach 127.0.0.1 8086
   • In A Breakpoints setzen, mit <leader>dc starten, in B Aktionen auslösen.

3. Schnelles Ausführen von Code im Target
   • Sobald OSV im Target läuft: \:LuaDebugRunThis in der Client-Instanz ausführen, um den aktuellen Buffer im Target evaluieren zu lassen (nützlich für schnelle Experimente).

Troubleshooting und Hinweise

• Kein Verbindungsaufbau
Prüfen, ob OSV im Target läuft (\:LuaDebugLaunch ausgeführt?) und Host/Port stimmen. Firewalls/SELinux können TCP blockieren.

• Falsche Instanz erwischt
Besonders bei mehreren Neovim-Instanzen sicherstellen, dass man in der richtigen die OSV-Launch-Kommandos ausführt.

• DAP-UI öffnet nicht
Plugin rcarriga/nvim-dap-ui optional, aber empfehlenswert. Mit <leader>du togglen, ansonsten Logs in \:messages prüfen.

• Evaluation klappt nicht
\:LuaDebugRunThis benötigt OSV im Target. Alternativ in der Target-Instanz \:luafile % zum lokalen Test verwenden.

• Symlinks/Remote-FS
Pfad-Mapping ist bei lokalem Lua-Code meist unkritisch. Bei ungewöhnlichen Setups (z. B. rclone/sshfs) auf identische Pfade achten, sonst können Breakpoints nicht gematcht werden.

• Performance
nvim-dap-virtual-text ist praktisch, kann aber CPU kosten; bei großen Buffern abschalten oder minimal konfigurieren.

Konfiguration anpassen

• Port/Host defaults
In der oberen cfg-Tabelle host/port anpassen, falls 127.0.0.1:8086 nicht passt.

• Weitere DAP-Konfigurationen
dap.configurations.lua kann zusätzliche Einträge enthalten, z. B. dedizierte Attach-Profile für verschiedene Ports oder Hosts.

• Keymaps
Präfix <leader>d ist gängig; man kann die Zeilen im mappings\_enabled-Block frei ändern oder ausschalten.

Damit steht ein stabiler Debug-Workflow für Neovim-Lua (Plugins, init.lua, Runtime-Code) zur Verfügung, mit klaren Commands und kommentiertem Code für langfristige Wartbarkeit.

