# FINISH: von mir ausführen

## `lib.nvim`

- [ ]In `lib.nvim` implementieren:
  - [ ]In `lib.nvim.`:

- [ ] Aus `lib.nvim` implementieren:
  - [ ] Aus `lib.nvim.window` zb.: `nice_quit`

## General

- [ ] Schlachtplan erstellen für jeden dieser Punkte:
  - [ ] Checklisten einzeln, nacheinander anwenden; Gehe dafür jede List einzeln durch und erstelle für jede eine `/docs/ROADMAP/**.md` wobei `**` also der Dateiname jeweils der List-Name ist:
      - [Architekur&Coding-Regeln](E:/repos/Notes/MyNotes/Checklists/Lua/Arch&Coding-Regeln.md) -> (`/docs/ROADMAP/Arch&Coding.md`)
      - [Zentrale Prinzipien](E:/repos/Notes/MyNotes/Checklists/Lua/Zentrale-Prinzipien.md) -> (`/docs/ROADMAP/Zentral-Prinzipien.md`)
      - [Checklist.md](E:/repos/Notes/MyNotes/Checklists/Lua/Checklist.md) -> (`/docs/ROADMAP/Checklist.md`)
  - [ ] `/docs/ROADMAP.md` durchgehen und Plan zur Implementierung erstellen
  - [ ] `/NEOTREE_FEATURES` durchgehen und bewerten, was damit gemacht wird
- [ ] `:Recommender` durch alle Module laufen lassen
- [ ] `vimdoc`-Datei `doc/{NAME}.txt` + Funktnion die auto `tags`-Datei generiert für user (`doc/tags` in `.gitignore`)? Bzw. gibt es ein Autocmd, damit die Tgas bei jeden User der das Repo ladet automatisch erstellt werden?
- [ ] Alle Plugins auf `.nvim`-Namensendung umstellen (wenn möglich)
- [ ] `Github Actions` einrichten (`luacheck` usw.)
- [ ] `ProjectInsight stats lib` über alle Repos ausführen und gesammelte Übersicht erstellen
- [ ] Wenn sinnvoll: `docs/TESTS/**` Testdateien für die Features schreiben
  - [ ] Alle features/bugfixes committen und pushen (wenn nicht möglich: commit message ausgeben)

---

## Opus HOCH oder Fable5

- [ ] `telescope-selected-index` implementierung prüfen: Momentan passt weder die Indexierung sobald sich in der Prompt etwas tut noch oftmals die indexierung gleich beim start. ist es nciht möglich, nachdem die resultatsliste upgedatet aht (zb nahch einen keystroke in dre prompt), dass danach nochmal drüber gegangen und die nummerierung eingebetet wird mit einen kurzen debounce ... oder eine ganz andere möglichkeit, af die ich noch nict gedacht habe vielleicht?

---

