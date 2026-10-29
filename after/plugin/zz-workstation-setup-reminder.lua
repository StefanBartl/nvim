-- Loader of the one-off reminder in the config root; remove both from the repo once no machine needs them
-- (`:WorkstationSetupDone` only stops it per machine, see the module header).
local file = vim.fn.stdpath("config") .. "/workstation-setup-reminder.lua"
if vim.uv.fs_stat(file) then
  dofile(file)
end
