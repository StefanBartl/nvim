---@module 'custom.recommender'
---Public API

local notify = require("lib.notify").create("[custom.recommender]")

local rendering = require("custom.recommender.rendering")
local keymaps = require("custom.recommender.keymaps")
local custom_aliases = require("custom.recommender.custom_aliases")
local blacklist_module = require("custom.recommender.blacklist")

local M = {}

local api = vim.api
local km_set = vim.keymap.set

local analyzers = {
  regex = require("custom.recommender.regex"),
  treesitter = require("custom.recommender.treesitter"),
}

---@class Recommender.opts
---@field analyzer? "regex"|"treesitter"
---@field threshold? number
---@field custom_aliases? table<string, string>
---@field blacklist? string[]

---@type Recommender.opts
local default_opts = {
  analyzer = "regex",
  threshold = 3,
  custom_aliases = custom_aliases,
  blacklist = blacklist_module.default,
}

local ignore_by_buf = {}

---@param opts Recommender.opts|nil
function M.setup(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})

  api.nvim_create_user_command("Recommender", function(cmd)
    -- Parse arguments
    local args = vim.split(vim.trim(cmd.args or ""), "%s+")

    -- Check for flags
    local replace_mode = false
    local filtered_args = {}

    for _, arg in ipairs(args) do
      if arg == "-r" or arg == "--replace" then
        replace_mode = true
      else
        table.insert(filtered_args, arg)
      end
    end

    local analyzer = (filtered_args[1] and analyzers[filtered_args[1]]) and filtered_args[1] or opts.analyzer
    local threshold = tonumber(filtered_args[2]) or opts.threshold

    -- Check if window is already open - toggle behavior
    if rendering.is_open() then
      rendering.close()
      return
    end

    local bufnr = api.nvim_get_current_buf()
    ignore_by_buf[bufnr] = ignore_by_buf[bufnr] or {}

    local state = {}
    state.ignored = ignore_by_buf[bufnr]
    state.custom_aliases = opts.custom_aliases or {}
    state.blacklist = opts.blacklist or {}
    state.source_bufnr = bufnr -- Store the source buffer
    state.replace_mode = replace_mode -- Store replace mode flag

    function state.refresh()
      -- Wrap in pcall to catch errors
      local ok, err = pcall(function()
        -- Ensure we analyze the source buffer, not the float
        local all
        if state.source_bufnr and api.nvim_buf_is_valid(state.source_bufnr) then
          api.nvim_buf_call(state.source_bufnr, function()
            all = analyzers[analyzer].analyze(threshold, state.custom_aliases, state.blacklist)
          end)
        else
          notify.warn("Source buffer is no longer valid")
          rendering.close()
          return
        end

        state.visible = {}

        for _, s in ipairs(all) do
          if not state.ignored[s.chain] then
            state.visible[#state.visible + 1] = s
          end
        end

        if #state.visible == 0 then
          notify.info("No suggestions found (threshold: " .. threshold .. ")")
          rendering.close()
          return
        end

        local title = string.format("Recommender: %d suggestions", #state.visible)
        if replace_mode then
          title = title .. " [REPLACE MODE]"
        end

        local current_index = rendering.cursor_index
        rendering.open(state.visible, title, current_index)

        -- Attach keymaps after window is opened
        if rendering.float_buf and api.nvim_buf_is_valid(rendering.float_buf) then
          keymaps.attach(rendering.float_buf, state)
        end
      end)

      if not ok then
        notify.error("Recommender error: " .. tostring(err))
        rendering.close()
      end
    end

    -- Initial refresh
    vim.schedule(state.refresh)
      end, {
    nargs = "*",
    desc = "Suggest local aliases for repeated Lua chains. Use -r flag to auto-replace after insert.",
  })

  -- Optional: Keymap für schnellen Zugriff
  km_set("n", "<leader>lr", "<cmd>Recommender<cr>", {
    desc = "Lua Recommender",
    silent = true,
  })

  -- Mit Replace-Mode
  km_set("n", "<leader>lR", "<cmd>Recommender -r<cr>", {
    desc = "Lua Recommender (Replace Mode)",
    silent = true,
  })

  -- Alternative: Mit verschiedenen Analyzern
  km_set("n", "<leader>lrr", "<cmd>Recommender regex<cr>", {
    desc = "Recommender (Regex)",
    silent = true,
  })

  km_set("n", "<leader>lrt", "<cmd>Recommender treesitter<cr>", {
    desc = "Recommender (Treesitter)",
    silent = true,
  })

  -- Mit höherem Threshold für große Dateien
  km_set("n", "<leader>lrh", "<cmd>Recommender regex 5<cr>", {
    desc = "Recommender (High Threshold)",
    silent = true,
  })
end

return M
