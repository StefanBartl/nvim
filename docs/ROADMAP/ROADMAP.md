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

## nvim: ZIEL

1. ROADMAP.md durchgehen
2. Alle plugin fähigen Module augliedern
3. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
4. TODO usw.. durchgehen
5. Checklisten anwenden
  1. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?

---

## CUSTOM PLUGINS

1. Module und Plugins durchgehen und CHEATSHEETS schreibenm. Jedes repo soll auch eigene /docs/BINDINGS.lua haben mit allen keymaps, usrcmds aber auch die autocmds!
2. `lib.nvim` auf alle plugins anwenden (als dependency)
3. Alle .nvim pluigfins eine .vim version erstellen (wenn notwendig fc)
4. Checklisten anwenden: Bestes Modell Bester Modus
  1. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
  2. Weitere fetures, usrcmds, keymaps, autocmds ROADMAP erstellen
  3. In der `README.md` badges und toc
5. ist es möglioch die neotree inteegrierung von pdfport innerhal podfports zu belassen?
6. Weenn fertig: alles auf remote stellen statt lokal
7. gopath auf main stellen, alle anderen auch
8. Format.nvim - Nummerieungen zu checkboxen uwmandeln;weoter featuresderart
9. Alle features testen
10. Sind alle Plugins `lazy`?
11. `:checkhealth` sollten alle module haben^
12. `objtrack`
13. `monkeypatch` noch sinnvoll? besser ausbauen

---

## nvim: High

1. `leader wq`: Alle issues lösen
2. Epressions, die auswerten auf welchen os wir sind, durch `system.env` ersetzen
3. [avante](./avante.md) letzter teil umsetzen1
  1. avante: usrcmds erstellen
  2. gp. gegen avante testen
4. center in neotree: wen nich mit der maus scrolle, dase centered es, was mühasm ist
5. wkdoptiuons UI Linemarker gehört README
6. wkdoptions mit options.lua verheiraten
7. manchmal briucht C-c mit sigint nvim ab, es solte aber alles kopieren des buffers
8. `nvim/init.lua` durchgehen
9. `/plugins/personal.lua`: Einbauen, dass wenn die `vim.env.REPOS_DIR` nicht da ist zuerst gecheckt wird, ob es einen `/repos`-Ordner im root der Laufwerke gibt, wenn ja, check das, wenn nein alle plugins automatisch auf remote umstellen. So müsste es eigentlich immer passen. Ein notify immer dann, wenn es keine REPOS_DIR variable gibt damit man daraauf hingewiesen wird.

---

## nvim

1. lsp: Einen switch einbauen, mitdem ich regeln kann, was der root für lsp ist: Switch zwischen cwd/nächstes_git/pfad/

---

## nvim: Bugs

1. mehrere Zeilen markiert, dann verscuht zu identen: `A-Rght`:
```vim
   Error  10:56:34 AM msg_show.emsg E5108: Lua: ...cal/nvim/lua/mappings/utils/line_renumbering/helpers.lua:28: 'start' is higher than 'end'
stack traceback:
	[C]: in function 'nvim_buf_set_lines'
	...cal/nvim/lua/mappings/utils/line_renumbering/helpers.lua:28: in function 'shift_line'
	...cal/nvim/lua/mappings/utils/line_renumbering/helpers.lua:38: in function 'shift_range'
	.../StefanBartl/AppData/Local/nvim/lua/mappings/editing.lua:151: in function 'visual_shift'
	.../StefanBartl/AppData/Local/nvim/lua/mappings/editing.lua:163: in function <.../StefanBartl/AppData/Local/nvim/lua/mappings/editing.lua:162>

```
1. `leader toc` sollter sicherstellen, dass am ende jeder Headline ein `---` ist.
2. `ZenMode` sollte auch eienen usrcmds toggle schalter haben
3. `:Emojis clear` entfern korrekt di eEmjois, hinterlässt aber einen char leerzeivchen dort wo das emoji war. das solte auch entfernt wereden


---

## nvim: Low

1. Spellchecking nochmnal durchgehen und notizen machen. Spell Strategie ausarbeiten - entweder Plugin einbindne oder Modul debuggen
2. Durchsuchen %/cwd/path nach einen bestimmten String, alle Treffer sollen je nach eingabe mit char sumhüllt werden, zb ``, ''. "" oder **. Das soll abgefragt werden bzw bei einen usrcmd angegebn werden können wenn.
3. In allen modulen  `/bindings` und dort dann
    - `usrcmds`
    - `keymaps`
    - `autocmds` - sind zentralisiert !
    - Wenn etwas beide ist, dann `Bindings` oder `Interaction` bzw. `InteractionLayer`

---

### nvim markdown: Low

1. Einen `/config` Folder mit `/config/DEFAULTS.lua` in jedem Module und Plugin wo es sinn macht
2. `markdown_render`-implementieren in `:Markdown [] []` usrcmd
3. `usrcmds.collection` machen wenn diese nirgends anders zueprdnet werden können, dami die uscmds aus der init.lua rauskommen!
4. `:MARKDOWN create fs`: Neuer usrcmd, soll zb.: wenn hier alle Zeilen markiert sind, dann soll es alle Pfade die enthalten sind in der markierung anlegen, sofern sie noch nicht existieren:

[PART 1 - Projects I](./PART1/Intro.md)
[PART 2 - Licensing](./PART2/Intro.md)
[PART 3 - Projects II](./PART3/Intro.md)
[PART 4 - DEX and CICD](./PART4/Intro.md)
[PART 5 - Logs](./PART5/Intro.md)

Erzeugt / stellt sicher, dass /PART1/Intro.md bis /PART5/Intro.md existieren
Wenn ees noch weitere interesxsante optioenn neben `fs` für das neue usrcmd `Markdown create` gibt, gerne!

---

## Neotree

1. Neotree: Keymaps auch als usrcmds implementieren, die in neotree aber auch nvim tree usw funktioenren, zb könte man dann alle folder eines ordnnenr pfad kopieren, und den rekuuriscen kevek angeben
2. Neotree, aktuelle zeile entweder hl oder vom cursor zum ersten char der node unterstrichen?
3. Folgender error:

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
