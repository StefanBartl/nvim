---@module 'autocmds.patches.usercommands'
---@brief User commands for patch management system.
---@description
--- Provides convenient Vim commands for common patch operations.
--- All commands are prefixed with 'Patch' for easy discovery via :Patch<Tab>.

local patches = require("autocmds.patches")

local M = {}

local create_usercommand = vim.api.nvim_create_user_command
local notify =  vim.notify
local levels = vim.log.levels

--- Register all user commands
---@return nil
function M.setup()
  -- Apply all patches
  create_usercommand("PatchApply", function(opts)
    local args = vim.split(opts.args, " ", { trimempty = true })

    if #args == 0 then
      -- Apply all patches
      patches.apply_all_async()
    elseif args[1] == "repo" and args[2] then
      -- Apply patches for specific repo
      patches.apply_async({ repos = { args[2] } })
    elseif args[1] == "key" and args[2] then
      -- Apply specific patch by key
      patches.apply_async({ keys = { args[2] } })
    else
      notify(
        "Usage: PatchApply [repo <name>|key <name>]",
        levels.ERROR
      )
    end
  end, {
    nargs = "*",
    desc = "Apply patches (all, by repo, or by key)",
    complete = function(_, cmd_line, _)
      local args = vim.split(cmd_line, " ", { trimempty = true })

      if #args == 1 or (#args == 2 and cmd_line:sub(-1) ~= " ") then
        return { "repo", "key" }
      elseif #args >= 2 and args[2] == "repo" then
        -- List all repos
        local patch_list = patches.list()
        local repos = {}
        for _, p in ipairs(patch_list) do
          local repo = p.repo or "unknown"
          repos[repo] = true
        end
        return vim.tbl_keys(repos)
      elseif #args >= 2 and args[2] == "key" then
        -- List all keys
        local patch_list = patches.list()
        return vim.tbl_map(function(p) return p.key end, patch_list)
      end

      return {}
    end,
  })

  -- Show patch status
  create_usercommand("PatchStatus", function(_)
    local status = patches.get_status()

    if #status == 0 then
      notify("No patches registered", levels.INFO)
      return
    end

    -- Format status table
    local lines = { "Patch Status:", "" }
    local icons = {
      applied = "✅",
      failed = "❌",
      already_applied = "⏭️",
      disabled = "⏸️",
      never_tried = "⭕",
    }

    for _, entry in ipairs(status) do
      local icon = icons[entry.status] or "❓"
      local msg = entry.message and (" - " .. entry.message) or ""
      table.insert(
        lines,
        string.format(
          "%s [%s] %s%s",
          icon,
          entry.repo,
          entry.key,
          msg
        )
      )
    end

    notify(table.concat(lines, "\n"), levels.INFO)
  end, {
    nargs = 0,
    desc = "Show patch status for all registered patches",
  })

  -- Validate patches
  create_usercommand("PatchValidate", function()
    notify("Validating patches...", levels.INFO)
    patches.validate_all(function(results)
      local valid = vim.tbl_filter(function(r) return r.valid end, results)
      local invalid = vim.tbl_filter(function(r) return not r.valid end, results)

      if #invalid == 0 then
        notify(
          string.format("All %d patches are valid ✅", #results),
          levels.INFO
        )
      else
        local lines = {
          string.format("Validation: %d valid, %d invalid", #valid, #invalid),
          "",
          "Invalid patches:"
        }
        for _, r in ipairs(invalid) do
          table.insert(lines, string.format("  ❌ %s: %s", r.key, r.error))
        end
        notify(table.concat(lines, "\n"), levels.WARN)
      end
    end)
  end, {
    nargs = 0,
    desc = "Validate all patch files (dry-run)",
  })

  -- Clear status cache
  create_usercommand("PatchClear", function()
    if patches.clear_status() then
      notify("Patch status cache cleared", levels.INFO)
    else
      notify("Failed to clear status cache", levels.ERROR)
    end
  end, {
    nargs = 0,
    desc = "Clear patch status cache",
  })

  -- Show logs
  create_usercommand("PatchLogs", function(_)
    patches.show_logs_buffer()
  end, {
    nargs = 0,
    desc = "Open patch logs in a new buffer",
  })

  -- List registered patches
  create_usercommand("PatchList", function()
    local patch_list = patches.list()

    if #patch_list == 0 then
      notify("No patches registered", levels.WARN)
      return
    end

    local lines = { "Registered Patches:", "" }
    for _, entry in ipairs(patch_list) do
      local enabled = entry.enabled ~= false and "✓" or "✗"
      local priority = entry.priority or 0
      table.insert(
        lines,
        string.format(
          "%s [%s] %s (priority: %d)",
          enabled,
          entry.repo or "unknown",
          entry.key,
          priority
        )
      )
    end

    notify(table.concat(lines, "\n"), levels.INFO)
  end, {
    nargs = 0,
    desc = "List all registered patches",
  })

  -- Enable verbose mode
  create_usercommand("PatchVerbose", function(opts)
    local enable = opts.args ~= "off"
    patches.setup({ verbose = enable })
    notify(
      string.format("Verbose logging %s", enable and "enabled" or "disabled"),
      levels.INFO
    )
  end, {
    nargs = "?",
    complete = function() return { "on", "off" } end,
    desc = "Enable/disable verbose logging (PatchVerbose [on|off])",
  })

  -- System check
  create_usercommand("PatchCheck", function()
    local issues = {}
    local ok_icon = "✅"
    local warn_icon = "⚠️"
    local err_icon = "❌"

    -- Check if patch command exists
    local patch_path = vim.fn.exepath("patch")
    local has_patch = patch_path ~= ""

    local lines = { "System Check:", "" }

    if has_patch then
      table.insert(lines, string.format("%s patch command found: %s", ok_icon, patch_path))

      -- Get version
      local version = vim.fn.system("patch --version"):match("patch ([%d%.]+)")
      if version then
        table.insert(lines, string.format("   Version: %s", version))
      end
    else
      table.insert(lines, string.format("%s patch command NOT found", err_icon))
      table.insert(issues, "patch")
    end

    -- Check registry
    local patch_list = patches.list()
    table.insert(lines, "")
    table.insert(lines, string.format("%s %d patches registered", ok_icon, #patch_list))

    -- Check patch files exist
    local missing_patches = 0
    local missing_targets = 0

    for _, entry in ipairs(patch_list) do
      if vim.fn.filereadable(entry.patch) ~= 1 then
        missing_patches = missing_patches + 1
      end
      if vim.fn.filereadable(entry.target) ~= 1 then
        missing_targets = missing_targets + 1
      end
    end

    if missing_patches > 0 then
      table.insert(lines, string.format("%s %d patch files missing", warn_icon, missing_patches))
      table.insert(issues, "missing_patches")
    else
      table.insert(lines, string.format("%s All patch files present", ok_icon))
    end

    if missing_targets > 0 then
      table.insert(lines, string.format("%s %d target files missing", warn_icon, missing_targets))
      table.insert(issues, "missing_targets")
    else
      table.insert(lines, string.format("%s All target files present", ok_icon))
    end

    -- Show recommendations
    if #issues > 0 then
      table.insert(lines, "")
      table.insert(lines, "Recommendations:")

      if vim.tbl_contains(issues, "patch") then
        table.insert(lines, "")
        table.insert(lines, "  Install patch command:")
        if vim.fn.has("win32") == 1 then
          table.insert(lines, "    • Git for Windows: includes patch.exe in usr/bin")
          table.insert(lines, "    • Scoop: scoop install patch")
          table.insert(lines, "    • Chocolatey: choco install patch")
        else
          table.insert(lines, "    • Linux: sudo apt install patch")
          table.insert(lines, "    • macOS: brew install gpatch")
        end
      end

      if vim.tbl_contains(issues, "missing_patches") then
        table.insert(lines, "")
        table.insert(lines, "  Some patch files are missing. Check paths in paths.lua")
      end

      if vim.tbl_contains(issues, "missing_targets") then
        table.insert(lines, "")
        table.insert(lines, "  Some target files are missing. Install missing plugins:")
        table.insert(lines, "    :Lazy sync")
      end
    end

    local level = #issues > 0 and levels.WARN or levels.INFO
    notify(table.concat(lines, "\n"), level)
  end, {
    nargs = 0,
    desc = "Check system requirements for patch system",
  })

  -- Show help
  create_usercommand("PatchHelp", function()
    local lines = {
      "Patch Management Commands:",
      "",
      "  :PatchApply              - Apply all patches",
      "  :PatchApply repo <name>  - Apply patches for specific repo",
      "  :PatchApply key <name>   - Apply specific patch",
      "",
      "  :PatchStatus             - Show status of all patches",
      "  :PatchList               - List registered patches",
      "  :PatchValidate           - Validate patch files",
      "",
      "  :PatchLogs               - Open log file",
      "  :PatchClear              - Clear status cache",
      "  :PatchVerbose [on|off]   - Toggle verbose logging",
      "",
      "  :PatchHelp               - Show this help",
      "",
      "For more info: :help patches",
    }
    notify(table.concat(lines, "\n"), levels.INFO)
  end, {
    nargs = 0,
    desc = "Show patch command help",
  })
end

return M
