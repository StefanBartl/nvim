Ziel und Einordnung

* mason-tool-installer ist eine dünne Schicht über mason.nvim.
* Man gibt eine Liste von Mason-Paketnamen vor (`ensure_installed`), und das Plugin sorgt dafür, dass diese Tools vorhanden (und optional aktuell) sind.
* Es installiert „Mason-Pakete“ (Formatter, Linter, DAPs, einige Server) anhand ihrer Mason-Namen. Es mappt NICHT automatisch von lspconfig-Namen. Für LSP-Server erledigt man das Mapping separat mit mason-lspconfig.

Wichtigste Optionen

| Name              | Typ       | Bedeutung                                                                                                           |
| ----------------- | --------- | ------------------------------------------------------------------------------------------------------------------- |
| ensure\_installed | string\[] | Liste von Mason-Paketen, die vorhanden sein sollen (z. B. `lua-language-server`, `stylua`, `prettierd`, `eslint_d`) |
| run\_on\_start    | boolean   | Wenn true, läuft die Sicherstellung beim Start automatisch                                                          |
| start\_delay      | number    | Startverzögerung in Millisekunden, um den Start zu entlasten (z. B. 3000)                                           |
| auto\_update      | boolean   | Wenn true, werden veraltete Pakete aktualisiert, wenn der „Debounce“-Zeitraum abgelaufen ist                        |
| debounce\_hours   | number    | Minimale Stunden zwischen zwei Auto-Update-Versuchen, auch über Neustarts hinweg                                    |

Ablauf bei `run_on_start = true`

1. Beim Start wartet das Plugin optional `start_delay` Millisekunden.
2. Es lädt die Registry von Mason.
3. Für jedes Paket in `ensure_installed`:

   * Wenn nicht installiert → wird installiert.
   * Wenn installiert und `auto_update = true` und „Debounce“ abgelaufen → wird aktualisiert.
   * Andernfalls passiert nichts.
4. Fehlen Systemvoraussetzungen (z. B. `python3`, `npm`, `go`, `gem`), scheitern einzelne Pakete unabhängig von den anderen.

Wichtige Unterscheidung zu mason-lspconfig

* mason-lspconfig nimmt lspconfig-Servernamen (`lua_ls`, `gopls`, …) und mappt intern auf Mason-Pakete.
* mason-tool-installer erwartet bereits Mason-Paketnamen (`lua-language-server`, `gopls`, …).
* In der Praxis setzt man mason-lspconfig für LSPs und mason-tool-installer für Formatter/Linter/DAPs ein.

Minimalbeispiel mit Lazy/Lua

```lua
---@module 'plugins.mason_tools'
--- Install/update only the tools desired; no surprise installs.

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    opts = {
      -- Use Mason package names here (NOT lspconfig names)
      ensure_installed = {
        -- LSP servers (Mason package names)
        "lua-language-server",
        "gopls",
        -- Formatters
        "stylua",
        "shfmt",
        "prettierd",
        -- Linters
        "eslint_d",
        -- Add others as needed...
      },
      run_on_start = true,     -- set to false if you prefer manual :MasonToolsInstall
      start_delay = 3000,      -- ms
      debounce_hours = 24,     -- do not auto-update more often than this
      auto_update = false,     -- set true if you want periodic updates
    },
  },
}
```

Typische Kommandos

* `:MasonToolsInstall` installiert alle fehlenden Pakete aus `ensure_installed`.
* `:MasonToolsUpdate` aktualisiert installierte Pakete (respektiert `debounce_hours` nicht; manuell ist sofort).
* `:MasonToolsInstallSync`/`:MasonToolsUpdateSync` blockierend.
* `:MasonToolsClean` deinstalliert Pakete, die nicht in `ensure_installed` stehen.

Ungewollte Pakete zuverlässig verhindern

* Ein Paket wird nur automatisch (wieder) installiert, wenn es in `ensure_installed` steht.
* Deshalb dort konsequent auslisten, was man nicht möchte.
* Falls eine fremde Config die Liste erweitert, kann man sie filtern:

```lua
---@module 'plugins.mason_tools_filter'
--- Remove unwanted entries from ensure_installed regardless of where they come from.

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      local block = {
        cmakelang = true,
        cmakelint = true,
      }
      local list, out = opts.ensure_installed or {}, {}
      for _, name in ipairs(list) do
        if not block[name] then
          out[#out + 1] = name
        end
      end
      opts.ensure_installed = out
    end,
  },
}
```

Zusammenspiel mit Conform/nvim-lint

* Conform (`formatters_by_ft`) und nvim-lint (`linters_by_ft`) konfigurieren nur, „was benutzt wird“. Installieren tun sie nichts.
* Mason-Installationen übernimmt dann mason-tool-installer. Dafür muss man die Mason-Paketnamen in `ensure_installed` aufführen.
* Optional kann man diese Liste aus der eigenen Conform/nvim-lint-Config ableiten und auf Mason-Paketnamen mappen:

```lua
---@module 'plugins.mason_tools_auto_from_conform_lint'
--- Derive mason ensure_installed from your Conform/nvim-lint config.

---@type table<string, string>
local map_to_mason = {
  -- formatters
  prettierd = "prettierd",
  prettier  = "prettier",
  stylua    = "stylua",
  shfmt     = "shfmt",
  black     = "black",
  isort     = "isort",
  ruff      = "ruff",
  -- linters
  eslint_d  = "eslint_d",
  flake8    = "flake8",
  shellcheck = "shellcheck",
}

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
      { "stevearc/conform.nvim", optional = true },
      { "mfussenegger/nvim-lint", optional = true },
    },
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      local function add(name)
        local pkg = map_to_mason[name] or name
        table.insert(opts.ensure_installed, pkg)
      end

      -- Pull from Conform
      local ok_conform, conform = pcall(require, "conform")
      if ok_conform and type(conform.formatters_by_ft) == "table" then
        for _, v in pairs(conform.formatters_by_ft) do
          if type(v) == "table" then
            for _, fmt in ipairs(v) do add(fmt) end
          elseif type(v) == "string" then
            add(v)
          end
        end
      end

      -- Pull from nvim-lint
      local ok_lint, lint = pcall(require, "lint")
      if ok_lint and type(lint.linters_by_ft) == "table" then
        for _, v in pairs(lint.linters_by_ft) do
          if type(v) == "table" then
            for _, l in ipairs(v) do add(l) end
          elseif type(v) == "string" then
            add(v)
          end
        end
      end

      -- De-duplicate and drop blocked tools
      local block = { cmakelang = true, cmakelint = true }
      local seen, out = {}, {}
      for _, name in ipairs(opts.ensure_installed) do
        if not block[name] and not seen[name] then
          seen[name] = true
          out[#out + 1] = name
        end
      end
      opts.ensure_installed = out

      -- Reasonable defaults
      opts.run_on_start = opts.run_on_start ~= false
      opts.start_delay = opts.start_delay or 3000
      opts.debounce_hours = opts.debounce_hours or 24
      opts.auto_update = opts.auto_update or false
    end,
  },
}
```

Fehlersuche

* `:MasonLog` zeigt Protokolle, warum eine Installation fehlschlägt (fehlendes `python3`, `npm`, `go`, `gem`).
* `:echo $PATH` in Neovim prüfen, wenn Installationen zwar im Terminal klappen, aber aus Neovim heraus scheitern.
* `require("mason-registry").get_installed_packages()` kann in `:lua` genutzt werden, um den Zustand zu inspizieren.

Pragmatischer Tipp

* Wenn man keine Auto-Installationsläufe beim Start möchte, `run_on_start = false` setzen und Pakete manuell verwalten:

  * `:MasonToolsInstall` für Neuinstallationen
  * `:MasonToolsUpdate` für Updates
  * `:MasonToolsClean` um alles zu deinstallieren, was nicht in `ensure_installed` steht.
