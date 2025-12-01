---@module 'autocmds.markdown.gf.01_gopath'
--- Module implementing the first gf-case: try to resolve and open using gopath.
--- This module returns two values from `try`: (handled:boolean, path:string|nil).
--- If handled == true, the caller must stop further processing (action already taken).
--- If handled == false and path is a string, the caller will continue with normal
--- path normalization/opening logic.
local M = {}

---@param node table|nil  -- TSNode or nil; receiver will call only with whatever ts_utils returned
---@param bufnr integer    -- buffer number where node was found
---@param cfg table        -- user config table for goto_file feature
---@return boolean, string|nil
---@diagnostic disable-next-line unused-param
function M.try(node, bufnr, cfg)
  -- If there's no node, this module cannot make a decision.
  if not node then
    return false, nil
  end

  -- Attempt to walk up to a "link_destination" node like the original logic.
  -- We avoid requiring ts_utils here; the caller should pass node produced by ts_utils.get_node_at_cursor().
  local function find_parent(n, types)
    while n and not vim.tbl_contains(types, n:type()) do
      n = n:parent()
    end
    return n
  end

  local dest = find_parent(node, { "link_destination" })
  if not dest or dest:type() ~= "link_destination" then
    -- This module only handles inline link destinations.
    return false, nil
  end

  -- Extract text for the destination using a small helper similar to original ts_text.
  local function ts_text(n, bufnr_local)
    if not n then
      return nil
    end
    local sr, sc, er, ec = n:range()
    local lines = vim.api.nvim_buf_get_lines(bufnr_local, sr, er + 1, false)
    if not lines or #lines == 0 then
      return nil
    end
    if #lines == 1 then
      return lines[1]:sub(sc + 1, ec)
    end
    -- multiple lines: join appropriately
    lines[1] = lines[1]:sub(sc + 1)
    lines[#lines] = lines[#lines]:sub(1, ec)
    return table.concat(lines, "\n")
  end

  local path = ts_text(dest, bufnr) or ""
  if path == "" then
    return false, nil
  end

  -- Normalize slashes so gopath resolver receives predictable input.
  path = path:gsub("\\", "/")

  -- If path looks like a module identifier (e.g. mdview.huhu) we still pass it through;
  -- the downstream gopath resolver is expected to handle module-like names if necessary.
  -- Here we perform the special action requested: call require("gopath").commands.resolve_and_open("edit")
  -- but only if the gopath module exists and exposes that API.
  local ok, gopath = pcall(require, "gopath")
  if ok and gopath and gopath.commands and type(gopath.commands.resolve_and_open) == "function" then
    -- Call the resolver action. We provide the original (raw) path as argument if API accepts it.
    -- If the API is fixed to a signature like resolve_and_open(method, target), adapt as needed.
    -- Here we attempt two common signatures:
    local called = false
    if not called then
      pcall(function()
        gopath.commands.resolve_and_open("edit")
        called = true
      end)
    end

    if called then
      -- Indicate we handled the action fully; caller should stop and not attempt fallback.
      return true, nil
    end
  end

  -- If gopath was not available or call failed, return the path so the caller can continue with the
  -- standard opening logic (normalization, URL handling, edit).
  return false, path
end

return M
