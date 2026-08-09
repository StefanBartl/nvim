# mdview.nvim

## Zweck
mdview.nvim ist ein browserbasiertes Markdown-Live-Preview-Plugin. Ein kleiner Go-Relay-Server
streamt den Bufferinhalt per WebSocket an einen Browser-Tab; Rendering und HTML-Sanitizing laufen
komplett clientseitig in einem Rust/WASM-Modul (comrak + ammonia), sodass ungeprüfter
Markdown/HTML-Text nie serverseitig zu DOM wird (`README.md:33-37`). Binary und Client-Bundle werden
einmalig von GitHub Releases geladen — der Nutzer braucht kein Go/Rust/Node-Toolchain
(`lua/mdview/adapter/install.lua:1-6`). Zusätzlich existiert ein reiner In-Neovim-Tab-Preview
(`bindings/usrcmds/preview_tab.lua`) für den Fall ganz ohne Browser/Server.

## Nicht-standard Patterns / Algorithmen

1. **Drei parallele Diff-Implementierungen, bewusst dokumentierter Fehlschlag inklusive**
   (`lua/mdview/utils/diff_granular.lua:1-84`, `lua/mdview/utils/diff.lua:1-45`,
   `lua/mdview/utils/line_diff.lua:1-39`).
   `diff_granular.lua` implementiert einen vollen Myers-LCS-Algorithmus, wird aber laut Kommentar
   in `line_diff.lua:11-12` explizit als "a buggy Myers attempt that dropped real changes"
   verworfen und ist nur noch über `core/events.lua` (dormant) erreichbar. Die aktuell aktive
   Lösung `line_diff.lua` ist bewusst simpler: Sie berechnet nur den gemeinsamen Prefix/Suffix und
   liefert eine einzige zusammenhängende Ersetzungsregion — korrekt für den Live-Typing-Fall
   (fast immer ein zusammenhängender Bereich), aber nicht minimal bei Multi-Cursor-Edits
   (Kommentar Zeilen 8-12). Grund für die Abweichung vom "richtigen" LCS-Ansatz: Korrektheit vor
   Optimalität — ein simplerer Algorithmus, der nachweisbar korrekt ist, schlägt einen
   komplexeren, der in der Praxis Änderungen verliert. `diff.lua` ist eine noch ältere/kleinere
   Prefix/Suffix-Variante, nur noch vom Test-Harness (`test/diff_harness.lua`) benutzt.
   Lektion: Ein fehlgeschlagener Algorithmus wurde nicht gelöscht, sondern mit Kommentar als
   Warnung im Repo belassen ("kept simple on purpose", Zeile 12) — spart zukünftigem Ich die
   Wiederholung des Fehlers.

2. **Detached-Process-Spawn strikt getrennt vom "lebenden" Relay-Prozess**
   (`lua/mdview/adapter/detached.lua:1-9`). `M.spawn` nutzt `uv.spawn` mit `detached = true`,
   `stdio = {nil,nil,nil}` und ruft danach `handle:unref()` + `handle:close()` (Zeilen 57-83).
   Der Kommentar begründet explizit, warum dies eine eigene Funktion statt eines Flags auf
   `adapter.runner` ist: der reguläre Relay-Child ist an die laufende Instanz gebunden
   (VimLeavePre killt ihn, stdout geht in den Log-Buffer, State trackt das Handle) — ein
   detached Prozess braucht exakt das Gegenteil aller drei Eigenschaften. Ein einzelner Spawn mit
   drei Flags hätte Fehlerpotenzial für jeden Aufrufer bedeutet.

3. **Env-Overrides per expliziter env-Liste statt `vim.env`-Mutation**
   (`lua/mdview/adapter/detached.lua:17-24`, `M.build_env`). Begründung im Kommentar: `vim.env.X
   = nil` löscht eine Variable wirklich, ein Save/Restore-Zyklus um den Spawn kann daher "war
   ungesetzt" nicht von "fehlt in meiner Restore-Tabelle" unterscheiden und würde den Override in
   die eigene Instanz durchsickern lassen. Defensive Vermeidung eines subtilen Zustands-Lecks.

4. **Download + Checksum-Verifikation nach Mason/nvim-treesitter-Vorbild**
   (`lua/mdview/adapter/install.lua:1-6, 82-96, 119-166`). `ensure_asset` lädt `checksums.txt` und
   die Ziel-Datei per curl, parst goreleaser-Checksum-Zeilen (`^(%x+)%s+%*?(.+)$`), berechnet
   `fn.sha256` über die geladene Datei und löscht sie bei Mismatch sofort wieder
   (`pcall(os.remove, path)`, Zeilen 154/160). Sicherheitsrelevant, weil ein Binary aus dem
   Internet geladen und lokal ausgeführt wird — ohne Checksum-Check wäre ein kompromittiertes
   GitHub-Release oder ein MITM auf einem alten TLS-Setup unbemerkt ausführbar.

5. **Config-Validierung warnt vor Merge, nicht danach**
   (`lua/mdview/config/init.lua:72-114`). `M.validate(opts)` läuft VOR `M.merge(opts)` und baut
   sich über `collect_known_names()` einen flachen Namensindex aller bekannten (auch absichtlich
   nil-wertigen, `KNOWN_NIL_KEYS`) Keys, um bei unbekannten Top-Level-Keys einen
   "did you mean `experimental.line_diff`?"-Hinweis zu geben (Zeilen 96-98). Der Kommentar
   (Zeilen 72-75) nennt den konkreten Fehlerfall: ein `experimental.*`-Flag versehentlich auf
   oberster Ebene übergeben — würde nach einem Merge lautlos in die Defaults einsortiert und nie
   auffallen. Validierung vor statt nach dem Merge ist hier die einzige Reihenfolge, die das
   Problem überhaupt erkennen kann.

6. **In-place Deep-Merge statt Tabellen-Ersetzung**
   (`lua/mdview/config/init.lua:5-9, 24-32`). Begründung im Modul-Docstring: mehrere
   Submodule (`mdview.config.browser`, `mdview.config.usrcmd_start`) zeigen mit ihrem eigenen
   `M.defaults` direkt auf `M.defaults.browser` bzw. `M.defaults.start` der Haupttabelle — eine
   Ersetzung der Tabelle (statt In-Place-Mutation) würde diese Referenzen entkoppeln, unabhängig
   davon, ob das Submodul vor oder nach `setup()` geladen wurde.

## Abgeleitete Guidelines

1. Ein gescheiterter Algorithmus-Versuch darf im Code bleiben, wenn er mit klarem Kommentar
   ("buggy", "dormant", Grund) markiert ist — verhindert, dass man den Fehler später wiederholt.
   Toter Code ohne diese Markierung sollte dagegen entfernt werden.
2. Prozesse, die die Neovim-Instanz überleben sollen (`detached spawn`), gehören in ein eigenes
   Modul mit eigenen Defaults (kein Pipe-Handle, `detached=true`, sofort `unref()+close()`) —
   nicht als Flag-Variante eines Moduls, das an den Lifecycle der Instanz gebunden ist.
3. Bei Prozess-Env-Overrides niemals `vim.env` global mutieren und zurücksetzen; stattdessen eine
   explizite Env-Liste an `uv.spawn` übergeben (vermeidet nil-vs-absent-Leck).
4. Jedes Plugin, das Binaries von GitHub Releases lädt, MUSS Checksums (sha256 aus
   `checksums.txt` im goreleaser-Format oder äquivalent) prüfen, bevor die Datei ausgeführt oder
   das Downloadergebnis als vertrauenswürdig behandelt wird; bei Mismatch die Datei löschen statt
   sie liegen zu lassen.
5. Config-Validierung (Unknown-Key-Warnung) muss vor dem Merge laufen, sonst verschwinden
   Tippfehler in verschachtelten Optionen lautlos in den Defaults. "Did you mean"-Vorschläge
   lohnen sich, sobald die Config mehr als eine Verschachtelungsebene hat.
6. Wenn Submodule (`config.browser`, `config.usrcmd_start`) auf Teiltabellen der zentralen
   Default-Config zeigen sollen, MUSS der Merge in-place mutieren (`deep_merge_in_place`),
   niemals `M.defaults = neue_tabelle` — sonst brechen alle bereits gezogenen Teilreferenzen.
7. Ein einziger `:Plugin <subcommand>`-Befehlsbaum über einen Composer/Router
   (`lib.nvim.usercmd.composer`, siehe `bindings/usrcmds/init.lua`) statt zehn Einzelbefehlen
   verhindert Doku-Drift und liefert Tab-Completion + generierte Doku "for free" — Standardmuster
   für zukünftige Plugins mit >3 Subcommands.
8. lib.nvim-Abhängigkeit früh und mit klarer Fehlermeldung prüfen: ein `pcall(require, ...)`-Probe
   ganz am Anfang von `init.lua` (siehe `lua/mdview/init.lua:9-14`) statt einen tiefen Stacktrace
   aus einem inneren Modul zu riskieren.
9. Harte technische Entscheidungen (z.B. "warum LCS-Diff verworfen wurde", "warum kein
   Full-Doc-Reload nötig ist") gehören als Kommentar an die Stelle im Code, nicht nur in ein
   externes Roadmap-Dokument — das Modul bleibt so auch isoliert verständlich.

## Keybindings-Audit
mdview.nvim definiert keine eigenen Keymaps (kein `bindings/keymaps.lua` im Repo vorhanden,
`find lua -iname "*keymap*"` liefert nichts). Alle Interaktion läuft über den einzigen
`:MDView <subcommand>`-Befehlsbaum, registriert in `lua/mdview/bindings/usrcmds/init.lua` via
`composer.verb("MDView", { routes = ... })`.

- **Count-Unterstützung**: nicht anwendbar — es gibt keine Keymaps, nur Ex-Commands. Für
  count-artige Aktionen (z.B. `:MDView zoom +`/`-`) wird stattdessen ein Argument (`step`)
  übergeben (`bindings/usrcmds/init.lua`, Route `zoom`), kein `v:count`. Für ein Kommando wie Zoom
  wäre `N<leader>zoom+` (N-fach) aber denkbar und aktuell nicht vorgesehen.
- **Autocompletion**: Ja, durchgehend. Jede Route mit `args`/`flags` bekommt über den Composer
  Tab-Completion; Argumente mit fester Werteliste (`values = theme.known`, `values = cursor.modes`,
  `values = sync.actions`, `values = zoom.actions`, `values = reveal.actions`,
  `values = blanklines.actions`, `values = overlay.names()`) sind vollständig auto-vervollständigt
  — sehr sauber gelöst, da die Werteliste jeweils aus der Quelle des jeweiligen Feature-Moduls
  kommt und nicht dupliziert wird.
- **Fehlende Flags/Optionen (Ideen)**: `:MDView zoom <factor>` akzeptiert laut Doc-String
  einen beliebigen Faktor als String, aber es gibt keine sichtbare Validierung/Clamping des Werts
  in der Route selbst (delegiert an `zoom.run`, nicht mitgelesen) — wert, das bei Gelegenheit zu
  prüfen. Kein `:MDView start --port <n>` sichtbar, um einen festen Port zu erzwingen (z. B. für
  Firewall-Regeln) — nur implizit über `config.browser`/`server_args`.

## Ideen für andere Plugins
- Ein generisches "download + checksum-verify + extract" Bootstrap-Modul (wie
  `adapter/install.lua`) lohnt sich als eigenständiges Utility in lib.nvim, weil mehrere künftige
  Plugins (Sprachserver-Wrapper, Formatter-Wrapper) denselben Mason-artigen Pattern brauchen
  könnten, statt ihn pro Plugin neu zu schreiben.
- Ein generischer "detached spawn watcher" (Plugin, das laufende detached Prozesse listet/killt,
  die frühere Neovim-Instanzen hinterlassen haben) wäre ein sinnvolles Diagnose-Tool, das direkt
  aus `adapter/detached.lua`s Muster (PID-Rückgabe, kein Tracking danach) folgt — aktuell gibt es
  keine Möglichkeit, verwaiste `mdview-server`-Prozesse aus Neovim heraus zu sehen.
- Der "Composer/Router für :Cmd subcommand"-Ansatz aus `lib.nvim.usercmd.composer` scheint reif
  genug, um als eigenständiges, dokumentiertes Pattern (ggf. eigenes kleines Lib-Modul mit
  Cheatsheet-Generierung) in mehreren Plugins konsistent wiederverwendet zu werden — genau das
  passiert hier schon, aber ein Blick lohnt, ob alle 5 Plugins es gleich nutzen.
</content>
