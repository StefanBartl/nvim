--@module 'mynotes.checklists'

local M = {}

-- Configuration: change title or dir if needed.
local CFG = {
  -- Picker title shown in the UI.
  title = "Checklists",
  -- Directory to search. "~" will be expanded. Keep Linux/macOS style.
  dir = vim.fn.expand(vim.env.REPOS_DIR .. "/Notes/MyNotes/Checklists"),
  notify = true,
}

-- Internal helpers -----------------------------------------------------------

--- Cheap notifier with level.
---@param msg string
---@param level integer
local function note(msg, level)
  if CFG.notify ~= false then
    vim.notify("[Checklists " .. msg, level)
  end
end

--- Normalize directory and ensure it exists.
---@nodiscard
---@param path string
---@return string|nil norm
local function norm_dir(path)
  local p = vim.fn.expand(path)
  local st = vim.loop.fs_stat(p)
  if not st or st.type ~= "directory" then
    note(("Directory does not exist: %s"):format(p), vim.log.levels.ERROR)
    return nil
  end
  return p
end

---@nodiscard
---@return string|nil cwd
local function cwd_or_nil()
  return norm_dir(CFG.dir)
end

--- Check presence of ripgrep; warn if missing (both engines rely on it).
local function assert_rg()
  if vim.fn.executable("rg") ~= 1 then
    note("ripgrep (rg) not found in PATH; live grep will not work.", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- fzf-lua adapter ------------------------------------------------------------

---@nodiscard
---@return boolean ok, table|nil mod
local function try_fzf()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    note("fzf-lua is not available (require failed).", vim.log.levels.WARN)
    return false, nil
  end
  return true, fzf
end

--- fzf-lua: find files with preview, fixed cwd and custom prompt.
function M.fzf_files()
  local cwd = cwd_or_nil()
  if not cwd then
    return
  end
  local ok, fzf = try_fzf()
  if not ok or not fzf then
    return
  end
  -- Preview is on by default in fzf-lua; prompt config via `prompt`.
  fzf.files({
    cwd = cwd,
    prompt = CFG.title .. " > ",
  })
end

--- fzf-lua: live grep with preview.
--- Note: `live_grep_glob` is deprecated; use `live_grep` (glob parsing enabled by default).
function M.fzf_grep()
  if not assert_rg() then
    return
  end
  local cwd = cwd_or_nil()
  if not cwd then
    return
  end
  local ok, fzf = try_fzf()
  if not ok or not fzf then
    return
  end
  fzf.live_grep({
    cwd = cwd,
    prompt = CFG.title .. " > ",
    -- Optional hints:
    -- file_ignore_patterns = { "node_modules", "%.git/", "build/" },
    -- rg_opts = "--hidden --glob '!.git' --line-number --column --smart-case",
  })
end

-- Telescope adapter ----------------------------------------------------------

---@nodiscard
---@return boolean ok, table|nil builtin
local function try_telescope()
  local ok, tb = pcall(require, "telescope.builtin")
  if not ok then
    note("telescope.builtin is not available (require failed).", vim.log.levels.WARN)
    return false, nil
  end
  return true, tb
end

--- Telescope: find files with preview, fixed cwd and title.
function M.tel_files()
  local cwd = cwd_or_nil()
  if not cwd then
    return
  end
  local ok, tb = try_telescope()
  if not ok or not tb then
    return
  end
  tb.find_files({
    cwd = cwd,
    prompt_title = CFG.title,
    previewer = true,
    hidden = true, -- also show dotfiles
  })
end

--- Telescope: live grep with preview, fixed cwd and title.
function M.tel_grep()
  if not assert_rg() then
    return
  end
  local cwd = cwd_or_nil()
  if not cwd then
    return
  end
  local ok, tb = try_telescope()
  if not ok or not tb then
    return
  end
  tb.live_grep({
    cwd = cwd,
    prompt_title = CFG.title,
    previewer = true,
  })
end

-- User commands --------------------------------------------------------------

pcall(vim.api.nvim_create_user_command, "ChecklistsFiles", function()
  M.fzf_files()
end, { desc = "Checklists (fzf-lua): Find files with preview in configured directory" })

pcall(vim.api.nvim_create_user_command, "ChecklistsGrep", function()
  M.fzf_grep()
end, { desc = "Checklists (fzf-lua): Live grep with preview in configured directory" })

-- pcall(vim.api.nvim_create_user_command, "MyNvimTelFiles", function()
--   M.tel_files()
-- end, { desc = "WKD Neovim (Telescope): Find files with preview in configured directory" })
--
-- pcall(vim.api.nvim_create_user_command, "MyNvimTelGrep", function()
--   M.tel_grep()
-- end, { desc = "WKD Neovim (Telescope): Live grep with preview in configured directory" })

-- Keymaps (normal mode) ------------------------------------------------------

-- In case of reloads, vim.keymap.set will replace mappings with the same lhs/buffer.
vim.keymap.set("n", "<leader>chf", M.fzf_files, { desc = "Checklists: fzf files" })
vim.keymap.set("n", "<leader>chg", M.fzf_grep, { desc = "Checklists: fzf grep" })
-- vim.keymap.set("n", "<leader>tf", M.tel_files, { desc = "WKD Neovim: telescope files" })
-- vim.keymap.set("n", "<leader>tg", M.tel_grep, { desc = "WKD Neovim: telescope grep" })

return M
