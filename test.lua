
-- Alle Theme-Dateien prüfen
local theme_path = vim.fn.stdpath("config") .. "/lua/custom/themes/"
for _, file in ipairs(vim.fn.glob(theme_path .. "*.lua", true, true)) do
  for line_num, line in ipairs(vim.fn.readfile(file)) do
    local match = line:match("#[0-9a-fA-F]+")
    if match and #match > 7 then
      print(("Fehler in %s:%d → %s"):format(file, line_num, match))
    end
  end
end
