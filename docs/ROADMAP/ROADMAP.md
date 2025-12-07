# WKD Neovim Roadmap

## MIXED

- lsp.tools behandeln
- [nvim install doc](./NVIM-Install Doc/install_notes.md) fertig aufteilen

## ideas

- lua annotationen auskomenteren geht nicht, weil --- zu - gemacht wird
- :messages aktualisert sich nicht, wenn man neue einträge reinbekomt
- Picker, der zuerst alle wkdbooks auflistet zum auswählen, dann die files oder greps picked. Ähnlicjh wie `custom/repopickers`

## Long run

1. workspace lsp warnings debuggen
    1. alle `disable-next-line` durchsehen
    2. Todo Coments anschauen und durchgehen
2. pcall fpr alle require von custom modules
3. probieren nvchad rauszunehmen und nochmal mit lazyvim
4. experimental options:
   1. statusline und winbar breadcrumbs sollten sich ein modul teilen

--

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

