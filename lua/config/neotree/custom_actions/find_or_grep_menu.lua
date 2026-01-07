---@module 'config.neotree.user_actions.find_or_grep_menu'
--- <M-m> → choose {find_files|live_grep} in a tiny fzf-lua menu, then run on node's directory.

---@class NeoTreeUsrPicker
local M = {}

function M.attach(opts)
  -- Require fzf-lua once; fall back gracefully if missing
  local ok_fzf, fzf = pcall(require, "fzf-lua")

  -- Ensure nested tables exist on opts
  opts.filesystem = opts.filesystem or {}
  opts.filesystem.window = opts.filesystem.window or {}
  opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}

  --- Resolve a directory based on the Neo-tree state.
  --- Files -> parent directory; Directories -> themselves; No node -> current working directory.
  ---@param state Cfg.NeoTree.State
  ---@return string
  local function resolve_dir(state)
    -- Prefer the currently focused node from the state
    local node = state and state.current_node or nil

    -- No node selected: fall back to current working directory
    if not node then
      -- Prefer libuv cwd; fall back to Vim's cwd
      return vim.uv and vim.uv.cwd() or vim.loop.cwd() or vim.fn.getcwd()
    end

    -- Neo-tree nodes expose the path directly
    local path = node.path or node.id or ""
    if path == "" then
      return vim.fn.getcwd()
    end

    -- Files resolve to their parent directory
    if node.type == "file" then
      return vim.fn.fnamemodify(path, ":p:h")
    end

    -- Directories resolve to themselves
    return path
  end

  --- Run a specific fzf-lua action rooted at a given directory.
  ---@param action '"find_files"'|'"live_grep"'
  ---@param dir string
  local function run_fzf(action, dir)
    if not ok_fzf then
      vim.notify("fzf-lua not available", vim.log.levels.ERROR)
      return
    end
    if action == "find_files" then
      -- Use fd under the hood; include hidden files, follow symlinks, skip .git
      fzf.files({
        cwd = dir,
        fd_opts = "--hidden --follow --exclude .git",
      })
    elseif action == "live_grep" then
      -- Use ripgrep; include hidden files, exclude .git via glob
      fzf.live_grep({
        cwd = dir,
        rg_opts = "--hidden --glob !.git",
      })
    else
      vim.notify("Unknown action: " .. tostring(action), vim.log.levels.WARN)
    end
  end

  --- Present a tiny fzf menu to pick the action, with a clean first-column-only list.
  --- Falls back to a confirm dialog when fzf-lua is unavailable.
  ---@param dir string
  local function fzf_menu(dir)
    if not ok_fzf then
      local idx = vim.fn.confirm("fzf-lua action", "&find_files\n&live_grep", 1)
      local choice = (idx == 1 and "find_files") or (idx == 2 and "live_grep") or nil
      if choice then
        run_fzf(choice, dir)
      end
      return
    end

    ---@type string[]
    local lines = {
      "find_files\tBrowse files (fd, hidden, no .git)",
      "live_grep\tSearch text recursively (rg, hidden, no .git)",
    }

    fzf.fzf_exec(lines, {
      -- Prompt and UI
      prompt = "Action> ",
      winopts = {
        width = 0.40,
        height = 0.25,
        row = 0.30,
        col = 0.50,
        title = "Neo-tree → fzf-lua",
        title_pos = "center",
        border = "rounded",
      },
      -- Show only the first tab-separated column
      fzf_opts = {
        ["--delimiter"] = "\t",
        ["--with-nth"] = "1",
        ["--prompt"] = "Action> ",
        ["--no-multi"] = "",
      },
      actions = {
        ---@param selected string[]  -- first item contains "value\tdescription"
        default = function(selected)
          if not selected or not selected[1] then
            return
          end
          local value = selected[1]:match("^[^\t]+")
          run_fzf(value, dir)
        end,
      },
    })
  end

  -- Map Alt-m inside Neo-tree's filesystem window
  opts.filesystem.window.mappings["<M-m>"] = function(state)
    local dir = resolve_dir(state)
    fzf_menu(dir)
  end
end

return M
