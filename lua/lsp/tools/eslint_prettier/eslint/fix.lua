---@module 'lsp.tools.eslint_prettier.eslint.fix'
--- Run eslint_d --fix on current file (uses resolved bin)
local api = vim.api
local eslint = require("lsp.tools.eslint_prettier.eslint")

local M = {}

--- run async command and collect stdout/stderr
---@param argv string[] list of command + args
---@param opts table|nil
local function run_cmd_collect(argv, opts)
  opts = opts or {}
  local stdout = {}
  local stderr = {}
  local on_exit = opts.on_exit
  local cwd = opts.cwd or nil

  local jid = vim.fn.jobstart(argv, {
    stdout_buffered = true,
    stderr_buffered = true,
    cwd = cwd,
    on_stdout = function(_, data)
      if data then
        for _, l in ipairs(data) do
          if l ~= "" then table.insert(stdout, l) end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, l in ipairs(data) do
          if l ~= "" then table.insert(stderr, l) end
        end
      end
    end,
    on_exit = function(_, code)
      if on_exit then vim.schedule(function() on_exit(code, stdout, stderr) end) end
    end,
  })
  return jid
end

---@param bufnr number|nil
function M.eslint_fix(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local filename = api.nvim_buf_get_name(bufnr)
    if filename == "" then
        vim.notify("No file to lint", vim.log.levels.WARN)
        return
    end

    local bin = eslint.get_eslint_bin()
    if not bin then
        vim.notify("eslint_d not found (PATH or mason).", vim.log.levels.ERROR)
        return
    end

    -- Write buffer before running eslint
    if api.nvim_buf_get_option(bufnr, "modified") then
        api.nvim_buf_call(bufnr, function() vim.cmd("write") end)
    end

    -- Ermittle Projekt-Root und setze als cwd
    local find_root = require("lsp.tools.eslint_prettier.core.find_root")
    local root = find_root(bufnr)
    if not root then
        vim.notify("Could not determine project root, using current directory.", vim.log.levels.WARN)
        root = vim.fn.getcwd()
    end

    local args = { bin, "--fix", filename }

    -- Sammle stdout/stderr, setze cwd auf Projekt-Root
    run_cmd_collect(args, {
        cwd = root,
        on_exit = function(code, stdout, stderr)
            if code == 0 then
                vim.cmd("checktime") -- Refresh buffer
                vim.notify("eslint_d: fixed", vim.log.levels.INFO)
            else
                local msg = {}

                if stdout and #stdout > 0 then
                    table.insert(msg, "[stdout]")
                    vim.list_extend(msg, stdout)
                end

                if stderr and #stderr > 0 then
                    table.insert(msg, "[stderr]")
                    vim.list_extend(msg, stderr)
                end

                if #msg == 0 then
                    table.insert(msg, "eslint_d returned non-zero exit code, but no output captured.")
                end

                vim.notify(table.concat(msg, "\n"), vim.log.levels.ERROR)
            end
        end,
    })
end

return M
