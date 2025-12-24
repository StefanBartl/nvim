---@module 'custom.function_index'
-- Build a list of all Lua function definitions in the current working directory
-- using ripgrep -> This does NOT load files as buffers and does NOT use LSP.

local function collect_lua_functions_cwd()
  local cmd = {
    "rg",
    "--vimgrep",
    "--no-heading",
    "--pcre2",
    [[
^\s*(local\s+)?function\s+[A-Za-z_][A-Za-z0-9_]*\s*\(
|^\s*[A-Za-z0-9_.]+\s*=\s*function\s*\(
    ]],
    ".",
  }

  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return {}
  end

  ---@type table[]
  local results = {}

  for _, line in ipairs(lines) do
    local file, lnum, col, text = line:match("([^:]+):(%d+):(%d+):(.*)")

    if file then
      results[#results + 1] = {
        filename = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = vim.trim(text),
      }
    end
  end

  return results
end

function Telescope_functions_index()
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local entries = collect_lua_functions_cwd()

  pickers
    .new({}, {
      prompt_title = "Lua Functions (CWD)",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(e)
          return {
            value = e,
            display = e.filename .. ":" .. e.lnum .. " " .. e.text,
            ordinal = e.text .. " " .. e.filename,
            filename = e.filename,
            lnum = e.lnum,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(_, map)
        map("i", "<CR>", function(bufnr)
          local sel = action_state.get_selected_entry()
          actions.close(bufnr)
          vim.cmd("edit " .. sel.filename)
          vim.api.nvim_win_set_cursor(0, { sel.lnum, 0 })
        end)
        return true
      end,
    })
    :find()
end

function Fzf_functions_index()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    return
  end

  local entries = collect_lua_functions_cwd()

  local lines = {}
  for _, e in ipairs(entries) do
    lines[#lines + 1] = string.format("%s:%d:%s", e.filename, e.lnum, e.text)
  end

  fzf.fzf_exec(lines, {
    prompt = "Functions> ",
    previewer = "builtin",
    actions = {
      ["default"] = function(sel)
        local file, lnum = sel[1]:match("([^:]+):(%d+):")
        vim.cmd("edit " .. file)
        vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
      end,
    },
  })
end

local M = {}

function M.setup()
  vim.api.nvim_create_user_command("FunctionIndexTelescope", function()
    Telescope_functions_index()
  end, { desc = "[Telescope] Find all functions in cwd" })

  vim.api.nvim_create_user_command("FunctionIndexFzfLua", function()
    Fzf_functions_index()
  end, { desc = "[FzfLua] Find all functions in cwd" })

  -- -- Telescope picker for all Lua functions in the CWD
  -- vim.keymap.set("n", "<leader>pf", Telescope_functions_index, {
  --   noremap = true,
  --   silent = true,
  -- })
  --
  -- -- fzf-lua picker for all Lua functions in the CWD
  -- vim.keymap.set("n", "<leader>fzt", Fzf_functions_index, {
  --   noremap = true,
  --   silent = true,
  -- })
end

return M

