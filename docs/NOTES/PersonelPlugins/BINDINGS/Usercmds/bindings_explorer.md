# bindings-explorer — `:Bindings [subcommand]` Cheatsheet

Ein Verb über `lib.nvim.usercmd.composer`, wie `:Case`/`:Image`. Bare
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
