---@module 'config.neotree.usr_picker'
--- Alt-m → choose {find_files|live_grep} in a tiny fzf-lua menu, then run on node's directory.

---@class NeoTreeUsrPicker
local M = {}

function M.attach(opts)
  local ok_fzf, fzf = pcall(require, "fzf-lua")

  opts.filesystem = opts.filesystem or {}
  opts.filesystem.window = opts.filesystem.window or {}
  opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}

  --- Resolve directory from current node; file → parent dir; dir → itself; fallback → cwd.
  --- @param state table
  --- @return string
  local function resolve_dir(state)
    local node = state and state.tree and state.tree:get_node() or nil
    if not node then
      return vim.loop.cwd() or vim.fn.getcwd()
    end
    local path = node:get_id()
    if node.type == "file" then
      return vim.fn.fnamemodify(path, ":p:h")
    end
    return path
  end

  --- Run fzf-lua action with cwd=dir.
  --- @param action '"find_files"'|'"live_grep"'
  --- @param dir string
  local function run_fzf(action, dir)
    if not ok_fzf then
      vim.notify("fzf-lua not available", vim.log.levels.ERROR)
      return
    end
    if action == "find_files" then
      fzf.files({
        cwd = dir,
        fd_opts = "--hidden --follow --exclude .git",
      })
    elseif action == "live_grep" then
      fzf.live_grep({
        cwd = dir,
        rg_opts = "--hidden --glob !.git",
      })
    end
  end

  --- Show a tiny fzf menu instead of vim.ui.select. Uses tab delimiter for neat columns.
  --- @param dir string
  local function fzf_menu(dir)
    if not ok_fzf then
      -- Fallback: simple confirm dialog
      local idx = vim.fn.confirm("fzf-lua action", "&find_files\n&live_grep", 1)
      local choice = (idx == 1 and "find_files") or (idx == 2 and "live_grep") or nil
      if choice then run_fzf(choice, dir) end
      return
    end

    -- Each line: "<value>\t<description>"
    ---@type string[]
    local lines = {
      "find_files\tBrowse files (fd, hidden, no .git)",
      "live_grep\tSearch text recursively (rg, hidden, no .git)",
    }

    fzf.fzf_exec(lines, {
      prompt = "Action> ",
      -- Hide the description in the final value; show only the first column in list
      fzf_opts = {
        ["--delimiter"] = "\t",
        ["--with-nth"] = "1",
        ["--prompt"] = "Action> ",
        ["--no-multi"] = "",
      },
      winopts = {
        width = 0.40,   -- tune as desired
        height = 0.25,
        row = 0.30,
        col = 0.50,
        title = "Neo-tree → fzf-lua",
        title_pos = "center",
        border = "rounded",
      },
      actions = {
        ---@param selected string[]  -- first item contains "value\tdescription"
        default = function(selected)
          if not selected or not selected[1] then return end
          local value = selected[1]:match("^[^\t]+") -- extract before the first tab
          run_fzf(value, dir)
        end,
      },
    })
  end

  opts.filesystem.window.mappings["<leader>P"] = function(state)
    local dir = resolve_dir(state)
    fzf_menu(dir)
  end
end

return M
