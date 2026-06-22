-- =============================================================================
-- lua/custom/pdfport/integrations/neotree.lua
-- =============================================================================
---@module 'custom.pdfport.integrations.neotree'
---@brief Neo-tree integration API for pdfport.
---@description
--- Provides two public functions:
---
---   commands() -> table<string, fun(state): nil>
---     Returns Neo-tree command definitions that can be merged into the
---     `commands` key of the neo-tree setup opts.
---
---   keymaps() -> table<string, string>
---     Returns Neo-tree window mapping definitions that can be merged into
---     a source's `window.mappings` table.
---
--- Usage in neotree config:
---
---   local pdfport_neo = require("custom.pdfport.integrations.neotree")
---   opts.commands = vim.tbl_extend("force", opts.commands, pdfport_neo.commands())
---   opts.filesystem.window.mappings = vim.tbl_extend(
---     "force",
---     opts.filesystem.window.mappings,
---     pdfport_neo.keymaps()
---   )

local M = {}

--- Returns the path of the node currently under the Neo-tree cursor.
---@param state table  Neo-tree state object
---@return string|nil path
local function node_path(state)
  if not state then return nil end

  -- state.tree is available after the source has been navigated at least once
  local tree = state.tree
  if not tree then return nil end

  local node = tree:get_node()
  if not node then return nil end

  return node:get_id()
end

--- Returns true when the path points to a PDF file.
---@param path string
---@return boolean
local function is_pdf(path)
  if not path or path == "" then return false end
  return path:lower():match("%.pdf$") ~= nil
end

--- Shows a hover_select picker for choosing the open mode.
---@param path string  PDF path
---@return nil
local function pick_mode_and_open(path)
  local pdfport = require("custom.pdfport")
  local hover   = require("lib.nvim.ui.hover_select")

  ---@type { label: string, mode: PdfPort.RendererMode, backend?: PdfPort.BackendId }[]
  local choices = {
    { label = "Plain text  (pdftotext)",  mode = "buffer",   backend = "pdftotext"  },
    { label = "Markdown    (marker)",      mode = "buffer",   backend = "marker"     },
    { label = "Markdown    (docling)",     mode = "buffer",   backend = "docling"    },
    { label = "Markdown    (Claude AI)",   mode = "buffer",   backend = "claude"     },
    { label = "Markdown    (Ollama AI)",   mode = "buffer",   backend = "ollama"     },
    { label = "Float window (auto)",       mode = "float",    backend = nil          },
    { label = "Terminal preview",          mode = "terminal", backend = nil          },
    { label = "System application",        mode = "system",   backend = nil          },
  }

  local items = { [#choices] = nil }
  for i, c in ipairs(choices) do
    items[i] = c.label
  end

  hover.open({
    title    = "Open PDF as…",
    items    = items,
    auto_width = true,
    on_select = function(_, idx)
      local choice = choices[idx]
      if not choice then return end

      pdfport.open({
        path       = path,
        mode       = choice.mode,
        backend_id = choice.backend,
        focus      = true,
      })
    end,
  })
end

--- Returns Neo-tree command definitions for pdfport.
---@return table<string, fun(state: table): nil>
function M.commands()
  return {
    -- Open a PDF with an interactive mode picker
    pdfport_open = function(state)
      local path = node_path(state)
      if not path then
        vim.notify("node path is nil", vim.log.levels.WARN)
        return
      end
      if not is_pdf(path) then
        vim.notify("pdfport: selected node is not a PDF file", vim.log.levels.WARN)
        return
      end

      pick_mode_and_open(path)
    end,

    -- Open as plain text in a buffer (quick access, no picker)
    pdfport_text = function(state)
      local path = node_path(state)
      if not path then
        vim.notify("node path is nil", vim.log.levels.WARN)
        return
      end
      if not is_pdf(path) then return end

      require("custom.pdfport").open({
        path   = path,
        mode   = "buffer",
        split  = "vsplit",
        focus  = true,
      })
    end,

    -- Open with system application
    pdfport_system = function(state)
      local path = node_path(state)
      if not path then
        vim.notify("node path is nil", vim.log.levels.WARN)
        return
      end

      if not is_pdf(path) then return end
      require("custom.pdfport").open({ path = path, mode = "system" })
    end,

    -- Terminal image preview
    pdfport_terminal = function(state)
      local path = node_path(state)
      if not path then
        vim.notify("node path is nil", vim.log.levels.WARN)
        return
      end

      if not is_pdf(path) then return end
      require("custom.pdfport").open({ path = path, mode = "terminal" })
    end,
  }
end

--- Returns Neo-tree window key mappings for pdfport commands.
--- These keys are suggestions; callers can override them freely.
---@return table<string, string>
function M.keymaps()
  return {
    ["<leader>po"] = "pdfport_open",     -- interactive mode picker
    ["<leader>pt"] = "pdfport_text",     -- quick text extraction
    ["<leader>ps"] = "pdfport_system",   -- open in system app
    ["<leader>pi"] = "pdfport_terminal", -- terminal image preview
  }
end

return M
