# WKD Neovim Roadmap

- Alle mappings, autovmds und usercommand funktionen beiu Gelegenheit von `setup()` auf `attach()` umschreiben
- `pcall` doppelungen rauscoden

## Important Bugs

Snacks ~
 WARNING setup called *after* `VimEnter`
 WARNING `snacks.nvim` should not be lazy-loaded. Add `lazy=false` to the plugin spec
 WARNING `snacks.nvim` should have a priority of 1000 or higher. Add `priority=1000` to the plugin spec


Snacks.explorer ~
 WARNING setup {disabled}
 OK 'powershell' `In Zeile:1 Zeichen:3`
 OK System trash command found

Snacks.image ~
- WARNING setup {disabled}
- OK 'wezterm' `wezterm 20240203-110809-5046fc22`
- ERROR Tool not found: 'magick'
- ERROR `magick` is required to convert images. Only PNG files will be displayed.
- OK `wezterm` detected and supported
- WARNING `wezterm` does not support placeholders. Fallback rendering will be used
- WARNING Inline images are disabled
- OK Terminal Dimensions:
  - {size}: `1539` x `684` pixels
  - {scale}: `1.13`
  - {cell}: `9` x `18` pixels
- OK 'gs' `10.05.1`
- OK PDF files are supported
- ERROR None of the tools found: 'tectonic', 'pdflatex'
- WARNING `tectonic` or `pdflatex` is required to render LaTeX math expressions
- ERROR Tool not found: 'mmdc'
- WARNING `mmdc` is required to render Mermaid diagrams
- OK your terminal supports the kitty graphics protocol

Snacks.input ~
- WARNING setup {disabled}

Snacks.lazygit ~
- OK {lazygit} installed

Snacks.notifier ~
- WARNING setup {disabled}
- ERROR is not ready

Snacks.picker ~
- WARNING setup {disabled}
- WARNING `vim.ui.select` for `Snacks.picker` is not enabled


- MARKDOWN LSP:
- Wenn in einer Markdown File ein Codeblock ist und man fomratiert, dann sollte der Codeblock in der Sprache mit dem passenden FOrmatter formatiert werden, nicht mit marksman


- Telescope und FZF-Lua:
   - aktive zeilen weiß als Hintergrund probieren, zumindest aber eine kotrastreichere Option
   - In der Nähe der Prompt sollen nicht die Anzahl der Treffer angegeben werden, sondern auch, welches gerade selected ist, zb 32/74
- Custom Snacks Dashboard (CSD):  Manchmal, wenn man eine Datei öffnet, verschwindet das CSD nicht. Ich habe eigentlich eine Markdown Datei geöffnet, aber nur das CSD war weiterhin sichtbar. Weder `bclose` noch `:q` hat das CSD beendet. `set filetype?` hat jedoch `markdown` und nicht `snacks_dashboard` ergeben, was weird ist. Weiters änderte auch `:e test.lua` nichts daran, dass nur dsa CSD sichtba4r war, aber `set filetype?` hat num `lua` ergeben, was darauf hinweißt, dass die Dateien  schon in Buffer geladen wurden, nur das CSD es "unerreichbar" für mich überdeckt. Die einzige Möglichkeit, die ich gefunden habe, ist, `nvim` neu zu starten.
- `gf` funktioenrt nicht in lua, wenn der pfad zb `lua.mdview.huhu` idt und man aber `require("mdview.huhu")` hat


## Cleanup

1. `init.lua`: Statusline ausgliedern

## MIXED

- Picker, der zuerst alle wkdbooks auflistet zum auswählen, dann die files oder greps picked. Ähnlicjh wie `custom/repopickers`
- AUDIT's anschauen und durchgehen
- lokale funktionen wenn keine externe Referenz! Alle files durchgehen!
- mappings.custom erstellen, aus der dann markdown, pathprobe, usw aufgerufen werden, anstatt mappings.markdown, mappings.pathprobe usw..
- custom.diagnostics erstellen, extra_diagnostice mappings und usrcmds.diagnistcs hinein mergen, dann aus mappings.extra_diagnostics und usrcmds.diagnostics aus ausrufen
- keymaps.lua zu mappings.lua umbennen
- snacks dashboard überarbeiten
- ``- Backticks inline code color in Source code!


---

### new mapping, user_command, autocmd, etc.... ideas

---

### Long run

1. workspace lsp warnings debuggen
    1. alle `disable-next-line` durchsehen
2. pcall fpr alle require von custom modules
3. probieren nvchad rauszunehmen und nochmal mit lazyvim
4. experimental options:
   1. modularisieren, utilities ausgliedern usw...
   1. statusline und winbar breadcrumbs sollten sich ein modul teilen
5. typen aus dateien ableiten (custom bool ) ???
6. alle neuen scripte auf performance checken
7. Configs eventuell aufteilen auf eigene repo
8. @metas, @async sicherstellen
9. mylsp zu lsp mergen bzw. nachdneken, ob diese Aufteilung so Sinn macht (am Ende ist ja beides 'meine LSP-Config')
10. Überlegen, ob usrcmds nicht eigentlichs usercmds gennant werden sollen

---

## DOCS

1. Docs (README.md, help.txt and eventually ROADMAP.md) for every section.
2. `docs/plugins/translate.nvim.md` sollte besser ausgeführt sein

---

## MISC

1. `configs/*` nach dem Vorbild `configs/translate` implementieren

```sh
config/
└── somePluginCfg/
    ├── init.lua              -- Orchestrierung aller Submodule
    ├── smeFunctionality.lua  -- Implementierung von Funktionalitäten
    ├── usercommands.lua      -- Usercommands wie :somePluginFunctionality
    ├── keymaps.lua           -- Keymaps für somePlugin
    └── types/                -- Typdefinitionen
        └── *.lua
docs/
└── plugins/
    └── somePluginCfg/
        ├── README.md
        └── help.txt
```

---

## Terminals

### QOF

1. bclose, also leader bc und wrsch auch leader bx schließen nur das die shell im terminal buffer, überigt bleibt dann ein leerer Buffer den man nochmal schließen muss
2. `ctrl l` im terminal-mode sollte ein clear ausführen so wie in 'normalen' üblich. chansend funktioniert nicht, Nicht-Beispiel:

    ```lua
	-- Terminal-Insert-Modus Ctrl-l Mapping
	vim.keymap.set("t", "<C-l>", function()
			local term_id = vim.b.terminal_job_id
			if term_id then
					-- Windows: cls, sonst clear
					local cmd = vim.fn.has("win32") == 1 and "cls" or "clear"
					vim.fn.chansend(term_id, cmd .. "\n")
			end
	end, { noremap = true, silent = true })
    ```

---

## Treesitter

1. Mit `%` sollte man auch in Markdown Headings zum Ende des Blocks springen:
Beispiel: Wenn man mit dem Cursor in einem `##`-Heading steht und `%` auslöst, dann Sprung an den Ende des Abschnitt auslöst, dann Sprung an den Ende des Abschnitts.
Es gibt installierte Plugins, die eventuell wichtig sind:
- `vim-matchup` in `plugins/editing.lua`:
```lua
	{
		'andymass/vim-matchup',
		lazy = false, -- or ft = { "lua", "vim", "c", "cpp", "python", "typescript", "javascript", "html", "tex" },
		init = function()
			-- Disable parenthesis highlight only
			vim.g.matchup_matchparen_enabled = 1 -- no MatchParen highlight
			vim.g.matchup_matchparen_deferred = 1 -- no delayed flashes
			-- vim.g.matchup_matchparen_offscreen = {} -- no offscreen popup
			vim.g.matchup_matchparen_offscreen = { method = "status" } -- Show off-screen matches in a popup/status
		end,
		opts = {
			treesitter = {
				-- Limit how far match-up looks around the cursor with Tree-sitter.
				-- Larger values increase range but may be slower on huge files.
				stopline = 500,
			},
		},
	},
```
---

