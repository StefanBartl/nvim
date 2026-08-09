# `markdown.nvim`

---

## Aus `MyPlugin-Notes/md_tablewrap/featuremap.md` (Analyse 2026-08-08)

Quelle: `E:/repos/Notes/MyPlugin-Notes/md_tablewrap/featuremap.md` (20 QoL-Punkte)
plus `MyPlugin-Notes/PluginsDoc/underline_headings.md`.

**Gegen den Code geprüft** (`E:/repos/markdown.nvim/lua/markdown/`): vorhanden sind
`core/table_fmt.lua` (Parsen, Ausrichten, GFM-Rendering, `format_table_at_cursor`
/ `_in_buffer` / `_in_scope`), `core/table_mode.lua` (Live-Reformat, `tableize`,
`next_cell`/`prev_cell`) und `tableview/**` (Browser-/Box-Ansichten).

**Was nachweislich fehlt: das Kernthema der Notiz.** `calc_widths` in
`table_fmt.lua` nimmt schlicht das Maximum der Zellbreiten — es gibt keine
Obergrenze, keine Fensterbreiten-Berücksichtigung und kein Umbrechen einer
logischen Zeile auf mehrere physische Zeilen. Genau das war `md_tablewrap`.

---

### 1. Kernfeature: breitenbegrenztes Umbrechen (der eigentliche `md_tablewrap`)

- [ ] `max`/`min`/`auto` pro Spalte, `pad`, `left`/`right` in `table_fmt`
      einziehen; `auto` = an Fensterbreite ausrichten.
- [ ] Zellinhalt, der die Spaltenbreite übersteigt, auf Fortsetzungszeilen
      derselben logischen Tabellenzeile umbrechen (GFM-gültig bleiben).
- [ ] `:MDTableUnwrap` als Gegenbefehl — Fortsetzungszeilen wieder zu einer
      physischen Zeile zusammenführen (Trenner ` ` oder `<br>`), nötig für
      Export und saubere Diffs.

**Aufwand:** Mittel (das Umbruch-/Zusammenführ-Paar ist der Kern, alles Weitere
hängt daran)
**Nutzen:** hoch — betrifft jede breite Tabelle in den eigenen Docs; die
ROADMAP-Dateien selbst sind voll davon.

### 2. Direkt daran hängende Punkte

| Punkt | Beschreibung | Aufwand | Nutzen |
|---|---|---|---|
| Cursor-/Zell-Erhalt | Nach Reflow per Extmark zurück in *dieselbe logische Zelle*, nicht nur in dieselbe physische Zeile | Quick Win (Extmark-Muster existiert in `buffer-ctx.nvim`) | hoch |
| Fortsetzungs-Marker | Virt-Text-Gutter-Hint (`↳`) für Zusatzzeilen einer logischen Zeile | Quick Win | hoch — ohne das ist umgebrochener Text schwer lesbar |
| URL-/Token-aware Wrapping | Weiche Trennstellen (`soft_break_chars = "/._-?,&=#@:"`), niemals mitten in `[text](url)` oder `` `code` `` | Mittel | hoch — sonst zerlegt der Umbruch genau die Links, die `link_scan`/`link_diagnostics` danach anmeckern |
| Falten der Fortsetzungsblöcke | `:MDTableFoldRow`/`FoldAll` per `foldmethod=expr` | Mittel | mittel — `core/fold.lua` + `fold_levels.lua` existieren, dort andocken |

### 3. Steuerung und Feintuning

| Punkt | Beschreibung | Aufwand | Nutzen |
|---|---|---|---|
| Per-Table-Direktiven | `<!-- mdwrap: auto=false max=40 min=12 pad=1 -->` über der Tabelle überschreibt die Defaults nur für diese Tabelle | Quick Win | hoch — löst „diese eine Tabelle soll anders sein" ohne Config-Änderung |
| Breitenprofile | `:MDTableProfile compact|docs|wide` lädt `{auto,min,max,pad,left,right}` in einem Rutsch | Quick Win | mittel |
| Spalten-Nudges | `:MDTableCol+ [n]` / `:MDTableCol-` verbreitert/verengt die Spalte unter dem Cursor unter Erhalt der Gesamtsumme | Mittel | mittel |
| Alignment-Toggle | `:MDTableAlign cycle|left|center|right` für die aktuelle Spalte, Separator wird neu gebaut | Quick Win — `format_row` kennt bereits `override_map` | mittel |
| Markdown-Flavor-Schalter | „GitHub-streng" vs. „locker" (Mindest-Dash-Länge, Leerzeichenpolitik) | Quick Win — `gen_separator` hat schon `separator_style` | niedrig |

### 4. Scope und Performance

| Punkt | Beschreibung | Aufwand | Nutzen |
|---|---|---|---|
| `:MDTableWrapVisual[!]` | Nur Tabellen in der visuellen Auswahl | Quick Win — `format_tables_in_scope` existiert bereits | mittel |
| `:MDTableWrapVisible[!]` | Nur Tabellen im sichtbaren Fensterbereich | Quick Win | mittel — relevant in grossen Dateien |
| Selektives Reflow nach `changedtick` | On-Save nur Tabellen anfassen, die sich geändert haben | Quick Win | mittel — vermeidet Rausch-Diffs |
| `VimResized`/`WinResized`-Hook | Togglebar; Reflow sichtbarer Tabellen im Auto-Modus | Mittel | mittel — muss debounced sein, sonst Reflow-Sturm |
| Nur-Header-Reflow | `:MDTableReflowHeader` lässt den Body unangetastet | Quick Win | niedrig |

### 5. Diagnose und Export

- [ ] `:MDTableLint` — ungleiche Spaltenzahl, fehlende Separatorzeile, leere
      Header-Zellen; dazu `:MDTableFixMissingSeparator`.
      **Andockpunkt:** `core/link_diagnostics.lua` macht dasselbe bereits für Links —
      dieselbe Diagnostic-Namespace-Mechanik wiederverwenden, nicht neu bauen.
- [ ] `:MDTableDebug` — kompakte Planansicht (Avail, Pipes, Padding, Summe,
      Breiten je Spalte, Min/Max/Mode). Beantwortet „warum ist Spalte 1 nur 19?".
      Wird beim Bauen von Punkt 1 ohnehin gebraucht — **zuerst** machen.
- [ ] `:MDTableToCSV` / `:MDTableFromCSV` Roundtrip.
- [ ] API-Hooks `before_reflow(bounds, plan)` / `after_reflow(bounds, plan)`.

**Aufwand:** Lint Mittel, Debug Quick Win, CSV Quick Win, Hooks Quick Win
**Nutzen:** Debug hoch (Entwicklungswerkzeug für alles andere), Lint mittel,
CSV/Hooks niedrig.

### 6. Nicht übernehmen

- **Soft-Hyphenation (`\u00AD`)**: hängt vollständig am Renderer der Gegenseite
  und ist in Plain-Text-Diffs unsichtbar — hohe Verwirrungsgefahr, geringer Nutzen.

