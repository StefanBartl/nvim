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

### 1. Bare Identifier → Modul auflösen (Notiz-Feature 2) — ✅ erledigt (2026-08-09)

`binding_index` mappt bereits `identifier → module`, `symbol_locator` nutzt das
aber nur für `.field`-Chains. Cursor auf einem nackten `resolver` in
`local resolver = require("gopath.resolve")` fällt durch.

- [x] Erst prüfen, ob `registry.run_language_pipeline` das inzwischen abdeckt.
      → **War bereits gebaut**: `identifier_locator.lua` deckt genau diesen
      Fall ab und läuft in `registry.lua`'s treesitter-Pipeline vor dem
      Chain-Resolver. Nur dokumentiert (vimdoc + docs/features.md), kein
      Code nötig. Commit `9595266`.

**Aufwand:** Quick Win (Notiz schätzt 3–5 Tage, real eher <1 Tag, da alle Bausteine da sind)
**Nutzen:** hoch — trifft den häufigsten Lua-Navigationsfall im eigenen Ökosystem.

### 2. LSP-first Provider-Order für Chains (Notiz-Feature 3) — ✅ erledigt (2026-08-09)

Notiz: Treesitter könnte vor LSP laufen und ein ungenaueres Ergebnis (Datei statt
Datei+Zeile) zurückgeben. `providers/lsp.definition_at_cursor` liefert bereits
eine exakte Range.

- [x] Verifizieren, welche Reihenfolge `config/DEFAULTS` tatsächlich setzt und ob
      der Chain-Pfad LSP zuerst versucht.
      → **War bereits korrekt**: Default `order = {"lsp","treesitter","builtin"}`,
      und `PIPELINE.lsp` versucht `symbol_locator.via_lsp` vor allem anderen.
      Nur dokumentiert. Commit `9595266`.

**Aufwand:** Quick Win (1–2 Tage laut Notiz, davon fast alles Testing)
**Nutzen:** hoch — Sprung auf die Definitionszeile statt nur auf die Datei.

### 3. Treesitter statt Regex in `symbol_locator` und `table_locator` — ⏳ teilweise (2026-08-09)

Aus `Improvements.md`:

- `symbol_locator.via_treesitter` nutzt trotz des Namens Regex-Patterns.
- `table_locator.find_balanced_region` zählt Klammern manuell mit Tiefen-Tracking —
  fehleranfällig; in `v0.2_Features.md` ist dort schon einmal eine Endlosschleife
  gefixt worden.

- [ ] Beide auf echte Treesitter-Queries umstellen. **Bewusst nicht in dieser
      Session gemacht** — echtes ~1-Wochen-Projekt (8 Fallback-Strategien in
      `table_locator.locate` müssen erhalten bleiben), riskant ohne
      Funktionstests blind durchzuziehen. Stattdessen: beim Testen der
      Cache-Änderung (Punkt 4) einen konkreten, reproduzierbaren Bug in
      `find_child_table` gefunden und gefixt (doppelte Klammer-Zählung auf der
      Eröffnungszeile einer Tabelle verhinderte jeden Kindschlüssel-Treffer ab
      dem zweiten Sibling) — Commits `dcec3f3`, `220b30e`. Volle Migration als
      Follow-up-Task gespawnt (task_02128309).

**Aufwand:** Mittel (je ~1 Woche, weil die Fallback-Pfade erhalten bleiben müssen)
**Nutzen:** mittel-hoch — beseitigt eine ganze Fehlerklasse statt einzelner Bugs.

### 4. Root-Inferenz cachen (`value_origin.lua`) — ✅ erledigt (2026-08-09)

`infer_roots_from_lines` ist inline definiert und liest die Datei bei **jedem**
`try_locate_with_roots`-Aufruf neu. `binding_index.lua` hat dafür schon das
richtige Muster: Cache pro Buffer mit `changedtick`-Invalidierung.

→ Cache implementiert (mtime-Key statt changedtick, da die Datei nicht
zwingend ein offener Buffer ist). **Beim Schreiben eines Funktionstests dafür
einen echten, vorbestehenden Bug gefunden**: `M.resolve()` übergab die
*volle* Chain (inkl. letztem Blatt-Key) sowohl als `extra_chain` als auch
separat als `seek_key` — `try_locate_with_roots` suchte dadurch immer eine
Ebene zu tief und konnte den eigentlichen "value origin"-Kernfall (z. B.
`cfg.highlight.enable_x`) nie finden. Gefixt: Chain ohne letztes Segment an
`resolve_base` übergeben. Commit `dcec3f3`.

**Aufwand:** Quick Win
**Nutzen:** mittel — spürbar nur in grossen Dateien, aber billig zu haben.

### 5. Kleinere offene Punkte aus `roadmap.md` — ✅ erledigt (2026-08-09)

| Punkt | Aufwand | Nutzen | Status |
|---|---|---|---|
| Environment-Variablen im Pfad expandieren (`$REPOS_DIR/...`) | Quick Win | hoch — wird in der eigenen Config permanent benutzt | War bereits gebaut (`env_variable_resolution`), nur verifiziert |
| `:h` / Vimdoc | Mittel | mittel | Diese Session: vimdoc für alle 9 Punkte aktualisiert |
| Types ausdefinieren | Mittel | mittel | War bereits weitgehend gebaut (`@types/`-Bäume + LuaLS-Commit), nur verifiziert |
| Hardcodierte Extension-Liste in `external/helpers/detector.lua` an `config` durchreichen | Quick Win | mittel — Config-Feld existiert laut Notiz schon, nur nicht verdrahtet | Verdrahtet: `external.extensions` erweitert die Liste, `external.enable=false` deaktiviert komplett (war vorher auch tot). Commit `193e557` |

### 6. Alternate-UI: Backend, Preview, Lernen — ⏳ teilweise (2026-08-09)

Aus `Improvements.md` „Future Enhancements":

- [x] UI-Backend konfigurierbar (statt fix `vim.ui.select`) — **War bereits
      gelöst**, allerdings anders als vorgeschlagen: `alternate/ui.lua` nutzt
      `lib.nvim.ui.kit.select` mit `respect_override = true`, was auf die vom
      User konfigurierte `vim.ui.select`-Override (telescope-ui-select,
      dressing.nvim, …) ausweicht. Deckt das eigentliche Ziel
      (Ökosystem-Konsistenz) ab, ohne harte `pickers.nvim`-Abhängigkeit.
- [x] Preview in der Alternate-Auswahl (erste Zeilen, Grösse, mtime). →
      Grösse + mtime umgesetzt (`directory.file_meta()`); "erste Zeilen"
      bräuchte eine echte Preview-Pane, die `kit.select`/`kit.picker` heute
      nicht anbieten (nur Prompt+Results-Slots) — das wäre wieder
      `pickers.nvim`-Territorium.
- [ ] Häufigkeits-Lernen: oft gewählte Alternates hochsortieren. **Nicht
      umgesetzt** — Cross-Repo-Arbeit (lib.nvim + pickers.nvim + gopath),
      bewusst nicht blind in einer Session angefasst. In `docs/ROADMAP.md`
      als geplantes Feature nachgetragen.
- [x] Eigene Similarity-Funktion statt fix Levenshtein (z. B. Prefix-Matches
      bevorzugen). → `calculate_similarity()` gibt jetzt mindestens das
      Präfix-Längen-Verhältnis zurück, wenn ein String Präfix des anderen ist.

Commit `5a597ca`.

**Aufwand:** Backend-Anbindung Mittel, Preview Quick Win, Lernen Mittel
**Nutzen:** Backend hoch (Konsistenz im Ökosystem), Rest mittel.

### 7. Fehler-Recovery beim Öffnen — ✅ erledigt (2026-08-09)

Kein Fallback, wenn der externe Opener fehlschlägt oder Rechte fehlen.
`lib.nvim.cross` hat inzwischen die harte Windows-Erfahrung aus `reveal_in_fm`
verarbeitet — hier sollte dieselbe Mechanik genutzt und nicht noch einmal
separat gelöst werden.

→ `reveal_in_fm` ist für "im Dateimanager anzeigen", nicht das hier
Gesuchte — der passende Baustein ist `lib.nvim.fs.open.url.system_opener`,
den `opener.lua` schon nutzt. Der eigentliche Bug: schlug `system_opener`
fehl (z. B. kein `xdg-open` auf einem schlanken Linux), gab gopath sofort
auf, statt auf den eingebauten Minimal-Fallback (der sonst nur greift, wenn
`lib.nvim` komplett fehlt) durchzufallen. Jetzt kaskadiert
`open.nvim → system_opener → Minimal-Opener` bei jedem Fehlschlag. Commit
`d4e0d29`.

**Aufwand:** Quick Win
**Nutzen:** mittel.

### 8. Bug aus `Bugs.md` — ✅ erledigt (2026-08-09)

- [x] `event = "VeryLazy"` ist für die Initialisierung zwingend. Entweder in
      `plugin_spec`/README als Pflicht dokumentieren oder die Initialisierung so
      umbauen, dass sie ohne dieses Event auskommt.
      → Umbau ist von innen nicht möglich (Lazy-Load-Trigger werden vom User
      in dessen eigener Spec-Tabelle deklariert, nicht vom Plugin selbst).
      Stattdessen in README/installation.md/vimdoc/troubleshooting.md
      **prominent als Pflicht** dokumentiert, inkl. eigenem
      Troubleshooting-Eintrag ("gP tut nichts, und :Gopath/:checkhealth
      existieren auch nicht"). Commit `0f6d9cd`.

**Aufwand:** Quick Win
**Nutzen:** mittel — sonst stiller Ausfall bei fremden Setups.

### 9. Recherchenotiz: `includeexpr` / `suffixesadd` — ✅ erledigt (2026-08-09)

`Notes/includeexpr-sufficesadd.md` beschreibt die Vim-native Kette
`<cfile>` → `includeexpr` → `findfile()` → `suffixesadd`. gopath umgeht das heute
komplett.

- [x] Prüfen, ob die builtin-Resolver `suffixesadd` respektieren sollten — das ist
      die Erwartungshaltung von Usern, die von `gf` kommen.
      → **War bereits korrekt**: `util/path.lua`'s `search_with_vim_path`
      (von `filetoken.lua` für den generischen `<cfile>`-Resolver genutzt)
      nutzt `vim.fn.findfile()` mit `vim.o.suffixesadd`, exakt wie `gf`. Nur
      dokumentiert (vorher stand nur "&path", nicht explizit `suffixesadd`).
      `includeexpr` bleibt bewusst ungenutzt — gopaths eigene Pipeline deckt
      ab, wofür es typischerweise pro Filetype konfiguriert würde. Commit
      `f846c52`.

**Aufwand:** Quick Win (Prüfung), Mittel (falls Umsetzung)
**Nutzen:** mittel.

---

## Session-Zusammenfassung (2026-08-09)

Alle 9 Punkte abgearbeitet, jeweils dokumentiert (vimdoc + `docs/features.md`
+ ggf. `docs/configuration.md`/`docs/RESOLUTION(.md/-DE.md)`) und einzeln auf
`main` gepusht (Commits `9595266` … `f846c52`). Drei der neun Punkte waren
bereits vollständig implementiert und brauchten nur Verifikation +
Dokumentation (1, 2, 9). Bei den übrigen sechs wurden echte Code-Änderungen
gemacht — davon zwei **echte vorbestehende Bugs** gefunden und gefixt, die
über den ursprünglichen Punkt hinausgingen (der `table_locator`-Klammer-
Zähl-Bug und der `value_origin`-Chain/seek_key-Overlap-Bug — beide über
einen selbstgeschriebenen Funktionstest aufgedeckt, nicht durch Code-Lesen
allein). `docs/BINDINGS.md` und die persönlichen
`NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/gopath.nvim.md`
brauchten **keine** Änderung — diese Session hat keine Keymaps/Commands/
Autocmds hinzugefügt oder verändert, nur interne Logik und Doku. Offen
geblieben, bewusst nicht blind angefasst: volle Treesitter-Migration von
`table_locator`/`symbol_locator` (Punkt 3, Follow-up-Task gespawnt) und
Frecency-Lernen für Alternates (Punkt 6, Cross-Repo-Arbeit, in
`docs/ROADMAP.md` nachgetragen).
