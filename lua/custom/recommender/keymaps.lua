---@module 'custom.recommender.keymaps'
---Navigation and actions

local rendering = require("custom.recommender.rendering")
local autocmds = require("custom.recommender.autocmds")

local M = {}

local api = vim.api
local km_set = vim.keymap.set

---Check if a window is a normal, editable window
---@param winid integer
---@return boolean
local function is_normal_window(winid)
  if not api.nvim_win_is_valid(winid) then
    return false
  end

  local bufnr = api.nvim_win_get_buf(winid)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  -- Skip special buffers (nofile, terminal, etc.)
  local buftype = api.nvim_buf_get_option(bufnr, "buftype")
  if buftype ~= "" then
    return false
  end

  -- Must be modifiable
  if not api.nvim_buf_get_option(bufnr, "modifiable") then
    return false
  end

  return true
end

---Find the best target window for insertion
---@return integer|nil
local function find_target_window()
  -- 1. Try the stored source window
  if rendering.source_win and is_normal_window(rendering.source_win) then
    return rendering.source_win
  end

  -- 2. Try alternate window (previous window)
  local alt_win = vim.fn.win_getid(vim.fn.winnr("#"))
  if alt_win and alt_win ~= 0 and is_normal_window(alt_win) then
    return alt_win
  end

  -- 3. Fallback: find first normal window
  for _, win in ipairs(api.nvim_list_wins()) do
    if is_normal_window(win) then
      return win
    end
  end

  return nil
end

---Check if a line is selectable (chain line, not alias line)
---@param line integer
---@return boolean
local function is_selectable(line)
  return line > 1 and (line - 2) % 3 == 0
end

---Move cursor to next/previous selectable line
---@param delta integer
local function move(delta)
  if not rendering.is_open() then
    return
  end

  local ok, cursor = pcall(api.nvim_win_get_cursor, rendering.float_win)
  if not ok then
    return
  end

  local line = cursor[1]
  local target = line + delta

  -- Get buffer line count
  local line_count = api.nvim_buf_line_count(rendering.float_buf)

  -- Find next selectable line
  while target >= 2 and target <= line_count do
    if is_selectable(target) then
      pcall(api.nvim_win_set_cursor, rendering.float_win, { target, 0 })
      rendering.cursor_index = target
      return
    end
    target = target + delta
  end
end

---@param bufnr integer
---@param state table
function M.attach(bufnr, state)
  if not bufnr or not api.nvim_buf_is_valid(bufnr) then
    return
  end

  local opts = { buffer = bufnr, silent = true, nowait = true }

  km_set("n", "j", function()
    move(3)
  end, opts)

  km_set("n", "k", function()
    move(-3)
  end, opts)

  km_set("n", "<Down>", function()
    move(3)
  end, opts)

  km_set("n", "<Up>", function()
    move(-3)
  end, opts)

  km_set("n", "q", function()
    rendering.close()
  end, opts)

  km_set("n", "<ESC>", function()
    rendering.close()
  end, opts)

  km_set("n", "<CR>", function()
    if not rendering.is_open() then
      return
    end

    local idx = math.floor((rendering.cursor_index - 2) / 3) + 1
    local item = state.visible[idx]
    if not item then
      return
    end

    local alias_text = item.alias
    local chain = item.chain

    local target_win = find_target_window()
    if not target_win then
      vim.notify("Could not find a suitable window for insertion", vim.log.levels.WARN)
      return
    end

    -- save pending state
    state._pending_insert = {
      win = target_win,
      text = alias_text,
    }

    if state.replace_mode then
      autocmds.register_replace_finish(state)
    end

    rendering.close()

    vim.schedule(function()
      if not api.nvim_win_is_valid(target_win) then
        return
      end

      api.nvim_set_current_win(target_win)

      -- Editor stabilisieren (ersetzt das frühere nvim_put)
      vim.cmd("normal! \27") -- sicher Normal-Mode
      vim.cmd("redraw")

      if state.replace_mode then
        local var_name = alias_text:match("^%s*local%s+([%w_]+)") or alias_text:match("^%s*([%w_]+)%s*=")

        if var_name and vim.fn.exists(":Replace") == 2 then
          local cmd = string.format("Replace %s %s %%", chain, var_name)
          vim.cmd(cmd)
        end
      end
    end)
  end, opts)

  -- Ignore entry
  km_set("n", "<BS>", function()
    if not rendering.is_open() then
      return
    end

    local idx = math.floor((rendering.cursor_index - 2) / 3) + 1
    local item = state.visible[idx]

    if item then
      -- Mark as ignored
      state.ignored[item.chain] = true

      -- Refresh from the source buffer context
      local source_bufnr = state.source_bufnr
      if source_bufnr and api.nvim_buf_is_valid(source_bufnr) then
        vim.schedule(function()
          -- Temporarily switch to source buffer for analysis
          api.nvim_buf_call(source_bufnr, function()
            state.refresh()
          end)
        end)
      else
        vim.notify("Source buffer no longer valid", vim.log.levels.WARN)
        rendering.close()
      end
    end
  end, opts)

  -- Un-ignore all
  km_set("n", "U", function()
    if not rendering.is_open() then
      return
    end

    -- Clear ignore list
    for k in pairs(state.ignored) do
      state.ignored[k] = nil
    end

    -- Refresh from the source buffer context
    local source_bufnr = state.source_bufnr
    if source_bufnr and api.nvim_buf_is_valid(source_bufnr) then
      vim.schedule(function()
        api.nvim_buf_call(source_bufnr, function()
          state.refresh()
        end)
      end)
    else
      vim.notify("Source buffer no longer valid", vim.log.levels.WARN)
      rendering.close()
    end
  end, opts)

  -- Help
  km_set("n", "?", function()
    local help_text = {
      "Recommender Help:",
      "",
      "j/k, ↓/↑  - Navigate",
      "Enter     - Insert alias" .. (state.replace_mode and " + auto-replace" or ""),
      "Backspace - Ignore entry",
      "U         - Un-ignore all",
      "q/Esc     - Close",
    }
    vim.notify(table.concat(help_text, "\n"), vim.log.levels.INFO)
  end, opts)
end

return M
