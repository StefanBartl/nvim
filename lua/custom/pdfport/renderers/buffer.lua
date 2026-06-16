---@module 'custom.pdfport.renderers.buffer'
---@brief Renders extracted PDF text into a Neovim scratch buffer.
---@description
--- Creates a new scratch buffer with filetype=markdown (or =text for plain
--- output) and writes the extracted content into it. The buffer is not tied
--- to any file on disk and will be discarded when closed.
---
--- Split behavior is controlled by opts.split:
---   "vsplit" (default), "split", "tab", or nil (current window)
---
--- Fix (split-Seite): Vor dem Öffnen des Splits wird sichergestellt, dass
--- das aktuelle Fenster ein normales Editor-Fenster ist (nicht Neo-tree).
--- Andernfalls würde vsplit links neben Neo-tree öffnen statt rechts davon.

local M = {}

-- ── Helpers ──────────────────────────────────────────────────────────────────

--- Gibt einen deduplizierten Buffer-Namen für den PDF-Pfad zurück.
---@param path string
---@return string
local function buf_name(path)
  local stem = vim.fn.fnamemodify(path, ":t:r")
  return string.format("pdfport://%s", stem)
end

--- Öffnet oder reaktiviert einen vorhandenen Scratch-Buffer mit diesem Namen.
---@param name string
---@return integer bufnr
local function get_or_create_buf(name)
  for _, nr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(nr) then
      if vim.api.nvim_buf_get_name(nr) == name then
        return nr
      end
    end
  end
  local nr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(nr, name)
  return nr
end

--- Bereinigt einen String von Windows-Zeilenenden (\r) und anderen
--- Steuerzeichen, die als ^M im Buffer angezeigt werden.
--- Wird auf jede einzelne Zeile angewendet, nachdem vim.split() den Text
--- bereits an \n getrennt hat – so bleiben leere Zeilen korrekt erhalten.
---@param line string
---@return string
local function strip_cr(line)
  -- \r am Zeilenende entfernen (klassisches CRLF-Residuum)
  return line:gsub("\r$", "")
end

--- Wechselt in das "beste" normale Editor-Fenster (nicht Neo-tree, nicht Float).
--- Gibt die ursprüngliche Win-ID zurück, damit der Aufrufer entscheiden kann,
--- ob er zurückwechseln will.
---
--- Hintergrund: vsplit öffnet immer RECHTS vom aktuellen Fenster. Wenn das
--- aktuelle Fenster Neo-tree (links angedockt) ist, landet der neue Split
--- zwischen Neo-tree und dem vorherigen Editor-Fenster. Wir wechseln daher
--- zuerst in ein echtes Editor-Fenster, bevor wir splitten.
---
---@return integer orig_win  Fenster-ID vor dem Wechsel (0 wenn kein Wechsel nötig)
local function ensure_editor_win()
  local cur_win  = vim.api.nvim_get_current_win()
  local cur_buf  = vim.api.nvim_win_get_buf(cur_win)
  local cur_ft   = vim.bo[cur_buf].filetype
  local cur_cfg  = vim.api.nvim_win_get_config(cur_win)

  -- Schon in einem normalen Editor-Fenster → nichts tun
  local is_neo   = cur_ft == "neo-tree"
  local is_float = cur_cfg.relative ~= ""
  if not is_neo and not is_float then
    return 0
  end

  -- Suche das letzte normale (nicht-Neo-tree, nicht-Float) Fenster im Tab
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for i = #wins, 1, -1 do
    local w = wins[i]
    if w ~= cur_win and vim.api.nvim_win_is_valid(w) then
      local buf = vim.api.nvim_win_get_buf(w)
      local cfg = vim.api.nvim_win_get_config(w)
      local ft  = vim.bo[buf].filetype
      if cfg.relative == "" and ft ~= "neo-tree" then
        vim.api.nvim_set_current_win(w)
        return cur_win  -- merken, dass wir gewechselt haben
      end
    end
  end

  -- Kein normales Fenster gefunden → nichts tun, Neovim splittet dann halt wo es will
  return 0
end

-- ── Public API ───────────────────────────────────────────────────────────────

---@param result PdfPort.Result
---@param opts   PdfPort.RenderOpts
---@return nil
function M.render(result, opts)
  local path  = opts.path or ""
  local name  = buf_name(path)
  local bufnr = get_or_create_buf(name)
  local split = opts.split or "vsplit"
  local focus = opts.focus ~= false  -- default: true

  -- Filetype aus dem Extraktions-Format ableiten
  local ft = (result.format == "markdown") and "markdown" or "text"

  -- Text aufbereiten:
  --   1. vim.split trennt an \n
  --   2. strip_cr entfernt residuale \r (→ ^M) aus jedem Element
  local raw_lines = vim.split(result.text or "", "\n", { plain = true })
  local lines = {}
  for i = 1, #raw_lines do
    lines[i] = strip_cr(raw_lines[i])
  end

  -- Buffer befüllen
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.api.nvim_buf_set_option(bufnr, "buftype",    "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden",  "wipe")
  vim.api.nvim_buf_set_option(bufnr, "filetype",   ft)
  vim.api.nvim_buf_set_option(bufnr, "swapfile",   false)

  -- Dekorativer Header (ebenfalls ohne \r)
  local header = strip_cr(string.format(
    "<!-- pdfport: %s | backend: %s | format: %s -->",
    vim.fn.fnamemodify(path, ":t"),
    result.backend,
    result.format
  ))
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { header, "" })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- ── Split-Positionierung ─────────────────────────────────────────────────
  -- Sicherstellen, dass wir in einem echten Editor-Fenster sind, bevor
  -- wir splitten. So landet der neue Buffer immer rechts vom Editor,
  -- nicht links zwischen Neo-tree und dem vorherigen Fenster.
  local orig_win = ensure_editor_win()

  if split == "tab" then
    vim.cmd("tabnew")
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), bufnr)

  elseif split == "split" then
    vim.cmd("split")
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), bufnr)

  elseif split == "vsplit" then
    vim.cmd("vsplit")
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), bufnr)

  else
    -- split == nil: Buffer im aktuellen Fenster öffnen
    vim.api.nvim_win_set_buf(0, bufnr)
  end

  -- Wenn wir vorhin in ein anderes Fenster gewechselt sind, aber focus=false,
  -- zurück zum Original-Fenster (z. B. Neo-tree soll fokussiert bleiben).
  if not focus then
    if orig_win ~= 0 and vim.api.nvim_win_is_valid(orig_win) then
      vim.api.nvim_set_current_win(orig_win)
    else
      vim.cmd("wincmd p")
    end
  end
end

return M
