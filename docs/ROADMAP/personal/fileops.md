# `fileops.nvim`

1. Wenn man  `:File delete %` auslöst, wird die file gelöscht und der Buffer geschlossen, perfekt. Es wird abber immer auch ein leerer Buffer aufgemacht, selbst wenn andree Buffer existieren - das ist unnötig.
2. `CwdHere` → passt in `fileops.nvim`
  Das Plugin ist explizit "File operations for Neovim — creating, navigating, renaming, duplicating, deleting files." `lcd` auf das Buffer-Verzeichnis zu setzen ist Dateisystem-Navigation — dieselbe Domäne wie `File next`/`File prev`. Es würde sich als `File cd` oder als separater `CwdHere`-Command im Plugin natural anfühlen.

  ```vim
  vim.api.nvim_create_user_command("CwdHere", function()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname ~= "" then
      local dir = vim.fn.fnamemodify(bufname, ":p:h")
      vim.cmd("lcd " .. vim.fn.fnameescape(dir))
    end
  end, {})
  ```

 > Implementiere das Feature in `fileops.nvim`
 > Braucht aber einen Fix: Funktioniert so zwar, aber ein neotree/nvimtree/netrw reload muss ausgelöst werden damit dieser aktualisert das neue cwd in ihm.

---
