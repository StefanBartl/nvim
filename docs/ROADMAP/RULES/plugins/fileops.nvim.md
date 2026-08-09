# fileops.nvim

## Zweck
`fileops.nvim` bündelt alle Datei-Lebenszyklus-Operationen (create, rename, move,
duplicate, copy, delete, touch, bulk-rename, "cycle" durch Dateien eines
Verzeichnisses, cd-to-buffer-dir, Pfad-in-Zwischenablage, Lock-Diagnose) hinter
einem einzigen Ex-Befehl `:File[!] {subcommand}` sowie einer parallelen Lua-API
(`lua/fileops/init.lua`). Alle Filesystem-Mutationen laufen über libuv
(`vim.uv`/`vim.loop`) bzw. `lib.nvim.cross.fs.mutate`, nie über eine Shell. Zwei
optionale Ambient-Features kommen dazu: Git-Conflict-Marker-Highlighting
(`features/conflict_marks.lua`) und eine CursorHold-Line-Diff-Vorschau
(`features/on_hold.lua`). Laut `docs/architecture.md` ist `lib.nvim` trotz
gegenteiliger README-Aussage ("no mandatory dependency") faktisch eine
**harte** Abhängigkeit (siehe Abschnitt "Nicht-standard Patterns").

## Nicht-standard Patterns / Algorithmen

1. **Windows-Sharing-Violation-Retry mit aktiver Handle-Freigabe**
   `lua/fileops/ops/file.lua:76-108` (`retry_opts`) — naive Retry-Logik würde
   einfach mit Backoff warten. Hier wird zusätzlich bei jedem Retry aktiv
   `lib.nvim.neotree.watch.release(path)` aufgerufen, weil neo-tree seine
   `fs_event`-Handles nur `:stop()`t statt `:close()`t und Windows die Datei
   dadurch bis zur GC gesperrt hält — reines Warten würde also nie zum Erfolg
   führen. Zusätzlich wird ein `User FileopsRetry`-Autocmd gefeuert, damit
   *andere* Plugins ihre eigenen offenen Handles ebenfalls freigeben können,
   bevor der nächste Versuch startet (`vim.wait` hält dabei den Event-Loop am
   Laufen, damit libuv die Handles wirklich schließt). Default-Retry-Budget in
   `config/DEFAULTS.lua:39-45`: 6 Versuche mit 60ms-Backoff nur unter Windows
   (`is_windows`), unter Unix nur 1 Versuch — bewusste Plattform-Unterscheidung,
   weil das Problem (Virenscanner/Indexer/OneDrive halten Datei kurz offen)
   Unix-spezifisch praktisch nicht auftritt.

2. **Fehlerklassifikation statt Rohcode-Weitergabe**
   `lua/fileops/ops/file.lua:110-128` (`explain_fs_error`) — EBUSY/EPERM/EACCES
   werden nach Ablauf des Retry-Budgets nicht als bloßer libuv-Code an den User
   durchgereicht, sondern mit einer konkreten, handlungsleitenden Erklärung
   angereichert ("another process is holding the file open … the open buffer
   itself is not the cause"). Bewusst, weil Nutzer bei einem rohen `EBUSY`
   reflexhaft vermuten, der eigene offene Buffer sei die Ursache — was laut
   Kommentar nie zutrifft (Neovim schließt die Datei nach dem Lesen).

3. **Asynchrone Lock-Diagnose als Sonderfall im sonst synchronen `(ok, msg)`-Vertrag**
   `lua/fileops/ops/file.lua:696-726` (`diagnose_lock`) — jede andere Funktion
   in diesem Modul gibt synchron `ok, msg` zurück; nur diese eine nutzt einen
   Callback, weil die Holder-Lookup (`lib.nvim.cross.fs.lock`) einen Hilfsprozess
   spawnt. Explizit als Ausnahme dokumentiert statt den Rückgabewert-Vertrag
   application-weit zu verkomplizieren.

4. **Bulk-Rename: Plan/Execute-Trennung mit Best-effort-Fortsetzung**
   `lua/fileops/ops/bulk.lua` — `plan()` ist eine reine, seiteneffektfreie
   Funktion (kein Rename passiert), die separat aufgerufene `execute()`-Funktion
   führt die eigentlichen Renames aus. Dadurch kann die Bindings-Schicht
   (`usrcmds.lua:do_bulk_rename`) den Plan erst per `notify.info` anzeigen und
   über `kit.confirm` bestätigen lassen, bevor irgendetwas auf Platte passiert.
   In `execute()` (Zeile 79-108) wird bei einem Fehler auf Item 3 nicht
   abgebrochen — `first_err` wird nur einmal gesetzt, aber die Schleife läuft
   für alle Items weiter ("a conflict on file 3 shouldn't block files 4..N").
   Abweichung vom naiven "stop on first error", weil ein Namenskonflikt bei
   einer Datei kein Grund ist, alle anderen ungerenamten zu lassen.

5. **Symlink-Zyklenschutz beim rekursiven Directory-Walk**
   `lua/fileops/ops/cycle.lua:89-117` (`collect_recursive`) — symlinkte
   Verzeichnisse werden nie betreten (`uv.fs_lstat` + `type == "link"`-Check
   vor dem rekursiven Aufruf), explizit damit ein Symlink-Zyklus keinen
   Endlos-Walk auslösen kann. Naive `vim.fs.dir`-Rekursion ohne diesen Check
   würde bei einem Zyklus hängen bleiben oder crashen.

6. **Fallback-Klassifikation für unklare `vim.fs.dir`-Einträge**
   `lua/fileops/ops/cycle.lua:68-87` (`classify_entry`) und identisch in
   `bulk.lua:44-47` — wenn `vim.fs.dir` den Typ eines Eintrags nicht bestimmen
   kann (`t == nil`, z.B. auf manchen Netzwerk-Mounts), wird zusätzlich
   `uv.fs_stat` befragt statt den Eintrag stillschweigend zu verwerfen oder
   fälschlich als Datei zu behandeln.

7. **"Current file not in filtered list" — temporäres Einfügen statt Fehler**
   `lua/fileops/ops/cycle.lua:293-323` (`navigate`) — wenn die aktuelle Datei
   wegen eines aktiven Filter-Patterns nicht in der Trefferliste auftaucht,
   wird sie temporär eingefügt und die Liste neu sortiert, um trotzdem einen
   sinnvollen "nächste/vorherige Datei"-Index bestimmen zu können, statt einen
   Fehler zu werfen. Naiv würde man erwarten, dass Cycle nur auf Basis der
   gefilterten Liste ohne Sonderfall arbeitet.

8. **Generation-Counter gegen veraltete `vim.defer_fn`-Callbacks**
   `lua/fileops/features/on_hold.lua:251-258, 301-316` — pro Fenster wird ein
   Zähler (`gen_by_win`) hochgezählt; ein verzögert per `vim.defer_fn`
   ausgeführter Callback prüft vor dem eigentlichen Rendern, ob seine erfasste
   Generation noch aktuell ist. Löst das Problem, dass zwischen dem Start des
   Timers und dessen Ausführung ein Moduswechsel (z.B. Normal → Insert)
   stattgefunden haben kann — ein simples `vim.defer_fn` ohne Generation-Check
   würde eine veraltete Vorschau auf den falschen Buffer/State rendern.

9. **Git-Fallback via `git blame` + `git show` statt Diff-Bibliothek**
   `lua/fileops/features/on_hold.lua:162-197` (`get_previous_line`) — statt
   eine Diff-Library einzubinden, wird die vorherige Zeile durch zwei
   argv-only `git`-Aufrufe rekonstruiert: `git blame -L n,n --porcelain`
   liefert die SHA des letzten Commits vor der aktuellen Zeile, `git show
   sha:file` liefert den Blob-Inhalt zu dieser Version, aus dem die Zeile
   extrahiert wird. Bewusst minimal statt vollständiges Line-Diffing, weil nur
   "was stand hier vorher" gebraucht wird, nicht ein vollständiger Hunk.

10. **`gitsigns.preview_hunk_inline` bevorzugt, View/Cursor explizit restauriert**
    `lua/fileops/features/on_hold.lua:319-347` — wenn gitsigns verfügbar ist
    und eine Inline-Hunk-Vorschau anbietet, wird diese bevorzugt (spart die
    eigene Fallback-Implementierung), aber `winsaveview()`+Cursor werden vorher
    gesichert und per `vim.schedule` danach wiederhergestellt, weil
    `preview_hunk_inline()` einen Scroll-Jump auslösen kann. Ein naiver aufruf
    ohne View-Save würde den Nutzer unerwartet wegscrollen lassen.

11. **Kein Shell-Aufruf irgendwo für Git** — `lua/fileops/util/git.lua` und
    `features/on_hold.lua` verwenden ausschließlich `vim.system({...})` mit
    Argv-Arrays (nie String-Konkatenation für ein Shell-Kommando) und setzen
    `cwd` explizit auf das Verzeichnis der betroffenen Datei statt auf
    Neovims globales cwd (`util/git.lua:14-24`, Kommentar: "works regardless
    of Neovim's global cwd"). Verhindert sowohl Shell-Injection als auch
    falsche Ergebnisse bei einem Repo, das nicht am globalen cwd hängt.

12. **`git rm` mit Fallback auf libuv-Delete bei Fehlschlag**
    `lua/fileops/ops/file.lua:659-677` (`delete_current`) — schlägt `git rm`
    fehl (z.B. Datei ist getrackt, aber Repo in inkonsistentem Zustand), wird
    nicht abgebrochen, sondern automatisch auf den normalen
    `fsops.delete_file`-Pfad zurückgefallen ("Fall back to a plain delete
    rather than leaving the file untouched"). Bewusste Entscheidung: das Ziel
    "Datei ist weg" hat Vorrang vor "Git-Index ist sauber".

13. **Aktive `:mksession`-Session wird nach Rename/Move nachgeführt**
    `lua/fileops/ops/file.lua:422-431` — nach einem Rename/Move wird geprüft,
    ob `v:this_session` gesetzt ist (Vim/Neovim setzt das selbst bei
    geladener/gespeicherter Session) und die Session explizit erneut
    gespeichert (`mksession! <pfad>`), damit sie nicht auf den alten Pfad
    zeigt. Der Kommentar hält fest, dass ein bloßes `:mksession!` ohne
    expliziten Pfad `v:this_session` ignorieren und stattdessen
    `./Session.vim` im cwd schreiben würde — ein konkreter, dokumentierter
    Footgun der Vim-API, den der Code umgeht.

14. **Delete: Fenster erst umlenken, dann Buffer löschen** —
    `lua/fileops/ops/file.lua:574-621` (`switch_windows_off`) — bevor der
    Buffer der gelöschten Datei geschlossen wird, werden alle Fenster, die ihn
    zeigen, auf einen Alternate-Buffer umgelenkt (bevorzugt `#`, sonst
    irgendein gelisteter Buffer mit echtem Dateinamen). Verhindert, dass
    Neovim beim Schließen automatisch einen leeren Scratch-Buffer erzeugt.

15. **`touch` nutzt `O_CREAT|O_EXCL` gegen Create-Race** —
    `lua/fileops/ops/file.lua:310-338` — statt "readable? → dann anlegen" naiv
    zweistufig zu prüfen, wird direkt mit dem exklusiven Flag
    (`uv.fs_open(abs, "wx", 420)`) angelegt; ein `EEXIST`-Fehler danach wird
    als Erfolg gewertet ("Lost a create race … the file existing is the
    outcome we wanted either way"). Sauberer Umgang mit TOCTOU statt
    `filereadable`-Check + separatem Open.

16. **Direkter `nvim_create_augroup(..., {clear=true})` statt Helper, um
    Autocmd-Duplikate bei Re-Setup zu vermeiden** —
    `features/conflict_marks.lua:10-19`, `features/on_hold.lua:28-37`,
    `bindings/autocmds.lua:22-26` — an drei Stellen identisch begründet:
    `lib.nvim.autocmd.group()` cached Gruppen nach Namen und überspringt das
    `clear` bei wiederholten Aufrufen, was bei erneutem `setup()` doppelte
    Autocmds stapeln würde. Bewusster Griff zur rohen API statt zum
    eigentlich bevorzugten lib.nvim-Wrapper, mit Begründung im Code.

## Abgeleitete Guidelines

1. **`(ok, msg)`-Rückgabevertrag statt Exceptions/Notify-in-der-Tiefe.** Alle
   Kernfunktionen in `ops/*.lua` geben `boolean, string|nil` zurück und rufen
   selbst nie `notify` auf (`ops/file.lua:5-9`, `ops/cycle.lua:5-9`). Die
   Entscheidung, *ob* und *wie* etwas angezeigt wird, liegt an genau einer
   Stelle (`util/notify.lua:M.report`). Für neue Plugins: Kernlogik von
   UI-Feedback trennen, damit dieselbe Logik aus Keymap, Ex-Befehl und Lua-API
   wiederverwendbar bleibt.

2. **Pure-Plan / Effectful-Execute-Trennung bei riskanten Bulk-Operationen.**
   Wie in `ops/bulk.lua`: erst eine seiteneffektfreie `plan()`-Funktion, dann
   eine separate `execute()`, dazwischen Preview + explizite Bestätigung. Für
   jede Operation, die mehrere Dateien gleichzeitig verändert, dieses Muster
   übernehmen.

3. **Best-effort statt Fail-fast bei Batch-Operationen über N unabhängige
   Items.** Ein Fehler bei Item i darf i+1..N nicht blockieren; nur der erste
   Fehler wird gemeldet, aber alle Items werden versucht (`ops/bulk.lua:84-105`).

4. **Kein Shell — ausschließlich Argv-Arrays für Subprozesse.** Sowohl
   `util/git.lua` als auch `features/on_hold.lua` rufen `vim.system({cmd,
   arg1, arg2, ...})` nie mit zusammengebauten Strings auf, und setzen `cwd`
   explizit statt sich auf das globale cwd zu verlassen. Für jedes Plugin, das
   externe Prozesse aufruft: gleiche Regel.

5. **Retry-Strategien plattformspezifisch parametrisieren, nicht pauschal.**
   `config/DEFAULTS.lua:39-45` unterscheidet Windows/Unix explizit mit
   Begründung im Kommentar. Bei Cross-Platform-Plugins: Default-Werte, die nur
   auf einer Plattform ein reales Problem adressieren, auch nur dort aktivieren.

6. **Soft- vs. Hard-Dependencies klar kennzeichnen und im Code konsistent
   behandeln — Doku muss der Realität folgen, nicht umgekehrt.**
   `health.lua:71-75` deckt explizit auf, dass `lib.nvim` entgegen der
   README-Behauptung ("no mandatory dependency") faktisch hart gebraucht wird,
   weil `ops/file.lua` und `ops/cycle.lua` es ungeschützt (ohne `pcall`)
   requiren. Nur `util/notify.lua` und `bindings/which_key.lua` sind echte,
   pcall-geschützte Soft-Dependencies. **Lektion:** Bei jeder `require()`
   entscheiden und konsistent halten, ob es hart oder weich ist; harte
   Abhängigkeiten nicht in README/docs als optional bewerben.

7. **Health-Check als Wahrheits-Audit, nicht nur Statusanzeige.** `health.lua`
   prüft nicht nur "ist X da", sondern dokumentiert bewusst Diskrepanzen
   zwischen Doku und Code (siehe Punkt 6). Für neue Plugins: `:checkhealth`
   auch nutzen, um stillschweigende Annahmen des Codes offen zu legen.

8. **Retry-Hook nutzen, um kooperierende Plugins zur Handle-Freigabe zu
   bewegen, statt nur zu warten.** `ops/file.lua:93-108` feuert bei jedem
   Retry ein `User FileopsRetry`-Event *und* ruft aktiv einen bekannten
   Konflikt-Verursacher (`lib.nvim.neotree.watch.release`) auf. Für Plugins,
   die mit Filesystem-Locking-Problemen rechnen müssen: gleiches Muster
   (aktive Bereinigung + generisches Event für Dritte) statt reinem Timeout.

9. **Fehlermeldungen für den Menschen umformulieren, sobald der Rohcode allein
   irreführend wäre.** `explain_fs_error` (`ops/file.lua:110-128`) ist ein
   konkretes Beispiel: bekannte, aber falsch interpretierbare Fehlercodes
   bekommen eine Erklärung mit angehängt.

10. **`User <Plugin>Changed`-Autocmd als offener Integrationspunkt statt
    fest verdrahteter Explorer-Liste.** `M.notify_change` (`ops/file.lua:150-167`)
    feuert immer ein generisches `User FileopsChanged`-Event zusätzlich zum
    hart codierten Reload von nvim-tree/neo-tree. Dritte Plugins (z.B.
    Session-Manager) können sich daran hängen, ohne dass fileops sie kennen
    muss. Für jedes Plugin mit Zustandsänderungen, die andere Plugins
    interessieren könnten: dieses Muster statt einer wachsenden if/pcall-Liste
    bekannter Konsumenten.

11. **Guarded Setup via Modul-lokales Flag, kein Autocmd-Doppel-Register.**
    `init.lua:5,10-13` (`_setup_done`) verhindert doppelte Registrierung bei
    mehrfachem `setup()`-Aufruf zusätzlich zum `vim.g.loaded_fileops`-Guard in
    `plugin/fileops.lua`. Zwei Ebenen des gleichen Schutzes (Plugin-Datei +
    Modul), bewusst redundant.

12. **Direkte `nvim_create_augroup(..., {clear=true})`-Aufrufe an Stellen, die
    mehrfach ausgeführt werden könnten**, statt eines cachenden Wrapper-Helpers
    — mit Kommentar, warum der Helper hier falsch wäre (siehe Pattern 16
    oben). Lektion: eigene Lib-Helper sind nicht immer die richtige Wahl;
    bewusst abweichen und begründen, statt blind zu wrappen.

13. **`opts.bang` konsequent als "override safety checks" nutzen**, nie als
    generisches "force alles". Jede destruktive/überschreibende Operation
    (`rename`, `move`, `duplicate`, `copy`, `delete`, `bulk rename`) hat exakt
    definiertes Bang-Verhalten (Overwrite-Erlaubnis bzw. Force-Close bei
    modifiziertem Buffer). Konsistente Bang-Semantik über alle Subcommands
    hinweg ist ein wiederverwendbares Vim-Idiom.

## Keybindings-Audit

Alle Keymaps werden von `lua/fileops/bindings/keymaps.lua` registriert, gated
über `config.keymaps.cycle`/`config.keymaps.delete` und individuell per
`config.keymaps.lhs.*` (Default-LHS in `config/DEFAULTS.lua:59-69`).

| Keymap (Default) | Aktion | Count-Unterstützung | Autocompletion | Anmerkungen |
|---|---|---|---|---|
| `<leader>nf` | Next file (replace) | Ja — `cycle_fn` übergibt `vim.v.count1` direkt an `cycle.navigate` (`keymaps.lua:40-52`); `3<leader>nf` springt 3 Dateien weiter. Sinnvoll implementiert. | n/a (reines Keymap, kein Ex-Input) | — |
| `<leader>pf` | Previous file (replace) | Ja, wie oben | n/a | — |
| `<leader>nfn` | Next file (stay listed/"current") | Ja | n/a | — |
| `<leader>pfn` | Previous file (stay listed) | Ja | n/a | — |
| `<leader>nF` | Next file (background) | Ja | n/a | — |
| `<leader>pF` | Previous file (background) | Ja | n/a | — |
| `<leader>NF` | Next file (vsplit) | Ja | n/a | — |
| `<leader>PF` | Previous file (vsplit) | Ja | n/a | — |
| `<leader>dcf` | Delete current file + close buffer | Nein — `attach_delete` (`keymaps.lua:86-94`) ruft `file.delete_current({})` ohne Count-Bezug auf. Nicht anwendbar: "N Dateien löschen" ist keine sinnvolle Count-Semantik für einen einzelnen aktuellen Buffer. | n/a | Kein Bang-Äquivalent über die Keymap erreichbar (nur über `:File! delete`) — bei unsaved changes bricht die Keymap-Variante einfach mit Fehlermeldung ab, statt z.B. nachzufragen. Mögliche Lücke: ein "confirm and force" für die Keymap fehlt. |

Der `:File`-Ex-Befehl selbst (nicht in der obigen Tabelle, da kein Keymap) hat
in `bindings/usrcmds.lua` durchdachte Tab-Completion über
`composer.register_type`:
- `FILEOPS_PATH`/`FILEOPS_DEST_FIRST`: bufdir-relative Pfad-Completion
  (`complete_from_bufdir`, Zeile 117-128) statt cwd-relativ — bewusst, weil
  `getcompletion`'s Default sonst bei Buffern außerhalb des cwd in die falsche
  Richtung completed.
- `FILEOPS_CYCLE_ARG`: prefix-gefilterte Completion der bekannten
  Cycle-Target-Keywords (`replace`/`stay`/`current`/…), fällt aber auf
  "alles erlaubt" zurück, weil derselbe Slot auch ein Glob-Pattern sein darf
  (`next *.lua`) — Completion ist hier bewusst nicht strikt.
- `cd`/`path`/`first`/`last`/`open` nutzen einfache `enum`-Constraints
  (`CD_SCOPES`, `PATH_MODES`, `CYCLE_TARGETS`).

Insgesamt: **Ex-Befehl-Completion ist vorbildlich vollständig** (jeder Pfad-
und Enum-Slot hat einen registrierten Typ); die Keymaps selbst sind reine
Direktaktionen ohne Eingabefeld, für die Completion nicht zutrifft.

Fehlende Flags/Optionen (Ideen beim Lesen aufgefallen):
- Kein Keymap für `bulk rename`, `lockinfo`, `info`, `path`, `cd` — nur über
  `:File …` erreichbar. Für sehr häufig genutzte (`path`, `cd`) könnte ein
  optionales `lhs`-Config-Feld analog zu `delete` sinnvoll sein.
- `attach_delete` bietet keine `<leader>Ddcf`-artige "force delete"-Variante
  für modifizierte Buffer — nur der Ex-Befehl mit `!` deckt das ab.
- Cycle-Keymaps kennen kein Pattern-Filter-Äquivalent (`next *.lua` gibt es
  nur im Ex-Befehl, nicht als Keymap-Variante mit Prompt).

## Ideen für andere Plugins

1. **Eigenständiges "fs-lock-diagnose"-Utility-Modul**: `diagnose_lock`
   (`ops/file.lua:696-726`) delegiert bereits an `lib.nvim.cross.fs.lock` — das
   Muster "wer hält diese Datei unter Windows offen, und warum" ist generisch
   genug für ein eigenes kleines Plugin/Command, das nicht an fileops gebunden
   ist (z.B. `:LockWho <path>` überall im Editor, auch für Nicht-Buffer-Dateien).

2. **Generisches "confirm-and-diff bulk rename" als eigenständiges Plugin**:
   Das Plan/Preview/Confirm/Execute-Muster aus `ops/bulk.lua` +
   `usrcmds.lua:do_bulk_rename` ließe sich verallgemeinern zu einem
   projektweiten "Bulk File Op"-Plugin, das nicht nur Renames, sondern auch
   Bulk-Delete/Bulk-Move mit Pattern-Matching unterstützt (gleiche
   Preview-vor-Ausführung-UX).

3. **On-Hold-Line-Diff als eigenständiges Ambient-Feature-Plugin**: Die
   `on_hold.lua`-Logik (gitsigns-Vorzug, generation-counter-gesichertes
   Debounce, throttle pro Fenster, Mode-Awareness) ist inhaltlich unabhängig
   von "fileops" und könnte als eigenes, fokussiertes
   "line-history-preview.nvim" existieren, das auch außerhalb eines
   File-Ops-Kontexts nützlich ist (reines Git-Blame-Ambient-Overlay).

4. **"Session-Path-Rewriter" als generisches Cross-Plugin-Utility**: Das
   `session_compat`-Verhalten (nach Rename/Move die aktive `:mksession`-Session
   neu speichern, `v:this_session`-Footgun umgehen) ist ein wiederkehrendes
   Problem für jedes Plugin, das Dateien umbenennt/verschiebt. Eine kleine,
   von fileops und sessions.nvim gemeinsam nutzbare `lib.nvim`-Funktion
   `resave_active_session()` würde die Logik konsolidieren statt sie in jedem
   Plugin neu zu implementieren.

5. **Konflikt-Marker-Highlighting als Teil eines größeren "merge-assist.nvim"**:
   `conflict_marks.lua` ist aktuell nur Highlighting; ein eigenständiges Plugin
   könnte darauf aufbauend Navigation zwischen Konflikt-Blöcken (`]x`/`[x`),
   "take ours/theirs"-Aktionen und automatisches `git add` nach Auflösung
   anbieten — deutlich mehr Wert als reines Highlighting.

6. **Retry-mit-aktiver-Handle-Freigabe als generisches lib.nvim-Pattern
   dokumentieren**: Das `retry_opts`/`on_retry`-Muster (aktive Bereinigung +
   `User <Plugin>Retry`-Event) ist wertvoll genug, um als benanntes,
   wiederverwendbares Pattern in `lib.nvim` selbst zu leben, statt in jedem
   Plugin einzeln reimplementiert zu werden — filetree.nvim hat laut Kommentar
   in `ops/file.lua:84` bereits denselben Bedarf.
