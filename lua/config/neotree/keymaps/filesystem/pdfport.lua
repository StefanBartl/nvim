-- TODO: image preview zuerst checkne, also snacks, images.nviim, ueberzug usw... dann wenn das nicht ist, mit system app

---@module 'config.neotree.keymaps.filesystem.pdfport'
---@brief PDF and image keymaps for the Neo-tree filesystem source.
---@description
--- This module is loaded last in config/neotree/keymaps/filesystem/init.lua
--- so that it wins the <Tab> and <CR> merge slots.
---
--- Handler priority per keypress:
---   1. PDF   -> pdfport quick open  (pdftotext buffer)
---   2. Image -> system default app  (xdg-open / open)
---   3. Other -> standard Neo-tree behaviour (toggle_preview / expand / open)
---
--- Keymaps:
---   <Tab>  -> PDF: pdfport quick  | Image: system app | Other: toggle_preview
---   <CR>   -> PDF: pdfport quick  | Image: system app | Other: expand / open
---   gP     -> pdfport mode picker (always, regardless of node type)

local notify        = require("lib.notify").create("[cfg.neotree.keymaps.fs.pdfport]")
local node_utils    = require("config.neotree.utils.node")
local pdfport_action = require("config.neotree.actions.pdfport")
local img           = require("config.neotree.keymaps.filesystem.images")

--- Returns true when the node under the cursor is a PDF file.
---@param state Cfg.NeoTree.State
---@return boolean
local function current_node_is_pdf(state)
  local node = node_utils.get_current(state)
  if not node then return false end
  local path, _ = node_utils.get_path(node)
  return type(path) == "string" and path:lower():match("%.pdf$") ~= nil
end

--- Returns true when the node under the cursor is an image file.
---@param state Cfg.NeoTree.State
---@return boolean
local function current_node_is_image(state)
  local node = node_utils.get_current(state)
  if not node then return false end
  local path, _ = node_utils.get_path(node)
  return img.is_image_path(path)
end

--- Opens the image at the node under the cursor in the system default app.
---@param state Cfg.NeoTree.State
local function open_image(state)
  local node = node_utils.get_current(state)
  local path, _ = node_utils.get_path(node)
  if type(path) ~= "string" then
    notify.warn("Could not resolve path for image node")
    return
  end
  img.open_in_system_app(path)
end

---@type table<string, any>
return {

  -- <Tab>: PDF -> pdfport quick | Image -> system app | Other -> toggle_preview
  ["<Tab>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      if current_node_is_pdf(state) then
        pdfport_action.open_quick(state)
        return
      end

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
    desc = "PDF: pdfport quick | Image: system app | Other: preview toggle",
  },

  -- <CR>: PDF -> pdfport quick | Image -> system app | Other -> expand / open
  ["<CR>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      if current_node_is_pdf(state) then
        pdfport_action.open_quick(state)
        return
      end

      if current_node_is_image(state) then
        open_image(state)
        return
      end

      -- Fallback: identical to the handler in files.lua.
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
    desc = "PDF: pdfport quick | Image: system app | Other: expand / open",

  },
}
