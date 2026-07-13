# FINISH: von mir ausführen

- [ ] Alle polugins durchgehen und checken, ob es eh keine doppelungen bei den lhs bei dne keymaps hibt
- [ ] Nvim startet, dann kann ich ein oaar sekunden was machen, dann freezed er mehrere minuten, dann geht es normal weiter
- [ ] Plugins explizit auf sicherheitsrelevantes abklopfen und härten

## `lib.nvim`

- [ ] Aus `lib.nvim` implementieren:
  - [ ] Aus `lib.nvim.window` bzw `lib.nvim.ui.kit` zb.: `nice_quit` usw.. für alle aufrufe von windows checken und die lib nvim ui kit variante iomplemeniteren

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
- [ ] Wenn sinnvoll: `TESTS/**` Testdateien für die Features schreiben und_
  - [ ] `docs/TESTS/**` verschiedben nach `TESTS/**`, sodass es im root des plugins st , nicht mehrr in `docs`
- [ ] Alle features/bugfixes committen und pushen (wenn nicht möglich: commit message ausgeben)


---
