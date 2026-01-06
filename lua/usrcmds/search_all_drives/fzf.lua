---@module 'usrcmds.search_all_drives.fzf'
--- fzf-lua command wrapper for usrcmds.search_all_drives.
--- Presents the search tabs as a simple fzf selector.

local search_all_drives = require("usrcmds.search_all_drives")

---@param opts table|nil
local function open(opts)
  opts = opts or {}

  local fzf = require("fzf-lua")
  local builtin = require("telescope.builtin")

  local tabs = search_all_drives.build_tabs(builtin)

  ---@type string[]
  local labels = {}
  for i = 1, #tabs do
    labels[i] = tabs[i].name
  end

  fzf.fzf_exec(labels, {
    prompt = "Search all drives> ",
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then
          return
        end
        for i = 1, #tabs do
          if tabs[i].name == selected[1] then
            tabs[i].tele_func()
            return
          end
        end
      end,
    },
  })
end

return {
  open = open,
}

