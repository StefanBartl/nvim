---@module 'wkdoptions.options_config'
--- Editor option toggles & global behaviors which are not purely visual
--- highlight groups:
---   * cursorline/column defaults (cooperate with hl_config)
---   * guicursor mapping to custom highlight groups
---   * optional subtle matchparen blink (enable_matchparen, matchtime_tenths)
---   * user commands :MyOptSet / :MyOptShow / :MyOptList

local lazy = require("lib.lazy")
local C = lazy.require("wkdoptions.config")
local ocfg = lazy.require("wkdoptions.config.data.options")
local hcfg = lazy.require("wkdoptions.config.data.highlight")

---@diagnostic disable-next-line unused local
local buffer_is_ui_like = require("wkdoptions.hl_config.utils.skip").std_skip

local AUG_OPTS = vim.api.nvim_create_augroup("myopt_Options", { clear = true })

---@return nil
local function apply_matchparen()
  if ocfg.enable_matchparen then
    vim.opt.showmatch = true
    vim.opt.matchtime = tonumber(ocfg.matchtime_tenths or 2) or 2
  else
    -- Disable subtly: showmatch off, reset matchtime to default (2 tenths)
    vim.opt.showmatch = false
    vim.opt.matchtime = 2
  end
end

---@return nil
local function apply_cursorline_defaults()
  vim.opt.cursorline = hcfg.enable_line
  vim.opt.cursorlineopt = "both"
  vim.opt.cursorcolumn = hcfg.enable_column
end

---@return nil
local function apply_guicursor()
  if not hcfg.map_cursor_to_hl then
    vim.opt.guicursor = "" -- default
    return
  end
  if hcfg.enable_insert_submode_colors then
    local preferred = table.concat({
      "n-v-c:block-CursorNormal",
      "i-ci:ver25-CursorInsert",
      "r-cr:hor20-CursorReplace",
      "o:hor50-CursorNormal",
      "v-ve:block-CursorVisual",
    }, ",")
    local ok = pcall(vim.api.nvim_set_option_value, "guicursor", preferred, { scope = "global" })
    if ok then
      return
    end
  end
  local fallback = table.concat({
    "n-v-c:block-Cursor",
    "i-ci:ver25-Cursor",
    "r-cr:hor20-Cursor",
    "o:hor50-Cursor",
  }, ",")
  local ok2 = pcall(vim.api.nvim_set_option_value, "guicursor", fallback, { scope = "global" })
  if ok2 then
    return
  end
  vim.cmd("set guicursor&")
end

---@param key string
---@return nil
local function after_set(key)
  if key == "enable_matchparen" or key == "matchtime_tenths" then
    apply_matchparen()
    return
  end
  -- Even though these are in highlight.cfg, cursor defaults and guicursor
  -- depend on them; we re-apply when highlight-keys change.
  if
    key == "enable_line"
    or key == "enable_column"
    or key == "map_cursor_to_hl"
    or key == "enable_insert_submode_colors"
  then
    apply_cursorline_defaults()
    apply_guicursor()
    return
  end
end

---@return nil
local function enable()
  apply_matchparen()
  apply_cursorline_defaults()
  apply_guicursor()

  -- Re-apply on colorscheme too (to keep guicursor sane if scheme touches it)
  vim.api.nvim_clear_autocmds({ group = AUG_OPTS })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = AUG_OPTS,
    callback = function()
      apply_cursorline_defaults()
      apply_guicursor()
      apply_matchparen()
    end,
    desc = "Keep base options/guicursor stable across colorscheme changes",
  })

  -- Subscribe to my own option changes
  C.on_after_set("options", after_set)

  -- Also subscribe to highlight keys that affect options behavior
  C.on_after_set("highlight", after_set)

  require("wkdoptions.commands").register_options_commands({
    after_set = after_set, -- bestehende Re-Apply-Funktion
    show_table = ocfg, -- Live-Options-Konfiguration (C.cfg.options)
    names = { set = "MyOptSet", show = "MyOptShow", list = "MyOptList" }, -- optional
  })
end

return { enable = enable }
