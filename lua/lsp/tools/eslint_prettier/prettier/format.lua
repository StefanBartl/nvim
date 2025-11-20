---@module 'lsp.tools.eslint_prettier.prettier.format'
local api = vim.api
local run = require("lsp.tools.eslint_prettier.prettier")

local M = {}

local function run_cmd_collect(argv, opts)
  opts = opts or {}
  local stdout, stderr = {}, {}
  local jid = vim.fn.jobstart(argv, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, l in ipairs(data) do
          if l ~= "" then
            table.insert(stdout, l)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, l in ipairs(data) do
          if l ~= "" then
            table.insert(stderr, l)
          end
        end
      end
    end,
    on_exit = function(_, code)
      if opts.on_exit then
        vim.schedule(function()
          opts.on_exit(code, stdout, stderr)
        end)
      end
    end,
  })
  return jid
end

---@param bufnr number|nil
function M.prettier_format(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local filename = api.nvim_buf_get_name(bufnr)
  if filename == "" then
    vim.notify("No file to format", vim.log.levels.WARN)
    return
  end

  local bin = run.get_prettier_bin()
  if not bin then
    vim.notify("prettier not found (PATH or mason).", vim.log.levels.ERROR)
    return
  end

  if api.nvim_buf_get_option(bufnr, "modified") then
    api.nvim_buf_call(bufnr, function()
      vim.cmd("write!")
    end)
  end

  local args = { bin, "--write", filename }
  run_cmd_collect(args, {
    on_exit = function(code, _, err)
      if code == 0 then
        vim.cmd("checktime")
        vim.notify("prettier: formatted", vim.log.levels.INFO)
      else
        vim.notify("prettier failed:\n" .. table.concat(err, "\n"), vim.log.levels.WARN)
      end
    end,
  })
end

return M
