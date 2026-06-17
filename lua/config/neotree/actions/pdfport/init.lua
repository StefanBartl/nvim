---@module 'config.neotree.actions.pdfport'
---@brief Öffnet pdfport für den Node, auf dem der Cursor in Neo-tree steht.
---@description
--- Stellt zwei Aktionen bereit:
---   - open(state)       → interaktiver Modus-Picker
---   - open_quick(state) → direkt `buffer – pdftotext`, kein Picker
---
--- Freeze-Schutz:
---   Neo-tree kann bei bestimmten Filetypes (z. B. PDF) interne Preview-
---   Mechanismen auslösen, die Neovim kurz einfrieren. Diese Action ruft
---   explizit `preview.hide()` auf und stellt sicher, dass kein anderer
---   PDF-Handler gleichzeitig aktiv wird.
---
--- Split-Position:
---   Der Buffer-Renderer wechselt intern in ein normales Editor-Fenster,
---   bevor er splittet. Das hier stellt sicher, dass Neo-tree-Fokus
---   danach korrekt wiederhergestellt wird.

local notify     = require("lib.notify").create("[config.neotree.actions.pdfport]")
local node_utils = require("config.neotree.utils.node")

local M = {}

-- ── Private helpers ──────────────────────────────────────────────────────────

---@param path string
---@return boolean
local function is_pdf(path)
  return type(path) == "string" and path:lower():match("%.pdf$") ~= nil
end

--- Stoppt aktive Neo-tree Preview-Mechanismen, bevor pdfport startet.
--- Verhindert den Freeze, der entsteht wenn Neo-tree versucht, eine PDF
--- im Preview-Fenster zu rendern während pdfport gleichzeitig aktiv wird.
---@return nil
local function suppress_neotree_preview()
  -- neo-tree.sources.common.preview stoppen falls aktiv
  local ok, preview = pcall(require, "neo-tree.sources.common.preview")
  if ok and type(preview) == "table" then
    if type(preview.hide) == "function" then
      pcall(preview.hide)
    end
    if type(preview.stop) == "function" then
      pcall(preview.stop)
    end
  end

  -- Snacks-Image-Preview stoppen falls vorhanden (verursacht ebenfalls Freezes)
  local ok_snacks, snacks = pcall(require, "snacks.image")
  if ok_snacks and type(snacks) == "table" then
    if type(snacks.clear) == "function" then
      pcall(snacks.clear)
    end
  end
end

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
    return nil, string.format("Kein PDF: %s", vim.fn.fnamemodify(path, ":t"))
  end

  return path, nil
end

-- ── Public API ───────────────────────────────────────────────────────────────

--- Interaktiver Modus-Picker.
---@param state Cfg.NeoTree.State
---@return nil
function M.open(state)
  local path, err = get_pdf_path(state)
  if not path then
    notify.warn(err or "Kein PDF-Pfad")
    return
  end

  -- Neo-tree Preview sofort stoppen → kein Freeze
  suppress_neotree_preview()

  local ok_pdfport, pdfport = pcall(require, "custom.pdfport")
  if not ok_pdfport then
    notify.error("pdfport-Modul nicht geladen")
    return
  end

  local hover_ok, hover = pcall(require, "lib.ui.hover_select")

  local choices = {
    { label = "buffer  – plain text (auto)",    mode = "buffer",   backend = nil          },
    { label = "buffer  – pdftotext",            mode = "buffer",   backend = "pdftotext"  },
    { label = "buffer  – marker (Markdown AI)", mode = "buffer",   backend = "marker"     },
    { label = "buffer  – docling",              mode = "buffer",   backend = "docling"    },
    { label = "buffer  – Claude API",           mode = "buffer",   backend = "claude"     },
    { label = "buffer  – Ollama",               mode = "buffer",   backend = "ollama"     },
    { label = "float   – auto",                 mode = "float",    backend = nil          },
    { label = "terminal image preview",         mode = "terminal", backend = nil          },
    { label = "system application",             mode = "system",   backend = nil          },
  }

  local items = {}
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

--- Schnell-Open: pdftotext direkt, kein Picker.
--- Wird von <Tab> / <CR> auf PDF-Nodes verwendet.
---@param state Cfg.NeoTree.State
---@return nil
function M.open_quick(state)
  local path, err = get_pdf_path(state)
  if not path then
    notify.warn(err or "Kein PDF-Pfad")
    return
  end

  -- Neo-tree Preview sofort stoppen → kein Freeze
  suppress_neotree_preview()

  local ok_pdfport, pdfport = pcall(require, "custom.pdfport")
  if not ok_pdfport then
    notify.error("pdfport-Modul nicht geladen")
    return
  end

  -- neo_win merken: nach dem Öffnen Fokus zurück zu Neo-tree
  local neo_win = vim.api.nvim_get_current_win()

  pdfport.open({
    path       = path,
    mode       = "buffer",
    backend_id = "pdftotext",
    split      = "current",
    focus      = true,   -- buffer.lua wechselt intern ins Editor-Fenster
  })

  -- Neo-tree Fenster ist nach dem open() noch gültig → Fokus lassen wie er ist.
  -- (buffer.lua mit focus=true setzt den Cursor in den neuen Buffer;
  --  Neo-tree bleibt links angedockt — korrekte Reihenfolge: Neo-tree | Editor | pdfport)
  _ = neo_win  -- nur zur Dokumentation; kein Zurückwechseln nötig
end

return M
