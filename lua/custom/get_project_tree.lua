local M = {}

--- Writes the project directory tree to ~/temp/<projectname>-tree.txt
function M.init()
  local fn = vim.fn
  local cwd = fn.getcwd()
  local cwd_name = fn.fnamemodify(cwd, ":t")
  local temp_dir = fn.expand("~/temp/")

  os.execute("mkdir -p " .. vim.fn.shellescape(temp_dir))

  local tree_file = temp_dir .. cwd_name .. "-tree.txt"
  local list_command = "find " .. vim.fn.shellescape(cwd)
      .. " -not -path '*/.git/*' -printf '%P\n' | sort > "
      .. vim.fn.shellescape(tree_file)

  local result = os.execute(list_command)

  if result == 0 then
    vim.notify("Projektstruktur gespeichert in: " .. tree_file, vim.log.levels.INFO)
  else
    vim.notify("Fehler beim Schreiben der Projektstruktur.", vim.log.levels.ERROR)
  end
end

--- Copies the project tree file content to the clipboard using xclip
function M.copy_to_clipboard()
  local fn = vim.fn
  local cwd = fn.getcwd()
  local cwd_name = fn.fnamemodify(cwd, ":t")
  local tree_file = fn.expand("~/temp/" .. cwd_name .. "-tree.txt")

  if fn.filereadable(tree_file) == 0 then
    vim.notify("Keine Projektstrukturdatei gefunden: " .. tree_file, vim.log.levels.ERROR)
    return
  end

  local copy_command = "xclip -selection clipboard < " .. vim.fn.shellescape(tree_file)
  local result = os.execute(copy_command)

  if result == 0 then
    vim.notify("Projektstruktur wurde in die Zwischenablage kopiert.", vim.log.levels.INFO)
  else
    vim.notify("Fehler beim Kopieren in die Zwischenablage.", vim.log.levels.ERROR)
  end
end

--- Counts all files (excluding .git) in the current project directory and shows the result
function M.count_files()
  local cwd = vim.fn.getcwd()
  local count_command = "find " .. vim.fn.shellescape(cwd) .. " -type f -not -path '*/.git/*' | wc -l"
  local handle = io.popen(count_command)
  local result = handle and handle:read("*a")
  if handle then handle:close() end

  if result then
    local count = tonumber(result:match("%d+"))
    if count then
      vim.notify("Anzahl der Dateien im Projekt: " .. count, vim.log.levels.INFO)
    else
      vim.notify("Fehler beim Zählen der Dateien (ungültiges Ergebnis).", vim.log.levels.ERROR)
    end
  else
    vim.notify("Fehler beim Ausführen des Count-Kommandos.", vim.log.levels.ERROR)
  end
end

-- User Commands
vim.api.nvim_create_user_command("ProjectTreeGet", function()
  require("custom.get_project_tree").init()
end, {})

vim.api.nvim_create_user_command("ProjectTreeCopyClipboard", function()
  require("custom.get_project_tree").copy_to_clipboard()
end, {})

vim.api.nvim_create_user_command("ProjectFilesCount", function()
  require("custom.get_project_tree").count_files()
end, {})

return M
