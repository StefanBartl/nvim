# Roadmap for `main-workstation` branch

## Table of content

- [Roadmap for `main-workstation` branch](#roadmap-for-main-workstation-branch)
  - [nvim: High](#nvim-high)
  - [nvim](#nvim)
  - [nvim: Low](#nvim-low)
    - [nvim markdown: Low](#nvim-markdown-low)
  - [nvim: Bugs](#nvim-bugs)
    - [`gopath.nvim`](#gopathnvim)
  - [Neotree](#neotree)
  - [Harpoon](#harpoon)

---

## nvim: High

1. `leader wq`: Alle issues lösen
2. Epressions, die auswerten auf welchen os wir sind, durch `system.env` ersetzen
3. `leader toc` sollte eigntlich das erste Level headline nicht angeben (h1_protected = true)

---

## nvim

1. ROADMAP.md durchgehen
2. nvim-containers: Neues feature testen usw...
3. `:Copy`
    1. hat keine ordentliche autocompletions
    2. `:Copy module [lua/c/js/...]` command, wobei die logik für das erstellen des modulpfades mit `:Isert module` geteilt werden kann
4. Vereinen von neotree keymaps filetree: preview;images;pdfprot
5. insert mode paste funktioert nicht
6. TODO usw.. durchgehen

---

## nvim: Low

2. Spellchecking nochmnal durchgehen und notizen machen. Spell Strategie ausarbeiten - entweder Plugin einbindne oder Modul debuggen
3. Durchsuchen %/cwd/path nach einen bestimmten String, alle Treffer sollen je nach eingabe mit char sumhüllt werden, zb ``, ''. "" oder **. Das soll abgefragt werden bzw bei einen usrcmd angegebn werden können wenn.
4. claude code . avante nvim plugin anschauen wenn lizernz da ist
5. repo_picker, dir_picker, usw... lässt es sich fusionieren?
6. Module als pugins auslagern: umso mehr aus der config weg ist, umso weniger lsp probleme wird es geben
7. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
8. In allen modulen  `/bindings` und dort dann
    - `usrcmds`
    - `keymaps`
    - `autocmds`
    - Wenn etwas beide ist, dann `Bindings` oder `Interaction` bzw. `InteractionLayer`

### nvim markdown: Low

1. strg+f/p soll auch mit count sein, also
    - `2, strg+f/p` soll 2 weiter vor/nach hinten springen
    - `2+leader, strg+f` soll zu nächsten/vorigen 2 level headline springen
2. `leader toc` sollte eigentlich unter jeder headline `---` sicherstellen
3. Einen `/config` Folder mit `/config/DEFAULTS.lua` in jedem Module und Plugin wo es sinn macht
4. `markdown_render`-implementieren in `:Markdown [] []` usrcmd
5. `usrcmds.collection` machen wenn diese nirgends anders zueprdnet werden können, dami die uscmds aus der init.lua rauskommen!

## nvim: Bugs

1. todo-comments problem mit end line.... einfach keywords eingben, dann schmeißt er in irgendwann

### `gopath.nvim`

17. `gopath.nvim` bug:

```lua
---@module 'custom.markdown.hl_options' -- <-- in diesem modul
--- ...
--- ...
local blockquote = require("custom.markdown.hl_options.hl_groups.blockquote") -- <-- funktoinert `gF` nicht, aber `gf` schon
```

9. `gopath`: solte eigentlich diesen pfad öffnen können:
    `.../AppData/Local/nvim/lua/config/neotree/commands/init.lua:13: module 'config.neotree.commads.markdown_links' not found:`

---

## Neotree

1. Folgender error:

```vim
   Error  10:54:33 msg_show.lua_error Lua callback:
...a/Local/nvim/lua/config/neotree/open/filemanager/win.lua:62: attempt to call upvalue 'cb' (a table value)
stack traceback:
	...a/Local/nvim/lua/config/neotree/open/filemanager/win.lua:62: in function 'on_exit'
	vim/_core/system.lua:388: in function <vim/_core/system.lua:358>
   Error  10:54:33 msg_show.emsg E486: Pattern not found: \<resolver_module\>
   Error  10:54:21 msg_show.lua_error Lua callback:
...a/Local/nvim/lua/config/neotree/open/filemanager/win.lua:62: attempt to call upvalue 'cb' (a table value)
stack traceback:
	...a/Local/nvim/lua/config/neotree/open/filemanager/win.lua:62: in function 'on_exit'
	vim/_core/system.lua:388: in function <vim/_core/system.lua:358>
```


## Harpoon

1. Es wäre sinnvoll, dass leader h einen neuen einrtag am ende der liste hinzufügt, nicht zu beginn

---
