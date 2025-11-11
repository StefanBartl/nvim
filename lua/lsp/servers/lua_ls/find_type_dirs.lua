---@module 'lisp.servers.lua_ls.find_type_dirs'
-- Find directories named "types" / "@types" while pruning common noise directories.
-- Using shared ignore set

local uv = vim.loop
local norm = vim.fs.normalize

--- Return string[] of discovered "types" dirs under root.
--- @param root string
--- @param opts { max_results?: integer, max_depth?: integer }|nil
--- @return string[]
return function (root, opts)
  opts = opts or {}
  local MAX_RESULTS = opts.max_results or 200
  local MAX_DEPTH = opts.max_depth or 12

  -- Use shared ignore set for fast membership testing
  local ignore_set = require("lsp.servers.lua_ls.ignore").as_set()

  local matches, stack = {}, { { path = norm(root), depth = 0 } }
  while #stack > 0 and #matches < MAX_RESULTS do
    local node = table.remove(stack)
    if node.depth <= MAX_DEPTH then
      local it = uv.fs_scandir(node.path)
      if it then
        while true do
          ---@diagnostic disable-next-line: undefined-field
          local name, kind = uv.fs_scandir_next(it)
          if not name then break end

          -- skip dotfiles except .config (preserve original behavior)
          if name:sub(1, 1) == "." and name ~= ".config" then goto inner_continue end

          if kind == "directory" then
            -- use normalized compare via platform normalization
            local key = package.config:sub(1,1) == "\\" and name:lower() or name
            if ignore_set[key] then goto inner_continue end

            local child = norm(node.path .. (package.config:sub(1,1) == "\\" and "\\" or "/") .. name)
            if name == "types" or name == "@types" then
              matches[#matches + 1] = child
            end
            stack[#stack + 1] = { path = child, depth = node.depth + 1 }
          end
          ::inner_continue::
        end
      end
    end
  end
  return matches
end
