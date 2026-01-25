---@module 'config.neotree.open.window.debug'
---@brief Debug commands for custom float implementation

local notify = require("lib.notify").create("[config.neotree.open.window.debug]")

local M = {}

---Force-reset all neo-tree window state including custom float
---@return nil
function M.force_reset_state()
  local state = require("config.neotree.state.windows")
  local tree_state = require("config.neotree.state.tree")
  local controller = require("config.neotree.open.window.controller")

  -- Clear busy guard
  controller.clear_semaphore()

  -- Reset window state
  state.set_closed("force_reset")

  -- Reset tree state
  tree_state.reset()

  -- Close all neo-tree buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  notify.info("[neo-tree] State forcefully reset (including custom float)")
end

---Show current state including custom float
---@return nil
function M.show_debug_state()
  local state = require("config.neotree.state.windows")
  local tree_state = require("config.neotree.state.tree")
  local custom_float = require("config.neotree.open.window.custom_float")

  local info = {
    window_state = {
      open = state.is_open(),
      position = state.get_position(),
      source = state.get_source(),
    },
    tree_state = {
      node_id = tree_state.get_node(),
      expanded_count = vim.tbl_count(tree_state.get_expanded()),
    },
    custom_float = {
      is_open = custom_float.is_open(),
      window = custom_float.get_window(),
      buffer = custom_float.get_buffer(),
    },
    neo_tree_buffers = {},
    neo_tree_windows = {},
  }

  -- Find neo-tree buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
      table.insert(info.neo_tree_buffers, buf)
    end
  end

  -- Find neo-tree windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        local win_cfg = vim.api.nvim_win_get_config(win)
        table.insert(info.neo_tree_windows, {
          win = win,
          buf = buf,
          relative = win_cfg.relative,
        })
      end
    end
  end

  vim.print(info)
end

---Test custom float window
---@param source? string Source to test (default: "filesystem")
function M.test_custom_float(source)
  source = source or "filesystem"

  local custom_float = require("config.neotree.open.window.custom_float")

  notify.info(string.format("[debug] Testing custom float with source: %s", source))

  custom_float.open(source, function(success)
    if success then
      notify.info("[debug] Custom float opened successfully")
    else
      notify.error("[debug] Custom float failed to open")
    end
  end)
end

---Compare custom float vs native float (side by side test)
function M.compare_float_implementations()
  notify.info("[debug] Starting float comparison test")
  notify.info("[debug] Step 1: Testing custom float...")

  local custom_float = require("config.neotree.open.window.custom_float")

  custom_float.open("filesystem", function(success)
    if success then
      notify.info("[debug] ✓ Custom float: SUCCESS")

      vim.defer_fn(function()
        custom_float.close(function()
          notify.info("[debug] Step 2: Testing native float...")

          vim.defer_fn(function()
            local ok, NeoCmd = pcall(require, "neo-tree.command")
            if ok then
              pcall(NeoCmd.execute, {
                source = "filesystem",
                action = "show",
                position = "float",
                toggle = false,
              })

              notify.info("[debug] Native float executed")
            end
          end, 500)
        end)
      end, 2000)
    else
      notify.error("[debug] ✗ Custom float: FAILED")
    end
  end)
end

-- ============================================================================
-- User Commands
-- ============================================================================

---FIX: enable()

vim.api.nvim_create_user_command("NeoTreeDebugState", function()
  M.show_debug_state()
end, { desc = "[Neo-tree] Show debug state (including custom float)" })

vim.api.nvim_create_user_command("NeoTreeResetState", function()
  M.force_reset_state()
end, { desc = "[Neo-tree] Force reset all state" })

vim.api.nvim_create_user_command("NeoTreeTestFloat", function(opts)
  local source = opts.args ~= "" and opts.args or "filesystem"
  M.test_custom_float(source)
end, {
  nargs = "?",
  complete = function()
    return { "filesystem", "buffers", "git_status", "document_symbols" }
  end,
  desc = "[Neo-tree] Test custom float window",
})

vim.api.nvim_create_user_command("NeoTreeCompareFloats", function()
  M.compare_float_implementations()
end, { desc = "[Neo-tree] Compare custom vs native float" })

return M

