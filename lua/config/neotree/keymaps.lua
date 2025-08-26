---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.
--- Split into:
---   1) Window mappings (Neo-tree-only, require `state`)
---   2) Source-specific mappings (filesystem/buffers/git/document_symbols)
---   3) Extra buffer-local bindings applied on `NeoTreeBufferEnter` (e.g. <C-o>)
---
--- All mappings are applied only to the Neo-tree buffer and defined late,
--- ensuring they take precedence over plugin defaults.

---@class NeoTreeKeymaps
---@field window fun(): table<string, any>                 -- window.mappings
---@field filesystem fun(): table<string, any>             -- filesystem.window.mappings
---@field buffers fun(): table<string, any>                -- buffers.window.mappings
---@field git_status fun(): table<string, any>             -- git_status.window.mappings
---@field document_symbols fun(): table<string, any>       -- document_symbols.window.mappings
---@field setup_autocmds fun()                             -- extra buffer-local maps (reveal root/cwd)

local M = {}

-- Optional helpers
local uv = vim.uv or vim.loop

---@return string
local function cwd()
  return uv.cwd() or vim.fn.getcwd()
end

local function hide_preview_safe(_)
  pcall(function()
    require("neo-tree.sources.common.preview").hide()
  end)
end

function M.window()
  return {
    -- basic
    ["q"] = "close_window",
    ["?"] = "noop",
    ["g?"] = "show_help",
    ["<leader>"] = "noop",

    -- clear filter, preview and search highlight
    ["<Esc>"] = function(state)
      require("neo-tree.sources.filesystem").reset_search(state, true)
      require("neo-tree.sources.filesystem.lib.filter_external").cancel()
      hide_preview_safe(state)
      vim.cmd "nohlsearch"
    end,

    -- open/close (safe variants)
    ["<2-LeftMouse>"] = "open",

    ["<CR>"] = function(state)
      local node = state.tree:get_node()
      if node and (node.type == "directory" or (node:has_children() and not node:is_expanded())) then
        state.commands.toggle_node(state)
        return
      end
      hide_preview_safe(state)
      if pcall(require, "window-picker") then
        state.commands.open_with_window_picker(state)
      else
        state.commands.open(state)
      end
    end,

    ["SV"] = function(state)
      hide_preview_safe(state)
      if pcall(require, "window-picker") then
        state.commands.split_with_window_picker(state)
      else
        state.commands.open_split(state)
      end
    end,

    ["SG"] = function(state)
      hide_preview_safe(state)
      if pcall(require, "window-picker") then
        state.commands.vsplit_with_window_picker(state)
      else
        state.commands.open_vsplit(state)
      end
    end,

    ["l"] = function(state)
      local node = state.tree:get_node()
      if node.type == "directory" or (node:has_children() and not node:is_expanded()) then
        state.commands.toggle_node(state)
      else
        state.commands.open(state)
      end
    end,
    ["h"] = "close_node",
    ["C"] = "close_node",
    ["z"] = "close_all_nodes",
    ["<C-r>"] = "refresh",

    -- splits/tabs
    ["s"] = "noop",
    ["sv"] = "open_split",
    ["sg"] = "open_vsplit",
    ["st"] = "open_tabnew",

    -- source switching
    ["<S-Tab>"] = "prev_source",
    -- ["<Tab>"] = "next_source", -- intentionally not used here, reserved for preview

    -- file ops via neo-tree clipboard
    ["c"] = "copy_to_clipboard",
    ["x"] = "cut_to_clipboard",
    ["p"] = "paste_from_clipboard",
    ["r"] = "rename",

    -- create/delete
    ["dd"] = "delete",
    ["a"] = { "add", nowait = true, config = { show_path = "relative" } },
    ["N"] = { "add_directory", config = { show_path = "relative" } },
    -- ["m"] = { "move", config = { show_path = "relative" } },

    -- preview: Tab toggles floating preview, K once
    ["<Tab>"] = { "toggle_preview", config = { use_float = true } },
    ["K"] = { "preview", config = { use_float = true } },

    -- helpers: copy paths to system clipboard
    ["[p"] = {
      function(state)
        local node = state.tree:get_node()
        local path = node and (node.path or node:get_id()) or ""
        if path == "" then
          vim.notify("no path", vim.log.levels.WARN)
          return
        end
        vim.fn.setreg("+", path, "c")
        vim.notify(("copied: %s"):format(path), vim.log.levels.INFO)
      end,
      desc = "Copy absolute path (+)",
    },

    ["]p"] = {
      function(state)
        local node = state.tree:get_node()
        local path = node and (node.path or node:get_id()) or ""
        if path == "" then
          vim.notify("no path", vim.log.levels.WARN)
          return
        end
        local base = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
        vim.fn.setreg("+", base, "c")
        vim.notify(("copied: %s"):format(base), vim.log.levels.INFO)
      end,
      desc = "Copy base (dir) path (+)",
    },

    -- resize helper
    ["w"] = function(state)
      local normal = state.window.width
      local large = normal * 1.9
      local small = math.floor(normal / 1.6)
      local cur_width = state.win_width
      local new_width = normal
      if cur_width > normal then
        new_width = small
      elseif cur_width == normal then
        new_width = large
      end
      vim.cmd(new_width .. " wincmd |")
    end,

    ["Y"] = {
      function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        vim.fn.setreg("+", path, "c")
      end,
      desc = "Copy Path to Clipboard",
    },

    ["O"] = {
      function(state)
        require("lazy.util").open(state.tree:get_node().path, { system = true })
      end,
      desc = "Open with System Application",
    },

    ["M"] = {
      function(state)
        local is_wsl = require "lib.is_wsl"

        local mod
        if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 or is_wsl() then
          -- Windows nativ oder WSL → Explorer
          mod = "config.neotree.open_fm.win"
        else
          -- macOS oder echtes Linux → Unix-Modul
          mod = "config.neotree.open_fm.unix"
        end

        local ok, fm = pcall(require, mod)
        if not ok then
          vim.notify("open_fm module not found: " .. mod, vim.log.levels.ERROR)
          return
        end
        fm.open(state)
      end,
      desc = "Open in system file manager",
    },

    ["+"] = {
      function(state)
        local node = state.tree:get_node()
        local path = node and (node.path or node:get_id()) or ""
        if path == "" then
          vim.notify("no path under cursor", vim.log.levels.WARN)
          return
        end
        local dir = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
        local ok, err = pcall(vim.api.nvim_set_current_dir, dir)
        if not ok then
          vim.notify(("cd failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
          return
        end
        local ok_cmd, _ = pcall(require, "neo-tree.command")
        if ok_cmd then
          require("neo-tree.command").execute { source = "filesystem", dir = dir, reveal = true }
        end
        vim.notify(("cwd → %s"):format(dir), vim.log.levels.INFO)
      end,
      desc = "Set Neovim cwd to node and focus Neo-tree there",
    },

    ["-"] = {
      function(state)
        local current_root = state.path
        if not current_root or current_root == "" then
          local node = state.tree:get_node()
          local path = node and (node.path or node:get_id()) or ""
          if path == "" then
            vim.notify("no path under cursor", vim.log.levels.WARN)
            return
          end
          current_root = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
        end
        local parent = vim.fn.fnamemodify(current_root, ":h")
        if parent == current_root or parent == "" then
          vim.notify("already at top-level directory", vim.log.levels.WARN)
          return
        end
        local ok, err = pcall(vim.api.nvim_set_current_dir, parent)
        if not ok then
          vim.notify(("cd failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
          return
        end
        local ok_cmd, cmd = pcall(require, "neo-tree.command")
        if ok_cmd and cmd then
          cmd.execute { source = "filesystem", dir = parent, reveal = true }
        end
        vim.notify(("cwd → %s"):format(parent), vim.log.levels.INFO)
      end,
      desc = "Up one level: set cwd to parent and focus Neo-tree there",
    },

    ["<leader>qq"] = {
      function(state)
        -- open like <CR>
        local node = state.tree:get_node()
        if node and (node.type == "directory" or (node:has_children() and not node:is_expanded())) then
          state.commands.toggle_node(state)
          return
        end
        pcall(function()
          require("neo-tree.sources.common.preview").hide()
        end)
        state.commands.open(state)
        -- close only for this key
        require("neo-tree.command").execute { action = "close" }
      end,
      desc = "Open and close Neo-tree (one-shot)",
    },
  }
end

function M.filesystem()
  return {
    ["d"] = "noop",
    ["/"] = "noop",
    ["f"] = "filter_on_submit",
    ["F"] = "fuzzy_finder",
    ["<C-c>"] = "clear_filter",
  }
end

function M.buffers()
  return {
    ["dd"] = "buffer_delete",
  }
end

function M.git_status()
  return {
    ["d"] = "noop",
    ["dd"] = "delete",
  }
end

function M.document_symbols()
  return {
    ["/"] = "noop",
    ["F"] = "filter",
  }
end

-- Extra buffer-local bindings applied after Neo-tree buffer is ready.
-- These use `neo-tree.command` and do not require `state`.
function M.setup_autocmds()
  vim.api.nvim_create_autocmd("User", {
    pattern = "NeoTreeBufferEnter",
    callback = function(ev)
      local bufnr = ev.buf
      local ok_cmd, neo_cmd = pcall(require, "neo-tree.command")
      if not ok_cmd then
        return
      end

      local Root = require "utils.lv_project_root"

      local function reveal_at_root()
        neo_cmd.execute { source = "filesystem", dir = Root.get(0), reveal = true }
      end
      local function reveal_at_cwd()
        neo_cmd.execute { source = "filesystem", dir = cwd(), reveal = true }
      end

      -- Only in Neo-tree buffer; defined late → override plugin’s binds if duplicated.
      vim.keymap.set("n", "<C-o>", reveal_at_root, {
        buffer = bufnr,
        silent = true,
        nowait = true,
        desc = "Neo-tree: Reveal at project root",
      })

      -- GUIs may support <C-S-o>; terminals often don't.
      vim.keymap.set("n", "<C-S-o>", reveal_at_cwd, {
        buffer = bufnr,
        silent = true,
        nowait = true,
        desc = "Neo-tree: Reveal at cwd",
      })
    end,
  })
end

return M
