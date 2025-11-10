---@module 'md.tablewrap.commands'
--- User-facing commands, toggles, and autocmds for md.tablewrap.
--- This layer owns all notifications and user interactions.

local api = vim.api

local config = require("usrcmds.md_tablewrap.config")
local core = require("usrcmds.md_tablewrap.core")
local notify = vim.notify
local desc_tag = "[MDTableWrap] "

---@type MDTableWrapConfig
local CFG

local AUGROUP = "MDTableWrapAuto"

---@return nil
local function ensure_autocmds()
  -- Drop and recreate the group to reflect latest toggles.
  pcall(api.nvim_del_augroup_by_name, AUGROUP)
  if not CFG.on_save_enabled then
    return
  end

  local id = api.nvim_create_augroup(AUGROUP, { clear = true })
  api.nvim_create_autocmd("BufWritePre", {
    group = id,
    callback = function(args)
      local buf = args.buf
      if vim.bo[buf].filetype ~= "markdown" then
        return
      end
      if vim.wo.diff then
        return
      end -- avoid fighting diff mode

      local last = vim.b[buf].md_tablewrap_last_tick or 0
      local tick = api.nvim_buf_get_changedtick(buf)
      if tick == last then
        return
      end

      local ok, changed, err = core.reformat_all("detect", buf, CFG)
      if not ok then
        notify("MDTableWrap (on-save): " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
      end
      if changed and changed > 0 then
        vim.b[buf].md_tablewrap_last_tick = api.nvim_buf_get_changedtick(buf)
        notify(string.format("%s formatted %d table(s) on save.", desc_tag, changed), vim.log.levels.INFO)
      end
    end,
    desc = desc_tag .. "reflow all tables on save (Markdown only, detect mode).",
  })
end

---@param user_opts table|nil
---@return nil
local function setup(user_opts)
  local ok, cfg_or_err, err = config.normalize(user_opts)
  if not ok then
    notify(desc_tag .. " invalid configuration: " .. (err or "unknown"), vim.log.levels.ERROR)
    CFG = config.defaults()
  else
    ---@diagnostic disable-next-line
    CFG = cfg_or_err
  end

  -- helper to set mode safely
  local function set_mode(mode)
    if mode ~= "auto" and mode ~= "equal" and mode ~= "minflex" then
      notify(desc_tag .. " invalid mode " .. tostring(mode), vim.log.levels.ERROR)
      return
    end
    ---@diagnostic disable-next-line
    CFG.width_mode = mode
    CFG.auto_width = (mode == "auto") -- keep legacy flag coherent
    notify(desc_tag .. " width_mode = " .. mode, vim.log.levels.INFO)
  end

  ensure_autocmds()

  -- Core reflow command: scope depends on wrap_all_default
  api.nvim_create_user_command("MDTableWrap", function(opts)
    if not CFG then
      return
    end
    local mode = opts.bang and "force" or "detect"
    ---@diagnostic disable-next-line
    if CFG.wrap_all_default then
      local ok2, changed, e = core.reformat_all(mode, api.nvim_get_current_buf(), CFG)
      if not ok2 then
        notify(desc_tag .. " " .. (e or "failed"), vim.log.levels.ERROR)
        return
      end
      if changed and changed > 0 then
        notify(string.format("%sformatted %d table(s).", desc_tag, changed), vim.log.levels.INFO)
      else
        notify(desc_tag .. " nothing to format.", vim.log.levels.INFO)
      end
    else
      local ok2, e = core.reformat_current(mode, CFG)
      if not ok2 then
        if e == "not on a table line" and mode ~= "force" then
          notify(desc_tag .. " place cursor inside a Markdown table.", vim.log.levels.WARN)
        else
          notify(desc_tag .. " " .. (e or "failed"), vim.log.levels.ERROR)
        end
        return
      end
      notify(desc_tag .. " table formatted.", vim.log.levels.INFO)
    end
  end, {
    desc = desc_tag .. "Reflow Markdown tables (scope depends on wrap_all_default). Use ! to force.",
    bang = true,
  })

  api.nvim_create_user_command("MDTableWrapAll", function(opts)
    local mode = opts.bang and "force" or "detect"
    ---@diagnostic disable-next-line
    local ok2, changed, e = core.reformat_all(mode, api.nvim_get_current_buf(), CFG)
    if not ok2 then
      notify(desc_tag .. " " .. (e or "failed"), vim.log.levels.ERROR)
      return
    end
    if changed and changed > 0 then
      notify(string.format("%sformatted %d table(s).", desc_tag, changed), vim.log.levels.INFO)
    else
      notify(desc_tag .. " nothing to format.", vim.log.levels.INFO)
    end
  end, { desc = desc_tag .. "Reflow all Markdown tables in the current buffer. Use ! to force.", bang = true })

  api.nvim_create_user_command("MDTableWrapAllToggle", function()
    if not CFG then
      notify(desc_tag .. "CFG not available", 4)
      return
    end
    CFG.wrap_all_default = not CFG.wrap_all_default
    notify(desc_tag .. " wrap_all_default = " .. tostring(CFG.wrap_all_default), vim.log.levels.INFO)
  end, { desc = desc_tag .. "Toggle default scope for :MDTableWrap between current table and all tables." })

  api.nvim_create_user_command("MDTableOnSaveToggle", function()
    if not CFG then
      notify(desc_tag .. "CFG not available", 4)
      return
    end
    CFG.on_save_enabled = not CFG.on_save_enabled
    ensure_autocmds()
    notify(desc_tag .. " on_save_enabled = " .. tostring(CFG.on_save_enabled), vim.log.levels.INFO)
  end, { desc = desc_tag .. "Toggle reflow of all tables on save (Markdown buffers only)." })

  -- Width strategy toggles
  api.nvim_create_user_command("MDTableWidthToggle", function()
    set_mode(CFG.width_mode == "auto" and "equal" or "auto")
  end, { desc = desc_tag .. "Toggle between auto-width and equal-width modes." })

  api.nvim_create_user_command("MDTableAutoWidth", function()
    set_mode("auto")
  end, { desc = desc_tag .. "Set auto-width mode." })

  api.nvim_create_user_command("MDTableEqualWidth", function()
    set_mode("equal")
  end, { desc = desc_tag .. "Set equal-width mode." })

  api.nvim_create_user_command("MDTableFlexWidth", function()
    set_mode("minflex")
  end, { desc = desc_tag .. "Set minflex mode (keep minima, give remainder to wrapping columns)." })

  api.nvim_create_user_command("MDTableWidthMode", function(opts)
    local m = vim.trim(opts.args or "")
    set_mode(m)
  end, {
    desc = desc_tag .. "Set width_mode: auto|equal|minflex.",
    nargs = 1,
    complete = function()
      return { "auto", "equal", "minflex" }
    end,
  })

  api.nvim_create_user_command("MDTableWidthCycle", function()
    local order = { auto = "equal", equal = "minflex", minflex = "auto" }
    if not CFG then
      set_mode("auto")
      return
    end
    if order[CFG.width_mode] and order[CFG.width_mode] ~= "" then
      set_mode(order[CFG.width_mode] and order[CFG.width_mode] or "auto")
    else
      set_mode("auto")
    end
  end, { desc = desc_tag .. "Cycle width_mode: auto → equal → minflex → auto." })

  -- Setters for min/max width
  api.nvim_create_user_command("MDTableWidthInfo", function()
    if not CFG then
      notify(desc_tag .. "CFG not available", 4)
      return
    end
    local m = string.format(
      "width_mode=%s (auto_width=%s), max_col_width=%s, min_col_width=%s, inner_pad=%d, outer_left=%d, outer_right=%d, wrap_all_default=%s, on_save_enabled=%s",
      tostring(CFG.width_mode),
      tostring(CFG.auto_width),
      CFG.max_col_width and tostring(CFG.max_col_width) or "nil",
      CFG.min_col_width and tostring(CFG.min_col_width) or "nil",
      CFG.inner_pad and CFG.inner_pad or 0,
      CFG.outer_left and CFG.outer_left or 0,
      CFG.outer_right and CFG.outer_right or 0,
      tostring(CFG.wrap_all_default),
      tostring(CFG.on_save_enabled)
    )
    notify(desc_tag .. " " .. m, vim.log.levels.INFO, { title = "MDTableWrap" })
  end, { desc = desc_tag .. "Show current width and behavior settings." })

  api.nvim_create_user_command("MDTableSetMinWidth", function(opts)
    if not CFG then
      notify(desc_tag .. "CFG not available", 4)
      return
    end
    local a = vim.trim(opts.args or "")
    if a == "" or a == "nil" or a == "false" or a == "0" then
      CFG.min_col_width = 1
      notify(desc_tag .. " min_col_width set to 1.", vim.log.levels.INFO)
      return
    end
    local n = tonumber(a)
    if not n or n < 1 or n ~= math.floor(n) then
      notify(desc_tag .. " invalid min_col_width (need integer ≥ 1).", vim.log.levels.ERROR)
      return
    end
    CFG.min_col_width = math.floor(n)
    notify(desc_tag .. " min_col_width = " .. tostring(CFG.min_col_width), vim.log.levels.INFO)
  end, { desc = desc_tag .. "Set min column width in cells (≥1).", nargs = "?" })

  -- Info
  api.nvim_create_user_command("MDTableWidthInfo", function()
    if not CFG then
      notify(desc_tag .. "CFG not available", 4)
      return
    end
    local m = string.format(
      "auto_width=%s, max_col_width=%s, min_col_width=%s, inner_pad=%d, outer_left=%d, outer_right=%d, wrap_all_default=%s, on_save_enabled=%s",
      tostring(CFG.auto_width),
      CFG.max_col_width and tostring(CFG.max_col_width) or "nil",
      CFG.min_col_width and tostring(CFG.min_col_width) or "nil",
      CFG.inner_pad or "nil",
      CFG.outer_left or "nil",
      CFG.outer_right or "nil",
      tostring(CFG.wrap_all_default),
      tostring(CFG.on_save_enabled)
    )
    notify(desc_tag .. " " .. m, vim.log.levels.INFO, { title = "MDTableWrap" })
  end, { desc = desc_tag .. "Show current width and behavior settings." })
end

local M = {}
M.setup = setup

--- Optional: allow tests to override text area provider (DI).
---@param fn_provider fun(win:integer):integer
function M.set_text_area_provider(fn_provider)
  core.set_text_area_provider(fn_provider)
end

return M
