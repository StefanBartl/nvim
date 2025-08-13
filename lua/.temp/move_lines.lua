---@module 'mappings.move_lines'
--- Move the current line or the current visual selection up/down with a single mapping.
--- Works in Normal, Visual, and Visual-Line/Block mode. In Visual mode, the selection
--- is preserved after the move. In Normal mode, indentation is fixed automatically.
--- Count is respected in Normal mode (e.g., `3<A-Down>` moves the line down 3 lines).

-- Set a local alias type for direction values to help LuaLS
---@alias MoveDirection '"up"'|'"down"'

--- Move line(s) depending on the current mode.
--- In Visual modes (`v`, `V`, CTRL-V), moves the selected region and restores the selection.
--- In Normal mode, moves the current line and reindents it.
---@param direction MoveDirection  -- "up" or "down"
---@param count? integer           -- optional repeat count (Normal mode only, defaults to v:count1)
local function move_lines(direction, count)
  -- Detect current mode: "n" = normal, "v" = charwise visual, "V" = linewise visual, "\22" = block visual
  local mode = vim.api.nvim_get_mode().mode

  -- Helper to reselect and reindent the moved visual selection
  local function reselection_reindent_visual()
    -- `gv` reselects the last visual selection. `=` reindents. We use Normal mode commands explicitly.
    vim.cmd("normal! gv=gv")
  end

  if mode == "v" or mode == "V" or mode == "\22" then
    -- Visual modes: use '< and '> marks which track the start/end of the visual selection
    if direction == "up" then
      -- Move the whole selection block one line up.
      vim.cmd([[m '<-2]])
    else
      -- Move the whole selection block one line down.
      vim.cmd([[m '>+1]])
    end
    reselection_reindent_visual()
  else
    -- Normal mode: move the current line. Respect a numeric count if provided, else use v:count1.
    local n = tonumber(count) or vim.v.count1
    if direction == "up" then
      -- For moving a single line up, `:m .-2` places the current line above the previous line.
      -- For moving N lines up, use `:m .-(N+1)`.
      local off = n + 1
      vim.cmd(("move .-%d"):format(off))
    else
      -- For moving a single line down, `:m .+1` places the current line below the next line.
      -- For moving N lines down, use `:m .+N`.
      vim.cmd(("move .+%d"):format(n))
    end
    -- Reindent the line after movement to keep formatting consistent.
    vim.cmd("normal! ==")
  end
end

-- Public keymaps:
-- Use a single mapping that works in both Normal and Visual modes.
local map = vim.keymap.set

-- Alt+Up / Alt+Down: move current line or current selection
map({ "n", "v" }, "<A-Up>", function()
  move_lines("up")
end, { desc = "[Text] Move line/selection up", noremap = true, silent = true })

map({ "n", "v" }, "<A-Down>", function()
  move_lines("down")
end, { desc = "[Text] Move line/selection down", noremap = true, silent = true })

-- Optional: Alt+k / Alt+j as ergonomic aliases (uncomment if desired)
-- map({ "n", "v" }, "<A-k>", function() move_lines("up") end,   { desc = "[Text] Move line/selection up", noremap = true, silent = true })
-- map({ "n", "v" }, "<A-j>", function() move_lines("down") end, { desc = "[Text] Move line/selection down", noremap = true, silent = true })

