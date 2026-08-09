# markdown.nvim

## Zweck
Ein in sich geschlossenes Markdown-Toolkit für Neovim: Heading-Navigation/-Shift, TOC-Generierung,
Custom-Foldexpr, GFM-Table-Formatierung + eine eigene TableView-Renderengine (Markdown-Style +
Box-Drawing + Browser-Export), Link-/Anchor-Handling (Folgen, Diagnostics, automatische
Ref-Synchronisation bei Heading-Umbenennung), sowie ein Cursor-Action-Handler für Bilder/URLs/Dateien.
Rein FileType-gescoped (`lua/markdown/init.lua:1-4`), harte Abhängigkeit ist `lib.nvim` (Command-Layer,
Debouncing), alle anderen Integrationen (pdfport.nvim, images.nvim/snacks/image.nvim, telescope/fzf-lua)
sind Soft-Deps mit Laufzeit-Erkennung (README.md:50-59).

## Nicht-standard Patterns / Algorithmen

1. **Extmark-basierte Rename-Erkennung + Positional-Fallback** (`lua/markdown/core/refs.lua:44-86`,
   `149-176`). Statt bei jedem Speichern die ganze Datei neu zu diffen, wird pro Heading ein Extmark
   gesetzt, der beim Editieren „mitreitet". Ein Rename wird primär über `nvim_buf_get_extmark_by_id`
   erkannt (Zeile 158-169). Da eine Zeilen-Ersetzung (`cc`, `:s`, Formatter) den Extmark killt, gibt es
   einen zweiten Mechanismus: einen positionalen Diff der geordneten Anchor-Listen (`positional_renames`,
   Zeile 74-86), der einen Rename nur akzeptiert, wenn linker UND rechter Nachbar unverändert sind — das
   unterscheidet eine isolierte Umbenennung von einer strukturellen Verschiebung (Insert/Delete), ohne
   einen vollen Sequenzabgleich (LCS/Myers) fahren zu müssen. Warum nicht naiv: ein simpler Vollvergleich
   aller Anchors würde bei Insert/Delete falsche Renames erzeugen; ein Timer-Diff bei jedem Tastendruck
   wäre zu teuer.
2. **Debounced Live-Sync mit Timer-Neustart statt Queue** (`lua/markdown/core/refs.lua:267-289`).
   `on_change` stoppt und schließt einen laufenden `uv.new_timer()`, bevor ein neuer gestartet wird — klassisches
   Debounce, aber mit explizitem `pcall` beim `timer:close()`, um Race-Conditions beim Buffer-Wipeout
   abzufangen. Der Default-Delay ist bewusst hoch (2000ms, `config/DEFAULTS.lua:161`) mit Kommentar
   „a rename is rare […] but we never want to run it on every keystroke".
3. **Ripgrep-Prefilter vor vollem File-Scan** (`lua/markdown/core/file_refs.lua:11-17, 46-65, 95-122`).
   Statt jede `*.md`-Datei im Root zu lesen und zu parsen, wird zuerst per `rg --files-with-matches
   --fixed-strings <basename>` die Kandidatenmenge auf Dateien eingegrenzt, die den Ziel-Basename
   überhaupt erwähnen — erst danach werden diese wenigen Dateien wirklich gelesen und mit
   `link_scan.from_lines` geparst. Pure-Lua-`globpath`-Fallback, wenn `rg` fehlt (Zeile 84-86, 137-142).
   Warum: Naive Variante würde bei großen Repos jede Markdown-Datei öffnen und parsen — teuer bei
   hunderten Dateien, wenn nur eine Handvoll den Link enthält.
4. **Style-erhaltendes Retargeting** (`lua/markdown/core/file_refs.lua:176-197`,
   `lua/markdown/util/path.lua:194-225`). Beim Umschreiben eines Links nach Datei-Umbenennung wird nicht
   pauschal auf eine kanonische Form normalisiert, sondern der ursprüngliche Stil (absolut vs.
   relativ-zu-Basis vs. `./`-Präfix) über `resolve_traced`/`retarget` rekonstruiert, damit `./old.md` zu
   `./new.md` wird und nicht zu einem absoluten Pfad kollabiert. Bewusste Abweichung vom „einfachsten"
   Ansatz (alles normalisieren), weil das den Autoren-Stil im Dokument zerstören würde.
5. **Mehrstufige Pfad-Resolution mit Existenz-Probe** (`lua/markdown/util/path.lua:126-170`).
   `candidate_bases()` versucht Buffer-Verzeichnis, dann cwd (dedupliziert via
   `lib.nvim.lua.tables.dedup_list`), und `resolve_impl` nimmt den ersten Kandidaten, der laut
   `uv.fs_stat` tatsächlich existiert — nicht einfach den ersten überhaupt. Kommentar Zeile 8-13
   erklärt explizit den Bugfix: `vim.fn.fnamemodify(:p)` kollabiert `.`/`..` auf Windows nicht
   zuverlässig, und rein buffer-relative Auflösung bricht bei Root-relativ geschriebenen Links.
6. **Eigene `.`/`..`-Collapse-Implementierung mit Windows-Drive-Schutz** (`lua/markdown/util/path.lua:90-114`,
   dupliziert/gespiegelt in `lib.nvim.cross.fs.separators.collapse_dots`, siehe Kommentar Zeile 87).
   Verhindert, dass `..` über eine Windows-Laufwerksangabe (`C:`) hinaus „poppt".
7. **Datengetriebene Keymap-Definition statt Imperativ-Code** (`lua/markdown/bindings/keymaps.lua:41-70`).
   Alle Default-Keymaps sind eine Tabelle mit stabiler `id`, die von der User-Config gezielt überschrieben/
   deaktiviert werden kann (`config.keymaps[id]`), zusätzlich zu Legacy-Booleans für Abwärtskompatibilität
   (`flag`-Feld, Zeile 98). Kein hartkodiertes `vim.keymap.set` pro Taste.
8. **Ex-Command-Completion durch Selbstaufruf statt Duplikation** (`lua/markdown/bindings/usrcmds.lua:49-56`).
   Die Completion für `:Markdown <sub> <arg>` synthetisiert intern eine `"Markdown {subcmd} {arg_lead}"`
   Cmdline-Zeichenkette und ruft `commands.complete()` erneut auf, statt eine zweite
   Subcommand-Dispatch-Tabelle zu pflegen — vermeidet Drift zwischen Ausführungs- und
   Completion-Logik (explizit im Kommentar Zeile 13-17 begründet).

## Abgeleitete Guidelines

1. Bei Rename-/Sync-Problemen: Extmarks für Identitäts-Tracking über Edits hinweg nutzen, aber immer
   einen positionalen Fallback für Fälle vorsehen, in denen der Extmark durch Zeilen-Ersetzung verloren
   geht (nicht nur einen Mechanismus verlassen).
2. Teure Scans (Filesystem, externe Prozesse) IMMER hinter einer günstigen Prefilter-Stufe (ripgrep,
   Glob-Pattern, Existenz-Check) verstecken, bevor der teure Pfad (Datei lesen + parsen) läuft; Pure-Lua-
   Fallback bereitstellen, wenn das externe Tool fehlt.
3. Debounce-Timer explizit stoppen+schließen (`timer:stop()` + `pcall(timer.close)`) vor Neustart, nie
   einfach überschreiben — sonst laufen alte Timer im Hintergrund weiter.
4. Pfad-Resolution: nie nur einen Basis-Kandidaten annehmen. Mehrere Basen in fester Reihenfolge probieren
   und den ersten nehmen, der laut `fs_stat` real existiert; beim Umschreiben von Pfaden den
   ursprünglichen Schreibstil (relativ/absolut/Präfix) erhalten statt zu kanonisieren.
5. Cross-Platform-Pfad-Logik (Separatoren, Drive-Buchstaben, `.`/`..`) an lib.nvim delegieren, aber
   inline-Fallbacks bereithalten, damit das Plugin auch standalone (ohne lib.nvim) lauffähig bleibt
   (`optional()`-Pattern mit `pcall(require, …)`, `lua/markdown/util/path.lua:25-29`).
6. Keymaps als Datentabelle mit stabiler `id` je Eintrag modellieren, nicht als Sequenz von
   `vim.keymap.set`-Aufrufen — macht Remapping/Disable pro User-Config trivial und dokumentierbar
   (`M.defaults()` als Introspektions-API für Tooling/Doku).
7. Bei mehreren äquivalenten Einstiegspunkten (Ex-Command-Dispatch + dessen Completion) die
   Completion-Logik durch Wiederverwendung der echten Dispatch-Funktion synthetisieren statt eine
   Parallel-Struktur zu pflegen — verhindert Drift.
8. Ex-Commands über `lib.nvim.usercmd.composer` registrieren (`composer.verb`, `composer.register_type`)
   statt raw `vim.api.nvim_create_user_command` — liefert Flags/Routing/Completion-Typen konsistent mit
   dem Rest des Ökosystems.
9. Konfigurierbare Subsysteme (refs.mode = off/save/live) immer mit manuellem Override-Command versehen
   (`:Markdown refs sync`/`check` funktionieren unabhängig vom Modus) — Automatik darf den manuellen Pfad
   nie verdrängen.
10. Read-only Analysefunktionen (`find_references`) klar als "liest nur, mutiert nichts" dokumentieren und
    sowohl sync- als auch async-Variante mit identischer Rückgabe anbieten, wenn eine potenziell teure
    Systemoperation (hier: `vim.system`) involviert ist.

## Keybindings-Audit

Alle Bindings sind in `lua/markdown/bindings/keymaps.lua` als Datentabelle definiert
(`DEFAULT_KEYMAPS`, Zeile 41-70) plus die TableView-Keys in `apply_tableview` (Zeile 126-138).

- `**` (visual, toggle_bold_visual) — count nicht anwendbar (Toggle-Aktion auf Selektion, kein
  wiederholbarer Zähl-Kontext). Keine Autocompletion nötig (kein Ex-Command-Input).
- `<leader>[` (n/v, wrap_link) — count nicht anwendbar (Wortgrenzen-Aktion).
- `<C-p>`/`[[`, `<C-f>`/`]]` (Heading-Navigation) — count wird NICHT ausgewertet, obwohl `N[[`/`N]]`
  ("N Headings weiterspringen") ein natürlicher Vim-Move wäre. Fehlt: `vim.v.count1`-Unterstützung in
  `actions.prev_heading`/`next_heading`, um `3]]` = 3 Headings vorwärts zu ermöglichen — sollte geprüft
  werden (Datei `lua/markdown/bindings/actions.lua` wurde hier nicht gegengelesen, aber die
  Keymap-Definition selbst zeigt keinen count-Bezug).
- `<leader><C-p>`/`<C-f>` (Heading nach Level) — gleiche Einschränkung, kein sichtbarer count-Support.
- `zf`, `zu`, `zi`, `zk` (Fold-Kommandos) — count bei Fold-Kommandos in Vim traditionell nicht zentral;
  nicht anwendbar.
- `<leader>toc` (TOC einfügen/aktualisieren) — kein count-Bezug sinnvoll (Struktur-Operation, kein
  Wiederholzähler). Ex-Command-Pendant `:Markdown toc [level]` hat aber KEIN count via `[count]toc`;
  ein `3<leader>toc` für "max_level=3" wäre eine denkbare Ergänzung, existiert nicht.
- `<C-Right>`/`<C-Left>` (heading_inc/dec, auch visual) — count nicht ausgewertet; `3<C-Right>` (3 Level
  erhöhen) wäre naheliegend und fehlt vermutlich (nicht in Aktion gegengeprüft).
- `]|`/`[|` (Table-Zellen-Navigation) — count wäre hier besonders sinnvoll (`3]|` = 3 Zellen springen),
  aus der Datentabelle nicht ersichtlich, ob unterstützt.
- `mi` (open_image), `mj` (jump_anchor), `ma` (cursor_action) — count nicht anwendbar (punktuelle
  Cursor-Aktionen).
- TableView-Keys (`<leader>tvt/tvx/tvs/tvb/tvc/tvm`) — reine Toggle/Ex-Command-Wrapper, count nicht
  anwendbar.
- `:Markdown <sub> <arg>` — hat vollständige Autocompletion über `composer.register_type("MARKDOWN_SUBARG", …)`
  (`lua/markdown/bindings/usrcmds.lua:49-56`), inkl. Subcommand-Dispatch. Vorbildlich.
- `:TableView* [scope]` — Completion für `scope`-Argument (`%`, `cwd`, dann Datei/Verzeichnis-Completion,
  `complete_scope`, Zeile 253-262) ist vorhanden und durchdacht.
- Insgesamt: Ex-Commands haben durchgängig gute Completion; die reinen Bewegungs-Keymaps (Heading-Nav,
  Fold, Cell-Nav) haben erkennbar KEINE count-Unterstützung, obwohl mehrere davon (Heading-Sprünge,
  Zellen-Navigation, Level-Erhöhung) klassische Kandidaten für `[count]` wären.

## Ideen für andere Plugins

- Ein eigenständiges **link-integrity.nvim**: verallgemeinert `file_refs.lua`s Ripgrep-Prefilter +
  Style-erhaltendes Retargeting auf beliebige Dateitypen (nicht nur Markdown) — z. B. für einen
  File-Manager, der vor Löschen/Umbenennen warnt und Referenzen in Code-Kommentaren/Configs mitzieht.
- Ein generisches **rename-tracker**-Modul (auf Extmark+Positional-Fallback basierend) als lib.nvim-Baustein,
  den auch andere Plugins (z. B. für Variablennamen, Tags, IDs) wiederverwenden könnten, statt dass jedes
  Plugin seine eigene Rename-Erkennung baut.
- Ein **table-view.nvim** als eigenständiges Mini-Plugin: die TableView-Engine (Markdown/Box-Style-Rendering,
  Browser-Export mit Tab-Reuse) ist generisch genug, um losgelöst von Markdown auch CSV/TSV oder Ex-Command-
  Output darzustellen.
