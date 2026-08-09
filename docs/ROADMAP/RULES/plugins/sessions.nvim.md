# sessions.nvim

## Zweck
Branch- und projekt-bewusste Neovim-Sessions auf Basis der eingebauten `:mksession`/
`:source`, mit Metadaten (`.json`-Begleitdatei), portablen Pfaden über Maschinen/OS hinweg,
Tab- und Layout-Scoping, Git-Integration (`skip-worktree`-Toggle zum Sync ohne Commit) und
einem optionalen Picker (Snacks/Telescope). Baut auf lib.nvim, fällt bei fehlenden
lib.nvim-Submodulen auf native `vim.fn`/`vim.system`-Implementierungen zurück.

## Nicht-standard Patterns / Algorithmen

- `lua/sessions/core.lua:271-274` — vor dem `:source` einer Session wird `only!`/`tabonly!`
  ausgeführt, um Windows/Tabs zu kollabieren; davor werden per `modified_buffer_names()`
  (Zeile 146-159) alle modifizierten Buffer identifiziert und (implizit über `only!`)
  versteckt statt verworfen. Kommentiert als "E445 fix" (README.md:80) — verhindert, dass
  die Session-Datei eigenes `only`/`tabonly` gegen ungespeicherte Änderungen läuft und mit
  E445 abbricht. Naiver Ansatz wäre ein Fehler oder Datenverlust gewesen.
- `lua/sessions/core.lua:124-144` (`wipe_blacklisted`) — vor jedem Save werden Buffer nach
  buftype/filetype/Pfadpräfix-Blacklist zwangsweise per `nvim_buf_delete({force=true})`
  entfernt, damit z.B. Quickfix- oder Temp-Buffer nie in der Session landen. Ein
  Standardansatz (einfach `:mksession` laufen lassen) würde diesen Noise mit aufnehmen.
- `lua/sessions/portable.lua:1-8, 37-84` — Portabilität wird NICHT durch Eingriff in
  Neovims eigenes `:mksession`, sondern als Nachbearbeitung der resultierenden Plain-Text
  `.vim`-Datei gelöst: alle Vorkommen des cwd (in zwei möglichen Schreibweisen, die
  `:mksession` erzeugen kann — geslashter absoluter Pfad und `fnamemodify(..., ':~')`-Form,
  Zeile 53-67) werden durch einen Platzhalter `{{SESSION_ROOT}}` ersetzt. Beim Laden wird
  aus einer *temporären Kopie* (nie der Originaldatei, Zeile 96-119) der Platzhalter wieder
  aufgelöst — die gespeicherte Datei bleibt für andere Maschinen/OS unverändert korrekt.
  Grund: die eingebaute `cd`/`lcd`-Zeile und Pfade außerhalb `cwd` bleiben sonst
  host-absolut, selbst mit `curdir` in `sessionoptions`.
- `lua/sessions/portable.lua:37-51` (`pat_escape`/`repl_escape`) — sowohl das Such- als
  auch das Ersetzungsmuster werden für Lua-Pattern-Sonderzeichen escaped (Klammern, `%`,
  `.`, `+`, `-`, `*`, `?`, `[`, `]`, `^`, `$` bzw. `%` in der Ersetzung) — ein Pfad mit
  Klammern oder Punkten (Windows-Programme, versionierte Ordnernamen) würde sonst als
  Lua-Pattern fehlinterpretiert statt als Literal behandelt.
- `lua/sessions/git.lua:9-33, 37-56` — dreifacher Fallback pro Git-Operation: zuerst
  `lib.nvim.git`/`lib.nvim.fs.find_upward_dir`, dann `vim.system`, dann `vim.fn.system` +
  `vim.v.shell_error`. Zusätzlich werden lib.nvim-Rückgaben explizit gegen "sieht wie eine
  Fehlermeldung aus" geprüft (`branch:lower():find("error")`, Zeile 15, 29-31, 42) — eine
  Absicherung gegen den Fall, dass eine Abstraktionsschicht einen Fehlerstring statt eines
  echten Ergebnisses zurückgibt und dieser sonst unbemerkt als gültiger Branch-/Root-Name
  weiterverwendet würde.
- `lua/sessions/git.lua:62-82` (`sanitize`) — Whitelist-Filterung (`[^%w%-_]` → `-`) plus
  vorheriges Entfernen von ANSI-Escape-Sequenzen (`\27%[[0-9;]*m`, Zeile 66) BEVOR
  whitelistet wird — ein Branch-Name aus einer Git-Ausgabe mit Farbcodes würde sonst
  Steuerzeichen in einen Dateinamen einschleusen. Läuft anschließend Runs von Bindestrichen
  zusammen (Zeile 76) und trimmt Rand-Bindestriche.
- `lua/sessions/core.lua:101-121` (`resolve`) — Save und Load nutzen bewusst
  unterschiedliche Auflösungslogik: Save resolved bei fehlendem Namen den Projekt-/
  Branch-Namen live (und lädt `sessions.git` nur dann, `git_aware`-Gate, Zeile 108-110, um
  nie unnötig zu shellen), Load bevorzugt stattdessen die "zuletzt geladene" Session aus
  `state`, mit Existenzcheck (`filereadable`) BEVOR sie verwendet wird (Zeile 114-119) —
  ein gelöschtes "remembered" verweist nicht ins Leere.
- `lua/sessions/core.lua:220-254` (`save_tab`) — für Tab-Snapshots wird `sessionoptions`
  temporär um `"tabpages"` reduziert (`strip_tabpages`, Zeile 78-87) und danach sofort
  wiederhergestellt (`apply_sessionoptions()`, Zeile 240), damit `:mksession` nur den
  aktuellen Tab aufzeichnet, ohne die globale Nutzerkonfiguration dauerhaft zu verändern.

## Abgeleitete Guidelines

1. Vor jedem `:mksession`/Buffer-Manipulations-Flow prüfen, ob ungespeicherte Buffer
   E445-artige Fehler bei `only!`/`tabonly!` auslösen können, und sie vorher explizit
   kollabieren/verstecken statt den Fehler laufen zu lassen.
2. Portabilität über Maschinen/OS durch Nachbearbeitung generierter Plain-Text-Artefakte
   lösen (Platzhalter-Substitution), statt in interne Engine-Internals einzugreifen — und
   dabei nie die Originaldatei mutieren, sondern über eine temporäre Kopie laden.
3. Bei jeder Such-/Ersetz-Operation mit nutzerkontrolliertem String als Lua-Pattern:
   sowohl Such- als auch Ersetzungsstring escapen (Pattern-Sonderzeichen bzw. `%`).
4. Fallback-Ketten (lib.nvim → `vim.system` → `vim.fn.system`) nicht nur auf Erfolg/
   Misserfolg des Calls prüfen, sondern die Rückgabe selbst gegen "sieht nach Fehlertext
   aus" validieren, wenn die Abstraktionsschicht Fehler als String statt als echten
   Fehlerwert zurückgeben kann.
5. Nutzerkontrollierte Strings, die Dateinamen-Bestandteile werden (Branch-Namen,
   Projekt-Basenamen), immer whitelist-sanitizen UND vorher Escape-/Steuersequenzen
   (ANSI-Codes) entfernen — Blacklist allein reicht nicht.
6. Bei "Save nur mit Explizit-Namen oder Auto-Resolve" vs. "Load mit Remember-Fallback"
   bewusst zwei unterschiedliche Resolutionsstrategien zulassen, statt eine gemeinsame
   Funktion für beide Fälle zu erzwingen — die Semantik unterscheidet sich tatsächlich.
7. Temporäre globale Optionsänderungen (`sessionoptions`) immer in einem eng begrenzten
   Save/Load-Aufruf wieder zurücksetzen, nie den geänderten Zustand nach außen durchsickern
   lassen.
8. Buffer-Blacklisting (buftype/filetype/Pfadpräfix) vor persistenten Snapshots aktiv
   durchsetzen statt sich auf `sessionoptions`-Filterung allein zu verlassen.

## Keybindings-Audit

Alle Keymaps sind standardmäßig deaktiviert (`keymaps = false`); nur aktiv, wenn der Nutzer
in `setup({ keymaps = {...} })` eine lhs setzt (`docs/BINDINGS.md:3-19`,
`lua/sessions/bindings/keymaps/init.lua`).

| Config-Key | Vorgeschlagenes lhs | Aktion |
|---|---|---|
| `save` | `<leader>ssa` | `:Session save` |
| `load` | `<leader>slo` | `:Session load` |
| `save_ts` | `<leader>sst` | `:Session save-timestamp` |
| `list` | `<leader>sli` | `:Session list` |

- `count`-Unterstützung: n.a. für alle vier — Save/Load/List sind singuläre Aktionen ohne
  sinnvolle "N-mal"-Semantik (Session-Save ist idempotent pro Aufruf, ein Count würde nichts
  bewirken).
- Ex-Command-Completion: `:Session save/load/delete/rename/toggle-track [name]`
  vervollständigen dynamisch gegen die aktuelle Sessionliste (`bindings/usercmds/init.lua:59-62`,
  `composer.register_type("SESSION", ...)`), `save-tab`/`load-tab` gegen eine separate
  Tab-Session-Liste, `save-layout`/`load-layout` gegen die Layout-Liste — alle drei Typen
  lesen live, keine eingefrorene Liste. Gute Abdeckung.
- Fehlende Flags/Ideen: kein Keymap für `:Session current` oder `:SessionLoad` (Picker) im
  Default-Bindings-Set vorgesehen — beide wären naheliegende Ergänzungen für Nutzer, die den
  Picker regelmäßig brauchen. `:Session delete`/`rename` haben ebenfalls keine
  Keymap-Option — vermutlich bewusst, da destruktiv/selten genug für reine Ex-Command-Nutzung.

## Ideen für andere Plugins

- **Generisches Portable-Path-Modul** für lib.nvim: das Placeholder-Substitutions-Pattern
  aus `portable.lua` (Pfad → Platzhalter beim Schreiben, Platzhalter → aktueller Pfad beim
  Lesen, nie das Original mutieren) ist ein wiederverwendbares Primitiv für jedes Plugin,
  das Artefakte cross-machine synct (Notizen, Bookmarks, Projekt-Configs).
- **Git-Skip-Worktree-Toggle-Helper**: `toggle_track`'s Logik (Datei ist getrackt vs.
  skip-worktree, Toggle je nach Zustand) taucht wahrscheinlich in weiteren
  "Config-Repo synct persönliche/transiente Dateien"-Szenarien wieder auf — als eigenständiger
  lib.nvim-Baustein sinnvoll.
- **Fallback-Ketten-Validator**: ein kleines Utility, das eine dreistufige Fallback-Kette
  (bevorzugte lib → `vim.system` → `vim.fn.system`) inklusive "sieht nach Fehlertext aus"
  Validierung generisch kapselt, statt dass jedes Plugin dieses Muster (wie hier in
  `git.lua`) einzeln neu schreibt.
