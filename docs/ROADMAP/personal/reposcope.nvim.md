# `reposcope.nvim`

---

### 1. Favoriten für Repositories

Im Code gibt es keinerlei Favoriten (grep über `lua/` liefert keinen Treffer).
Die Notiz will damit zwei Dinge auf einmal erschlagen: Schnellzugriff **und**
eine sinnvolle Startansicht.

- [ ] Favoriten persistieren (Repo-Metadaten + zugehörige README).
- [ ] Häufigste Queries mitschreiben und ebenfalls anbieten.

**Muster übernehmen statt neu erfinden:** `cmdlog.nvim` hat Favoriten samt
Toggle, Persistenz, Cache-Strategie (`core/favorites.lua`) und die dazu
passende Cache-Analyse bereits durchgespielt.

**Aufwand:** Mittel
**Nutzen:** hoch — ohne Startzustand ist reposcope bei jedem Öffnen bei null.

### 2. Startansicht: bereits geladene Repos / Favoriten zeigen

Folgt direkt aus Punkt 1: Beim Start die gecachten Repositories mit Suchfunktion
und einem Refresh pro Eintrag anzeigen, statt mit leerem Prompt zu beginnen.

**Aufwand:** Mittel
**Nutzen:** hoch.

### 3. README-Cache: Aktualität und Vorwärmen

Im `cache/`-Verzeichnis gibt es weder TTL noch Timestamp-Vergleich (grep nach
`ttl|timestamp|expire`: keine Treffer).

Aus `Workpaket.md` Punkt 6 stammt der eigentlich richtige Ansatz — nicht per
Ablaufzeit, sondern per Vergleich: Das Suchergebnis enthält bereits das
`updated_at` des Repositories. Ist der Cache-Eintrag jünger, spart man sich den
README-Request komplett.

- [ ] Timestamp pro gecachter README ablegen und gegen `updated_at` aus der
      Repository-Response prüfen.
- [ ] Beim Start die Datei-gecachten READMEs in den RAM vorziehen.
- [ ] Pre-Caching der ersten `n` Treffer, damit Durchscrollen ohne Ladepause geht.

Zwei offene Fragen aus dem Workpaket, die **vor** der Umsetzung zu klären sind:

- Zählt ein reiner README-Fetch (curl auf `raw.`) gegen das API-Ratelimit?
  (Vermutlich nein — dann ist der Cache weniger wichtig als gedacht.)
- Wie gross ist der gemessene Performance-Unterschied File-Cache vs. RAM-Cache
  überhaupt? Erst messen, dann bauen.

**Aufwand:** Messung Quick Win, Umsetzung Mittel
**Nutzen:** mittel-hoch — und die Messung kann den ganzen Punkt erledigen.

### 4. Kleinere UI-Punkte

| Punkt | Aufwand | Nutzen |
|---|---|---|
| `?` öffnet eine Keybinding-Übersicht | Quick Win | mittel — Muster existiert in `filetree.nvim`s neo-tree-Cheatsheet |
| Im Preview-Fenster mit Tasten scrollen | Quick Win | mittel |
| Schmale Leiste links (Navigation/Filter) | Mittel | niedrig |
| Colorthemes: **alle** Farben aus der Config, nicht teils hartkodiert (`"#E06C75"`) | Quick Win | mittel — hartkodierte Hex-Werte brechen bei Colorscheme-Wechsel |
| `prefix`-Option für andere Symbole | Quick Win | niedrig |

### 5. Clone über `wget`/`curl`

`providers/*/clone/clone_command.lua` existiert für alle drei Provider — die
Notiz will Clone auch ohne `git`, über Tarball-Download. Sinnvoll nur, wenn ein
Zielsystem `git` wirklich nicht hat.

**Aufwand:** Mittel
**Nutzen:** niedrig — realistisch hat jedes System mit `gh`/`curl` auch `git`.

### 6. Mittelfristige Notizen

- **Fehler-Modul einbinden, Metriken korrigieren** (aus `## Bugs`, „mittelfristig"):
  Clone-Metrik fehlt, URLs sollen mitgeloggt werden, `cache source` gehört zum
  README-Cache, und `stats_win` ist faktisch ein UI-Modul und liegt am falschen
  Ort. Letzteres ist im Baum sichtbar: `state/popups/stats_popup.lua` steht unter
  `state/`, obwohl daneben ein `ui/`-Bereich existiert.
  **Aufwand:** Quick Win (Verschieben) bis Mittel (Metriken). **Nutzen:** mittel.
