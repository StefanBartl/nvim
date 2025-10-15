# WKD Neovim Roadmap

## Cleanup

1. `init.lua`: Statusline ausgliedern

## MIXED

- Picker, der zuerst alle wkdbooks auflistet zum auswählen, dann die files oder greps picked. Ähnlicjh wie `custom/repopickers`
- harpoon verliert persist files wenn ctx switch, command und keymap um persit fiels dynamisch zu injecten
- leader mhD funktioniert erst, wenn man einmal alles mit C-v markiert hat oder keine Markierung - dann aber nur in der aktuellen headline - dann escaped, und dann leader mhD/I ausführt
   - markdown mappings/utils/markdown, mappings/marjkdown, utils/markdown und /utils/markdown_headings zusammenholen
- workspace lsp warnings debuggen
- AUDIT's anschauen und durchgehen
- diagnostic disable-next-line usw. auflösen
- pcall fpr alle require von custom modules
- lokale funktionen wenn keine externe Referenz! Alle files durchgehen!
- extra_diagnostice mappings und usrcmds.diagnistcs mergen

---

### new mapping, user_command, autocmd, etc.... ideas

---

### Long run

1. alle `disable-next-line` durchsehen
2. neues in den main-kanal geben, denn lazyvim ist nicht so super im cmp, bios dahinn...
3. probieren nvchad rauszunehmen und nochmal mit lazyvim
4. experimental options:
   1. modularisieren, utilities ausgliedern usw...
   1. statusline und winbar breadcrumbs sollten sich ein modul teilen
5. smart_edit und lib.insert_line_above mergen
6. typen aus dateien ableiten (custom bool )
7. alle neuen scripte auf performance checken
8. Configs eventuell aufteilen auf eigene repo
9. @metas, @async sicherstellen
10. mylsp zu lsp mergen bzw. nachdneken, ob diese Aufteilung so Sinn macht (am Ende ist ja beides 'meine LSP-Config')
11. Überlegen, ob usrcmds nicht eigentlichs usercmds gennant werden sollen

---

## DOCS

1. Docs (README.md, help.txt and eventually ROADMYP.md) for every section.

---

## MISC

1. Beim Start wird das klassiche NVIM No Buffer Dashboard geladen, welches dann vom Snacks Dashboard überschreiben wird. Eigentlich sollte das erste nicht sichtbar sein, ich weiß nicht, ob es deswegen sichtbar ist, weil das Snacks Dashboard "länger" als früher (da war das snicht so) zum laden benötigt aufgrund des Custom Snacks Session Dashboard.

---

## Terminals

1. Es sollte, wenn möglich, eine neue Wezterm Instanz als Terminal erstellt werden. In Windows in jeden Fall mindestens Powershell, nur als Fallback eine 'CMD'-Shell

---

## Sessions

- `last`-file sollte nicht ständig noise in `git` machen, dass es geändert wurde. Eine Lösung wäre, dass `last` eine grundsätzlich nicht im git index upgedatete file ist, sondern immer lokal bleibt, während sessions, die auf anderen Geräten verwendet werden sollen, mit Labels abgespeichert werden.

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


## `folke/todo-comments`

1. In markdown files sollten die keywords vorghehoben werden

---
