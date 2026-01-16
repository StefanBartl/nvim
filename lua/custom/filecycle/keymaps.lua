---@module 'custom.filecycle.keymaps'
require("custom.filecycle.@types")

local core = require("custom.filecycle.core")
local map = require("lib.map")

local M = {}

---@param opts FileCycle.Config
---@return nil
function M.attach(opts)
  -- leader nf/pf: replace current buffer (default behavior)
  map("n", "<leader>nf", function()
    local count = vim.v.count1
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      local override = vim.tbl_extend("force", opts, { open_target = "replace" })
      core.navigate(dir, "next", override, count)
    end
    vim.cmd("")
  end, { desc = "[filecycle] Next file (replace buffer)", silent = true })

  map("n", "<leader>pf", function()
    local count = vim.v.count1
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      local override = vim.tbl_extend("force", opts, { open_target = "replace" })
      core.navigate(dir, "prev", override, count)
    end
  end, { desc = "[filecycle] Previous file (replace buffer)", silent = true })

  -- leader nfn/pfn: stay mode (new buffer, keep old, focus new)
  map("n", "<leader>nfn", function()
    local count = vim.v.count1
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      local override = vim.tbl_extend("force", opts, { open_target = "current" })
      core.navigate(dir, "next", override, count)
    end
  end, { desc = "[filecycle] Next file (stay mode)", silent = true })

  map("n", "<leader>pfn", function()
    local count = vim.v.count1
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      local override = vim.tbl_extend("force", opts, { open_target = "current" })
      core.navigate(dir, "prev", override, count)
    end
  end, { desc = "[filecycle] Previous file (stay mode)", silent = true })

  -- leader nF/pF: background buffer (like :NextFile bg)
  map("n", "<leader>nF", function()
    local count = vim.v.count1
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      local override = vim.tbl_extend("force", opts, { open_target = "background" })
      core.navigate(dir, "next", override, count)
    end
  end, { desc = "[filecycle] Next file (background)", silent = true })

  map("n", "<leader>pF", function()
    local count = vim.v.count1
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      local override = vim.tbl_extend("force", opts, { open_target = "background" })
      core.navigate(dir, "prev", override, count)
    end
  end, { desc = "[filecycle] Previous file (background)", silent = true })

  -- leader NF/PF: vsplit (like :NextFile vsplit)
  map("n", "<leader>NF", function()
    local count = vim.v.count1
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      local override = vim.tbl_extend("force", opts, { open_target = "vsplit" })
      core.navigate(dir, "next", override, count)
    end
  end, { desc = "[filecycle] Next file (vsplit)", silent = true })

  map("n", "<leader>PF", function()
    local count = vim.v.count1
    local dir = select(1, core.get_root_dir(opts))
    if dir then
      local override = vim.tbl_extend("force", opts, { open_target = "vsplit" })
      core.navigate(dir, "prev", override, count)
    end
  end, { desc = "[filecycle] Previous file (vsplit)", silent = true })
end
return M
