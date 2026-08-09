# `gopath.nvim`

---

## Aus `MyPlugin-Notes/gopath/` (Analyse 2026-08-08)

Quelle: `E:/repos/Notes/MyPlugin-Notes/gopath/` (`NEW-Features.md`,
`Improvements.md`, `roadmap.md`, `Bugs.md`, `Notes/`).

**Vorab gegen den Code geprüft** (`E:/repos/gopath.nvim/lua/gopath/`), weil die
Notizen aus der Zeit vor v2 stammen und grosse Teile inzwischen gebaut sind:

| Notiz-Feature | Status im Code | Konsequenz |
|---|---|---|
| Feature 4: Line/Col-Parsing zentralisieren | `util/location.lua` existiert | erledigt, nicht mehr aufführen |
| Feature 1: Truncated Path Resolution | `truncated/` + `truncated/@types/` existiert | erledigt |
| Fuzzy-Alternate + External-Open (v2.0) | `alternate/`, `external/` existieren | erledigt |
| `checkhealth`-Modul | `health.lua` existiert | erledigt |
| Feature 2/3: Symbol→Modul, Direct Symbol Jump | **nicht verifiziert** — siehe unten | offen, erst prüfen |

Alles Folgende ist der Rest, der in den Notizen steht und im Code **nicht**
offensichtlich vorhanden war.

---

### 1. Bare Identifier → Modul auflösen (Notiz-Feature 2)

`binding_index` mappt bereits `identifier → module`, `symbol_locator` nutzt das
aber nur für `.field`-Chains. Cursor auf einem nackten `resolver` in
`local resolver = require("gopath.resolve")` fällt durch.

- [ ] Erst prüfen, ob `registry.run_language_pipeline` das inzwischen abdeckt.
- [ ] Falls nicht: im Pipeline-Vorlauf Treesitter-Node-Type `identifier` abfragen
      und über `binding_index.get_map()` auflösen, bevor der Chain-Resolver läuft.

**Aufwand:** Quick Win (Notiz schätzt 3–5 Tage, real eher <1 Tag, da alle Bausteine da sind)
**Nutzen:** hoch — trifft den häufigsten Lua-Navigationsfall im eigenen Ökosystem.

### 2. LSP-first Provider-Order für Chains (Notiz-Feature 3)

Notiz: Treesitter könnte vor LSP laufen und ein ungenaueres Ergebnis (Datei statt
Datei+Zeile) zurückgeben. `providers/lsp.definition_at_cursor` liefert bereits
eine exakte Range.

- [ ] Verifizieren, welche Reihenfolge `config/DEFAULTS` tatsächlich setzt und ob
      der Chain-Pfad LSP zuerst versucht.
- [ ] Falls nicht: LSP-Versuch mit kurzem Timeout voranstellen, Treesitter als Fallback.

**Aufwand:** Quick Win (1–2 Tage laut Notiz, davon fast alles Testing)
**Nutzen:** hoch — Sprung auf die Definitionszeile statt nur auf die Datei.

### 3. Treesitter statt Regex in `symbol_locator` und `table_locator`

Aus `Improvements.md`:

- `symbol_locator.via_treesitter` nutzt trotz des Namens Regex-Patterns.
- `table_locator.find_balanced_region` zählt Klammern manuell mit Tiefen-Tracking —
  fehleranfällig; in `v0.2_Features.md` ist dort schon einmal eine Endlosschleife
  gefixt worden.

- [ ] Beide auf echte Treesitter-Queries umstellen.

**Aufwand:** Mittel (je ~1 Woche, weil die Fallback-Pfade erhalten bleiben müssen)
**Nutzen:** mittel-hoch — beseitigt eine ganze Fehlerklasse statt einzelner Bugs.

### 4. Root-Inferenz cachen (`value_origin.lua`)

`infer_roots_from_lines` ist inline definiert und liest die Datei bei **jedem**
`try_locate_with_roots`-Aufruf neu. `binding_index.lua` hat dafür schon das
richtige Muster: Cache pro Buffer mit `changedtick`-Invalidierung.

**Aufwand:** Quick Win
**Nutzen:** mittel — spürbar nur in grossen Dateien, aber billig zu haben.

### 5. Kleinere offene Punkte aus `roadmap.md`

| Punkt | Aufwand | Nutzen |
|---|---|---|
| Environment-Variablen im Pfad expandieren (`$REPOS_DIR/...`) | Quick Win | hoch — wird in der eigenen Config permanent benutzt |
| `:h` / Vimdoc | Mittel | mittel |
| Types ausdefinieren | Mittel | mittel |
| Hardcodierte Extension-Liste in `external/helpers/detector.lua` an `config` durchreichen | Quick Win | mittel — Config-Feld existiert laut Notiz schon, nur nicht verdrahtet |

### 6. Alternate-UI: Backend, Preview, Lernen

Aus `Improvements.md` „Future Enhancements":

- [ ] UI-Backend konfigurierbar (statt fix `vim.ui.select`) — **naheliegend über
      `pickers.nvim` statt eigener Telescope/fzf-Anbindung**, das Engine-Routing
      existiert dort bereits (`pickers/engines/{telescope,fzf,snacks}.lua`).
- [ ] Preview in der Alternate-Auswahl (erste Zeilen, Grösse, mtime).
- [ ] Häufigkeits-Lernen: oft gewählte Alternates hochsortieren.
      *Achtung:* `pickers.nvim` hat mit `smart/frecency.lua` bereits eine
      Frecency-Implementierung — die gehört geteilt (via `lib.nvim`), nicht neu gebaut.
- [ ] Eigene Similarity-Funktion statt fix Levenshtein (z. B. Prefix-Matches bevorzugen).

**Aufwand:** Backend-Anbindung Mittel, Preview Quick Win, Lernen Mittel
**Nutzen:** Backend hoch (Konsistenz im Ökosystem), Rest mittel.

### 7. Fehler-Recovery beim Öffnen

Kein Fallback, wenn der externe Opener fehlschlägt oder Rechte fehlen.
`lib.nvim.cross` hat inzwischen die harte Windows-Erfahrung aus `reveal_in_fm`
verarbeitet — hier sollte dieselbe Mechanik genutzt und nicht noch einmal
separat gelöst werden.

**Aufwand:** Quick Win
**Nutzen:** mittel.

### 8. Bug aus `Bugs.md`

- [ ] `event = "VeryLazy"` ist für die Initialisierung zwingend. Entweder in
      `plugin_spec`/README als Pflicht dokumentieren oder die Initialisierung so
      umbauen, dass sie ohne dieses Event auskommt.

**Aufwand:** Quick Win
**Nutzen:** mittel — sonst stiller Ausfall bei fremden Setups.

### 9. Recherchenotiz: `includeexpr` / `suffixesadd`

`Notes/includeexpr-sufficesadd.md` beschreibt die Vim-native Kette
`<cfile>` → `includeexpr` → `findfile()` → `suffixesadd`. gopath umgeht das heute
komplett.

- [ ] Prüfen, ob die builtin-Resolver `suffixesadd` respektieren sollten — das ist
      die Erwartungshaltung von Usern, die von `gf` kommen.

**Aufwand:** Quick Win (Prüfung), Mittel (falls Umsetzung)
**Nutzen:** mittel.
