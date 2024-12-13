local M = {}

-- Pfad zur mappings.lua
local mappings_file = vim.fn.stdpath("config") .. "/lua/custom/mappings.lua"

-- Funktion zum Parsen der mappings.lua und Extrahieren der Tabellenüberschriften
local function parse_mappings()
  local file = io.open(mappings_file, "r")
  if not file then
    vim.notify("Could not open mappings.lua", vim.log.levels.ERROR)
    return {}
  end

  local tables = {}
  for line in file:lines() do
    -- Suche nach Tabellenüberschriften wie `M.general = {`
    local table_name = line:match("^M%.([a-zA-Z0-9_]+)%s*=%s*{")
    if table_name then
      table.insert(tables, table_name)
    end
  end

  file:close()
  return tables
end

-- Funktion zum Extrahieren der Keymaps eines bestimmten Tables
local function get_keymaps(table_name)
  local file = io.open(mappings_file, "r")
  if not file then
    vim.notify("Could not open mappings.lua", vim.log.levels.ERROR)
    return {}
  end

  local keymaps = {}
  local inside_table = false

  for line in file:lines() do
    -- Check if we are entering the requested table
    if line:match("^M%." .. table_name .. "%s*=%s*{") then
      inside_table = true
    elseif inside_table and line:match("^%s*}%s*$") then
      -- Exit the table
      inside_table = false
    elseif inside_table then
      -- Extract keymap entries
      local key, desc = line:match('%["(.-)"%]%s*=%s*{.-},%s*"(.-)"')
      if key and desc then
        table.insert(keymaps, { key = key, description = desc })
      end
    end
  end

  file:close()
  return keymaps
end

-- Funktion zur Anzeige der Auswahl mit fzf oder telescope
function M.select_table()
  local tables = parse_mappings()
  if vim.tbl_isempty(tables) then
    vim.notify("No tables found in mappings.lua", vim.log.levels.WARN)
    return
  end

  vim.ui.select(tables, { prompt = "Select a table:" }, function(choice)
    if choice then
      local keymaps = get_keymaps(choice)
      if vim.tbl_isempty(keymaps) then
        vim.notify("No keymaps found in table " .. choice, vim.log.levels.WARN)
        return
      end

      -- Erstelle einen neuen Buffer und zeige die Keymaps
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

      local lines = { "Keymaps for table: " .. choice, "" }
      for _, map in ipairs(keymaps) do
        table.insert(lines, map.key .. " -> " .. map.description)
      end

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.min(80, vim.o.columns - 4),
        height = math.min(20, vim.o.lines - 4),
        col = math.floor((vim.o.columns - 80) / 2),
        row = math.floor((vim.o.lines - 20) / 2),
        style = "minimal",
        border = "rounded",
      })
    end
  end)
end

-- Mapping für das Plugin
vim.api.nvim_set_keymap(
  "n",
  "<leader>la",
  ":lua require('mappings_plugin').select_table()<CR>",
  { noremap = true, silent = true }
)

return M
