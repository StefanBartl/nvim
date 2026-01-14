---@module 'config.neotree.config'

local M = {}

local function trash()
  -- Trash system setup
  local trash_mod = require("config.neotree.trash")
  trash_mod.setup({
    debug = false,
    auto_close_buffers = false,
    create_backups = true,
    use_safety_system = true,
  })

  -- Register trash user commands
  require("config.neotree.trash.commands").setup()
end

---@param opts table|nil
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts and opts.trash then
    trash()
  end

  if opts.window_debug or opts.debug then
    require("config.neotree.open.window.measuring").attach_opener_mappings()
  else
    require("config.neotree.open.window").attach_opener_mappings()
  end

  if opts.current_hl then
    require("config.neotree.current_hl").setup({
      colors = {
        file = "green",
        parent = { fg = "darkgreen", underline = false },
      },
    })
  end

  if opts.cwd_sync then
    require("config.neotree.cwd_sync").setup({
      debounce_ms = 150,
      keep_focus = true,
      also_set_nvim_cwd = false,
      open_if_closed = false,
      use_project_root = true,
      project_root_fallback_to_bufdir = true,
      force_position_left = true,
    })
  end
end

return M
