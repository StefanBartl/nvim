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
