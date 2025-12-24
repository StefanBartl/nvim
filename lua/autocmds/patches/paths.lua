---@module 'autocmds.patches.paths'
---@brief Patch registry with fully cross-platform paths.
---@description
--- Central registry for all patches. Each entry defines:
--- - Unique key for identification
--- - Repository name (auto-detected if nil)
--- - Paths to patch and target files
--- - Optional: priority, strip level, enabled flag

-- Path helpers for cross-platform compatibility
--- C:\Users\bartl\AppData\Local\nvim-data
local data = vim.fn.stdpath("data") --[[@as string]]
local config = vim.fn.stdpath("config") --[[@as string]]

local lazy = data .. "/lazy"
local patches = config .. "/patches"

-- Path builder helpers (for consistency)
local function patch_path(repo, subpath)
  return string.format("%s/%s/%s/diff.patch", patches, repo, subpath)
end

local function target_path(repo, file)
  return string.format("%s/%s/%s", lazy, repo, file)
end

-- #####################################################################
-- Patch Registry

---@type PatchTable
local registry = {

  -- =================================================================
  -- gitsigns.nvim
  -- =================================================================
  {
    key = "gitsigns-system-compat",
    repo = "gitsigns.nvim",
    priority = 100,
    enabled = true,
    strip = 0,
    patch = patch_path("gitsigns", "system/compat"),
    target = target_path("gitsigns.nvim", "lua/gitsigns/system/compat.lua"),
  },

  -- =================================================================
  -- noice.nvim
  -- =================================================================
  {
    key = "noice-lsp-signature",
    repo = "noice.nvim",
    priority = 80,
    enabled = true,
    strip = 0,
    patch = patch_path("noice", "lsp/signature"),
    target = target_path("noice.nvim", "lua/noice/lsp/signature.lua"),
  },

  -- =================================================================
  -- nvchad (UI plugin)
  -- =================================================================
  {
    key = "nvchad-ui-lsp-signature",
    repo = "nvchad",
    priority = 70,
    enabled = true,
    strip = 0,
    patch = patch_path("nvchad", "ui/lsp/signature"),
    target = target_path("ui", "lua/nvchad/lsp/signature.lua"),
  },

  {
    key = "nvchad-tabufline-init",
    repo = "nvchad",
    priority = 60,
    enabled = true,
    strip = 0,
    patch = patch_path("nvchad", "tabufline/init"),
    target = target_path("ui", "lua/nvchad/tabufline/init.lua"),
  },

  {
    key = "nvchad-tabufline-lazyload",
    repo = "nvchad",
    priority = 59,
    enabled = true,
    strip = 0,
    patch = patch_path("nvchad", "tabufline/lazyload"),
    target = target_path("ui", "lua/nvchad/tabufline/lazyload.lua"),
  },

  -- =================================================================
  -- nvim-cmp
  -- =================================================================
  -- {
  --   key = "nvim-cmp-config-mapping",
  --   repo = "nvim-cmp",
  --   priority = 50,
  --   enabled = true,
  --   strip = 0,
  --   patch = patches .. "/nvim-cmp/diff.patch",
  --   target = target_path("nvim-cmp", "lua/cmp/config/mapping.lua"),
  -- },

  -- =================================================================
  -- todo-comments.nvim
  -- =================================================================
  {
    key = "todo-comments-highlight",
    repo = "todo-comments.nvim",
    priority = 40,
    enabled = true,
    strip = 0,
    patch = patches .. "/todo_comments/diff.patch",
    target = target_path("todo-comments.nvim", "lua/todo-comments/highlight.lua"),
  },

}

-- #####################################################################
-- Validation on load

-- Warn about missing patch files (non-fatal)
for _, entry in ipairs(registry) do
  if vim.fn.filereadable(entry.patch) ~= 1 then
    vim.schedule(function()
      vim.notify(
        string.format(
          "[patches] Warning: Patch file not found\nKey: %s\nPath: %s",
          entry.key,
          entry.patch
        ),
        vim.log.levels.WARN
      )
    end)
  end
end

return registry
