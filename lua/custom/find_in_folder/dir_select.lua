---@module 'custom.find_in_folder.dir_select'
---@brief Interactive directory selection before fuzzy-file search.
---@description
--- Strategy (first available wins):
---   1. **Telescope file_browser** – if loaded, opens it in directory-only mode
---      and returns the chosen path via a one-shot autocmd on `TelescopeClose`.
---      Because Telescope's file_browser does not expose a native "select dir and
---      return path" callback, we use a small state machine: enter a dir with
---      `<CR>`, confirm selection with `<C-y>` (custom mapping injected at
---      runtime).
---   2. **vim.ui.input** – plain fallback that just asks the user to type a path.
---      Supports `~` expansion and tab-completion via `cmdline = "dir"`.

local notify = require("lib.nvim.notify").create("[find_in_folder.dir_select]")

local M = {}

-- ---------------------------------------------------------------------------
-- Telescope file-browser strategy
-- ---------------------------------------------------------------------------

---@param cb fun(path: string|nil)
local function select_via_telescope(cb)
  local ok_tel, telescope = pcall(require, "telescope")
  if not ok_tel then
    return false
  end

  -- Check file_browser extension is registered
  local ext_ok = pcall(function()
    telescope.extensions.file_browser.file_browser()
  end)
  -- We just probed – undo the open by pressing `q` would be wrong,
  -- so instead we open it properly with custom opts below.
  if not ext_ok then
    return false
  end

  -- State shared between the action and the callback
  local confirmed = false

  local action_state_ok, action_state = pcall(require, "telescope.actions.state")
  local actions_ok, tel_actions = pcall(require, "telescope.actions")
  if not (action_state_ok and actions_ok) then
    return false
  end

  -- Build a custom attach_mappings that injects <C-y> as "confirm this dir"
  local function attach_mappings(prompt_bufnr, map)
    local function confirm()
      local entry = action_state.get_selected_entry()
      local path

      if entry then
        -- file_browser entries expose entry.path or entry.value
        path = entry.path or entry.value or entry[1]
        if type(path) == "string" then
          -- If the entry is a file, take its parent
          if vim.fn.isdirectory(path) == 0 then
            path = vim.fn.fnamemodify(path, ":h")
          end
        end
      end

      -- Fall back to the current browser cwd
      if not path or path == "" then
        local picker = action_state.get_current_picker(prompt_bufnr)
        if picker and picker.cwd then
          path = picker.cwd
        end
      end

      confirmed = true
      tel_actions.close(prompt_bufnr)

      vim.schedule(function()
        cb(path)
      end)
    end

    map("i", "<C-y>", confirm)
    map("n", "<C-y>", confirm)
    map("n", "<CR>", confirm)   -- In normal mode CR also confirms
    return true
  end

  -- Actually open file_browser
  local open_ok = pcall(function()
    telescope.extensions.file_browser.file_browser({
      attach_mappings = attach_mappings,
      -- Only show directories for clarity
      files = false,
      dir_icon = "",
      prompt_title = "Select Folder  [<C-y> or <CR> to confirm]",
      hidden = true,
      respect_gitignore = false,
    })
  end)

  if not open_ok then
    return false
  end

  -- Register a cleanup autocmd in case the user closes without confirming
  vim.api.nvim_create_autocmd("WinClosed", {
    once = true,
    callback = function()
      if not confirmed then
        cb(nil)
      end
    end,
  })

  return true
end

-- ---------------------------------------------------------------------------
-- vim.ui.input fallback strategy
-- ---------------------------------------------------------------------------

---@param cb fun(path: string|nil)
local function select_via_input(cb)
  vim.ui.input({
    prompt = "Folder to search in (. = cwd): ",
    default = ".",
    completion = "dir",
  }, function(input)
    if not input or input == "" then
      cb(nil)
      return
    end
    -- Expand ~ and environment variables
    local expanded = vim.fn.expand(input)
    cb(expanded)
  end)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Select a directory interactively, then call cb with the chosen path or nil.
---@param _picker FindInFolder.Picker  Preferred picker (used to prefer matching UI)
---@param cb      fun(path: string|nil)
function M.select(_picker, cb)
  if type(cb) ~= "function" then
    notify.error("dir_select.select: cb must be a function")
    return
  end

  -- Try Telescope file_browser first (richest UX)
  local used_telescope = select_via_telescope(cb)
  if used_telescope then
    return
  end

  -- Fallback: plain input
  select_via_input(cb)
end

return M
