# `lib.nvim`

Custom PLugins sollen lib.nvim als hard dep nutzen, fallback code (pcall lib.nvim und wenn esnict klappt eigenimplementierung) nur in ausdnahmefällen und gut begrründet

1. Personal Plugins auf `utils`-Folder durchsuchen -> Eventuell Funktionen für die lib dabei?
  1. `lib.nvim/lua/nvim/neotree/**` Folder (filetree.nvim)

## Neue Features implementieren

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

1. **Test-Runner brauchen lib.nvim auf dem rtp.** Sobald ein Plugin hart requiret, schlägt seine
   Suite fehl. `fileops.nvim/docs/TESTS/run.lua` enthält jetzt eine Auflösungs-Routine
   (`$LIB_NVIM_PATH` → Sibling-Checkout → `stdpath("data")/lazy`) — als Vorlage kopierbar.
  1. `migrate.nvim` nimmt lib.nvim-abhängige Module bewusst aus dem Test-Scope — dort ggf. Präzedenz folgen.

### Neue Module (Kandidatenliste `FINISH/lib_NEW_MODULES.md`) — Status

Alle Kandidaten aus der Multi-Agent-Scan-Liste vom 2026-07-14 wurden bearbeitet. Policy dabei: Plugins nutzen
lib.nvim als hard dep (kein pcall-Fallback-Template im Regelbetrieb — siehe Kopf dieser Datei).

- [x] **Debounce/throttle** (5 Plugins) → `lib.nvim.debounce` — verdrahtet in pickers.nvim, reposcope.nvim,
      color_my_ascii.nvim, filetree.nvim (9 Fundstellen), markdown.nvim.
- [x] **Executable/CLI-Detection** (3 Plugins) → `lib.nvim.system.has_executable`/`first_available` —
      verdrahtet in nvim-containers, pdfport.nvim, reposcope.nvim.
- [x] **Async spawn+capture** (9 Fundstellen / 3 Plugins) → `lib.nvim.cross.uv.spawn_capture` — verdrahtet in
      pdfport.nvim (6 Backends), reposcope.nvim (curl/wget/gh; behob dabei einen Doppel-Callback-Bug in
      curl.lua). language.nvim's Job-Runner wurde nicht mit-absorbiert (out of scope, eigener Cancel/Timeout-
      Vertrag).
- [x] **Path-Template/Env-Var-Expansion** (2 Plugins) → verdrahtet in nvim-cmdlog, pickers.nvim.
- [x] **Dedup-Helper** (kein neues Modul, nur Verdrahtung) — ~14 Fundstellen in 10 Plugins auf
      `lib.lua.tables.unique_table`/`dedup_list` umgestellt.
- [x] **Strings/Text** → `lib.lua.strings.{utf8,encoding,distance,format,location,case,wrap}` — UTF-8
      codepoint-Handling, Percent-Encode/Base64, Levenshtein/Similarity, Byte-/Zahlenformatierung,
      Location-Parser, Case-Shape/Change-Case, Text-Centering verdrahtet in 10 Plugins.
      **Ausnahme:** reposcope.nvim's wortbewusstes `center_text`/`center_text_lines` wurde NICHT ersetzt —
      lib.nvim-Variante ist nicht wort-aware, echter Funktionsverlust.
- [x] **Deep merge** → `lib.lua.tables.deep_merge` — verdrahtet in migrate.nvim (mutierend statt pure,
      Wrapper-Adaption nötig).
- [x] **Numeral** (roman/alpha) → `lib.lua.numeral` — verdrahtet in cascade.nvim.
- [x] **UUID** → `lib.lua.uuid` — verdrahtet in buffer-ctx.nvim.
      **Ausnahme:** Timestamp-Formatter und Ephemeral-Token-Generator (mdview.nvim) wurden NICHT als eigene
      Module extrahiert — zu klein/eng genug am jeweiligen Call-Site, kein zweiter Konsument gefunden.
- [x] **Filesystem/Caching** → Read-to-string, atomic JSON write, Persistent-Disk-Cache-mit-TTL,
      recursive-dir-walker, Byte-Size-Formatter verdrahtet in learn-cli.nvim, github_stats.nvim (3 Dateien),
      filetree.nvim (2 Stellen), project-insight.nvim, migrate.nvim.
      **Ausnahme:** color_my_ascii's größenbegrenzter Buffer-Scoped-Cache wurde NICHT durch `lib.lua.memo`
      ersetzt (kein Size-Cap dort, echter Funktionsverlust). Trash/Recycle-Bin und Bounded-Concurrency-
      Async-Index (gopath.nvim) wurden nicht angefasst (kein zweiter Konsument, Scope-Grenze).
- [x] **Git Porcelain-Status-Parser** → verdrahtet in filetree.nvim.
- [x] **Async HTTP/Date** → Async-Curl+Bearer-Auth-Client, Date-Range-Presets, YAML-Decoder (`lib.lua.yaml`)
      verdrahtet in github_stats.nvim, learn-cli.nvim (behob dabei einen Dedent-Bug im YAML-Parser).
- [x] **Editor/Buffer/Window-Helfer** → `lib.nvim.safe_api` (neu, pcall-Wrapper über `vim.api`),
      Cross-Version-Buffer-Option-Getter, Named-Scratch-Split-Dedup (`window.open_named_scratch`),
      `.`-Repeat-Wiring (`lib.nvim.dotrepeat`), Poll-until-Predicate, Detached-GUI-Process-Launcher
      verdrahtet in color_my_ascii.nvim, mdview.nvim, nvim-containers (6 Dateien — behob dabei einen
      Fenster-Proliferations-Bug), cascade.nvim, pdfport.nvim, open.nvim.
      **Ausnahme:** debugging.nvim's Log-Fenster-Fokus-Helfer (`ensure_bottom`/`force_focus`) wurde NICHT
      ersetzt — Streaming-Log-aware Retry-Verhalten wäre verloren gegangen.
- [x] **Debug/Dev-Tooling** → `lib.lua.dump` (neu, Recursive-Value-Dumper, mit Bugfix: Metatable-Felder
      werden jetzt NEBEN statt ANSTATT den eigenen Feldern angezeigt) verdrahtet in debugging.nvim;
      `lib.lua.error.safe_call` verdrahtet in gopath.nvim.
- [x] **Structured-Error-Pattern** → `lib.lua.error` ({kind, message, data} + safe_call mit Traceback)
      verdrahtet in replacer.nvim, pickers.nvim.

Zusätzlich beim Wiring gefundene und behobene Bugs (nicht Teil der ursprünglichen Kandidatenliste, aber
direkt daraus entstanden): `spawn_capture`s `table.unpack`-Crash auf LuaJIT, `opts.env`-Typ-Diskrepanz in
dessen Doku, CRLF-Korruption in `fs.write.to_file`/`append`/`read` durch Text-Mode-`io.open` auf Windows
(betraf alle bereits verdrahteten Konsumenten von `fs.write`/`fs.json` rückwirkend), sowie ein
`config_dir`-Override-Bug in github_stats.nvim (out of scope belassen, als separater Task geflaggt).

### Übersprungene Replace-Kandidaten

Vier Fundstellen aus replace_moduls.md, bei denen ein Zwangsersatz durch die entsprechende lib.nvim-Funktion eine echte Funktionsregression gewesen wäre. In allen vier Fällen ist die Eigenimplementierung des Plugins in mindestens einer Dimension nachweislich fähiger als das aktuelle lib.nvim-Äquivalent.

1. emojis.nvim — lua/emojis/search.lua:210-255 (M.run)
Plugin: emojis.nvim — durchsucht das Arbeitsverzeichnis nach Emoji-Vorkommen (ripgrep-basiert), zeigt/zählt/löscht/ersetzt sie.

Was der Code tut: Startet rg asynchron, sammelt stdout zeilenweise über einen Callback, nutzt vim.system mit jobstart-Fallback für ältere Neovim-Versionen.

Warum kein Ersatz:

lib.nvim.cross.run (run(cmd, cb)) nimmt einen Shell-String, keinen argv-Array — würde Shell-Interpolation einführen, wo aktuell keine ist.
lib.nvim.cross.run_argv ist rein blockierend — keine Async-Variante.
lib.nvim.cross.uv.spawn_capture ist async, aber puffert komplett und ruft erst am Ende einen einzigen Callback auf — kein Line-by-Line-Streaming.
Keine der drei lib.nvim-Optionen deckt "async, argv-safe, zeilenweises Streaming, mit Jobstart-Fallback" ab. Ein Zwangsersatz hätte eine dieser vier Eigenschaften gekostet.

Sonstiges im Repo: util/notify.lua und util/lib.lua (Soft-Bridge zu lib.nvim.notify/lib.nvim.map) sind bereits korrekt — keine Änderung nötig.

2. filetree.nvim — features/infra/project_root/init.lua (komplettes Modul)
Plugin: filetree.nvim — Dateibaum-Explorer (Wrapper um neo-tree/nvim-tree) mit eigenen Features (PDF-Preview, System-Öffnen, u.a.).

Was der Code tut: Läuft von einem Pfad aufwärts durch die Verzeichnisstruktur und sucht nach Root-Markern (.git, package.json, Cargo.toml, *.rockspec, …), um das Projekt-Root zu bestimmen. Cached das Ergebnis für jedes durchlaufene Verzeichnis (nicht nur das Ausgangsverzeichnis).

Warum kein Ersatz (lib.nvim.fs.find_root):

Unterstützt Glob-Marker wie *.rockspec — lib.nvim.fs.find_root ist auf vim.fs.find mit exakten Namensvergleichen aufgebaut, keine Glob-Unterstützung.
Cached die gesamte durchlaufene Kette (jedes Verzeichnis auf dem Weg zum Root), nicht nur das eine abgefragte Verzeichnis wie lib.nvims LRU-Cache.
Beides sind reale, im Code sichtbare Fähigkeiten, die beim Ersatz verloren gegangen wären.

Weitere in diesem Repo bewusst nicht angefasste Kandidaten (gleiche Begründung, "System öffnen"-Familie):

util/pdf.lua — unkommitiertes WIP-Feature des Users (neue pdfport-Integration), nicht angerührt.
features/system/open_with/init.lua / open_in_fm/init.lua — bevorzugen vim.ui.open (Neovim 0.10+) mit WSL-wslview- und Exit-Code-Reporting-Fallback; open_in_fm macht zudem ein "im Dateimanager anzeigen" (Reveal), was system_opener konzeptionell gar nicht kennt.
features/paths/lua_require_copy/init.lua — der Input-Contract passt nicht zu lib.nvim.lua_ls.get_module_path (arbeitet auf bereits relativ gemachten Pfaden, ein Call-Site braucht zudem ein cwd-erzwungenes statt global gesuchtes Root).
3. markdown.nvim — util/platform.lua:29-69 (M.open)
Plugin: markdown.nvim — Markdown-Editing-Features (Tabellen-Formatierung, Link-Handling, Datei-Refs, u.a.).

Was der Code tut: Öffnet einen Pfad/eine URL mit der System-Standardanwendung. Bevorzugt vim.ui.open (Neovim 0.10+); Fallback ist ein per-OS-Argv-Aufruf (cmd.exe /c start / open / xdg-open) über vim.system/jobstart.

Warum kein Ersatz (lib.nvim.fs.open.url.system_opener):

Verliert die vim.ui.open-Präferenz — die aktuell modernste, shell-unabhängige Variante.
Der Code-Kommentar dokumentiert explizit einen gezielten Windows-Bugfix: eine List-Argv statt String-Form, weil die alte String-Form über &shell + shellescape bei shell=pwsh kaputtging (Pfade mit Leerzeichen wurden falsch gequotet). system_opener hat diesen Fix nicht.
Nebenbefund: M.os() (reine OS-Erkennung, ohne diese Caveats) wurde umgestellt auf cross.platform.is_windows/is_macos — nur M.open selbst blieb unangetastet, weil M.os() sowieso nur intern von M.open genutzt wird.

4. mdview.nvim — adapter/log.lua (komplettes Modul + path_dirname/ensure_dir)
Plugin: mdview.nvim — Markdown-Live-Preview im Browser (startet einen Dev-Server/Relay-Prozess, zeigt dessen Logs).

Was der Code tut: Sammelt rohe Zeilen aus dem Server-Subprozess (stdout/stderr) in einem In-Memory-Ring (Cap 2000 Zeilen), zeigt sie optional live in einem Scratch-Buffer, schreibt sie optional in eine Datei. path_dirname/ensure_dir legen dafür bei Bedarf Verzeichnisse an — explizit ohne vim.fn.mkdir, weil dieser Aufruf in einem "Fast Event Context" (Subprozess-Callback) mit Fehler E5560 abstürzt.

Warum kein Ersatz:

lib.nvim.fs.create_entry ruft intern vim.fn.mkdir auf — ein Zwangsersatz von ensure_dir hätte exakt den Absturz reintroduziert, den der Code bewusst umgeht.
Der große "STRONG"-Kandidat aus dem Scan — das komplette Modul in mdview/log.luas bereits vorhandene lib.nvim.logger-Instanz zu mergen — wurde nicht versucht: adapter/log.lua ist ein roher Zeilen-Relay-Collector, lib.nvim.logger ein strukturierter Leveled-Logger mit Record-basiertem Ring. Ein sicherer Merge bräuchte Live-Verifikation gegen den echten Dev-Server-Logging-Pfad, den ein Headless-Test-Setup nicht erreicht.
Was aus diesem Fund trotzdem umgesetzt wurde: Die ANSI-Strip-Logik in M.append war besser als lib.nvim.strings.strip_ansi (Null-Bytes, OSC-Sequenzen, breiterer Catch-all) → zuerst nach lib.nvim upgestreamt (Commit 156e597), danach verdrahtet. Ebenso helper/copy_lines.lua (→ tables.clone) und core/state.luas shallow_copy (→ tables.dict_clone).

Fazit
In allen vier Fällen war das Muster identisch: die Plugin-eigene Implementierung war in mindestens einer konkreten, im Code sichtbaren Eigenschaft überlegen (Async-Streaming, Glob-Marker, ein dokumentierter Windows-Bugfix, ein dokumentierter Crash-Workaround). Ein Zwangsersatz hätte in jedem Fall eine reale Fähigkeit gekostet — deshalb bewusst nicht angefasst, statt einer oberflächlichen "sieht nach Duplikat aus"-Vereinheitlichung.
---
