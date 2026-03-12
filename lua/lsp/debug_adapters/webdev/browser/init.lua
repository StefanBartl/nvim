---@module 'lsp.debug_adapters.webdev.browser'
--- Browser-basiertes Debugging für Web-Anwendungen mit js-debug-adapter
--[[
NOTE: Zusätzliche notwendige Schritte außerhalb von Neovim

Damit attach zuverlässig funktioniert, muss Chrome mit aktiviertem Remote-Debugging gestartet werden:
`google-chrome --remote-debugging-port=9222`

Für Chromium-basierte Browser (z. B. Brave, Edge) gilt sinngemäß dasselbe.
Typische Fehlerquellen nach der Umstellung:
  - falscher Pfad zu dapDebugServer.js
  - Chrome läuft nicht mit --remote-debugging-port
  - falsches webRoot, was zu nicht funktionierenden Breakpoints führt
]]--

local dap = require("dap")

-- js-debug-adapter (Chrome / Edge / Chromium)
dap.adapters["pwa-chrome"] = {
  type = "server", -- Der Adapter wird als Debug-Server gestartet
  port = "${port}", -- Port wird dynamisch vergeben
  executable = { -- Ausführbare Definition des Debug-Servers
    command = "node", -- Node.js wird benötigt, da js-debug in JavaScript implementiert ist
    args = { -- Einstiegspunkt des js-debug-adapters
      vim.fn.stdpath("data")
        .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
      "${port}",
    },
  },
}

-- Initialisierung der Konfigurationstabellen, um Mehrfachdefinitionen sicher zu vermeiden
dap.configurations.typescript = dap.configurations.typescript or {}
dap.configurations.javascript = dap.configurations.javascript or {}
dap.configurations.astro = dap.configurations.astro or {}

-- Gemeinsame Browser-Konfigurationen
---@type table[]
local browser_config = {
  {
    type = "pwa-chrome", -- Adapter-Typ
    request = "attach", -- Verbindung zu einer laufenden Chrome-Instanz
    name = "Attach to Chrome (js-debug)", -- Anzeigename in nvim-dap
    port = 9222, -- Standard-Remote-Debugging-Port von Chrome
    webRoot = "${workspaceFolder}", -- Root-Verzeichnis für Source Maps
  },
  {
   type = "pwa-chrome", -- Adapter-Typ
    request = "launch", -- Startet eine neue Chrome-Instanz
    name = "Launch Chrome (js-debug)", -- Anzeigename in nvim-dap
    url = "http://localhost:3000", -- Start-URL der Web-Anwendung
    webRoot = "${workspaceFolder}", -- Root-Verzeichnis für Source Maps
  },
}

-- Erweiterung der Konfigurationen für alle relevanten Dateitypen
for _, lang in ipairs({ "typescript", "javascript", "astro" }) do
  vim.list_extend(dap.configurations[lang], browser_config)
end

