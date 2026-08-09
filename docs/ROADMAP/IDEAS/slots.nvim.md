# `nvim-slots` — Konzept (aus den Notizen geborgen)

Angelegt 2026-08-08 aus `E:/repos/Notes/MyPlugin-Notes/slots/`
(`Konzept.md`, `slots-dev-notes.md`).

---

## Was es sein sollte

Nummerierte Datei-Slots in einer permanenten, togglebaren Sidebar rechts —
„eine leichte, gezielte Alternative zu Harpoon" mit Fokus auf numerische
Schnellnavigation und persistente Sichtbarkeit. Vollständig ausgearbeitet:
Feature-Tabelle, Config-Beispiel, Verzeichnisstruktur (hexagonal), Mappings,
visuelle Gestaltung.

Kern:

| Funktion | Beschreibung |
|---|---|
| Sidebar | rechts, ¼ Breite, `rounded`, nicht editierbar |
| Nummerierte Zeilen | ein Slot pro Zeile mit Dateipfad |
| Feste Startslots | `slots = { [3] = "~/projects/notes.md" }` in `setup()` |
| Lücken füllen | Neue Einträge belegen freie Slots unter Beachtung der festen |
| `:CMD <n>` | Datei in Slot `n` öffnen |
| `:CMDGet <n>` | Pfad aus Slot `n` in die Zwischenablage |
| Persistenz | optional, JSON unter `stdpath("data")` |

---

## Entscheidung, die vor allem anderen ansteht

**Kein Repo unter `E:/repos/`, kein Eintrag in `plugins/personal/source.lua`.**
Das Konzept liegt seit April 2025 unangetastet.

Bevor irgendetwas gebaut wird, ist zu klären, ob die Nische überhaupt noch frei
ist. Im heutigen Bestand gibt es mehrere Kandidaten, die den Zweck ganz oder
teilweise abdecken:

- [ ] **`buffer-ctx.nvim`** — arbeitet bereits mit Marken auf Extmark-Basis.
      Sind „Slots" nicht schlicht benannte, nummerierte Marken über Dateien
      hinweg statt innerhalb einer Datei?
- [ ] **`sessions.nvim`** — Persistenz von Arbeitszuständen.
- [ ] **`pickers.nvim`** — `smart/frecency.lua` liefert „die Dateien, an denen
      ich gerade arbeite", ohne dass man sie von Hand pflegt. Der Marks-Punkt
      aus `pickers.nvim.md` (Treffer markieren, in eigenem Picker sammeln) ist
      demselben Bedürfnis sehr nah.
- [ ] **`filetree.nvim`** — Sidebar-Infrastruktur existiert dort schon.

**Mögliches Ergebnis:** `nvim-slots` wird nicht gebaut, sondern die
Slot-Funktion wandert als Feature in eines der bestehenden Plugins. Das wäre
das bessere Resultat — ein weiteres eigenständiges Repo mit eigener Sidebar,
eigener Persistenz und eigenem Config-Block kostet dauerhaft Pflege.

**Aufwand (Entscheidung):** Quick Win
**Aufwand (Neubau als eigenes Plugin):** Lang — Sidebar, Persistenz, Config,
Docs, Tests, CI, alles von null
**Nutzen:** hoch, *sofern* die Funktion nicht schon dreimal vorhanden ist.

---

## Falls doch gebaut: was am Konzept anzupassen wäre

- [ ] **Command-Namen**: `:CMD` / `:CMDGet` sind Platzhalter aus dem Entwurf und
      als globale Namen unbrauchbar. Dem Ökosystem folgen: `:Slots <n>`,
      `:Slots yank <n>` — ein Command mit Subcommands, wie es `cmdlog.nvim` und
      `pickers.nvim` inzwischen machen.
- [ ] **Persistenz**: nicht global, sondern pro Projekt-Root — die
      Slot-Belegung ist projektspezifisch. `cmdlog.nvim`s `project_scoped` ist
      das fertige Muster.
- [ ] **Sidebar**: nicht selbst bauen, sondern gegen `lib.nvim.ui` bzw. die
      Fenster-Helfer prüfen, die inzwischen existieren.
- [ ] **Hexagonale Struktur aus dem Entwurf** (`core/`, `adapters/ui/`,
      `adapters/storage/`): für ein Plugin dieser Grösse überdimensioniert.
      Die heutigen Repos nutzen flachere Aufteilungen (`core/`, `ui/`,
      `config/`, `bindings/`) — daran halten.
- [ ] **Erweiterungsideen aus dem Konzept** (Slot-Gruppen/Profile `dev|notes|docs`,
      Drag & Drop per Mapping, Lua-API `require("nvim-slots").goto(3)`,
      Telescope-Vorschau): erst nach dem Kern, und die Picker-Anbindung über
      `pickers.nvim`.

---

## Nicht verwertbar

`slots-dev-notes.md` enthält ausser zwei Zeilen (GIFs/Screenshots für die
README) nur eine lange Sammlung fremder Keymaps (FzfLua, Neogit, Quickfix, LSP,
Treesitter-Textobjekte) ohne Bezug zu Slots. Das ist eine alte Mapping-Kladde,
kein Konzeptmaterial — falls davon etwas gebraucht wird, gehört es nach
`nvim/BINDINGS`, nicht hierher.
