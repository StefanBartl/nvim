---@module 'autocmds.patches.usercommands'
---@brief User commands for patch management system.
---@description
--- Provides convenient Vim commands for common patch operations.
--- All commands are prefixed with 'Patch' for easy discovery via :Patch<Tab>.

local patches = require("autocmds.patches")

local M = {}

local fn = vim.fn
local create_usercommand = vim.api.nvim_create_user_command
local notify, levels = vim.notify, vim.log.levels
local str_format = string.format
local tbl_insert, tbl_concat = table.insert, table.concat

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
      notify("Usage: PatchApply [repo <name>|key <name>]", levels.ERROR)
    end
  end, {
    nargs = "*",
    desc = "[autocmds.patches] Apply patches (all, by repo, or by key)",
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
        return vim.tbl_map(function(p)
          return p.key
        end, patch_list)
      end

      return {}
    end,
  })

  -- Command for applying all patches
  create_usercommand("PatchApplyAll", function()
    require("autocmds.patches").apply_all_async()
  end, {
    desc = "[autocmds.patches] Apply all patches asynchronously",
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
      tbl_insert(lines, str_format("%s [%s] %s%s", icon, entry.repo, entry.key, msg))
    end

    notify(tbl_concat(lines, "\n"), levels.INFO)
  end, {
    nargs = 0,
    desc = "[autocmds.patches] Show patch status for all registered patches",
  })

  -- Validate patches
  create_usercommand("PatchValidate", function()
    notify("Validating patches...", levels.INFO)
    patches.validate_all(function(results)
      local valid = vim.tbl_filter(function(r)
        return r.valid
      end, results)
      local invalid = vim.tbl_filter(function(r)
        return not r.valid
      end, results)

      if #invalid == 0 then
        notify(str_format("All %d patches are valid ✅", #results), levels.INFO)
      else
        local lines = {
          str_format("Validation: %d valid, %d invalid", #valid, #invalid),
          "",
          "Invalid patches:",
        }
        for _, r in ipairs(invalid) do
          tbl_insert(lines, str_format("  ❌ %s: %s", r.key, r.error))
        end
        notify(tbl_concat(lines, "\n"), levels.WARN)
      end
    end)
  end, {
    nargs = 0,
    desc = "[autocmds.patches] Validate all patch files (dry-run)",
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
    desc = "[autocmds.patches] Clear patch status cache",
  })

  -- Show logs
  create_usercommand("PatchLogs", function(_)
    patches.show_logs_buffer()
  end, {
    nargs = 0,
    desc = "[autocmds.patches] Open patch logs in a new buffer",
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
      tbl_insert(
        lines,
        str_format("%s [%s] %s (priority: %d)", enabled, entry.repo or "unknown", entry.key, priority)
      )
    end

    notify(tbl_concat(lines, "\n"), levels.INFO)
  end, {
    nargs = 0,
    desc = "[autocmds.patches] List all registered patches",
  })

  -- Enable verbose mode
  create_usercommand("PatchVerbose", function(opts)
    local enable = opts.args ~= "off"
    patches.setup({ verbose = enable })
    notify(str_format("Verbose logging %s", enable and "enabled" or "disabled"), levels.INFO)
  end, {
    nargs = "?",
    complete = function()
      return { "on", "off" }
    end,
    desc = "[autocmds.patches] Enable/disable verbose logging (PatchVerbose [on|off])",
  })

  -- System check
  create_usercommand("PatchCheck", function()
    local issues = {}
    local ok_icon = "✅"
    local warn_icon = "⚠️"
    local err_icon = "❌"

    -- Check if patch command exists
    local patch_path = fn.exepath("patch")
    local has_patch = patch_path ~= ""

    local lines = { "System Check:", "" }

    if has_patch then
      tbl_insert(lines, str_format("%s patch command found: %s", ok_icon, patch_path))

      -- Get version
      local version = fn.system("patch --version"):match("patch ([%d%.]+)")
      if version then
        tbl_insert(lines, str_format("   Version: %s", version))
      end
    else
      tbl_insert(lines, str_format("%s patch command NOT found", err_icon))
      tbl_insert(issues, "patch")
    end

    -- Check registry
    local patch_list = patches.list()
    tbl_insert(lines, "")
    tbl_insert(lines, str_format("%s %d patches registered", ok_icon, #patch_list))

    -- Check patch files exist
    local missing_patches = 0
    local missing_targets = 0

    for _, entry in ipairs(patch_list) do
      if fn.filereadable(entry.patch) ~= 1 then
        missing_patches = missing_patches + 1
      end
      if fn.filereadable(entry.target) ~= 1 then
        missing_targets = missing_targets + 1
      end
    end

    if missing_patches > 0 then
      tbl_insert(lines, str_format("%s %d patch files missing", warn_icon, missing_patches))
      tbl_insert(issues, "missing_patches")
    else
      tbl_insert(lines, str_format("%s All patch files present", ok_icon))
    end

    if missing_targets > 0 then
      tbl_insert(lines, str_format("%s %d target files missing", warn_icon, missing_targets))
      tbl_insert(issues, "missing_targets")
    else
      tbl_insert(lines, str_format("%s All target files present", ok_icon))
    end

    -- Show recommendations
    if #issues > 0 then
      tbl_insert(lines, "")
      tbl_insert(lines, "Recommendations:")

      if vim.tbl_contains(issues, "patch") then
        tbl_insert(lines, "")
        tbl_insert(lines, "  Install patch command:")
        if fn.has("win32") == 1 then
          tbl_insert(lines, "    • Git for Windows: includes patch.exe in usr/bin")
          tbl_insert(lines, "    • Scoop: scoop install patch")
          tbl_insert(lines, "    • Chocolatey: choco install patch")
        else
          tbl_insert(lines, "    • Linux: sudo apt install patch")
          tbl_insert(lines, "    • macOS: brew install gpatch")
        end
      end

      if vim.tbl_contains(issues, "missing_patches") then
        tbl_insert(lines, "")
        tbl_insert(lines, "  Some patch files are missing. Check paths in paths.lua")
      end

      if vim.tbl_contains(issues, "missing_targets") then
        tbl_insert(lines, "")
        tbl_insert(lines, "  Some target files are missing. Install missing plugins:")
        tbl_insert(lines, "    :Lazy sync")
      end
    end

    local level = #issues > 0 and levels.WARN or levels.INFO
    notify(tbl_concat(lines, "\n"), level)
  end, {
    nargs = 0,
    desc = "[autocmds.patches] Check system requirements for patch system",
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
    notify(tbl_concat(lines, "\n"), levels.INFO)
  end, {
    nargs = 0,
    desc = "[autocmds.patches] Show patch command help",
  })
end

--- Fix line endings in patch files
create_usercommand("PatchFixLineEndings", function(_)
  local utils = require("autocmds.patches.utils")
  local logger = require("autocmds.patches.logger")

  local patches_dir = fn.stdpath("config") .. "/patches"
  local files = fn.glob(patches_dir .. "/**/*.patch", false, true)

  local fixed_count = 0
  local failed_count = 0

  for _, file in ipairs(files) do
    local content, err = utils.read_file(file)
    if not content then
      logger.error("Failed to read", { file = file, error = err })
      failed_count = failed_count + 1
      goto continue
    end

    -- Normalize line endings
    local normalized = content:gsub("\r\n", "\n"):gsub("\r", "\n")

    -- Remove trailing whitespace from lines
    local lines = {}
    for line in normalized:gmatch("([^\n]*)\n?") do
      tbl_insert(lines, (line:gsub("%s+$", "")))
    end
    normalized = tbl_concat(lines, "\n")

    -- Ensure single trailing newline
    normalized = normalized:gsub("\n+$", "") .. "\n"

    -- Only write if changed
    if normalized ~= content then
      local ok, write_err = utils.write_file(file, normalized)
      if ok then
        fixed_count = fixed_count + 1
        logger.info("Fixed line endings", { file = file })
      else
        logger.error("Failed to write", { file = file, error = write_err })
        failed_count = failed_count + 1
      end
    end

    ::continue::
  end

  notify(
    str_format("[patches] Fixed %d files, %d failed", fixed_count, failed_count),
    fixed_count > 0 and levels.INFO or levels.WARN
  )
end, {
  desc = "Fix line endings in all patch files",
})

create_usercommand("PatchMeasureApplyAll", function()
  require("autocmds.potches.utils").measure_patch_time()
end, {
  desc = "[autocmds.patches] Measure patch application time",
})

return M
