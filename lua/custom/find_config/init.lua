---@module 'custom.find_config'
---@description Cross-platform "find in Neovim config" with pluggable engines (fzf-lua, Telescope)

local notify = require("lib.notify").create("[find_config]")
local defaults = require("custom.find_config.config.defaults")

---@class Custom.FindConfig
local M = {}

--- Internal state
---@class Custom.FindConfig.State
---@field engine '"fzf"'|'"telescope"' Active engine
---@field engine_impl table|nil Engine implementation module
local state = {
  engine = defaults.engine,
  engine_impl = nil,
}

--- Load engine implementation module
---@param engine_name '"fzf"'|'"telescope"'
---@return table|nil engine_module
---@return string|nil error_msg
local function load_engine(engine_name)
  local module_path = "custom.find_config.engines." .. engine_name
  local ok, engine = pcall(require, module_path)
  if not ok then
    return nil, "Failed to load engine '" .. engine_name .. "': " .. tostring(engine)
  end
  return engine, nil
end

--- Setup find_config with user configuration
---@param cfg table|nil Configuration options:
---   engine: "fzf"|"telescope" (default: "fzf")
---   keymaps: { enable: boolean, prefix: string, find: string, grep: string }
---   usercmds: { enable: boolean, find: string, grep: string }
---@return nil
function M.setup(cfg)
  cfg = cfg or {}

  -- Merge user config with defaults
  local config = vim.tbl_deep_extend("force", {
    engine = defaults.engine,
    keymaps = defaults.keymaps,
    usercmds = defaults.usercmds,
  }, cfg)

  -- Load selected engine
  local engine, err = load_engine(config.engine)
  if not engine then
    notify.error(err or "Unknown engine error")
    return
  end

  -- Update internal state
  state.engine = config.engine
  state.engine_impl = engine

  -- Setup keymaps if enabled
  if config.keymaps.enable then
    local prefix = config.keymaps.prefix or "<leader>"
    local find_key = prefix .. (config.keymaps.find or "fc")
    local grep_key = prefix .. (config.keymaps.grep or "gc")

    vim.keymap.set("n", find_key, function()
      M.find_in_config()
    end, { desc = "Find file in Neovim config" })

    vim.keymap.set("n", grep_key, function()
      M.grep_in_config()
    end, { desc = "Grep in Neovim config" })
  end

  -- Setup user commands if enabled
  if config.usercmds.enable then
    local find_cmd = config.usercmds.find or "FindConfig"
    local grep_cmd = config.usercmds.grep or "GrepConfig"

    vim.api.nvim_create_user_command(find_cmd, function(params)
      if params.args ~= "" then
        -- Pass initial query to engine
        M.find_in_config({ query = params.args })
      else
        M.find_in_config()
      end
    end, {
      nargs = "?",
      desc = "Search files in Neovim config directory",
    })

    vim.api.nvim_create_user_command(grep_cmd, function(params)
      if params.args ~= "" then
        M.grep_in_config({ search = params.args })
      else
        M.grep_in_config()
      end
    end, {
      nargs = "?",
      desc = "Live grep in Neovim config directory",
    })
  end
end

--- Find files in Neovim config directory
---@param opts table|nil Engine-specific options
---@return nil
function M.find_in_config(opts)
  if not state.engine_impl then
    notify.error("Engine not initialized. Call setup() first.")
    return
  end

  state.engine_impl.find_in_config(opts or {})
end

--- Grep in Neovim config directory
---@param opts table|nil Engine-specific options
---@return nil
function M.grep_in_config(opts)
  if not state.engine_impl then
    notify.error("Engine not initialized. Call setup() first.")
    return
  end

  state.engine_impl.grep_in_config(opts or {})
end

return M
