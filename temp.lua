-- Default nvim notify benutzung (Treffer)
vim.notify("Some notify", vim.log.levels.DEBUG)
vim.notify(
    "Some notify"
    ,
    vim.log.levels.WARN
)
local notify = vim.notify
notify("Some notify", vim.log.levels.INFO)
local levels = vim.log.levels
notify("Some notify", levels.ERROR)


-- benutzung der custom lib.notify modul (Ziel)
local notify = require("lib.notify")
notify.info("Refactor started")
notify.warn("Some paths could not be updated")
notify.error("LSP rename failed")
