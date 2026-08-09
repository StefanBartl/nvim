# `cmdlog.nvim`

---

## Aus `MyPlugin-Notes/cmdlog/` (Analyse 2026-08-08)

Quelle: `E:/repos/Notes/MyPlugin-Notes/cmdlog/` (`cmdlog-dev-notes.md`,
`OPTIONS.CONFIG.md`, `ui/`, `core/favorites/cache.md`) und der cmdlog-Block in
`MyPlugin-Notes/TODOS.md`.

**Gegen den Code geprüft** (`E:/repos/cmdlog.nvim/lua/cmdlog/`) — die Notizliste
umfasst 17 Punkte, davon sind die meisten längst gebaut. Erledigt und deshalb
hier *nicht* mehr aufgeführt: `checkhealth` (`health.lua`), Favoriten-Notizen
(`core/notes.lua`), projektbasierte History (`core/project_history.lua`),
projekt-scoped Favoriten (`project_scoped` in DEFAULTS), Fehler-/Status-Tracking
(`core/errors.lua` + `✗`-Marker in `picker_utils.lua`), Löschen von Einträgen
(`mappings.delete = "<C-x>"`), Tags (`core/tags.lua`), Usage-Stats
(`core/stats.lua`), Risky-Command-Highlighting (`core/risky.lua`), Previewer für
`:help`/`:term`/`:lua`/`:!shell` (`ui/telescope-previewer.lua`), Keymaps über
`setup()`, which-key-Integration, Umbau auf `:Cmdlog <subcommand>`.

Der Cache-Befund aus `core/favorites/cache.md` (Favoriten-Cache ist korrekt,
History-Cache war es nicht) ist ebenfalls umgesetzt.

Was bleibt:

---

### 1. Privacy-Filter: bestimmte Commands gar nicht aufzeichnen

`track_commands` ist heute ein reines An/Aus für *alles* (Projekt-History,
Stats, Error-Tracking). Die Notiz fordert ein feineres Opt-out:
„Don't log commands matching regex" — z. B. alles mit `password`, `secret`,
`token`, `--api-key`.

Das ist der einzige Punkt der Liste mit Sicherheitsrelevanz: die Stats- und
Projekt-History-Dateien liegen im Klartext unter `stdpath("data")`, und mit
`:!curl -H "Authorization: Bearer …"` landen Tokens dort dauerhaft.

- [ ] `redact_patterns` (Lua-Patterns, wie `risky_patterns` aufgebaut) in DEFAULTS,
      ausgewertet im `core/tracker.lua`-Choke-Point, bevor irgendetwas geschrieben wird.
- [ ] Sinnvolle Defaults mitliefern (`password`, `secret`, `token`, `Bearer`, `api[-_]?key`).

- [ ] In den docs angeben -> Sicherheitsfeature!

**Aufwand:** Quick Win
**Nutzen:** hoch.

### 2. `extra_files`: eigene Log-/Command-Dateien als Quelle

Notiz: `~/project/commands.log` oder `~/.local/my-commands.txt` wie eine History
durchsuchbar machen. In der Notiz als „Custom Telescope Launcher" bezeichnet —
trifft es gut.

```lua
setup({ extra_files = { history = { "~/my_global_history.txt" }, all = { "~/my_favs.txt" } } })
```

**Aufwand:** Quick Win (Quelle einlesen + in die bestehende Kombinationslogik hängen)
**Nutzen:** mittel-hoch — macht cmdlog vom History-Viewer zum Command-Launcher.

### 3. Herkunfts-Marker im Picker (nvim vs. shell)

`picker_utils.lua` markiert heute Favorit (`★`) und Known-bad (`✗`). In den
kombinierten Pickern (`:Cmdlog`, `all_picker`) ist aber nicht erkennbar, ob ein
Eintrag aus der Nvim- oder aus der Shell-History stammt.

- [ ] Zusätzliches, dezentes Präfix oder Suffix-Label pro Quelle
      (`picker_utils` hat mit `opts.label(entry)` bereits den Hook dafür).

**Aufwand:** Quick Win
**Nutzen:** mittel.

### 4. Zwischen Pickern wechseln, ohne den Picker zu verlassen

Heute: Picker schliessen, neues `:Cmdlog <sub>` tippen. Gewünscht: eine Taste,
die im offenen Picker durch die Varianten rotiert (history → shell → favorites →
project → …).

- [ ] `mappings.cycle_source` (z. B. `<C-n>`/`<C-p>`), der den aktuellen
      Prompt-Text beim Wechsel beibehält.

**Aufwand:** Mittel — der Engine-übergreifende Neuaufbau des Pickers unter
Erhalt des Prompts ist der eigentliche Aufwand.
**Nutzen:** hoch — spart bei der täglichen Nutzung am meisten Handgriffe.

### 5. Legende im Picker

Kurze Übersicht der aktiven Keys (`<Tab>` favorit, `<C-x>` löschen, `<C-t>` tag …)
im Picker-Header oder Prompt-Titel. Die Mappings sind konfigurierbar, also muss
die Legende aus `config.mappings` generiert werden, nicht hartkodiert.

**Aufwand:** Quick Win
**Nutzen:** mittel.

### 6. Favoriten: Undo und manuelle Sortierung

- [ ] Undo, wenn ein Favorit versehentlich weggetoggled wurde (letzte Toggle-Aktion merken).
- [ ] Favoriten in der Liste manuell verschieben/sortieren (heute: Reihenfolge = Einfügereihenfolge).

**Aufwand:** Undo Quick Win, Sortierung Mittel (braucht persistente Order im JSON)
**Nutzen:** mittel.

### 7. Export/Import + CLI (`cmdlogctl`)

Notiz-Punkt 17: Favoriten exportieren/importieren, dazu ein CLI-Tool zum Anzeigen
und Bearbeiten der History ausserhalb von Neovim.

Export/Import ist billig (JSON liegt schon vor) und wäre der Migrationsweg
zwischen Laptop und Workstation. Das CLI-Tool ist ein eigenes Projekt und passt
eher zu der `ROADMAP.md`-Idee, die Plugins gebündelt als Binary auszugeben — dort
verlinken statt hier separat verfolgen.

**Aufwand:** Export/Import Quick Win, CLI Sehr aufwendig
**Nutzen:** Export/Import mittel-hoch, CLI niedrig (solange die Binary-Idee offen ist).

### 8. Offener Bug aus `TODOS.md`

```
E5108: ...plenary/path.lua:737: ENOENT: no such file or directory:
  …/nvim-data/nvim-cmdlog/favorites.json
```

Trat beim Ganz-nach-unten-Scrollen auf. Zwei Dinge daran:

1. Der Pfad ist der **alte** (`nvim-cmdlog/`), heute steht in DEFAULTS
   `cmdlog/favorites.json` — der Fehler stammt also von vor der Umbenennung.
2. plenary ist laut `Roadmap-Effort-Overview.md` inzwischen entfernt worden.

- [ ] Nur noch verifizieren, dass der Fall „Favoriten-Datei existiert noch nicht"
      in `core/store.lua` sauber als leere Liste behandelt wird, statt zu werfen.
      Dann Punkt streichen.

**Aufwand:** Quick Win
**Nutzen:** mittel.

---

