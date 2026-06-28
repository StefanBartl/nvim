# Roadmap for `main-workstation` branch

- [ ]

## Table of content

- [Roadmap for `main-workstation` branch](#roadmap-for-main-workstation-branch)
  - [Table of content](#table-of-content)
  - [ZIEL](#ziel)
  - [High](#high)
  - [General](#general)
  - [Bugs](#bugs)
  - [Low](#low)
  - [Neotree](#neotree)
    - [Neotree: LOW](#neotree-low)

---

- mdview debuggen, dann als dependencsy in markdown.nvim implementieren

## ZIEL

1. ROADMAP.md durchgehen
2. Alle plugin fähigen Module augliedern
3. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
5. Checklisten anwenden
  1. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
  2. ToDo's duchgehen

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

1. tableview toggle sollt emit `q` bzw `Escape im Normal Mode` geschlossen werden können.
2. Manchmal funktioert `C-s` nicht mehr...
3. manchmal bricht `C-c` mit sigint nvim ab, es solte aber alles kopieren des buffers
4. Indenting von mehreren Zeilen funktiert zwar, aber manchmal springt dann der Fokus an irgendeine Stelle im Dokument. Warum ist das so und woe klan ich das verhindern?
5. indent (markeiert aber nicht sicher ob das wichtig ist) und dann nahc unten geshcoben, in der letzten Zeile angekommen folgenden error:

```vim
   Error  11:46:16 AM msg_show.emsg E5108: Lua: vim/_core/editor.lua:355: nvim_exec2(), line 1: Vim(move):E16: Invalid range
stack traceback:
	[C]: in function 'nvim_exec2'
	vim/_core/editor.lua:355: in function 'cmd'
	...rtl/AppData/Local/nvim/lua/bindings/mappings/editing.lua:71: in function <...rtl/AppData/Local/nvim/lua/bindings/mappings/editing.lua:70>
```

1. `:Open browser %` funktionert nicht, `:Open chrome %` schon

---

## Low

1. Spellchecking nochmnal durchgehen und notizen machen. Spell Strategie ausarbeiten - entweder Plugin einbindne oder Modul debuggen
2. Durchsuchen %/cwd/path nach einen bestimmten String, alle Treffer sollen je nach eingabe mit char sumhüllt werden, zb ``, ''. "" oder **. Das soll abgefragt werden bzw bei einen usrcmd angegebn werden können wenn.

---

## Neotree

1. neotree: .git folder soll default ausgebledet sein (ignored list), aber per keymap eitogglebar
2. Neotree: Keymaps auch als usrcmds implementieren, die in neotree aber auch nvim tree usw funktioenren, zb könte man dann alle folder eines ordnnenr pfad kopieren, und den rekuuriscen kevek angeben
3. Neotree, aktuelle zeile entweder hl oder vom cursor zum ersten char der node unterstrichen?
4. Folgender error:

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
2. Nach den gesamten Aufräumarbeiten checken, ob mit Snacks/image.nvim es nicht möglich ist, images zu öffnen

---
