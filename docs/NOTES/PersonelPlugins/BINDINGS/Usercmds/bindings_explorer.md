# bindings-explorer — `:Bindings [subcommand]` Cheatsheet

Ein Verb über `lib.nvim.bindings.usercmd.composer`, wie `:Case`/`:Image`. Bare
`:Bindings` ohne Subcommand ist gleichbedeutend mit `:Bindings search`.

Source: `lua/bindings/usrcmds/bindings_explorer/`
Docs: `lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md`, `:help bindings_explorer`

| Command | Effect |
| --- | --- |
| `:Bindings` | Wie `:Bindings search` |
| `:Bindings search [query]` | Live-Grep über beide BINDINGS-Bäume (Picker-Engine via `pickers.nvim`, sonst Prompt+Liste) |
| `:Bindings search keymaps\|usercmds\|autocmds [query]` | Dieselbe Suche, auf eine Unterkategorie gescopt |
| `:Bindings browse [scope]` | Picker über geparste Tabellenzeilen (alle drei Kategorien) statt Volltext |
| `:Bindings browse keymaps\|usercmds\|autocmds [scope]` | Dieselbe Tabellenzeilen-Suche, auf eine Kategorie gescopt |
| `:Bindings path [personal\|extern]` | BINDINGS-Wurzel(n) in die Zwischenablage kopieren |
| `:Bindings check [plugin]` | Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert (Personal, read-only) |

`scope` bei `browse` ist `personal`/`extern` (optional, ohne Argument beide).

## Notes

- **Kein `## which-key`**: `bindings_explorer` registriert keine Keymaps —
  bewusst usercommand-only, wie `:Case`/`:Image` auch für ihre
  Argument-tragenden Subcommands entscheiden. Es gibt daher auch keine
  `Keymaps/bindings_explorer.md` in diesem Ordner.
- **`search` vs. `browse`**: `search` durchsucht rohen Zeilentext (findet
  auch Prosa/Notes-Abschnitte), `browse` durchsucht nur geparste
  Tabellenzeilen (strukturierter, aber blind für alles außerhalb einer
  Tabelle). Siehe `docs/FEATURES.md` für die volle Begründung.
- **`check` ist bewusst eingeschränkt** (nur Personal, nur eine Richtung
  bei Keymaps, buffer-lokale/filetype-gescopte Keymaps sind ein bekannter
  False-Positive-Fall, noch nicht geladene Plugins werden übersprungen und
  namentlich gemeldet statt fälschlich als fehlend) — volle Begründung in
  `drift.lua`s Moduldoc, nicht hier dupliziert.
- **`:Bindings path` ergänzt, ersetzt nicht** das ältere `:BindingsPath`
  (`lua/bindings/usrcmds/init.lua`) — letzteres bleibt unverändert
  bestehen, zeigt aber weiterhin auf den nie existierenden Pfad
  `docs/NOTES/BINDINGS` statt der beiden echten Wurzeln.

## Changelog

- 2026-08-07: `:Bindings search`/`path` (Phase 1) implementiert.
- 2026-08-07 (2): Live-Grep-in-Picker (`pickers.nvim`-Engine-Schicht) statt
  reinem Prompt+Liste-Fluss, Kategorie-Scoping für `search` ergänzt.
- 2026-08-09: `:Bindings browse` (Phase 2, Tabellenzeilen-Picker) und
  `:Bindings check` (Phase 3, Drift-Bericht) ergänzt. Der ursprüngliche
  Konzept-Entwurf (`docs/ROADMAP/personal/bindings-explorer.nvim.md`) beim
  Aufräumen der Roadmap gelöscht — Feature war zu diesem Zeitpunkt
  vollständig umgesetzt, `docs/FEATURES.md` (im Modul selbst) ist seither
  die aktuelle Doku. Dieses Cheatsheet nachgezogen — fehlte bisher
  komplett, obwohl der Command längst existierte (dasselbe Muster, das
  `:Bindings check` selbst aufdecken soll).

## `:Bindings check` — die dritte Achse: Source (2026-08-15)

`drift.lua` verglich bisher zwei Achsen: **dokumentiert** (die BINDINGS-
Cheatsheets über `records.lua`) gegen **live** (`nvim_get_keymap`/
`nvim_get_commands`). Neu ist **Source** — was dieser Config-Quelltext
tatsächlich registriert, extrahiert von documentation.nvims
`core/bindings.lua` und aus `docs/map/module_map.json` gelesen
(`source.lua`).

**Warum das genau die fehlende Richtung möglich macht.** Die eigene
Einschränkung 1 in `drift.lua` sagt, „live aber undokumentiert" sei nicht
gebaut worden, weil man dafür gegen *jeden* globalen Keymap diffen müsste —
vims Defaults, matchit, jedes Plugin — und der Report damit geflutet wäre.
Dieser Einwand betrifft ausschließlich die **live**-Achse. Die Source-Achse
enthält bauartbedingt nur Registrierungen aus **diesem Repository**, also
exakt die Menge, die die Personal-Cheatsheets abdecken sollen. „Im Source,
nicht in den Docs" ist damit eine saubere, begrenzte Frage, die „live, nicht
in den Docs" nie sein konnte.

Neue Finding-Arten: `keymap-undocumented`, `usercmd-undocumented-source`.
Erster echter Lauf: **194 Findings** (150 Keymaps, 44 Usercmds), jeweils mit
`file:line`.

**Nur eine Richtung.** „Dokumentiert, aber nicht im Source" wird bewusst
*nicht* gemeldet: ein dokumentiertes Binding lebt legitim im Repo eines
Plugins statt hier, und der Fall „dokumentiert, aber wirklich weg" ist
bereits von `keymap-not-live` abgedeckt.

**Liest das Artefakt, scannt nicht.** `module_map.json` ist bereits generiert
und committed, und documentation.nvims Artefakte sind ausdrücklich kalt
lesbar. Ein Scan hier würde ~500 Dateien neu parsen, um Daten herzuleiten,
die auf der Platte liegen.

**Der Preis davon, ausgesprochen statt versteckt:** das Artefakt ist nur so
frisch wie das letzte `:DocMap`. Ein seither hinzugefügtes Binding fehlt in
dieser Achse. Deshalb meldet `source.lua` ein veraltetes oder fehlendes
Artefakt als *Grund* (dritter Rückgabewert von `drift.check`, gerendert von
`describe`) — nie als „keine Bindings gefunden". Die beiden Aussagen sind
verschieden, und ein Report, dem still eine ganze Achse fehlt, liest sich
sonst genau wie einer, in dem diese Achse nichts gefunden hat.

Damit das funktioniert, musste documentation.nvim `bindings` **immer** in
`module_map.json` schreiben (Commit `96eeacf` dort) — ein weggelassenes Feld
und „registriert nichts" wären sonst ununterscheidbar.
