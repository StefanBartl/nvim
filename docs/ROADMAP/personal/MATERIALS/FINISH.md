# Checkl1ist: Aufgaben

- [ ] Auf implementierte Filetree-Features checken (Neotree, NvimTree, Netrw, ...):
  - [ ] Eine Featurlist daraus erstellen indem enthalten ist: Welches Feature; Origin (Datei, Zeile); Wo es thematisch angelegt ist; Infos/Was sonst noch Sinn macht
  - [ ] `/docs/ROADMAP/NEOTREE_FEATURES.md` anlegen: Dort kommt eine Übersicht/Auflistung aller dieser Features hin
  - [ ] Nur zur Info: Die Features werden später dann alle später in `filetree.nvim` eingebaut und zwar **Cros--Platform** & **Filetree-Manager agnostisch**
- [ ] Für github.com erledige folgendes (`gh` ist installiert und authorisiert):
  - [ ] Kurzinfo für Repo schreiben: `gh repo edit --description "Mein cooles Neovim Listen-Plugin" --homepage "https://deine-seite.de"`
  - [ ] Korrekte, passende Keywords für Repo eingeben: `gh repo edit --add-topic "neovim,lua,plugin"`
  - [ ] usw.
- [ ] `.luarc.json` in jedem Root anlegen
- [ ] Schlachtplan erstellen für jeden dieser Punkte:
  - [ ] Checklisten einzeln, nacheinander anwenden; Gehe dafür jede List einzeln durch und erstelle für jede eine `/docs/ROADMAP/**.md` wobei `**` also der Dateiname jeweils der List-Name ist:
    - 1. [Architekur&Coding-Regeln](E:/repos/Notes/MyNotes/Checklists/Lua/Arch&Coding-Regeln.md) -> (`/docs/ROADMAP/Arch&Coding.md`)
      1. [Zentrale Prinzipien](E:/repos/Notes/MyNotes/Checklists/Lua/Zentrale-Prinzipien.md) -> (`/docs/ROADMAP/Zentral-Prinzipien.md`)
      2. [Checklist.md](E:/repos/Notes/MyNotes/Checklists/Lua/Checklist.md) -> (`/docs/ROADMAP/Checklist.md`)
  - [ ] `/docs/ROADMAP.md` durchgehen und Plan zur Implementierung erstellen
- [ ] Alle features/bugfixes committen und pushen (wenn nict möglich: commit message ausgeben)

---
