# 🎯 Markdown Heading Navigation mit `%`

## Analyse der Anforderung

Du möchtest:
```markdown
## Heading                    <-- Cursor hier, % drücken
Some content
More content
                              <-- Springt hierhin (Ende des Abschnitts)
## Next Heading
```

---

## 🔍 Problem: `vim-matchup` kennt keine Markdown-Heading-Semantik

`vim-matchup` basiert auf:
1. **Treesitter-Nodes** (z.B. `if`↔`end`)
2. **Regex-Patterns** (z.B. `\begin{}`↔`\end{}`)

Markdown-Headings haben **keine expliziten End-Delimiter** → `vim-matchup` kann das nicht nativ.

---

## ✅ Lösung: Custom Implementation in deinem Markdown-Modul

Ich empfehle **zwei Ansätze**:

### **Ansatz 1: Eigene `%`-Mapping in Markdown** (Empfohlen)
### **Ansatz 2: `vim-matchup` erweitern** (Komplexer)

---

## 🚀 Ansatz 1: Custom `%`-Mapping (Empfohlen)

### Neue Datei: `/custom/markdown/autocmds/heading_jump.lua`

```lua
---@module 'custom.markdown.autocmds.heading_jump'
--- Jump to end of current heading section with %.

local M = {}

--- Get heading level from line (e.g., "## Title" -> 2)
---@param line string
---@return integer|nil level (1-6 or nil if not a heading)
local function get_heading_level(line)
  local hashes = line:match("^(#+)%s")
  if hashes then
    return #hashes
  end
  return nil
end

--- Find end of current heading section.
---@param start_line integer Current line number (1-indexed)
---@param level integer Heading level (1-6)
---@return integer end_line Line number of section end
local function find_section_end(start_line, level)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local total_lines = #lines

  -- Search forward for next heading of same or higher level
  for i = start_line + 1, total_lines do
    local next_level = get_heading_level(lines[i])
    if next_level and next_level <= level then
      -- Found next section, go to line before it
      return i - 1
    end
  end

  -- No next heading found, go to end of file
  return total_lines
end

--- Jump to end of current heading section.
---@return nil
function M.jump_to_section_end()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local line_text = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]

  local level = get_heading_level(line_text)

  if not level then
    -- Not on a heading, fallback to vim-matchup's %
    vim.cmd("normal! %")
    return
  end

  local end_line = find_section_end(current_line, level)

  -- Move cursor to end of section
  vim.api.nvim_win_set_cursor(0, { end_line, 0 })

  -- Optional: Center screen
  vim.cmd("normal! zz")
end

--- Enable heading jump autocmd.
---@param cfg table Configuration
---@return nil
function M.enable(cfg)
  if not cfg.enable then return end

  local aug = vim.api.nvim_create_augroup("markdown_heading_jump", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = "markdown",
    callback = function()
      -- Override % in Markdown buffers
      vim.keymap.set("n", "%", function()
        M.jump_to_section_end()
      end, {
        buffer = true,
        desc = "Jump to end of heading section or matchup %",
        silent = true,
      })
    end,
    desc = "Markdown: Custom % to jump to section end",
  })
end

return M
```

---

### Integration in `/custom/markdown/autocmds/init.lua`

```lua
---@class MdAutoCmdsCfg
---@field wrap_key MdAutoCmdsWrapKeyCfg
---@field goto_file MdAutoCmdsGotoFileCfg
---@field heading_jump MdAutoCmdsHeadingJumpCfg  -- NEU

--- Default configuration
---@type MdAutoCmdsCfg
local Defaults = {
  wrap_key = { ... },
  goto_file = { ... },
  heading_jump = {                                -- NEU
    enable = true,
  },
}

function M.setup(opts)
  if not cfg().enable_autocmds then return end

  opts = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), opts or {})

  -- ... existing code ...

  -- Enable submodule features
  require("custom.markdown.autocmds.wrap_key").enable(opts.wrap_key)
  require("custom.markdown.autocmds.goto_file").enable(opts.goto_file)
  require("custom.markdown.autocmds.heading_jump").enable(opts.heading_jump)  -- NEU
end
```

---

### Types-Datei: `/custom/markdown/autocmds/types.lua`

```lua
---@class MdAutoCmdsHeadingJumpCfg
---@field enable boolean  -- Enable custom % mapping for heading navigation

---@class MdAutoCmdsCfg
---@field wrap_key MdAutoCmdsWrapKeyCfg
---@field goto_file MdAutoCmdsGotoFileCfg
---@field heading_jump MdAutoCmdsHeadingJumpCfg  -- NEU
```

---

### Aktivierung in `/autocmds/init.lua`

```lua
------------------------------------------------------
--- Markdown
------------------------------------------------------

require("custom.markdown.autocmds").setup({
  wrap_key = { ... },
  goto_file = { ... },
  heading_jump = {              -- NEU
    enable = true,
  },
})
```

---

## 🎮 Verhalten nach Implementation

### Szenario 1: Cursor auf Heading
```markdown
## Section A          <-- Cursor hier, % drücken
Content line 1
Content line 2
Content line 3
                      <-- Springt hierhin (letzte Zeile vor nächstem Heading)
## Section B
```

### Szenario 2: Cursor NICHT auf Heading
```markdown
Some text with (parentheses)  <-- % verhält sich normal (vim-matchup)

## Heading
Code: function() end          <-- % springt zwischen function↔end
```

### Szenario 3: Verschachtelte Headings
```markdown
# Main Section           <-- Cursor hier, %
## Subsection 1
Content
## Subsection 2
Content
                         <-- Springt hierhin (Ende des # Main Section)
# Next Main Section
```

---

## 🔄 Erweiterungen (Optional)

### 1. **Bidirektional Jump** (% toggle)

Zweites `%` springt zurück zum Heading:

```lua
local last_jump = nil

function M.jump_to_section_end()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  -- Toggle: if we're at section end, jump back to heading
  if last_jump and current_line == last_jump.end_line then
    vim.api.nvim_win_set_cursor(0, { last_jump.start_line, 0 })
    last_jump = nil
    return
  end

  -- ... existing jump logic ...

  -- Store jump for toggle
  last_jump = { start_line = current_line, end_line = end_line }
end
```

---

### 2. **Visual Mode Support**

Selektiere ganzen Abschnitt:

```lua
function M.enable(cfg)
  -- ... existing normal mode mapping ...

  -- Visual mode: select section
  vim.keymap.set("v", "%", function()
    local start = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(0, start - 1, start, false)[1]
    local level = get_heading_level(line)

    if level then
      local end_line = find_section_end(start, level)
      vim.cmd("normal! V")  -- Enter line-wise visual
      vim.api.nvim_win_set_cursor(0, { end_line, 0 })
    end
  end, { buffer = true, desc = "Select heading section" })
end
```

---

### 3. **Text Objects** (wie `i%`, `a%`)

```lua
-- "Inner" section (ohne Heading-Zeile)
vim.keymap.set({ "o", "x" }, "ih", function()
  local start = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, start - 1, start, false)[1]
  local level = get_heading_level(line)

  if level then
    local end_line = find_section_end(start, level)
    vim.cmd(string.format("normal! %dGV%dG", start + 1, end_line))
  end
end, { buffer = true, desc = "Inner heading section" })

-- "Around" section (mit Heading-Zeile)
vim.keymap.set({ "o", "x" }, "ah", function()
  -- ... ähnlich, aber ab start statt start+1
end, { buffer = true, desc = "Around heading section" })
```

---

## 🧪 Testing-Checkliste

| Status | Test | Erwartung |
|--------|------|-----------|
| `[ ]` | Cursor auf `##` → `%` | Springt zu Ende des Abschnitts |
| `[ ]` | Cursor auf `#` mit Sub-Headings | Springt über alle Subsections |
| `[ ]` | Cursor NICHT auf Heading → `%` | Fallback zu vim-matchup (Klammern etc.) |
| `[ ]` | Letztes Heading im Dokument → `%` | Springt zu EOF |
| `[ ]` | Code-Block in Heading-Section → `%` | vim-matchup funktioniert normal |
| `[ ]` | Visual Mode `%` (optional) | Selektiert ganzen Abschnitt |

---

## 📊 Performance-Check

| Aspekt | Bewertung | Begründung |
|--------|-----------|------------|
| Zeitkomplexität | O(n) | Linearer Scan bis nächstes Heading |
| Speicher | O(1) | Keine zusätzlichen Strukturen |
| Große Dateien | ⚠️ Mittel | Bei 10k+ Zeilen evtl. spürbar |

**Optimierung** (falls nötig):
```lua
-- Begrenze Scan-Reichweite
local max_scan_lines = 1000  -- ~2-3 Bildschirme
for i = start_line + 1, math.min(start_line + max_scan_lines, total_lines) do
  -- ...
end
```

---

## 🎯 Warum nicht `vim-matchup` erweitern?

**Ansatz 2** wäre möglich, aber:

❌ **Komplexer**: Benötigt Treesitter-Query-Modifikation
❌ **Fragil**: Updates von `vim-matchup` können brechen
❌ **Overhead**: vim-matchup lädt für alle Filetypes

✅ **Custom Lösung**: Sauber getrennt, wartbar, nur für Markdown

---

## 📝 Installation Summary

1. ✅ Neue Datei: `/custom/markdown/autocmds/heading_jump.lua`
2. ✅ Update: `/custom/markdown/autocmds/init.lua` (Submodul laden)
3. ✅ Update: `/custom/markdown/autocmds/types.lua` (Typen)
4. ✅ Update: `/autocmds/init.lua` (Aktivierung)

**Priorität**: 🟡 EMPFOHLEN (nice QoL-Feature, niedrige Komplexität)

---

Soll ich die vollständige Implementation mit allen Dateien als Artifacts ausgeben? 🚀
