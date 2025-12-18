---@diagnostic disable
---@module 'init'
---@brief Example integration of the patch system in user's init.lua

-- =================================================================
-- Beispiel 1: Minimale Integration (Standard-Config)
-- =================================================================

-- Patches werden automatisch geladen und mit Lazy.nvim integriert
-- Keine weitere Konfiguration nötig!
-- require("autocmds.patches") ist in autocmds/init.lua bereits enthalten

-- =================================================================
-- Beispiel 2: Custom-Konfiguration
-- =================================================================

require("autocmds.patches").setup({
  max_concurrency = 3,         -- Anzahl paralleler Patch-Operationen
  timeout_ms = 30000,          -- Timeout pro Patch (30 Sekunden)
  verbose = false,             -- DEBUG-Logging (nur bei Problemen aktivieren)
  notify = true,               -- Benachrichtigungen anzeigen
  lazy_update_delay_ms = 500,  -- Delay nach LazyUpdate-Event
})

-- =================================================================
-- Beispiel 3: Manuelles Triggern via Keymap
-- =================================================================

-- Alle Patches anwenden
vim.keymap.set("n", "<leader>pa", function()
  require("autocmds.patches").apply_all_async(function(results)
    local succeeded = vim.tbl_filter(function(r)
      return r.success
    end, results)

    vim.notify(
      string.format("Applied %d/%d patches", #succeeded, #results),
      vim.log.levels.INFO
    )
  end)
end, { desc = "Apply all patches" })

-- Status anzeigen
vim.keymap.set("n", "<leader>ps", function()
  local status = require("autocmds.patches").get_status()

  -- Formatierte Ausgabe
  local lines = { "Patch Status:" }
  for _, entry in ipairs(status) do
    local icon = entry.status == "applied" and "✅"
      or entry.status == "failed" and "❌"
      or entry.status == "already_applied" and "⏭️"
      or "⏸️"

    table.insert(
      lines,
      string.format("  %s %s [%s]", icon, entry.key, entry.status)
    )
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "Show patch status" })

-- Logs anzeigen
vim.keymap.set("n", "<leader>pl", function()
  require("autocmds.patches").show_logs_buffer()
end, { desc = "Show patch logs" })

-- Status-Cache leeren
vim.keymap.set("n", "<leader>pc", function()
  require("autocmds.patches").clear_status()
  vim.notify("Patch status cleared", vim.log.levels.INFO)
end, { desc = "Clear patch status" })

-- =================================================================
-- Beispiel 4: Selektive Anwendung
-- =================================================================

-- Nur gitsigns.nvim patchen
vim.keymap.set("n", "<leader>pg", function()
  require("autocmds.patches").apply_async({
    repos = { "gitsigns.nvim" },
    callback = function(results)
      vim.notify(
        string.format("Gitsigns: %d patches applied", #results),
        vim.log.levels.INFO
      )
    end,
  })
end, { desc = "Patch gitsigns.nvim" })

-- =================================================================
-- Beispiel 5: Post-Update-Hook (Custom Callback)
-- =================================================================

-- Eigener Autocommand NACH dem System-Autocommand
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyUpdate",
  callback = function()
    -- Warte auf System-Patches (500ms + 100ms Buffer)
    vim.defer_fn(function()
      local status = require("autocmds.patches").get_status({
        status_filter = { "failed" },
      })

      if #status > 0 then
        vim.notify(
          string.format(
            "⚠️  %d patches failed after LazyUpdate. Check :lua require('autocmds.patches').show_logs_buffer()",
            #status
          ),
          vim.log.levels.WARN
        )
      end
    end, 600)
  end,
  desc = "Check patch status after LazyUpdate",
})

-- =================================================================
-- Beispiel 6: Command für manuelle Anwendung
-- =================================================================

vim.api.nvim_create_user_command("PatchApply", function(opts)
  local args = vim.split(opts.args, " ", { trimempty = true })

  if #args == 0 then
    -- Alle Patches
    require("autocmds.patches").apply_all_async()
  elseif args[1] == "repo" and args[2] then
    -- Nach Repo
    require("autocmds.patches").apply_async({
      repos = { args[2] },
    })
  elseif args[1] == "key" and args[2] then
    -- Nach Key
    require("autocmds.patches").apply_async({
      keys = { args[2] },
    })
  else
    vim.notify("Usage: PatchApply [repo <name>|key <name>]", vim.log.levels.ERROR)
  end
end, {
  nargs = "*",
  desc = "Apply patches",
  complete = function(arg_lead, cmd_line, cursor_pos)
    local args = vim.split(cmd_line, " ", { trimempty = true })

    if #args == 1 then
      return { "repo", "key" }
    elseif #args == 2 and args[2] == "repo" then
      -- Liste alle Repos
      local patches = require("autocmds.patches").list()
      local repos = {}
      for _, p in ipairs(patches) do
        repos[p.repo or "unknown"] = true
      end
      return vim.tbl_keys(repos)
    elseif #args == 2 and args[2] == "key" then
      -- Liste alle Keys
      local patches = require("autocmds.patches").list()
      return vim.tbl_map(function(p)
        return p.key
      end, patches)
    end

    return {}
  end,
})

-- Usage:
-- :PatchApply                          " Alle Patches
-- :PatchApply repo gitsigns.nvim       " Nur gitsigns
-- :PatchApply key gitsigns-system-compat  " Nur ein Patch

-- =================================================================
-- Beispiel 7: Status in Statusline (z.B. lualine)
-- =================================================================

-- Funktion für lualine/statusline
local function patch_status_component()
  local status = require("autocmds.patches").get_status()

  local failed_count = vim.tbl_count(vim.tbl_filter(function(s)
    return s.status == "failed"
  end, status))

  if failed_count > 0 then
    return string.format("🔧 %d", failed_count)
  end

  return ""
end

-- In lualine.nvim Config:
-- sections = {
--   lualine_x = {
--     patch_status_component,
--     -- ... andere components
--   }
-- }

-- =================================================================
-- Beispiel 8: Validierung vor dem Commit (optional)
-- =================================================================

-- Autocommand für Pre-Commit-Hook (wenn Patches im Git-Repo sind)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = vim.fn.expand("~/.config/nvim/patches/**/*.patch"),
  callback = function()
    -- Validiere Patch-Datei bei Änderung
    local file = vim.fn.expand("<afile>")

    -- Einfacher Syntax-Check
    local lines = vim.fn.readfile(file)
    local has_diff_header = false

    for _, line in ipairs(lines) do
      if line:match("^diff ") or line:match("^%-%-%-") then
        has_diff_header = true
        break
      end
    end

    if not has_diff_header then
      vim.notify(
        string.format("Warning: %s does not appear to be a valid patch", vim.fn.fnamemodify(file, ":t")),
        vim.log.levels.WARN
      )
    end
  end,
  desc = "Validate patch file syntax",
})

-- =================================================================
-- Beispiel 9: Debugging-Helpers
-- =================================================================

-- Globale Debugging-Funktionen
_G.patch_debug = {
  -- Validiere alle
  validate = function()
    require("autocmds.patches").validate_all(function(results)
      vim.print(results)
    end)
  end,

  -- Status anzeigen
  status = function()
    local s = require("autocmds.patches").get_status()
    vim.print(s)
  end,

  -- Logs anzeigen
  logs = function(level)
    local logs = require("autocmds.patches").get_logs({
      level = level or "ERROR",
      limit = 20,
    })
    vim.print(logs)
  end,

  -- Teste einzelnen Patch
  test = function(key)
    require("autocmds.patches").apply_async({
      keys = { key },
      callback = function(results)
        vim.print(results[1])
      end,
    })
  end,
}

-- Usage in Neovim:
-- :lua patch_debug.validate()
-- :lua patch_debug.status()
-- :lua patch_debug.logs("ERROR")
-- :lua patch_debug.test("gitsigns-system-compat")

-- =================================================================
-- Beispiel 10: Performance-Monitoring
-- =================================================================

-- Messe Zeit für Patch-Anwendung
local function measure_patch_time()
  local start = vim.loop.now()

  require("autocmds.patches").apply_all_async(function(results)
    local duration = vim.loop.now() - start

    local total = #results
    local succeeded = vim.tbl_count(vim.tbl_filter(function(r)
      return r.success
    end, results))

    vim.notify(
      string.format(
        "Patches applied: %d/%d in %.2fs (avg: %.2fs per patch)",
        succeeded,
        total,
        duration / 1000,
        duration / 1000 / math.max(1, total)
      ),
      vim.log.levels.INFO
    )
  end)
end

-- Keymap für Performance-Test
vim.keymap.set("n", "<leader>pt", measure_patch_time, {
  desc = "Measure patch application time",
})
