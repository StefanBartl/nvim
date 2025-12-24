---@module 'custom.recommender'
---Public API

local M = {}

local rendering = require("custom.recommender.rendering")
local keymaps = require("custom.recommender.keymaps")
local custom_aliases = require("lua.custom.recommender.custom_aliases")

local analyzers = {
  regex = require("custom.recommender.regex"),
  treesitter = require("custom.recommender.treesitter"),
}

---@class Recommender.opts
---@field analyzer? "regex"|"treesitter"
---@field threshold? number
---@field custom_aliases? table<string, string>

---@type Recommender.opts
local default_opts = {
  analyzer = "regex",
  threshold = 3,
  custom_aliases = custom_aliases,
}

local ignore_by_buf = {}

---@param opts Recommender.opts|nil
function M.setup(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})

  vim.api.nvim_create_user_command("Recommender", function(cmd)
    -- Parse arguments
    local args = vim.split(vim.trim(cmd.args or ""), "%s+")
    local analyzer = (args[1] and analyzers[args[1]]) and args[1] or opts.analyzer
    local threshold = tonumber(args[2]) or opts.threshold

    -- Check if window is already open - toggle behavior
    if rendering.is_open() then
      rendering.close()
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    ignore_by_buf[bufnr] = ignore_by_buf[bufnr] or {}

    local state = {}
    state.ignored = ignore_by_buf[bufnr]
    state.custom_aliases = opts.custom_aliases or {}
    state.source_bufnr = bufnr -- Store the source buffer

    function state.refresh()
      -- Wrap in pcall to catch errors
      local ok, err = pcall(function()
        -- Ensure we analyze the source buffer, not the float
        local all
        if state.source_bufnr and vim.api.nvim_buf_is_valid(state.source_bufnr) then
          vim.api.nvim_buf_call(state.source_bufnr, function()
            all = analyzers[analyzer].analyze(threshold, state.custom_aliases)
          end)
        else
          vim.notify("Source buffer is no longer valid", vim.log.levels.WARN)
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
          vim.notify("No suggestions found (threshold: " .. threshold .. ")", vim.log.levels.INFO)
          rendering.close()
          return
        end

        local current_index = rendering.cursor_index
        rendering.open(state.visible, string.format("Recommender: %d suggestions", #state.visible), current_index)

        -- Attach keymaps after window is opened
        if rendering.float_buf and vim.api.nvim_buf_is_valid(rendering.float_buf) then
          keymaps.attach(rendering.float_buf, state)
        end
      end)

      if not ok then
        vim.notify("Recommender error: " .. tostring(err), vim.log.levels.ERROR)
        rendering.close()
      end
    end

    -- Initial refresh
    vim.schedule(state.refresh)
  end, {
    nargs = "*",
    desc = "Suggest local aliases for repeated Lua chains",
  })
end

return M
