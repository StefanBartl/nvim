---@module 'mappings.nvchad'

local M = {}

-- Function to toggle comments with annotation support
local function toggle_comment_with_annotations()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  -- Ist es KEINE Annotation? -> Normales gcc
  if not line:match("^%s*%-%-%-") and not line:match("^%s*%-%-%s+%-%-%-") then
    -- Einfach das normale gcc Mapping aufrufen
    local keys = vim.api.nvim_replace_termcodes("gcc", true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)
    return
  end

  -- Es IST eine Annotation -> Toggle Annotation
  local new_line
  if line:match("^%s*%-%-%s+%-%-%-") then
    -- Auskommentiert -> Normal: "-- ---@module" -> "---@module"
    new_line = line:gsub("^(%s*)%-%-%s+(%-%-%-)", "%1%2")
  else
    -- Normal -> Auskommentiert: "---@module" -> "-- ---@module"
    new_line = line:gsub("^(%s*)(%-%-%-)", "%1-- %2")
  end

  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
end

-- Visual mode version
local function toggle_comment_visual()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  -- Prüfen ob irgendeine Zeile eine Annotation ist
  local has_any_annotation = false
  for i = start_line, end_line do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    if line:match("^%s*%-%-%-") or line:match("^%s*%-%-%s+%-%-%-") then
      has_any_annotation = true
      break
    end
  end

  -- KEINE Annotationen? -> Normales gc
  if not has_any_annotation then
    local keys = vim.api.nvim_replace_termcodes("gc", true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)
    return
  end

  -- ES GIBT Annotationen -> Toggle alle
  for i = start_line, end_line do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    local new_line

    if line:match("^%s*%-%-%s+%-%-%-") then
      -- Auskommentiert -> Normal
      new_line = line:gsub("^(%s*)%-%-%s+(%-%-%-)", "%1%2")
    elseif line:match("^%s*%-%-%-") then
      -- Normal -> Auskommentiert
      new_line = line:gsub("^(%s*)(%-%-%-)", "%1-- %2")
    else
      new_line = line
    end

    if new_line ~= line then
      vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
    end
  end
end

function M.setup()
  local map = vim.g.__map_helper

  -- General
  map("n", "<Esc>", function()
    local ok, nes = pcall(require, "copilot-lsp.nes")
    if ok and nes and nes.clear then
      local cleared = nes.clear()
      if not cleared then
        vim.cmd("noh")
      end
    else
      vim.cmd("noh")
    end
  end, { desc = "Clear copilot NES overlays or nohl" })
  map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "[General] Copy whole file" })
  map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "[General] NvCheatsheet" })

  -- Format via Conform (fallback handled in LSP attach)
  map({ "n", "x" }, "<leader>fm", function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ lsp_fallback = true })
    end
  end, { desc = "[General] Format file" })

  -- Which-key
  map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "[General] WhichKey (all)" })
  map("n", "<leader>wk", function()
    vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
  end, { desc = "[General] WhichKey query" })

  -- Insert-mode cursor moves
  map("i", "<C-h>", "<Left>", { desc = "[Text] Left" })
  map("i", "<C-l>", "<Right>", { desc = "[Text] Right" })
  map("i", "<C-j>", "<Down>", { desc = "[Text] Down" })
  map("i", "<C-k>", "<Up>", { desc = "[Text] Up" })

  -- Comment.nvim
  map("n", "<leader>/", toggle_comment_with_annotations, { desc = "[Text] Toggle comment" })
  map("v", "<leader>/", toggle_comment_visual, { desc = "[Text] Toggle comment" })
end

return M
