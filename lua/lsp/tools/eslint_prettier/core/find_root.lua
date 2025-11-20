---@module 'lsp.tools.eslint_prettier.core.find_root'
--- Find project root by searching upward for markers.
local api = vim.api
local fn = vim.fn

---markers to detect project root
local markers = { "package.json", ".git", ".eslintrc", ".prettierrc" }

---@param bufnr number|nil
---@return string|nil
local function find_root(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    return nil
  end
  local start_dir = fn.fnamemodify(bufname, ":p:h")
  if vim.fs and vim.fs.find then
    for _, m in ipairs(markers) do
      ---@diagnostic disable-next-line: undefined-field
      local found = vim.fs.find(m, { upward = true, path = start_dir, stop = vim.loop.os_homedir() })
      if found and #found > 0 then
        return vim.fs.dirname(found[1])
      end
    end
  else
    local dir = start_dir
    while dir and dir ~= "/" and dir ~= "" do
      for _, m in ipairs(markers) do
        local candidate = dir .. "/" .. m
        if fn.filereadable(candidate) == 1 or fn.isdirectory(candidate) == 1 then
          return dir
        end
      end
      local parent = fn.fnamemodify(dir, ":h")
      if parent == dir then
        break
      end
      dir = parent
    end
  end
  return nil
end

return find_root
