# reposcope.nvim

## Zweck
Sucht, previewt und klont GitHub-/GitLab-/Codeberg-Repositories direkt aus
Neovim heraus, über eine Telescope-inspirierte, aber selbstgebaute UI (Prompt,
Liste, README-Preview, Hintergrund-Fenster) mit mehreren Providern und
mehreren Clone-Backends (gh, git, curl, wget). Quelle:
`E:\repos\reposcope.nvim\README.md`.

## Nicht-standard Patterns / Algorithmen
- `lua/reposcope/bindings/keymaps.lua:30,80-118,317-336` (`_registry`,
  `unmap_over_bufs`, `_clear_registered_keymaps`): Ein manuelles
  Keymap-Registry-Pattern — jede über `map_over_bufs` gesetzte Zuordnung wird
  mit `{mode, lhs, buffer, tag}` in einer modul-lokalen Liste gemerkt, damit
  sie später gezielt per Tag (`"reposcope_ui"`, `"reposcope_prompt_<field>"`)
  wieder entfernt werden kann — nötig, weil Reposcope seine UI-Buffer bei
  jedem Öffnen/Schließen neu erzeugt und sonst verwaiste Keymaps oder
  doppelte Registrierungen entstünden. `_clear_registered_keymaps` verweigert
  zudem explizit das Löschen ohne einen validen `reposcope_*`-Tag-Präfix
  (Zeile 318) — eine defensive Guard gegen versehentliches Löschen fremder
  Tags.
- `lua/reposcope/bindings/keymaps.lua:182-195` (`backspace`-Action): Backspace
  wird im Prompt-Buffer gezielt deaktiviert, wenn der Cursor exakt in Spalte 0
  von Zeile 2 steht — verhindert, dass der Nutzer über den Anfang eines
  strukturierten Prompt-Feldes hinaus löscht (z. B. in ein Präfix/Label
  hinein), was die Buffer-Struktur der Custom-UI korrumpieren würde.
- `lua/reposcope/cache/repository_cache.lua:99-123` (`M.set` /
  `_sanitize_repo`): API-Antworten werden vor dem Cachen defensiv
  sanitisiert — fehlende `name`/`owner.login`/`description`-Felder werden
  durch Platzhalter ersetzt (mit Warn-Notify), statt dass eine unvollständige
  API-Antwort später beim Rendern zu einem Fehler oder einer leeren Zeile
  führt.
- `lua/reposcope/cache/repository_cache.lua:161-211` (`M.get_selected`):
  Ermittelt das aktuell selektierte Repository nicht über einen gehaltenen
  Objekt-Index, sondern durch **Zurückparsen** der sichtbaren Buffer-Zeile
  (`"owner/reponame: description"` via Pattern-Match) und Abgleich gegen die
  Item-Liste — an mehreren Stellen defensiv abgesichert (Buffer-Gültigkeit,
  Zeilen-Anzahl-Grenze, Parse-Erfolg). Kopplung von UI-Text und Datenmodell
  über Text-Reparsing statt über eine stabile Referenz ist ungewöhnlich und
  fehleranfällig bei Formatänderungen der Anzeigezeile, aber hier bewusst so
  gewählt, vermutlich weil die Liste rein textbasiert (kein Extmark-Tracking
  pro Zeile) aufgebaut ist.
- `lua/reposcope/cache/repository_cache.lua:99-123,223-247`
  (`relevance_result`/`restore_relevance_sorting`): Ein zweiter, paralleler
  Cache-Slot hält explizit die *ursprüngliche* (nach Relevanz sortierte)
  API-Antwort, unabhängig vom aktuell angezeigten (ggf. umsortierten/gefilterten)
  Zustand — ermöglicht `:Reposcope sort relevance`, ohne erneut die API
  aufzurufen.
- `lua/reposcope/utils/protection.lua:104-132` (`is_valid_filename`) und
  `139-170` (`is_valid_path`): Eigene, mehrstufige Validierung (verbotene
  Zeichen inkl. Nullbyte, Nur-Whitespace-Check, Verzeichnis-vs-Datei-Pfad-
  Heuristik über fehlenden Trailing-Slash) statt sich allein auf
  Betriebssystem-Fehler beim Schreiben zu verlassen — fängt ungültige Namen
  vor dem eigentlichen I/O ab.
- `lua/reposcope/utils/protection.lua:204-215` (`is_dir_writeable`): Prüft
  Schreibbarkeit eines Verzeichnisses durch tatsächliches Anlegen und
  Löschen einer Testdatei (`.rs_write_test`) statt sich auf Datei-Metadaten/
  Permission-Bits zu verlassen — plattformübergreifend robuster, aber mit
  echtem I/O-Seiteneffekt (wenn auch minimal und aufgeräumt).
- `lua/reposcope/utils/protection.lua:217-233` (`safe_execute_shell`):
  Unterscheidet explizit zwischen einem String-Kommando (`vim.fn.system`,
  Shell-Interpretation) und einem argv-Table (`lib.nvim.cross.run_argv`, ohne
  Shell) — Kommentar begründet das mit Vermeidung von Shell-Quoting-Fallen bei
  Pfaden mit Leerzeichen, plattformübergreifend (Windows cmd.exe vs. POSIX).
- `lua/reposcope/providers/github/clone/clone_command.lua:1-34`: Baut
  Clone-Kommandos konsequent als argv-Tabellen (`{"gh","repo","clone",...}`)
  statt als zusammengesetzte Shell-Strings — aus demselben Grund wie oben:
  keine Shell-Quoting-Probleme bei Pfaden/URLs mit Sonderzeichen, identisches
  Verhalten auf Windows und POSIX.
- `lua/reposcope/ui/prompt/prompt_autocmds.lua` (laut `docs/BINDINGS.md:119-127`,
  nicht vollständig gelesen): Sperrt den Cursor per Autocommand-Kombination
  (`CursorMoved`, `CursorMovedI`, `InsertEnter`, `InsertLeave`) auf Zeile 2 des
  aktiven Prompt-Buffers — eine Custom-Single-Line-Input-Emulation innerhalb
  eines normalen Buffers statt eines nativen `vim.ui.input`.

## Abgeleitete Guidelines
1. Wenn eine UI ihre Buffer bei jedem Öffnen/Schließen neu erzeugt: Keymaps
   nicht "hoffnungsvoll" setzen und vergessen, sondern in einer eigenen
   Registry mit Tag pro Lebenszyklus-Phase (`ui`, `prompt_<field>`, ...)
   verwalten, damit gezieltes Aufräumen möglich ist, ohne fremde Mappings zu
   beschädigen.
2. Cleanup-Funktionen, die potenziell gefährlich sind (globales Entfernen von
   Zustand), sollten einen expliziten Namespace-Präfix-Guard erzwingen (hier:
   `"reposcope_*"`-Tag-Pflicht) statt sich auf disziplinierte Aufrufer zu
   verlassen.
3. Externe API-Antworten vor dem Cachen/Rendern defensiv sanitisieren
   (fehlende Pflichtfelder durch erkennbare Platzhalter ersetzen, mit
   Warnung) statt erst beim Rendern mit `nil`-Feldern zu scheitern.
4. Shell-Aufrufe grundsätzlich als argv-Tabelle statt als zusammengesetzten
   String bauen, wann immer die zugrunde liegende Runtime das unterstützt
   (`lib.nvim.cross.run_argv`) — eliminiert eine ganze Klasse von
   Quoting-/Injection-Bugs plattformübergreifend.
5. Schreibbarkeits-Checks von Verzeichnissen über einen echten Schreibtest
   (anlegen + löschen), nicht nur über Metadaten-Inspektion — robuster
   gegenüber exotischen Dateisystemen/Berechtigungsmodellen.
6. Bei textbasierten Custom-UI-Listen (kein natives Widget): wenn Zeilenformat
   und Datenmodell auseinanderdriften können, das Format an einer einzigen
   Stelle definieren (Build- und Parse-Funktion nebeneinander, wie hier
   `_build_repo_line` neben dem Parse-Pattern in `get_selected`) statt es an
   mehreren Stellen zu duplizieren.
7. Für Sortier-/Filter-UIs, die den Ursprungszustand wiederherstellen können
   sollen: den unveränderten Originalzustand explizit getrennt vom aktuell
   angezeigten (gefilterten/sortierten) Zustand cachen.

## Keybindings-Audit
Quelle: `docs/BINDINGS.md`, `lua/reposcope/bindings/keymaps.lua`.

Global (user-konfigurierbar, `n`):
- `<leader>rs` (`keymaps.open`, Reposcope öffnen): Count n. a. (öffnet eine
  UI, kein iterierbares Ziel). Autocompletion n. a. (kein Text-Input).
- `<leader>rc` (`keymaps.close`, Reposcope schließen): analog.

Prompt-Buffer (buffer-lokal, konfigurierbar über `prompt_keymaps`):
- `confirm` (`<CR>`, i): Bestätigt Prompt-Eingabe. Count n. a.
- `nav_up`/`nav_down` (`<Up>`/`<Down>`, n+i): Navigiert Liste + lädt README.
  - Count sinnvoll? **Nein implementiert, aber denkbar.** Ein `3<Down>`-artiges
    "drei Einträge weiter" wäre für eine lange Ergebnisliste plausibel
    nützlich, ist aber laut gelesenem Code nicht umgesetzt — jeder Tastendruck
    bewegt genau einen Eintrag.
- `focus_next`/`focus_prev` (`<C-w>`/`<C-l>`/`<Tab>` bzw. `<C-h>`/`<S-Tab>`,
  n+i): Fokus zwischen Prompt-Feldern wechseln. Count n. a. (Feld-Anzahl ist
  klein und fix).
- `open_viewer` (`<C-v>`, n+i): README-Viewer öffnen. Count n. a.
- `open_editor` (`<C-b>`, n+i): README-Editor öffnen. Count n. a.
- `clone` (`<C-c>`, n+i): Ausgewähltes Repo klonen (fragt nach Zielverzeichnis).
  Count n. a. — Autocompletion für das Zielverzeichnis-Prompt wurde in den
  gelesenen Dateien nicht verifiziert (Datei für das Clone-Zielverzeichnis-
  Prompt nicht gelesen); bei einem Verzeichnis-Prompt wäre Pfad-Completion
  wünschenswert.
- `backspace` (`<BS>`, n+i): Sonderfall mit Positions-Guard (siehe oben).

Close-UI (alle Reposcope-Buffer):
- `<Esc>` (n): UI schließen; (i/t/v): zu Normal-Mode wechseln.
- `<C-w>` (n): UI schließen; (i/t/v): No-op (bewusst deaktiviert, verhindert
  versehentliches Fenster-Wechseln aus der Custom-UI heraus).

`:Reposcope <subcommand> [args]` (laut `docs/BINDINGS.md:73-104`): Tab-Completion
für Subcommand-Namen vorhanden; für `status`/`update` zusätzlich spezielle
Verzeichnis-Completion (`$REPOS_DIR`, `~` vor regulärer Verzeichnis-Completion,
laut `fixed_dir_keywords` in `usrcmds.lua`, nicht selbst gelesen) — insgesamt
eine der best-dokumentierten Completion-Situationen der fünf untersuchten
Plugins. `filter [text]`/`prompt [field ...]` haben freie Text-Argumente ohne
erkennbare Completion (aus BINDINGS.md nicht ersichtlich, ob vorhanden).

## Ideen für andere Plugins
- Das taggingbasierte Keymap-Registry-Pattern (`_registry` + `tag`-Guard) als
  generisches `lib.nvim.keymap.scope`-Utility anbieten — jedes Plugin mit
  wiederholt neu erzeugten UI-Buffern (Custom-Picker, Floating-UIs) hat
  dasselbe Cleanup-Problem.
- Ein generisches "API-Response-Sanitizer"-Muster (Pflichtfelder mit
  Platzhalter + Warnung statt Crash) als `lib.nvim`-Baustein für alle
  Plugins, die externe JSON-APIs konsumieren (auch pdfport.nvim-Backends,
  falls die je strukturierte Antworten liefern).
- Ein eigenständiges "Custom-Single-Line-Prompt-Buffer"-Widget (Cursor-Lock via
  Autocommands, wie in `prompt_autocmds.lua` angedeutet) als wiederverwendbare
  `lib.nvim.ui`-Komponente, statt dass jedes Plugin mit eigener Text-Eingabe-UI
  das Cursor-Locking neu erfindet.
