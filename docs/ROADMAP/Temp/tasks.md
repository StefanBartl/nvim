Die drei Übergaben zu tasks-desktop sind zu einer zusammengeführt: `E:\repos\tasks-vault\wkdbook-tasks.nvim\handovers\tasks-desktop-stand-2026-10-14_HANDOVER.md` (Stand 2026-10-14 Abend). Die Fassungen vom 12.10., 13.10. und 14.10. (Mittag) liegen im Backlog (`wkdbook-tasks.nvim/Backlog/TASKS/2026-10-1x_..._HANDOVER.md`, je mit einer Zeile in `Backlog/README.md`, mit Vermerk "abgelöst"). Unter `nvim/docs/ROADMAP/handovers/` zeigt nur noch ein Symlink auf die eine Datei.

**Text zum Einfügen im nächsten Chat**

> Mach weiter mit `E:\repos\tasks-vault\wkdbook-tasks.nvim\handovers\tasks-desktop-stand-2026-10-14_HANDOVER.md`. Lies danach die `CLAUDE.md` in `tasks.nvim` und `tasks-desktop`. Zuerst: `gh run list --branch main` ansehen (Lauf zu `tasks-desktop@241b356`), dann die 🟡-Commits der Übergabe per Ultracode reviewen (ich schalte das Reasoning dafür um), dann `tasks-app-tasks-verwalten-luecken-schliessen-titel-aendern-t` (Verwerfen, Bereich wechseln) und die Touch-Bedienung der Kacheln. Force-Push für die Co-Autor-Zeile nur auf mein ausdrückliches Wort.

**Was seit der Fassung vom Mittag dazukam**
- **Check:** Funde pro Task beurteilt (`5b96a84`); die Basis kommt auch aus Listen, die die Seite während des Laufs hielt (`affd913`); der Hub führt den Check nach einer Änderung selbst nach (`5b091c8`, Fix `bc5d8ed`: der Bereich des Laufs bleibt). Der Check-Task ist erledigt, Rest E als eigener Task.
- **Kacheln der Übersicht umordnen** (`3e4542b`): Griff, Ziehen oder Pfeiltasten, Reihenfolge gemerkt. Offen: Touch, Menüeintrag, WebView2.
- **Text bearbeiten** (`tasks.nvim@a51a674` `set_body`, `tasks-desktop@e817666`, Fix `241b356`).
- **Aufgeräumt:** zwei Tasks erledigt (E2E-Flake, Leistung), der Verwalten-Task mit dem Code abgeglichen, `actions-checkout` und `install-umbenennen` waren schon erledigt.
- **Neuer Task:** `tasks-desktop-repo-kacheln-eine-favoritenseite-mit-gruppen` (Gruppen mit Titel, Kacheln mit Repo-Bild; die Beschriftungen der Skizze sind die Titel der Gruppen).

**Reviews:** nur mit hohem Reasoning von Hand (🟡): `tasks.nvim@4c6a7d9`, `a51a674`; `tasks-desktop@5b96a84`, `affd913`, `3e4542b`, `5b091c8`, `bc5d8ed`, `e817666`. Ohne Review: `tasks-desktop@241b356`. Grün gibt es erst nach einem Ultracode-Lauf.

**Zu beachten:** Die Co-Autor-Zeile steht in 11 Commits von `tasks.nvim` und 46+ von `tasks-desktop`; Force-Push nur auf dein Wort. Vor jedem Push `git log origin/main..HEAD` ansehen. Eine Befehlskette committet auch nach einem roten Test, wenn dessen Ausgabe nur gefiltert wird: Ergebnis lesen, dann committen.
