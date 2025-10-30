## Implementierung

```lua
---@module 'custom.markdown.core.column_align'
--- Align visually selected character to target column with fill character.
---@class column_align_module
---@field align_to_column fun(target_col: number, fill_char: string|nil): nil
local M = {}

local api = vim.api

--- Align visually selected character to target column.
--- Replaces all columns between current position and target with fill_char.
---@param target_col number Target column (1-based)
---@param fill_char string|nil Fill character (default: space)
---@return nil
function M.align_to_column(target_col, fill_char)
  fill_char = fill_char or " "

  -- Validate fill_char is single character
  if #fill_char ~= 1 then
    vim.notify("[Custom.Markdown] Column align: Fill character must be exactly one character", vim.log.levels.ERROR)
    return
  end

  -- Get visual selection marks
  local start_pos = api.nvim_buf_get_mark(0, "<")
  local end_pos = api.nvim_buf_get_mark(0, ">")

  -- Ensure single character selection
  if start_pos[1] ~= end_pos[1] then
    vim.notify("[Custom.Markdown] Column align: Selection must be on single line", vim.log.levels.ERROR)
    return
  end

  local line_nr = start_pos[1]
  local start_col = start_pos[2] + 1  -- Convert to 1-based
  local end_col = end_pos[2] + 1      -- Convert to 1-based

  if end_col - start_col > 0 then
    vim.notify("[Custom.Markdown] Column align: Select exactly one character", vim.log.levels.ERROR)
    return
  end

  -- Get current line
  local line = api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1]
  if not line then return end

  -- Get the selected character
  local selected_char = line:sub(start_col, start_col)

  -- Validate target column
  if target_col <= start_col then
    vim.notify("[Custom.Markdown] Column align: Target column must be greater than current position", vim.log.levels.ERROR)
    return
  end

  -- Build new line
  local before = line:sub(1, start_col - 1)
  local after = line:sub(start_col + 1)

  -- Calculate fill length
  local fill_length = target_col - start_col
  local fill = string.rep(fill_char, fill_length)

  -- Construct new line: before + fill + selected_char + after
  local new_line = before .. fill .. selected_char .. after

  -- Set new line
  api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, { new_line })

  -- Move cursor to aligned character position
  api.nvim_win_set_cursor(0, { line_nr, target_col - 1 })
end

--- Interactive alignment: prompt for column and fill character.
---@return nil
function M.align_interactive()
  -- Prompt for target column
  local target_input = vim.fn.input("Target column: ")
  if target_input == "" then return end

  local target_col = tonumber(target_input)
  if not target_col or target_col < 1 then
    vim.notify("[Custom.Markdown] Column align: Invalid column number", vim.log.levels.ERROR)
    return
  end

  -- Prompt for fill character
  local fill_input = vim.fn.input("Fill character (default: space): ")
  local fill_char = (fill_input == "") and " " or fill_input

  M.align_to_column(target_col, fill_char)
end

return M
```

## Integration in keymaps.lua

```lua
-- Column alignment (visual mode) --------------------------------------------
local ok_col, column_align = pcall(require, "custom.markdown.core.column_align")
if ok_col and column_align.align_interactive then
  map("x", "<leader>ma", column_align.align_interactive, "[Custom.Markdown] Align character to column", o)
end
```

## Verwendung

**Interaktiv (empfohlen):**
1. Ein einzelnes Zeichen visuell markieren (z.B. `v` und Cursor nicht bewegen)
2. `<leader>ma` drücken
3. Zielspalte eingeben (z.B. `30`)
4. Füllzeichen eingeben (z.B. `=`, `x`, oder Enter für Leerzeichen)

**Programmatisch:**
```lua
-- Align to column 30 with spaces
require('custom.markdown.core.column_align').align_to_column(30)

-- Align to column 30 with '='
require('custom.markdown.core.column_align').align_to_column(30, '=')

-- Align to column 30 with 'x'
require('custom.markdown.core.column_align').align_to_column(30, 'x')
```

## Beispiele

**Vorher:**
```
Text A
```

Man markiert das `A` visuell, drückt `<leader>ma`, gibt `30` ein und wählt `=` als Füllzeichen.

**Nachher:**
```
Text ============================A
```

**Weitere Beispiele:**

Mit Leerzeichen (Spalte 40):
```
Label:                                  X
```

Mit `-` (Spalte 20):
```
Start--------------X
```

Mit `.` (Spalte 50):
```
Begin..............................................X
```

Die Implementierung validiert:
- Einzelnes Zeichen muss markiert sein
- Zielspalte muss größer als aktuelle Position sein
- Füllzeichen muss genau ein Zeichen sein
- Auswahl muss auf einer Zeile sein

Der Cursor wird nach dem Alignment auf die neue Position des verschobenen Zeichens gesetzt.
