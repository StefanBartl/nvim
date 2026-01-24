---@module 'wkdoptions.config'
--- Central, single configuration table for both subsystems.
--- How to reload after a change in this file:
---   :luafile %          -- executes the current file buffer
---   :source %           -- alternative reload
--- Live updates via user commands:
---   :MyHlSet {key} {value}   -- operates within cfg.highlight
---   :MyOptSet {key} {value}  -- operates within cfg.options
--- Key completion is provided and values are parsed as bool/number/string automatically.

local M = {}

---@type WKDOptions.Config
M.cfg = {

  ---@type WKDOptions.HL_CFG
  highlight = {
    enable_line = true, -- Aktiviert CursorLine im aktiven Fenster (per winhighlight); sehr geringe Kosten.
    enable_column = true, -- Aktiviert eine vertikale Cursorspalte (cursorcolumn); wird bei großen Dateien ggf. unterdrückt.
    color_persist = true, -- Reappliziert alle Custom-Highlight-Gruppen nach :colorscheme (ColorScheme-Autocmd).
    map_cursor_to_hl = true, -- Mappt 'guicursor' auf eigene HL-Gruppen (Cursor / CursorNormal/Insert/…); fällt robust zurück.
    min_colored_file_kb = 4096, -- Dateigrößenschwelle (KiB) ab der 'cursorcolumn' und ähnliche Spalteneffekte deaktiviert werden.

    enable_indent_scope = false, -- Hebt den umgebenden Einrückungsblock im sichtbaren Viewport hervor (vollzeilig).

    enable_yank_flash = true, -- Kurzer Flash des yanked Bereichs (TextYankPost) mit Gruppe 'YankFlash'; nur visuelles Feedback.
    enable_put_flash = true, -- Kurzer Flash des gerade eingefügten Bereichs; nutzt '['/']'-Marks nach dem Put.
    map_put_flash = true, -- Installiert sichere p/P-Mappings, um Put-Flash zuverlässig zu triggern (non-recursive).
    enable_signcolumn_tint = true, -- Tönt die SignColumn je nach schlimmster Diagnostic-Severity; Zeichen selbst bleiben unverändert.
    enable_terminal_palette = true, -- Vereinheitlicht Terminal-Fenster (TermOpen) via winhighlight: Normal→TermNormal, CursorLine→TermCursorLine.
    enable_insert_submode_colors = true, -- Tönt CursorLine je Modus (N/I/V/R) und optional per-mode Cursor-Gesichter (guicursor).

    enable_current_word = true, -- Unterstreicht das aktuelle Wort (außer in Insert) mittels matchadd("CursorWord", …).
    cword_occurrences = {
      enabled = true, -- Master switch for painting occurrences.
      render = "underdashed", -- Rendering mode: "highlight" or one of the underline variants.
      underline_color = "#5FB0FC", -- Special color (`sp`) for underline-like modes (ignored for "highlight"). f.e. "#5FB0FC"
      force_plain_underline = true, -- Always include plain underline as safety fallback on weak UIs.
      marking = "word", -- Slice to render: "leadingchar"|"word"|"tailchar"|"firstN".
      firstN = 1, -- Number of leading bytes when marking == "firstN".
      viewport_only = true, -- Restrict scanning to the visible window lines for performance.
      min_len = 2, -- Minimum <cword> length to trigger decoration (in bytes).
      smart_case = true, -- Use \c unless <cword> contains uppercase, then \C (strict case).
      case_mode = "sensitive",
      match_kind = "exact",
      in_insert = false, -- Keep decorations active during Insert mode (more CPU) if true.
      hl = "CwordOccur", -- Highlight group for full-word slices when render == "highlight".
      hl_lead = "CwordOccurLead", -- Highlight group for partial slices (lead/tail/firstN) when "highlight".
      hl_attr = { bg = "#334155" }, -- Fallback attrs for `hl` if the group is missing or empty.
      hl_lead_attr = { bg = "#475569" }, -- Fallback attrs for `hl_lead` if the group is missing or empty.
      priority = 9, -- Extmark priority relative to other highlights.
      debounce_ms = 40, -- Debounce interval for repaint after movement/edits.
      large_file_kb = nil, -- Optional per-feature guard threshold (KiB); nil → inherit global.
    },

    enable_diff_peek = true, -- Weist 'gh' zum Gitsigns-Hunk-Preview zu (falls vorhanden); sonst Hinweis.
    large_file_kb = 5000, -- Globale Schranke (KiB) für „teuerere“ Effekte (z. B. Indent-Scope), um Performance zu wahren.

    enable_breadcrumbs = false, -- Aktiviert kompakte Breadcrumbs in der winbar (Repo-relativer Pfad + optional Symbolkette).
    breadcrumbs_max_len = 120, -- Maximale Länge der Breadcrumb-Zeile; Mittelteil wird bei Überschreitung ellipsisiert.
    breadcrumbs_separator = nil, -- If set, used verbatim as separator (with surrounding spaces as given). Example: " ⟩ " or " | "
    breadcrumbs_nerd_hex = "f0058", -- If set (and breadcrumbs_separator is nil), try Nerd Font glyph by hex codepoint. -- Example: "f0058" (case-insensitive). Falls back automatisch auf Unicode-Pfeile.

    breadcrumbs_ctx = {
      lua_table_root = {
        enable = true,
        mode = "only",
      },
      prefer_owner_in_literals = true, -- In Objekt-/Tabellen-Literalen Owner statt Funktionssymbol bevorzugen
      prefer_owner_on_member_access = true, -- Bei member access (a.b, obj:method) Owner bevorzugen
      dedupe_containers = true, -- Doppelte Containerteile entfernen ("M.M" -> "M")
      prefer_lsp_function = true, -- Prefer LSP function name first (b:lsp_current_function) for quick, low-cost context.
      use_treesitter_symbol = true, -- Build a semantic symbol path via Tree-sitter (e.g., Class → method()).
      use_container_chain = true, -- Prepend an owner/container (e.g., Module.Class) to the symbol when detectable.
      fallback_object_when_empty = true, -- If no symbol was found, try to use a useful object/owner under the cursor as fallback.
      fallback_word_when_empty = true, -- Final fallback: use the plain <cword> (outside Insert mode) to avoid empty context.
      use_lang_specific = true, -- Enable lightweight, language-specific heuristics (Lua/JS/TS/Python/Go).
      container_join = ".", -- Join string between container and symbol (e.g., ".", "::", " · ").
      container_max_depth = 2, -- Maximum number of container segments to collect (keeps chains compact).
      providers_order = { "lsp_func", "ts_symbol", "container", "lang_extra", "word" }, -- Provider order: tried in sequence until context is produced. Supported entries: "lsp_func", "ts_symbol", "container", "lang_extra", "word".
    },

    -- Colors used by the highlight module. Every key maps 1:1 to a :highlight group.
    -- All groups are defined globally (nvim_set_hl(0, ...)) and then referenced
    -- via winhighlight/guicursor where needed.
    ---@type HighlightColors
    colors = {
      -- Cursor line/column base tints
      CursorLine = { bg = "#2a2e36" }, -- Base tint for the cursor line when no per-mode tint is active
      CursorColumn = { bg = "#2a2e36" }, -- Subtle vertical guide under the cursor column
      CursorLineNr = { fg = "#ffd75f", bold = true }, -- Emphasized line number for the cursor line (focus anchor)
      LineNrDim = { fg = "#5a6374" }, -- Dimmed line numbers for side windows / non-focus contexts

      -- Per-mode CursorLine variants (used by winhighlight on ModeChanged)
      CursorLineN = { bg = "#2a2e36" }, -- CursorLine tint for Normal mode
      CursorLineI = { bg = "#24313a" }, -- CursorLine tint for Insert mode
      CursorLineV = { bg = "#322b3a" }, -- CursorLine tint for Visual/Select modes
      CursorLineR = { bg = "#3a2323" }, -- CursorLine tint for Replace/Op-pending variants

      -- Cursor faces (referenced by guicursor, per mode)
      Cursor = { bg = "#ff5f87", fg = "#1e1e1e" }, -- Unified fallback cursor face (when per-mode faces are off)
      CursorNormal = { bg = "#ffcc00", fg = "#1e1e1e" }, -- Cursor face in Normal mode
      CursorInsert = { bg = "#5fd7ff", fg = "#1e1e1e" }, -- Cursor face in Insert mode
      CursorVisual = { bg = "#ff5f2a", fg = "#1e1e1e" }, -- Cursor face in Visual mode
      CursorReplace = { bg = "#ff0000", fg = "#1e1e1e" }, -- Cursor face in Replace mode

      -- Short-lived flash regions (feedback for yank/paste)
      YankFlash = { bg = "#3e5f2a" }, -- Transient region to acknowledge yanks
      PutFlash = { bg = "#2a4d6b" }, -- Transient region to acknowledge puts

      -- SignColumn severity tint (worst diagnostic wins)
      SignColError = { bg = "#3a2323" }, -- SignColumn background when ERROR is present
      SignColWarn = { bg = "#3a3623" }, -- SignColumn background when WARN is present
      SignColInfo = { bg = "#22333e" }, -- SignColumn background when INFO is present
      SignColHint = { bg = "#1f2f2a" }, -- SignColumn background when HINT is present
      SignColNeutral = { bg = "NONE" }, -- Neutral SignColumn (no diagnostics or feature disabled)

      -- Terminal window palette (applied buffer-locally on TermOpen)
      TermNormal = { bg = "#151a1f" }, -- Normal background in terminal buffers
      TermCursorLine = { bg = "#20262d" }, -- CursorLine in terminal windows for alignment

      -- Current-word underline and matchparen face
      CursorWord = { underline = true }, -- Underline-only for the word under cursor (low noise)
      MatchParen = { bg = "#3b4048", bold = true }, -- Face used by the optional matchparen blink

      -- Indent scope block highlight (viewport-limited block around current indent)
      IndentScope = { bg = "#2f3440" }, -- Full-line background across the active indentation block
    },

    -- Skip rules (defaults match your original lists)
    winbar_skip = {
      only_normal_buffers = true, -- True: winbar nur in „normalen“ Buffern (buftype == ""); UIs/Prompts werden übersprungen.
      skip_floating = true, -- True: winbar in Float-Fenstern unterdrücken.
      min_height = 2, -- Unterdrücken, wenn Fensterhöhe zu klein ist (Platzwahrung).
      buftypes = { -- Buftypes, in denen winbar grundsätzlich nicht sinnvoll ist.
        "nofile",
        "prompt",
        "terminal",
        "quickfix",
        "help",
        "acwrite",
      },
      filetypes = { -- Filetypes/Plugin-UIs, in denen winbar vermieden wird (Picker, Explorer, Dashboards, …).
        "TelescopePrompt",
        "TelescopeResults",
        "fzf",
        "fzf-lua",
        "snacks_picker",
        "alpha",
        "dashboard",
        "starter",
        "neo-tree",
        "neo-tree-popup",
        "NvimTree",
        "oil",
        "aerial",
        "Outline",
        "trouble",
        "Trouble",
        "noice",
        "notify",
        "lazy",
        "mason",
        "LspInfo",
        "fugitive",
        "fugitiveblame",
        "NeogitStatus",
        "octo",
        "git",
        "gitcommit",
        "lazygit",
        "dapui_scopes",
        "dapui_breakpoints",
        "dapui_stacks",
        "dapui_watches",
        "dap-repl",
        "dapui_console",
        "help",
        "man",
        "qf",
        "checkhealth",
        "undotree",
        "which-key",
        "spectre_panel",
        "spectre_replace",
      },
      name_patterns = { -- Lua-Pattern auf den Buffer-Pfad/„Schema“-Namen (oil://, term://, …) zum Überspringen.
        "^oil://",
        "^term://",
        "^man://",
        ".*[\\/]neo%-tree[\\/].*",
        ".*[\\/]NvimTree[\\/].*",
        ".*[\\/]lazy[\\/].*",
        ".*[\\/]mason[\\/].*",
      },
    },

    indent_scope_skip = {
      only_normal_buffers = true, -- True: Indent-Scope nur für normale Datei-Buffer (keine Prompts/Terminals).
      skip_floating = true, -- True: in Float-Fenstern kein Indent-Scope (UI-Overlays etc.).
      buftypes = { -- Buftypes, in denen Blockmarkierung nie angewandt wird.
        "nofile",
        "prompt",
        "terminal",
        "quickfix",
        "help",
        "acwrite",
      },
      filetypes = { -- UIs/Seitenleisten/Pickers, die keine Blockfärbung erhalten sollen. AUDIT: remove
        "neo-tree",
        "neo-tree-popup",
        "NvimTree",
        "oil",
        "fzf",
        "fzf-lua",
        "TelescopePrompt",
        "TelescopeResults",
        "snacks_picker",
        "snacks_dashboard",
        "alpha",
        "dashboard",
        "starter",
        "aerial",
        "Outline",
        "trouble",
        "Trouble",
        "noice",
        "notify",
        "lazy",
        "mason",
        "LspInfo",
        "fugitive",
        "fugitiveblame",
        "NeogitStatus",
        "octo",
        "git",
        "gitcommit",
        "lazygit",
        "dapui_scopes",
        "dapui_breakpoints",
        "dapui_stacks",
        "dapui_watches",
        "dap-repl",
        "dapui_console",
        "help",
        "man",
        "qf",
        "checkhealth",
        "which-key",
        "spectre_panel",
        "spectre_replace",
        "neo-term",
        "minipick",
        "mini.files",
        "nvdash",
      },
      name_patterns = { -- AUDIT remove
        "^oil://",
        "^term://",
        "^man://",
        ".*[\\/]neo%-tree[\\/].*",
        ".*[\\/]NvimTree[\\/].*",
        ".*[\\/]lazy[\\/].*",
        ".*[\\/]mason[\\/].*",
      },
    },
  },

  ---@typeWKDOptions.HL_CFG.Utils.SkipCfg
  skip = {
    filetypes = {
      "neo-tree",
      "neo-tree-popup",
      "NvimTree",
      "oil",
      "fzf",
      "fzf-lua",
      "TelescopePrompt",
      "TelescopeResults",
      "snacks_picker",
      "snacks_dashboard",
      "alpha",
      "dashboard",
      "starter",
      "aerial",
      "Outline",
      "trouble",
      "Trouble",
      "noice",
      "notify",
      "lazy",
      "mason",
      "LspInfo",
      "fugitive",
      "fugitiveblame",
      "NeogitStatus",
      "octo",
      "git",
      "gitcommit",
      "lazygit",
      "dapui_scopes",
      "dapui_breakpoints",
      "dapui_stacks",
      "dapui_watches",
      "dap-repl",
      "dapui_console",
      "help",
      "man",
      "qf",
      "checkhealth",
      "which-key",
      "spectre_panel",
      "spectre_replace",
      "neo-term",
      "minipick",
      "mini.files",
      "nvdash",
    },
    name_patterns = {
      "^oil://",
      "^term://",
      "^man://",
      ".*[\\/]neo%-tree[\\/].*",
      ".*[\\/]NvimTree[\\/].*",
      ".*[\\/]lazy[\\/].*",
      ".*[\\/]mason[\\/].*",
    },
  },

  ---@type OptionsCfg
  options = {
    enable_matchparen = true, -- Aktiviert dezentes matchparen-Blinken (`showmatch`) bei Paarzeichen.
    matchtime_tenths = 2, -- Dauer des matchparen-Blinks in Zehntelsekunden (2 ≙ ~200 ms).
  },
}

-- Observer lists for re-apply hooks
M._after_set = { highlight = {}, options = {} }

-- Observer lists for re-apply hooks
M._after_set = { highlight = {}, options = {} }

--- Register after-set callback for a namespace ('highlight' | 'options').
---@param ns '"highlight"'|'"options"'
---@param fn fun(key:string):nil
---@return nil
function M.on_after_set(ns, fn)
  if type(fn) == "function" then
    table.insert(M._after_set[ns], fn)
  end
end

--- Parse a string token to boolean/number/string.
---@param s string|nil
---@return boolean|number|string
local function parse_value(s)
  if s == nil then
    return ""
  end
  local trimmed = s:gsub("^%s+", ""):gsub("%s+$", "")
  local unq = trimmed:match('^"(.*)"$') or trimmed:match("^'(.*)'$")
  if unq then
    return unq
  end
  local lower = trimmed:lower()
  if lower == "true" or lower == "on" or lower == "yes" or lower == "1" then
    return true
  end
  if lower == "false" or lower == "off" or lower == "no" or lower == "0" then
    return false
  end
  local num = tonumber(trimmed)
  if num ~= nil then
    return num
  end
  return trimmed
end

--- Set nested key in a table using a dot path.
---@param t table
---@param path string
---@param val any
---@param toggle_if_bool boolean
---@return boolean,string|nil
local function set_by_path(t, path, val, toggle_if_bool)
  local parts = vim.split(path, ".", { plain = true })
  if #parts == 0 then
    return false, "Empty key path"
  end
  local parent = t
  for i = 1, #parts - 1 do
    local seg = parts[i]
    if type(parent[seg]) ~= "table" then
      return false, ("Path segment '%s' is not a table"):format(seg)
    end
    parent = parent[seg]
  end
  local leaf = parts[#parts]
  if parent[leaf] == nil then
    return false, ("Unknown key '%s'"):format(path)
  end
  local old = parent[leaf]
  local oldt, newt = type(old), type(val)

  if oldt == "boolean" then
    if newt ~= "boolean" then
      if toggle_if_bool then
        parent[leaf] = not old
        return true
      end
      return false, ("Expected boolean for '%s'"):format(path)
    end
    parent[leaf] = val
    return true
  elseif oldt == "number" then
    if newt ~= "number" then
      return false, ("Expected number for '%s'"):format(path)
    end
    parent[leaf] = val
    return true
  elseif oldt == "string" then
    if newt ~= "string" then
      return false, ("Expected string for '%s'"):format(path)
    end
    parent[leaf] = val
    return true
  elseif oldt == "table" then
    return false, ("Set a leaf key within '%s' (e.g. '%s.bg')"):format(path, path)
  end
  parent[leaf] = val
  return true
end

--- Collect all leaf keys from a table (dot paths).
---@param root table
---@param prefix string|nil
---@param out string[]
local function collect_keys(root, prefix, out)
  prefix = prefix or ""
  for k, v in pairs(root) do
    local path = (prefix == "" and tostring(k)) or (prefix .. "." .. tostring(k))
    if type(v) == "table" then
      collect_keys(v, path, out)
    else
      out[#out + 1] = path
    end
  end
end

--- Public: parse a string into a typed value.
---@param s string|nil
---@return boolean|number|string
function M.parse(s)
  return parse_value(s)
end

--- Public: set a key in a namespace and trigger callbacks.
---@param ns '"highlight"'|'"options"'
---@param key string
---@param value any
---@param toggle_if_bool boolean
---@return boolean,string|nil
function M.set(ns, key, value, toggle_if_bool)
  local ok, err = set_by_path(M.cfg[ns], key, value, toggle_if_bool)
  if ok then
    for _, cb in ipairs(M._after_set[ns]) do
      pcall(cb, key)
    end
  end
  return ok, err
end

--- Public: list keys of a namespace for completion.
---@param ns '"highlight"'|'"options"'
---@return string[]
function M.keys(ns)
  local out = { [1] = "" }
  collect_keys(M.cfg[ns], "", out)
  table.remove(out, 1)
  table.sort(out)
  return out
end

return M
