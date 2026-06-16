---@module 'config.neotree.actions.pdfport'
---@brief Öffnet pdfport für den Node, auf dem der Cursor in Neo-tree steht.
---@description
--- Stellt zwei Aktionen bereit:
---   - open(state)       → interaktiver Modus-Picker (alle Backends/Modi)
---   - open_quick(state) → direkt `buffer – pdftotext` ohne Picker
---
--- Einbindung in neotree keymaps/usercmds via
---   config.neotree.keymaps.filesystem.pdfport   (Keymaps)
---   config.neotree.usercmds                     (User Commands)
---
---@see config.neotree.keymaps.filesystem.pdfport
---@see config.neotree.usercmds

local notify    = require("lib.notify").create("[config.neotree.actions.pdfport]")
local node_utils = require("config.neotree.utils.node")

local M = {}

-- ────────────────────────────────────────────────────────────────────────────
-- Private helpers
-- ────────────────────────────────────────────────────────────────────────────

---Gibt true zurück, wenn der Pfad auf eine PDF-Datei zeigt.
---@param path string
---@return boolean
local function is_pdf(path)
  return type(path) == "string" and path:lower():match("%.pdf$") ~= nil
end

---Gibt den absoluten Pfad der aktuell fokussierten Node zurück oder nil.
---@param state Cfg.NeoTree.State
---@return string|nil path
---@return string|nil err
local function get_pdf_path(state)
  local node = node_utils.get_current(state)
  if not node then
    return nil, "Kein Node unter dem Cursor"
  end

  local path, _ = node_utils.get_path(node)
  if not path or path == "" then
    return nil, "Node hat keinen Pfad"
  end

  if not is_pdf(path) then
    return nil, string.format("Keine PDF-Datei: %s", vim.fn.fnamemodify(path, ":t"))
  end

  return path, nil
end

-- ────────────────────────────────────────────────────────────────────────────
-- Public API
-- ────────────────────────────────────────────────────────────────────────────

---Öffnet den interaktiven pdfport-Modus-Picker für den Node unter dem Cursor.
---@param state Cfg.NeoTree.State
---@return nil
function M.open(state)
  local path, err = get_pdf_path(state)
  if not path then
    notify.warn(err or "Kein PDF-Pfad ermittelt")
    return
  end

  -- Weiterleiten an das pdfport-Modul; das kümmert sich um den Picker.
  -- Wir rufen die Funktion über den User-Command auf, damit wir keine
  -- Abhängigkeit auf den internen Picker duplizieren müssen.
  local ok_pdfport, pdfport = pcall(require, "custom.pdfport")
  if not ok_pdfport then
    notify.error("pdfport-Modul nicht geladen")
    return
  end

  local hover_ok, hover = pcall(require, "lib.ui.hover_select")

  local choices = {
    { label = "buffer  – plain text (auto)",    mode = "buffer",   backend = nil         },
    { label = "buffer  – pdftotext",            mode = "buffer",   backend = "pdftotext" },
    { label = "buffer  – marker (Markdown AI)", mode = "buffer",   backend = "marker"    },
    { label = "buffer  – docling",              mode = "buffer",   backend = "docling"   },
    { label = "buffer  – Claude API",           mode = "buffer",   backend = "claude"    },
    { label = "buffer  – Ollama",               mode = "buffer",   backend = "ollama"    },
    { label = "float   – auto",                 mode = "float",    backend = nil         },
    { label = "terminal image preview",         mode = "terminal", backend = nil         },
    { label = "system application",             mode = "system",   backend = nil         },
  }

  local items = { [#choices] = nil }
  for i, c in ipairs(choices) do items[i] = c.label end

  local on_select = function(_, idx)
    local c = choices[idx]
    if not c then return end
    pdfport.open({ path = path, mode = c.mode, backend_id = c.backend, focus = true })
  end

  if hover_ok then
    hover.open({
      title      = "pdfport – open as",
      items      = items,
      auto_width = true,
      on_select  = on_select,
    })
  else
    vim.ui.select(items, { prompt = "pdfport – open as:" }, function(_, idx)
      if idx then on_select(nil, idx) end
    end)
  end
end

---Öffnet die PDF sofort im Buffer mit pdftotext (kein Picker, schnell).
---Wird von <Tab> / <CR> auf PDF-Nodes verwendet.
---@param state Cfg.NeoTree.State
---@return nil
function M.open_quick(state)
  local path, err = get_pdf_path(state)
  if not path then
    notify.warn(err or "Kein PDF-Pfad ermittelt")
    return
  end

  local ok_pdfport, pdfport = pcall(require, "custom.pdfport")
  if not ok_pdfport then
    notify.error("pdfport-Modul nicht geladen")
    return
  end

  pdfport.open({
    path       = path,
    mode       = "buffer",
    backend_id = "pdftotext",
    split      = "vsplit",
    focus      = true,
  })
end

return M
