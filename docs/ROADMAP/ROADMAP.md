# Roadmap for `main-workstation` branch

- [ ]

## Table of content

  - [nvim: ZIEL](#nvim-ziel)
  - [CUSTOM PLUGINS (`/***.nvim`)](#custom-plugins-nvim)
    - [`debugging.nvim`](#debuggingnvim)
    - [Verifikation für jedes feature jedes plugins](#verifikation-fr-jedes-feature-jedes-plugins)
  - [`markdown.nvim` && `mdlinks.nvim`](#markdownnvim-mdlinksnvim)
  - [`fileops.nvim`](#fileopsnvim)
  - [nvim: High](#nvim-high)
  - [nvim](#nvim)
  - [nvim: Bugs](#nvim-bugs)
  - [nvim: Low](#nvim-low)
  - [CHECK: linemarker](#check-linemarker)
    - [nvim markdown: Low](#nvim-markdown-low)
  - [Neotree](#neotree)
    - [Neotree: LOW](#neotree-low)

---

## nvim: ZIEL

1. ROADMAP.md durchgehen
2. Alle plugin fähigen Module augliedern
3. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
4. TODO usw.. durchgehen
5. Checklisten anwenden
  1. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?

---

## CUSTOM PLUGINS (`/***.nvim`)

1. Module und Plugins durchgehen und CHEATSHEETS schreibenm. Jedes repo soll auch eigene /docs/BINDINGS.lua haben mit allen keymaps, usrcmds aber auch die autocmds!
2. `lib.nvim` auf alle plugins anwenden (als dependency)
3. Alle .nvim pluigfins eine .vim version erstellen (wenn notwendig fc)
4. Checklisten anwenden:
  1. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
  2. Weitere fetures, usrcmds, keymaps, autocmds ROADMAP erstellen
  3. In der `README.md` badges und toc
5. ist es möglioch die neotree inteegrierung von pdfport innerhal podfports zu belassen?
6. Wenn fertig: alles auf remote stellen statt lokal
7. gopath auf main stellen, alle anderen auch
8. Format.nvim - Nummerieungen zu checkboxen uwmandeln;weoter featuresderart
9. Alle features testen
10. Sind alle Plugins `lazy`?
11. `:checkhealth` sollten alle module haben^
12. `objtrack` - Analysieren (merge mit anderen Plugin? Ausbau notwendig?)
13. `monkeypatch` noch sinnvoll? besser ausbauen
14. migrate.nvim fertig stellen
15. readme.md überprüfen auf
      - license
      - dir = vime.env... raus aus den READMEs
16. Alle Plugins auf implementierte NVIM-Filetree-Features checken, diese
      - jedenfalls so ausbauen, dass es in Neotree, NvimTree, Netrw...
      - aus den gesammelten Features und aus `/(nvim/lua/config/neotree` ein eigenes Plugin `neotee-features.nvim` erstellen
17. `sessions` plugijn würdig?
18. `/autcmds` passt zu `/bindings` ?
19. `config.lua` für plugin defaults, aber möglichst viele Features sollen vom user aus einstellbar sein, also zb.:

    ```lua
    {
      -- "StefanBartl/project-insight.nvim",
      dir = vim.env.REPOS_DIR .. "/project-insight.nvim",
      cmd = "ProjectInsight",
      config = function()
        require("project_insight").setup({
          -- symbols.use_treesitter_for_lua = true,  -- optionale TS-Variante für Lua
          compress = {
              outdir = "C:\temp",
              ---@type ProjectInsight.CompressEngine
              engine = "tar",
          },
        })
      end,
    },
    ```

Hier kann man die keys **Output dir** und **Compress Engine** als User explizit setzen und damit die `config.lua` Pluginseitige Defaults überschreiben.

Dazu ist noch eines wichtig: Um dem User ein sehr gutes LSP Erlebnis zu bieten, braucht jeder Key einen Typen, wie zb.:
`--@alias ProjectInsight.CompressEngine "auto"|"tar"|"zip"|"powershell"`

Jedes Plugin muss abgeklopft werden, ob es sinnvolle Optionen gibt, die noch nicht User-seitig gesetzt werden können.

20. Passen folgende usrcmds in ein `.nvim` Plugin von mir?

  ```lua
  --FIX: Funktoinert, aber einen neotree/nvimtree/netrw reload muss ausgelöst werden damit dieser aktualisert das neue cwd in ihm.
  vim.api.nvim_create_user_command("CwdHere", function()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname ~= "" then
      local dir = vim.fn.fnamemodify(bufname, ":p:h")
      vim.cmd("lcd " .. vim.fn.fnameescape(dir))
    end
  end, {})

  vim.api.nvim_create_user_command('PowershellProfile', function()
      if vim.fn.executable("powershell") ~= 1 then
          print("Fehler: powershell ist auf diesem System nicht verfügbar.")
          return
      end
      -- argv array instead of io.popen with an embedded shell string
      local res = vim.system(
          { "powershell", "-NoProfile", "-Command", "[Console]::Write($PROFILE)" },
          { text = true }
      ):wait()
      local profile_path = res.code == 0 and res.stdout or nil

      if profile_path and profile_path ~= "" then
          vim.cmd('edit ' .. vim.fn.fnameescape(profile_path))
          return
      end
      print("Fehler: Der PowerShell Profil-Pfad konnte nicht ermittelt werden.")
  end, { desc = 'Öffnet das aktuelle PowerShell-Profil' })
  ```

21. `mdlink` vs `mdlinks`?
22. Alle Plugins auf .nvim umstellen

---

### `lib.nvim`

- [ ] Overlay/Fenster müssem sich oft im Normal-Mode intuitiv über `q` oder `Escape` schließen lassen. Dies könnte man in einer `lib.nvim`-Funktion anbieten: `function close_window_with_keymap(win_id){ ... }` Somit müsste man das nicht in jedem Plugin extra implementieren. Derartige weitere Features möglich?

### Verifikation für jedes feature jedes plugins

**Beispiel:**
- **A**: `:Debug module reload` auf einer Lua-Datei → Modul wird neu geladen; `:checkhealth debugging` grün
- **B**: `:ProjectInsight archive` → Archiv in `~/temp/`; auf Windows mit PowerShell; `:checkhealth project-insight` grün
- **C**: `:Open` auf URL → Browser öffnet; auf Datei → Explorer/Finder; `:checkhealth open_nvim` grün
- **D**: `:Format trim`, `:Format sort`, `:Format column 40` auf Testbuffer; `:checkhealth buffer_ctx` grün
- **E**: `:Format markdown headline_separators` (falls API-Redirect) oder komplett gestrichen; markdown.nvim-Test
- **F**: require-Pfad in Config testen, `MarkLineToggle` + `MarkLinesYank` funktionieren
- **G**: `:Pickers notes files` → Picker öffnet; `NotesFiles` als Compat-Command; prefix-Collection listet Unterordner; `:checkhealth pickers` grün; alle alten `:Nvim*Files`-Commands funktionieren als Compat-Aliases

---

## `markdown.nvim` && `mdlinks.nvim` && `mdview.nvim`

1.  sollte auch `markdown/core/wrap_links` enthalten. Außerdem sicher gehen, dass `markdown/core/headline_spacing´ funktioniert. (am besten ganzen ex-ordner kopieren)
2. `mdlinks.nvim` in `markdown.nvim` implementieren und dann auf nicht mehr gewartet setzen
3. `mdview.nvim` in `markdown.nvim` implementieren und dann auf nicht mehr gewartet setzen
4. `ml` soll, wenn unter dem cursor gerade kein Pfad/Url/usw. oder so ist, checken ob in der aktuellen Zeile Links/URls/usw.. sind. Wenn...
    - ...genau einer in der aktuellen Zeile ist, aber der Cursor nicht genau drauf steht, dann verwende diesen trotzdem
    - ...mehrere sind, dann mit `lib.nvim -> hover_select` verwenden um eine Entscheidung des Users herbeizuführen, welcher verwendet werden soll
    - Außerdem: Momentan funktioniert das Ganze nur innerhalb von markdown links, also [](), es wäre aber schön, wenn es ach generell in markdown dokumenten funktionieren würde, also auch wenn einfach auf einen Pfad/url/etc wie zb,; http://www.google.com steht und man `ml` ausführt, oder eben dass es auch alle Pfad/Links/etc dammelt die im Dokument sind
5. Feature-Check: `:Markdown`-usrcmmd, dass alle Links/Urls/usw...
    - im gewählten Scope (`%/cwd/path/...`) gesammelt
    - explizit per [option?] im usrcmd wie damit verfahren wird, denkbar: `lib.nvim -> hover_select`, `Telescope`, `fzf-lua`, OutputDir (in File schreiben), usw...
      - wichtig: Wenn in einem Picker oder hover_select, dann müssen die Entrys mit Enter dazu führen, dass sie geöffnet werden (nicht nur Aufzählung)
    - Das Default-Verhalten soll der User in der Plugin-Implementierung setzen können
6. `:Narkdown table` klappt nucht mehr?
7. `:Tableview` gehört auch nach markdown.nvim

---

## `fileops.nvim`

1. Wenn man  `:File delete %` auslöst, wird die file gelöscht und der Buffer geschlossen, perfekt. Es wird abber immer auch ein leerer Buffer aufgemacht, selbst wenn andree Buffer existieren - das ist unnötig.

---

## nvim: High

1. `leader wq`: Alle issues lösen
2. Epressions, die auswerten auf welchen os wir sind, durch `system.env` ersetzen
3. [avante](./avante.md) Letzter teil umsetzen1
4. avante: usrcmds erstellen
5. gp. gegen avante testen
6. center in neotree: wen nich mit der maus scrolle, dase centered es, was mühasm ist
7. wkdoptiuons UI Linemarker gehört README
8. wkdoptions mit options.lua verheiraten
9. manchmal briucht C-c mit sigint nvim ab, es solte aber alles kopieren des buffers
10. `nvim/init.lua` durchgehen
12. `:Lazy` -> `todo-comments` + `ui` haben Updates - sind bei mir aber monkeypatched, also Sicherungskope der Files anlegen, Updaten und neu bewerten

---

## nvim

1. lsp: Einen switch einbauen, mitdem ich regeln kann, was der root für lsp ist: Switch zwischen cwd/nächstes_git/pfad/

---

## nvim: Bugs

1. `leader toc` sollter sicherstellen, dass am ende jeder Headline ein `---` ist.
2. `ZenMode` sollte auch eienen usrcmds toggle schalter haben
3. tablewview toggle sollt emit `q` bzw `Escape im Nomral Mode` geschlossen werden können.
4. Manchmal funktioert `C-s` nicht mehr...


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

## CHECK: linemarker

line marker hat enen kleinen bug - ziel ist eigentlich:
vom standunkt der aktuellen zeile aus nach oben immer wieviele zeilen zur zeile 0 sind. wenn ich also in der uzeile 10 stehe, ost die nummerierung der aktuellen zeile 0 und die der errsten zeile 10.
Nach unten hingegegen: Auch hjier z#ählöt es hinauf, also zeile 11 hat nummerieung 1, zeile 20 hat nummerieung 10 usw.. Die  Nummerierung  der letzten zeile ist aber immer die macimale zeilanazahl, also wenn das dokument 122 zeilen hat, ist die nummerieung der leten zeile immer 122.

Ist das noch immer ein bug?

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

1. Es wäre ccool, wenn es unterstützung gibt bei erstellen eine md tables, also zb das ein leeres template mix col/rows eingefügt wird und noch mehr features

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
2. Nach den gesamten Aufräumarbeiten checken, ob mit Snacks/image.nvim es nicht möglich ist, images zu öffnen

---
