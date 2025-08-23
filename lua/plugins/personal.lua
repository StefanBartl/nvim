---@module 'plugins.personal'
--- Personal and local development plugins (myterm, mygrep, cmdlog, etc.)
--- Uses platform-aware base path from `system_env`:

---@type LazyPluginSpec[]
return (function()
  --- Load environment (must be initialized early in init.lua)
  -- ---@type { repo_base: string }
  -- local env = require("system.env").get()
  --
  -- --- Prefer Neovim 0.10's vim.uv, fallback to vim.loop
  -- local uv = vim.uv or vim.loop
  --
  -- --- Join path segments in a platform-agnostic way
  -- ---@param ... string
  -- ---@return string
  -- local function join(...)
  --   return vim.fs.joinpath(...)
  -- end
  --
  -- --- Build absolute repo path from base + name
  -- ---@param name string
  -- ---@return string
  -- local function repo(name)
  --   return join(env.repo_base or "", name)
  -- end

  -- --- Check if a path exists on disk
  -- ---@param path string|nil
  -- ---@return boolean
  -- local function exists(path)
  --   if type(path) ~= "string" or path == "" then return false end
  --   return uv.fs_stat(path) ~= nil
  -- end

  --[[
  --- Path to local myterm module under this config
  ---@return string
  local function myterm_local_dir()
    return join(vim.fn.stdpath("config"), "lua", "custom", "myterm")
  end
  ]] --

  return {

    --[[
    -- nvim-containers: Manage container engines from Neovim
    {
      dir = repo("nvim-containers"),
      cond = exists(repo("nvim-containers")),
      event = "VeryLazy",
      config = function()
        require("containers").setup({})
      end,
    },
    ]]--

    -- nvim-cmdlog: Command history management (remote plugin)
    {
      "StefanBartl/nvim-cmdlog",
      lazy = false,
      dependencies = {
        "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope.nvim" },
    { "ibhagwan/fzf-lua", optional = true },
      },
      config = function()
        require("cmdlog").setup({
          picker = "telescope",
        })
      end,
    },
    -- Optional: local dev version of cmdlog
    -- {
    --   dir = repo("nvim-cmdlog"),
    --   cond = exists(repo("nvim-cmdlog")),
    --   config = function()
    --     require("cmdlog").setup({ picker = "telescope" })
    --   end,
    -- },

    --[[

    -- reposcope.nvim: GitHub repo explorer
    {
      dir = repo("reposcope.nvim"),
      cond = exists(repo("reposcope.nvim")),
      name = "reposcope",
      event = "VeryLazy",
      config = function()
        require("reposcope.init").setup({})
      end,
    },

    ]]--

    -- myterm.local: Custom terminal interface with layout switching
    --[[
    {
      name = "myterm.local",
      dir = myterm_local_dir(),
      cond = exists(myterm_local_dir()),
      lazy = false,
      config = function()
        require("custom.myterm")
      end,
    },
    ]] --

    -- mygrep.nvim: Grep interface with memory, history, favorites
    -- {
    --   dir = repo("mygrep.nvim"),
    --   cond = exists(repo("mygrep.nvim")),
    --   name = "mygrep",
    --   lazy = false,
    --   config = function()
    --     require("mygrep").setup({
    --       tool_picker_style = "ui",
    --     })
    --   end,
    -- },

  }
end)()
