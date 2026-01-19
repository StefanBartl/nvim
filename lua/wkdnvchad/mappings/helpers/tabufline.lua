---@module 'wkdnvchad.mappings.helpers.tabufline'

local M = {}

--- Move to the next buffer `n` times.
--- @param n integer
function M.move_next_n(n)
  -- require the project-specific tabufline next function
  local ok, tabufline = pcall(require, "custom.tabufline")
  if not ok or type(tabufline.next) ~= "function" then
    -- If the custom module is not available, try nvchad's tabufline as fallback
    local ok2, nv = pcall(require, "nvchad.tabufline")
    if ok2 and type(nv.next) == "function" then
      for _ = 1, n do
        pcall(nv.next)
      end
    end
    return
  end

  for _ = 1, n do
    pcall(tabufline.next)
  end
end

--- Move to the previous buffer `n` times.
--- @param n integer
function M.move_prev_n(n)
  local ok, tabufline = pcall(require, "custom.tabufline")
  if not ok or type(tabufline.prev) ~= "function" then
    local ok2, nv = pcall(require, "nvchad.tabufline")
    if ok2 and type(nv.prev) == "function" then
      for _ = 1, n do
        pcall(nv.prev)
      end
    end
    return
  end

  for _ = 1, n do
    pcall(tabufline.prev)
  end
end

--- Close the current buffer, and repeat `count` times.
--- The semantics: calling the close function repeatedly will close the current buffer,
--- then the newly current buffer, etc. This yields closing N consecutive buffers
--- starting from the current one (if available).
--- @param n integer
function M.close_n_buffers(n)
  -- prefer nvchad.tabufline.close_buffer if available (as in the user's sample)
  local ok, tabufline = pcall(require, "nvchad.tabufline")
  if not ok or type(tabufline.close_buffer) ~= "function" then
    -- fallback: try custom.close_buffer
    local ok2, custom = pcall(require, "custom.tabufline")
    if ok2 and type(custom.close) == "function" then
      for _ = 1, n do
        pcall(custom.close)
      end
    end
    return
  end

  for _ = 1, n do
    -- protect against errors and missing next buffer
    pcall(tabufline.close_buffer)
  end
end

return M
