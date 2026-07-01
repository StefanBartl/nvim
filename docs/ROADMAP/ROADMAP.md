# Roadmap for `main-workstation` branch
filetreepicker
- [ ]

## Table of content

  - [ZIEL](#ziel)
  - [High](#high)
  - [General](#general)
  - [Bugs](#bugs)
  - [menus](#menus)

---

- `leader[` toc funktiert ncih
- `C-a`: Sollte alles markieren
- Nach indent vcon mehreren zeilen verscwindet die markeirung udn wen man eins mehr indenten will, mus man neu markeiren. die markierung soll bleiben.
- github:stats.nvim besser machen
- :h dateien der neuen repositories sind dort nicht auzffindbar. `:h nvim-cmdlog` schon als beispiel. SOllten die nicht automatisch generiert werden?
 - mdview debuggen, dann als dependencsy in markdown.nvim implementieren

1. checken, ob mit Snacks/image.nvim es nicht möglich ist, images zu öffnen
2. mappings für telescope und fzf lua müssten eigentlich schon über piockers.nvim kommen?

## ZIEL

1. ROADMAP.md durchgehen
2. Alle plugin fähigen Module augliedern
3. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
4. Checklisten anwenden
  1. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
  2. ToDo's duchgehen
5. Branch küren (so wenig commits wit möglch, damit die .git folder nicht groß ist)

---

## High

1. `leader wq`: Alle issues lösen
2. Epressions, die auswerten auf welchen os wir sind, durch `system.env` ersetzen
3. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
4. `nvim/init.lua` durchgehen
5. `:Lazy` -> `todo-comments` + `ui` haben Updates - sind bei mir aber monkeypatched, also Sicherungskope der Files anlegen, Updaten und neu bewerten
6. lightbulb: Manchmal stört sie und ich möchhte das schnell ausblenden können, am besten mit Keymap togglebnar (markdown lsp)

---

## General

1. lsp: Einen switch einbauen, mitdem ich regeln kann, was der root für lsp ist: Switch zwischen cwd/nächstes_git/pfad/
2. `ZenMode` sollte auch eienen usrcmds toggle schalter haben

---

## Bugs

1. Manchmal funktioert `C-s` nicht mehr...
2. manchmal bricht `C-c` mit sigint nvim ab, es solte aber alles kopieren des buffers

- `---@module '...'` ist nicht hervorgeheben, obwohl lua_ls attached ist

  Treesitter in der Zeile:

  ```vim
  20:21:46 msg_show.list_cmd   Inspect Treesitter
    - @comment.lua links to @comment   priority: 100   language: lua
    - @spell.lua links to @spell   priority: 100   language: lua
    - @comment.documentation.lua links to @comment   priority: 100   language: lua
  ```

---

## menus

   Error  19:26:07 msg_show.lua_error vim.schedule callback: ...AppData/Local/nvim-data/lazy/menu/lua/menus/neo-tree.lua:17: attempt to call local 'cb' (a nil value)
stack traceback:
	...AppData/Local/nvim-data/lazy/menu/lua/menus/neo-tree.lua:17: in function 'fn'
	vim/_core/editor.lua:273: in function <vim/_core/editor.lua:272>

---

