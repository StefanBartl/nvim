# Roadmap for `main-workstation` branch

## Table of content

  - [nvim: High](#nvim-high)
  - [nvim](#nvim)
  - [nvim: Bugs](#nvim-bugs)
  - [nvim: Low](#nvim-low)
    - [nvim markdown: Low](#nvim-markdown-low)
  - [Neotree](#neotree)
  - [Harpoon](#harpoon)

---

## nvim: High

1. `leader wq`: Alle issues lösen
2. Epressions, die auswerten auf welchen os wir sind, durch `system.env` ersetzen
3. `/custom/pathprope`, `/custom/pathfinder` && `gopath.nvim` vereiraten

---

## nvim

1. ROADMAP.md durchgehen
2. TODO usw.. durchgehen
3. Checklisten anwenden
4. lsp: Einen switch einbauen, mitdem ich regeln kann, was der root für lsp ist: Switch zwischen cwd/nächstes_git/pfad/

---

## nvim: Bugs

1. `:Gather Lua`

---

## nvim: Low

1. Spellchecking nochmnal durchgehen und notizen machen. Spell Strategie ausarbeiten - entweder Plugin einbindne oder Modul debuggen
2. Durchsuchen %/cwd/path nach einen bestimmten String, alle Treffer sollen je nach eingabe mit char sumhüllt werden, zb ``, ''. "" oder **. Das soll abgefragt werden bzw bei einen usrcmd angegebn werden können wenn.
3. claude code . avante nvim plugin anschauen wenn lizernz da ist
4. repo_picker, dir_picker, usw... lässt es sich fusionieren?
5. Module als pugins auslagern: umso mehr aus der config weg ist, umso weniger lsp probleme wird es geben
6. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
7. In allen modulen  `/bindings` und dort dann
    - `usrcmds`
    - `keymaps`
    - `autocmds`
    - Wenn etwas beide ist, dann `Bindings` oder `Interaction` bzw. `InteractionLayer`

---

### nvim markdown: Low

1. Einen `/config` Folder mit `/config/DEFAULTS.lua` in jedem Module und Plugin wo es sinn macht
2. `markdown_render`-implementieren in `:Markdown [] []` usrcmd
3. `usrcmds.collection` machen wenn diese nirgends anders zueprdnet werden können, dami die uscmds aus der init.lua rauskommen!

---

## Neotree
1. Neotree, aktuelle zeile entweder hl oder vom cursor zum ersten char der node unterstrichen?

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

1. `config/neotree/ui`: Alle neotree ui relevqanten features dorthin geben

---

### Neotree: LOW

1. Vereinen von neotree keymaps filetree: preview;images;pdfprot

---
