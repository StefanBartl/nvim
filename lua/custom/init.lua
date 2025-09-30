---@module 'custom'
-- Initialize modules for 'custom'

require("custom.find_config").enable({ usercmds = true, keymaps = true  })
require("custom.pathprobe").enable_keymaps()
require("custom.usr_pickers").enable({}, { usercmds = true, keymaps = true })

require("custom.repo_pickers").enable({
  -- repos_dir = "/home/steve/repos",
  only_git = true,
  selector = "vim_select", -- AUDIT: telescope and fzf should jsut select and than move on
  engine   = "auto",
  show_relative = true,
  usercmd_names = {
    find_files_telescope = "RepoFilesTelescope",
    grep_telescope       = "RepoGrepTelescope",
    find_files_fzf       = "RepoFilesFzf",
    grep_fzf             = "RepoGrepFzf",
  },
  keymaps_lhs = {
    repo_files = nil,
    repo_grep  = nil,
  },
}, { usercmds = true, keymaps = true })

