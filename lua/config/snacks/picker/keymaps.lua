---@module 'config.snacks.picker.keymaps'
---@brief Keymaps configuration for snacks picker
---@description
--- Provides custom keymaps for snacks.nvim picker:
--- - <C-a>: Create file/folder
--- - <S-CR>, <C-o>: Open in background
--- - <PageUp>, <PageDown>: Preview vertical scroll
--- - <C-Left>, <C-Right>: Preview horizontal scroll
--- - <C-p>, <C-n>: History navigation (if available)

local M = {}

---Get keymaps for input window
---@param has_history boolean Whether history is available
---@return table keymaps
function M.get_input_keys(has_history)
  local keys = {
    -- File creation
    ["<M-a>"] = { "create_file", mode = { "i", "n" } },

    -- Open in background
    ["<S-CR>"] = { "open_background", mode = { "i", "n" } },
    ["<C-o>"] = { "open_background", mode = { "i", "n" } },

    -- Preview scrolling (vertical)
    ["<PageDown>"] = { "preview_scroll_down", mode = { "i", "n" } },
    ["<PageUp>"] = { "preview_scroll_up", mode = { "i", "n" } },

    -- Preview scrolling (horizontal)
    ["<C-Right>"] = { "preview_scroll_right", mode = { "i", "n" } },
    ["<C-Left>"] = { "preview_scroll_left", mode = { "i", "n" } },
  }

  -- Add history navigation if available
  if has_history then
    keys["<C-p>"] = { "history_back", mode = { "i" } }
    keys["<C-n>"] = { "history_forward", mode = { "i" } }
  end

  return keys
end

---Get keymaps for list window
---@return table keymaps
function M.get_list_keys()
  return {
    -- File creation
    ["<C-a>"] = "create_file",

    -- Open in background
    ["<S-CR>"] = "open_background",
    ["<C-o>"] = "open_background",

    -- Preview scrolling (vertical)
    ["<PageDown>"] = "preview_scroll_down",
    ["<PageUp>"] = "preview_scroll_up",

    -- Preview scrolling (horizontal)
    ["<C-Right>"] = "preview_scroll_right",
    ["<C-Left>"] = "preview_scroll_left",
  }
end

---Get keymaps for preview window
---@return table keymaps
function M.get_preview_keys()
  return {
    -- Preview scrolling
    ["<PageDown>"] = "preview_scroll_down",
    ["<PageUp>"] = "preview_scroll_up",
    ["<C-Right>"] = "preview_scroll_right",
    ["<C-Left>"] = "preview_scroll_left",
  }
end

return M
