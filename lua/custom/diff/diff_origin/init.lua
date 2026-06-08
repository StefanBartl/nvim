---@module 'custom.diff.diff_origin'
--- Diff the current buffer against its last saved state on disk.
--- This command creates a readonly, non-modifiable snapshot buffer
--- containing the file contents from disk and enables Neovim's native
--- diff mode between the snapshot and the current working buffer.

local M = {}

---@return nil
function M.enable()
  vim.api.nvim_create_user_command("DiffOrig", function()
    vim.cmd([[
      " Open a new vertical split with an empty buffer
      vert new

      " Mark the buffer as not associated with any file on disk
      setlocal buftype=nofile

      " Read the alternate file (#), which represents the last saved
      " version of the current buffer, into this buffer
      read ++edit #

      " Remove the initial empty line created by :new before :read
      0d_

      " Protect the reference buffer from any modifications
      setlocal readonly
      setlocal nomodifiable

      " Enable diff mode for the reference (snapshot) buffer
      diffthis

      " Switch back to the original working buffer
      wincmd p

      " Enable diff mode for the working buffer
      diffthis
    ]])
  end, {
    desc = "[custom.diff_origin] Diff current buffer against last saved version",
  })
end

return M
