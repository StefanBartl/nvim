
-- TODO: Vereinen von preview;images;pdfprot

---@module 'config.neotree.keymaps.filesystem.images'
---@brief Image recognition, system-opener utilities, and Neo-tree keymaps.
---@description
--- Handles <Tab> and <CR> for image nodes by opening them in the platform
--- default application (xdg-open on Linux, open on macOS).
--- Non-image nodes fall through to the standard toggle_preview / open behaviour.
--- PDF nodes are handled by pdfport.lua which wins the merge via init.lua load order.
---
--- Exports is_image_path() and open_in_system_app() for use by pdfport.lua.
---
--- Supported extensions (case-insensitive):
---   png, jpg, jpeg, gif, bmp, tiff, tif, webp, svg, ico, avif, heic, heif
---
--- TODO: check for in-terminal image preview backends first (snacks, image.nvim,
---       ueberzug++) and fall back to the system app only when none is available.

local notify     = require("lib.nvim.notify").create("[cfg.neotree.keymaps.fs.images]")
local node_utils = require("config.neotree.utils.node")

-- ---------------------------------------------------------------------------
-- Image detection
-- ---------------------------------------------------------------------------

--- Lookup table used as a set for O(1) extension membership tests.
---@type table<string, true>
local IMAGE_EXTS = {
  png  = true, jpg  = true, jpeg = true, gif  = true,
  bmp  = true, tiff = true, tif  = true, webp = true,
  svg  = true, ico  = true, avif = true, heic = true,
  heif = true,
}

--- Returns true when `path` has a file extension recognised as an image.
--- Exported so that pdfport.lua can reuse the check without duplicating it.
---@param path string
---@return boolean
local function is_image_path(path)
  if type(path) ~= "string" then return false end
  local ext = path:match("%.([^%.]+)$")
  return ext ~= nil and IMAGE_EXTS[ext:lower()] == true
end

--- Returns true when the node under the cursor is an image file.
---@param state Cfg.NeoTree.State
---@return boolean
local function current_node_is_image(state)
  local node = node_utils.get_current(state)
  if not node then return false end
  local path, _ = node_utils.get_path(node)
  return is_image_path(path)
end

-- ---------------------------------------------------------------------------
-- System opener
-- ---------------------------------------------------------------------------

--- Resolves the correct opener command and arguments for the current platform.
--- Uses the system.env cache that is computed once at Neovim startup.
---
--- Platform mapping:
---   Windows (native) -> { "cmd.exe", "/c", "start", "", path }
---   WSL              -> wslview if available, else cmd.exe /c start via wsl.exe
---   macOS            -> { "open", path }
---   Linux            -> { "xdg-open", path }
---
---@param path string  Absolute filesystem path to open.
---@return string[]    Argument vector suitable for vim.system / vim.fn.jobstart.
local function build_open_argv(path)
  local env = require("system.env").get()

  if env.is_windows then
    -- "start" is a cmd built-in; the empty string is the window title,
    -- required when the path may contain spaces.
    return { "cmd.exe", "/c", "start", "", path }
  end

  if env.is_wsl then
    -- wslview (from the wslu package) is the idiomatic WSL opener and handles
    -- Windows paths as well as Linux paths transparently.
    if vim.fn.executable("wslview") == 1 then
      return { "wslview", path }
    end
    -- Fallback: invoke the Windows start command through wsl.exe interop.
    -- Convert the Linux path to a Windows path first so explorer understands it.
    local win_path = vim.fn.system({ "wslpath", "-w", path }):gsub("%s+$", "")
    return { "cmd.exe", "/c", "start", "", win_path }
  end

  if env.is_macos then
    return { "open", path }
  end

  -- Plain Linux.
  return { "xdg-open", path }
end

--- Spawns the system default application for `path` in a detached subprocess.
--- Exported for reuse by pdfport.lua.
--- Falls back to vim.fn.jobstart on Neovim < 0.10 where vim.system is absent.
---@param path string  Absolute filesystem path to open.
local function open_in_system_app(path)
  local argv = build_open_argv(path)
  if vim.system then
    vim.system(argv, { detach = true })
  else
    vim.fn.jobstart(argv, { detach = true })
  end
end

--- Resolves the path of the node under the cursor and opens it in the system
--- default application. Emits a warning when the path cannot be resolved.
---@param state Cfg.NeoTree.State
local function open_image(state)
  local node = node_utils.get_current(state)
  local path, _ = node_utils.get_path(node)
  if type(path) ~= "string" then
    notify.warn("Could not resolve path for image node")
    return
  end
  open_in_system_app(path)
end

-- ---------------------------------------------------------------------------
-- Keymaps
-- ---------------------------------------------------------------------------

---@type table<string, any>
local M = {

  -- <Tab>: image -> system app | other -> toggle_preview (preview.lua)
  ["<Tab>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      if current_node_is_image(state) then
        open_image(state)
        return
      end

      -- Fallback: identical to the handler in preview.lua.
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype ~= "neo-tree" then return end

      if not pcall(state.commands.toggle_preview, state) then
        local ok, preview = pcall(require, "neo-tree.sources.common.preview")
        if ok and preview.hide then preview.hide() end
      end
    end,
    desc = "Image: open in system app | Other: preview toggle",
  },

  -- <CR>: image -> system app | other -> expand / open (files.lua)
  ["<CR>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      if current_node_is_image(state) then
        open_image(state)
        return
      end

      -- Fallback: identical to the <CR> handler in files.lua.
      local node = node_utils.get_current(state)
      if not node then
        notify.info("No node under cursor")
        return
      end

      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype ~= "neo-tree" then
        notify.warn("Not in a Neo-tree window")
        return
      end

      local utils_ok, utils = pcall(require, "config.neotree.utils")
      if utils_ok and utils.safe_hide_preview then
        utils.safe_hide_preview()
      end

      if node.type == "directory" or (node.has_children and not node.is_expanded) then
        state.commands.toggle_node(state)
        return
      end

      if pcall(require, "window-picker") then
        if not pcall(state.commands.open_with_window_picker, state) then
          pcall(state.commands.open, state)
        end
      else
        pcall(state.commands.open, state)
      end
    end,
    desc = "Image: open in system app | Other: expand / open",
  },
}

-- Export helpers for pdfport.lua so it can reuse detection and opener
-- without duplicating the extension list or the platform check.
M.is_image_path      = is_image_path
M.open_in_system_app = open_in_system_app

return M
