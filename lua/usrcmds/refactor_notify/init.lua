-- usrcmds/refactor_notify/init.lua
local M = {}

-- Refactored eine einzelne Zeile (einzeiliges Pattern)
local function refactor_single_line(line)
  -- Pattern: finde (vim.)notify( ... , vim.log.levels.LEVEL )
  -- Verwende greedy match bis zum letzten ", vim.log.levels"
  local refactored, count = line:gsub(
    "^(%s*)(vim%.)?notify%s*%((.-),%s*vim%.log%.levels%.(%u+)%s*%)(.*)$",
    function(indent, vim_prefix, content, level, rest)
      -- Entferne führende/folgende Whitespaces vom Content
      content = content:match("^%s*(.-)%s*$")
      return indent .. "notify." .. level:lower() .. "(" .. content .. ")" .. rest
    end
  )

  if count > 0 then
    return refactored
  end
  return nil
end

-- Refactored mehrzeilige notify-Aufrufe
local function refactor_multiline(lines)
  -- Kombiniere die Zeilen
  local combined = table.concat(lines, "\n")

  -- Extrahiere Einrückung von der ersten Zeile
  local indent = lines[1]:match("^(%s*)")

  -- Pattern für mehrzeilige notify
  -- Erlaube Newlines und beliebige Whitespaces
  local full_pattern = combined:gsub("%s+", " ")
  local vim_prefix, content, level = full_pattern:match("^%s*(vim%.)?notify%s*%((.-),%s*vim%.log%.levels%.(%u+)%s*%)%s*$")

  if content and level then
    -- Entferne führende/folgende Whitespaces
    content = content:match("^%s*(.-)%s*$")
    -- Erstelle die refactored Version
    local refactored = indent .. "notify." .. level:lower() .. "(" .. content .. ")"
    return {refactored}
  end

  return nil
end

-- Finde das Ende eines mehrzeiligen notify-Aufrufs
local function find_notify_end(lines, start_idx)
  local paren_count = 0
  local start_line = lines[start_idx]

  -- Zähle Klammern in der ersten Zeile
  for char in start_line:gmatch(".") do
    if char == "(" then
      paren_count = paren_count + 1
    elseif char == ")" then
      paren_count = paren_count - 1
      if paren_count == 0 then
        return start_idx  -- Einzeilig, endet in derselben Zeile
      end
    end
  end

  -- Suche in den folgenden Zeilen
  for i = start_idx + 1, #lines do
    local line = lines[i]
    for char in line:gmatch(".") do
      if char == "(" then
        paren_count = paren_count + 1
      elseif char == ")" then
        paren_count = paren_count - 1
        if paren_count == 0 then
          return i
        end
      end
    end
  end

  return nil
end

-- Prüfe ob eine Zeile ein notify-Aufruf ist (Start oder komplett)
local function is_notify_line(line)
  return line:match("%f[%w_](vim%.)?notify%s*%(") ~= nil
end

-- Refactored die aktuelle Zeile oder markierten Bereich
local function refactor_current_line_or_selection()
  local mode = vim.api.nvim_get_mode().mode
  local start_line, end_line

  if mode == "v" or mode == "V" then
    -- Visual Mode: Hole markierten Bereich
    start_line = vim.fn.line("v")
    end_line = vim.fn.line(".")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    -- Verlasse Visual Mode
    vim.cmd('normal! ')
  else
    -- Normal Mode: Nur aktuelle Zeile
    start_line = vim.api.nvim_win_get_cursor(0)[1]
    end_line = start_line
  end

  -- Hole die Zeilen (0-indexed für API)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  -- Versuche zuerst einzeiliges Pattern
  if #lines == 1 then
    local refactored = refactor_single_line(lines[1])
    if refactored then
      vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, {refactored})
      vim.notify("Zeile " .. start_line .. " wurde refactored", vim.log.levels.INFO)
      return
    end
  end

  -- Versuche mehrzeiliges Pattern
  local refactored = refactor_multiline(lines)
  if refactored then
    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, refactored)
    vim.notify(string.format("Zeilen %d-%d wurden refactored", start_line, end_line), vim.log.levels.INFO)
  else
    vim.notify("Kein vim.notify Pattern gefunden", vim.log.levels.WARN)
  end
end

-- Refactored alle Zeilen im Buffer
local function refactor_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local count = 0
  local new_lines = {}
  local i = 1

  while i <= #lines do
    local line = lines[i]

    -- Prüfe ob diese Zeile ein notify enthält
    if is_notify_line(line) then
      -- Finde das Ende des notify-Aufrufs
      local end_idx = find_notify_end(lines, i)

      if end_idx then
        if end_idx == i then
          -- Einzeilig
          local refactored = refactor_single_line(line)
          if refactored then
            table.insert(new_lines, refactored)
            count = count + 1
          else
            table.insert(new_lines, line)
          end
        else
          -- Mehrzeilig
          local notify_lines = {}
          for j = i, end_idx do
            table.insert(notify_lines, lines[j])
          end

          local refactored_multi = refactor_multiline(notify_lines)
          if refactored_multi then
            for _, refactored_line in ipairs(refactored_multi) do
              table.insert(new_lines, refactored_line)
            end
            count = count + 1
          else
            -- Konnte nicht refactored werden, behalte Original
            for j = i, end_idx do
              table.insert(new_lines, lines[j])
            end
          end
          i = end_idx
        end
      else
        table.insert(new_lines, line)
      end
    else
      table.insert(new_lines, line)
    end

    i = i + 1
  end

  if count > 0 then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
    vim.notify(string.format("%d notify-Aufruf(e) wurden refactored", count), vim.log.levels.INFO)
  else
    vim.notify("Keine vim.notify Patterns im Buffer gefunden", vim.log.levels.WARN)
  end
end

-- Setup Funktion - registriert das User Command
function M.setup()
  vim.api.nvim_create_user_command("RefactorNotify", function(opts)
    if opts.args == "%" then
      refactor_buffer()
    else
      refactor_current_line_or_selection()
    end
  end, {
    nargs = "?",
    range = true,
    desc = "Refactored vim.notify zu notify.level Syntax"
  })
end

return M
