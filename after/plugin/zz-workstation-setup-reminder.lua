-- Loader of the one-off reminder in the config root; deleted together with it (see :WorkstationSetupDone).
local file = vim.fn.stdpath("config") .. "/workstation-setup-reminder.lua"
if vim.uv.fs_stat(file) then
  dofile(file)
end
