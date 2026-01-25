---@module 'lsp.tools.eslint_prettier.prettier.format'
local notify = require("lib.notify").create("[lsp.tools.eslint_prettier.prettier.format]")

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
    notify.warn("No file to format")
    return
  end

  local bin = run.get_prettier_bin()
  if not bin then
    notify.error("prettier not found (PATH or mason).")
    return
  end

  if api.nvim_get_option_value("modified", { buf = bufnr }) then
    api.nvim_buf_call(bufnr, function()
      vim.cmd("write!")
    end)
  end

  local args = { bin, "--write", filename }
  run_cmd_collect(args, {
    on_exit = function(code, _, err)
      if code == 0 then
        vim.cmd("checktime")
        notify.info("prettier: formatted")
      else
        notify.warn("prettier failed:\n" .. table.concat(err, "\n"))
      end
    end,
  })
end

return M
