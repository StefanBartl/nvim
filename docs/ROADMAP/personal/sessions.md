# `sessions.nvim`

[sessions/usercmds.lua](C:/Users/bartl/AppData/Local/nvim/lua/sessions/usercmds.lua:26) nutzt `pcall(vim.cmd("..."))`; dadurch wird `vim.cmd` vor `pcall` ausgeführt. Verbesserung: als Funktion kapseln. Das ist klein, aber tatsächlich fehlerrelevant.

---

