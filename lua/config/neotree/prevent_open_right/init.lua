---@module 'config.neotree.prevent_open_right'
---Prevents Neo-tree from opening on the right side in any situation.

local M = {}

---@type string[] Positions to block
M.blocked_positions = { "right" }

---@type string Fallback position when blocked position is detected
M.fallback_position = "left"

---Validates and sanitizes a position string
---@param position string|nil
---@return string Sanitized position
local function sanitize_position(position)
  if not position or vim.tbl_contains(M.blocked_positions, position) then
    return M.fallback_position
  end
  return position
end

---Check if a window is a Neo-tree window
---@param winid number
---@return boolean
local function is_neotree_window(winid)
  if not vim.api.nvim_win_is_valid(winid) then
    return false
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local filetype = vim.bo[bufnr].filetype
  return filetype == "neo-tree" or bufname:match("neo%-tree")
end

---Setup function: must be called BEFORE neo-tree.setup()
function M.setup()
  -- Hook into Neo-tree's command execution
  vim.api.nvim_create_autocmd("User", {
    pattern = "NeoTreeInit",
    callback = function()
      local ok_cmd, neo_cmd = pcall(require, "neo-tree.command")
      if not ok_cmd then return end

      local original_execute = neo_cmd.execute

      ---Wrapped execute function with position sanitization
      ---@param opts table|nil
      neo_cmd.execute = function(opts)
        if opts and opts.position then
          opts.position = sanitize_position(opts.position)
        end
        return original_execute(opts)
      end
    end,
  })

  -- Safeguard: Check Neo-tree windows after they open
  vim.api.nvim_create_autocmd("WinEnter", {
    pattern = "*",
    callback = function()
      -- Only process Neo-tree windows
      local winid = vim.api.nvim_get_current_win()
      if not is_neotree_window(winid) then
        return
      end

      -- Check if window is on the right side
      local ok_pos, win_pos = pcall(vim.api.nvim_win_get_position, winid)
      if not ok_pos then return end

      local ok_width, win_width = pcall(vim.api.nvim_win_get_width, winid)
      if not ok_width then return end

      local screen_width = vim.o.columns

      -- Window is on the right side (within 5 columns of right edge)
      if (win_pos[2] + win_width) >= (screen_width - 5) then
        vim.schedule(function()
          -- Get the source from the buffer
          local bufnr = vim.api.nvim_win_get_buf(winid)
          local bufname = vim.api.nvim_buf_get_name(bufnr)

          -- Extract source from buffer name (neo-tree://filesystem, etc.)
          local source = "filesystem" -- default
          if bufname:match("neo%-tree://(.+)") then
            source = bufname:match("neo%-tree://(.+)") or "filesystem"
          end

          -- Close the right-side window
          pcall(vim.api.nvim_win_close, winid, true)

          -- Reopen on the left
          local ok_cmd, neo_cmd = pcall(require, "neo-tree.command")
          if ok_cmd then
            neo_cmd.execute({
              source = source,
              position = M.fallback_position,
              action = "show",
            })
          end
        end)
      end
    end,
  })
end

return M
