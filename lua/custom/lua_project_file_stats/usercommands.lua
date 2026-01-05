---@module 'custom.lua_project_file_stats.usercommands'
---@brief Neovim user commands with completion

local notify = require("lib.notify").create("[LuaProjectFileStats]")

local M = {}

local api, fn = vim.api, vim.fn
local nvim_create_user_command = api.nvim_create_user_command
local getcwd = fn.getcwd
local schedule = vim.schedule

---Parse command arguments into config
---@param args table Command arguments from nvim_create_user_command
---@return LuaProjectFileStats.Config
local function parse_cmd_args(args)
  local config = {
    root_dir = vim.loop.cwd(), -- default auf cwd
    reverse_order = false,
    percent_mode = "both",
    fields_to_print = { "files", "folders", "summary" },
    single_file_path = nil,
    col_width = 7,
    top_n = 25,
    only_top_files_lines = false,
    only_top_files_words = false,
    show_ratios = false,
    show_deviations = false,
    output_file = nil,
    interactive = false,
    async = true,
  }

  for _, flag in ipairs(args.fargs) do
    if flag == "--reverse" then
      config.reverse_order = true
    elseif flag == "--percent-only" then
      config.percent_mode = "percent"
    elseif flag == "--numbers-only" then
      config.percent_mode = "numbers"
    elseif flag == "--ratios" then
      config.show_ratios = true
    elseif flag == "--deviations" then
      config.show_deviations = true
    elseif flag:match("^--fields=") then
      local val = flag:sub(10)
      config.fields_to_print = {}
      for f in val:gmatch("([^,]+)") do
        table.insert(config.fields_to_print, f)
      end
    elseif flag:match("^--file=") then
      config.single_file_path = flag:sub(9)
    elseif flag:match("^--colwidth=") then
      config.col_width = tonumber(flag:sub(12)) or config.col_width
    elseif flag:match("^--topn=") then
      config.top_n = tonumber(flag:sub(8)) or config.top_n
    elseif flag == "--top-files-lines-only" then
      config.only_top_files_lines = true
    elseif flag == "--top-files-words-only" then
      config.only_top_files_words = true
    elseif flag:match("^--output=") then
      config.output_file = flag:sub(11)
    elseif flag == "--sync" then
      config.async = false
    elseif flag == "-i" or flag == "--interactive" then
      config.interactive = true
    elseif not flag:match("^%-") then
      config.root_dir = flag -- nur hier überschreiben
    end
  end

  return config
end

---Completion function for command
---@param arg_lead string
---@param cmd_line string
---@param cursor_pos integer
---@return string[]
---@diagnostic disable-next-line: unused-local
local function complete_func(arg_lead, cmd_line, cursor_pos)
  local flags = {
    "--reverse",
    "--percent-only",
    "--numbers-only",
    "--ratios",
    "--deviations",
    "--fields=files",
    "--fields=folders",
    "--fields=summary",
    "--fields=files,folders,summary",
    "--file=",
    "--colwidth=7",
    "--topn=25",
    "--top-files-lines-only",
    "--top-files-words-only",
    "--output=",
    "--sync",
    "-i",
    "--interactive",
  }

  -- Filter flags that start with arg_lead
  local matches = {}
  for _, flag in ipairs(flags) do
    if flag:sub(1, #arg_lead) == arg_lead then
      table.insert(matches, flag)
    end
  end

  -- If arg_lead doesn't start with "--", suggest directories
  if not arg_lead:match("^%-") then
    local dirs = fn.getcompletion(arg_lead, "dir")
    vim.list_extend(matches, dirs)
  end

  return matches
end

---Setup user commands
function M.setup()
  local main = require("custom.lua_project_file_stats")

  -- Main command: :LuaFileStats
  nvim_create_user_command("LuaFileStats", function(args)
    local config = parse_cmd_args(args)

    if config.async then
      -- Async execution
      schedule(function()
        local success, err = pcall(main.analyze, config)
        if not success then
          notify.error("LuaFileStats error: " .. tostring(err))
        end
      end)
    else
      -- Sync execution
      local success, err = pcall(main.analyze, config)
      if not success then
        notify.error("LuaFileStats error: " .. tostring(err))
      end
    end
  end, {
    nargs = "*",
    complete = complete_func,
    desc = "Analyze Lua project file statistics",
  })

  -- Quick commands for common use cases
  nvim_create_user_command("LuaFileStatsQuick", function(args)
    local config = {
      root_dir = args.args ~= "" and args.args or getcwd(),
      reverse_order = false,
      percent_mode = "numbers",
      fields_to_print = { "summary" },
      single_file_path = nil,
      col_width = 7,
      top_n = 10,
      only_top_files_lines = false,
      only_top_files_words = false,
      show_ratios = false,
      show_deviations = false,
      output_file = nil,
      interactive = false,
      async = true,
    }

    schedule(function()
      pcall(main.analyze, config)
    end)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "Quick summary of Lua project statistics",
  })

  nvim_create_user_command("LuaFileStatsRatios", function(args)
    local config = {
      root_dir = args.args ~= "" and args.args or getcwd(),
      reverse_order = true,
      percent_mode = "both",
      fields_to_print = { "folders", "summary" },
      single_file_path = nil,
      col_width = 7,
      top_n = 25,
      only_top_files_lines = false,
      only_top_files_words = false,
      show_ratios = true,
      show_deviations = true,
      output_file = nil,
      interactive = false,
      async = true,
    }

    schedule(function()
      pcall(main.analyze, config)
    end)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "Show ratio analysis with deviations",
  })

  nvim_create_user_command("LuaFileStatsCurrentFile", function()
    local config = {
      root_dir = getcwd(),
      reverse_order = false,
      percent_mode = "both",
      fields_to_print = {},
      single_file_path = fn.expand("%:p"),
      col_width = 7,
      top_n = 0,
      only_top_files_lines = false,
      only_top_files_words = false,
      show_ratios = false,
      show_deviations = false,
      output_file = nil,
      interactive = false,
      async = true,
    }

    schedule(function()
      pcall(main.analyze, config)
    end)
  end, {
    desc = "Analyze current Lua file statistics",
  })

  -- Notify successful setup
  -- notify.info("LuaFileStats commands registered")
end

return M
