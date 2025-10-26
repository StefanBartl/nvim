# Roadmap für die Markdown-Konfiguration

## toc

---

## `/custom/markdown`-Modul

1. inline code in backticks wie `function` wird fast immer nicht gehighlighted
2. leader mhD funktioniert erst, wenn man einmal alles mit C-v markiert hat oder keine Markierung - dann aber nur in der aktuellen headline - dann escaped, und dann leader mhD/I ausführt
3. markdown mappings/utils/markdown, mappings/marjkdown, utils/markdown und /utils/markdown_headings zusammenholen

---

### Folding

1. `zf` und `za` falten nicht korrekt, wenn weitere Unter-Headings da sind

--

### Headings

1. Increase & Decrease funktioniert im normal, visual und visual block modus, aber nicht im visual line.
2. Wenn der Cursor in der Zeile eines Headings ist, so wird dieses momentan von der üblichen Headline-Color zur normalen COlor des Textes geändert. Besser wäre, wenn das Heading, ein der der Cursor gerade ist, sichtbarer Dargestellt wird. Entweder: Headline mit Hintergrundfarbe hervorheben, Headlinetext so belassen (füür Kontrast) oder Textfarbe der Headline ändern, so dass si sichtbarer ist oder beides, also Textfarbe ändern + Hntergrundfarbe platzieren.

### `/custom/markdown` als 'single source of truth' für Markdown config etablieren

Momentan wird in `/mappings/markdown` folgendes implemntiert:

```lua
function M.setup(opts)
  local md = require("custom.markdown")
  md.setup(vim.tbl_deep_extend("force", {
    enable_autocmds = true,
    enable_keymaps = true,
		ft_only = true,
  }, opts or {}))
end
```

1. BUG: Hier sollte nicht enable_autocmds implementiert werden

#### `/autocmds/markdown` mit `/custom/markdown/ui/autocmds/` zusammenführen

1. `/autocmds/markdown/types.lua` nach `/custom/markdown/autocmds/` verschieben
2. `/autocmds/markdown/init.lua` nach Funktionalitäten aufteilen und in neue `/custom/markdown/autocmds/{FIND_FILENAME}.lua`-files  migrieren
3. In `/autocmds/init.lua` ist folgendes zu finden:

```lua
------------------------------------------------------
--- Markdown
------------------------------------------------------

require("autocmds.markdown").enable({
	wrap_key = {
		enable = true, -- Registers a buffer-local mapping in Markdown buffers that atomically wraps <cword> as [word]().
		key = "<leader>[",
		description = "Wrap current word in Markdown link syntax",
		pattern = "markdown",
		only_modifiable = true,
	},
	goto_file = {
		enable = true,                 -- Overrides "gf" in Markdown: follows inline/reference links, opens URLs, resolves relative paths; otherwise falls back.
		debug = false,                 -- If true: emits step-by-step resolution messages via vim.notify.
		pattern = "markdown",
		enable_windows_opener = false, -- Default: Linux/macOS only; optionally enable a Windows opener.
		-- open_cmd_mac  = { "open", "<url>" },
		-- open_cmd_unix = { "xdg-open", "<url>" },
	},
})
```

Dies muss so angepasst werden, dass die neue `/custom/markdown/autocmds/init.lua` verwendet wird.

4. `/autocmds/markdown/autocmds/init.lua` muss neu angelegt werden. Dort sollen die Markdown Autocmd-Funktioinalitäten gebündelt werden. Die beretis bestehende `custom/markdown/autocmd.lua` soll mit dieser Datei gemerged werden bzw. kann als Vorlage dienen. Der Inhalt der `/custom/markdown /autocmd.lua` ist:

```lua
---@module 'custom.markdown.ui.autocmd'
--- Lightweight FileType hook (extensible).

local M = {}
local cfg = require("custom.markdown.config").get

---@return nil
function M.setup()
  if not cfg().enable_autocmds then return end
  local aug = vim.api.nvim_create_augroup("MarkdownSetup", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = { "markdown" },
    callback = function(_) end,
    desc = "Attach markdown utilities",
  })
end

return M
```

---

