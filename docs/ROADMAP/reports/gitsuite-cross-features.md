# gitsuite.nvim — Cross-Feature-Report

**Stand:** 2026-09-21
**Geprüft gegen:** `E:\repos\gitsuite.nvim` (aktueller Stand nach dem Security-/Perf-Review dieser Session) und alle 32 weiteren Plugins unter `E:\repos\` plus `docmap-desktop`.
**Methode:** Sechs sequenzielle Recherche-Durchgänge (je 6 Plugins), jede Aussage gegen echten Quelltext verifiziert, nicht aus READMEs geraten. Ideen ohne echten Code-Anker wurden verworfen statt erzwungen — nicht jedes Plugin hat eine sinnvolle Cross-Feature-Richtung, das wird pro Abschnitt explizit vermerkt.

---

## Table of Contents

- [Querschnittsbefunde](#querschnittsbefunde)
- [Priorisierte Kurzliste](#priorisierte-kurzliste)
- Pro Plugin: [ai](#ainvim) · [buffer-ctx](#buffer-ctxnvim) · [cascade](#cascadenvim) · [casedesk](#casedesknvim) · [cmdlog](#cmdlognvim) · [color_my_ascii](#color_my_asciinvim) · [data](#datanvim) · [dap](#dapnvim) · [debugging](#debuggingnvim) · [diff](#diffnvim) · [documentation](#documentationnvim) · [emojis](#emojisnvim) · [fileops](#fileopsnvim) · [filetree](#filetreenvim) · [github_stats](#github_statsnvim) · [gopath](#gopathnvim) · [hover](#hovernvim) · [images](#imagesnvim) · [insights](#insightsnvim) · [language](#languagenvim) · [lsp](#lspnvim) · [markdown](#markdownnvim) · [media](#medianvim) · [mdview](#mdviewnvim) · [open](#opennvim) · [pdfport](#pdfportnvim) · [pickers](#pickersnvim) · [recommender](#recommendernvim) · [replacer](#replacernvim) · [reposcope](#reposcopenvim) · [runtime-analysis](#runtime-analysisnvim) · [sandbox](#sandboxnvim) · [sessions](#sessionsnvim) · [spotlight](#spotlightnvim) · [ui](#uinvim) · [docmap-desktop](#docmap-desktop)

---

## Querschnittsbefunde

Über mehrere unabhängige Recherche-Durchgänge hinweg sind dieselben strukturellen Lücken wiederholt aufgetaucht — das sind die Befunde mit dem größten Hebel, weil sie nicht nur eine Idee blockieren, sondern jeweils mehrere gleichzeitig:

1. **`lib.nvim.git` hat kein `git show`/`cat-file`.** Es gibt keine Primitive, um den Inhalt einer Datei bei einer beliebigen Revision (`HEAD`, `MERGE_HEAD`, ein Tag, …) zu bekommen, ohne über das externe `diff.nvim` zu gehen. Blockiert konkret: `data.nvim`s Idee, einen `git:HEAD`-Blob vor dem Diff zu formatieren; `media.nvim`s Idee für Vorher/Nachher-Poster-Frame-Vergleiche bei Binärdateien; `mdview.nvim`s Idee, eine historische Markdown-Revision zu rendern.
2. **`status_porcelain`/`ahead_behind`/`current_branch` in `lib.nvim.git` nehmen kein `dir`-Argument**, obwohl `remote_url`/`relative_path`/`current_ref` das bereits tun. Dadurch rollen **drei unabhängige Plugins ihre eigenen Multi-Repo-Git-Shellouts**, obwohl `lib.nvim.git` konzeptionell genau das lösen sollte:
   - `replacer.nvim` (`lua/replacer/gitfiles.lua`) — drei sequenzielle `git`-Prozesse statt einem `status_porcelain()`-Aufruf, plus eine eigene `toplevel()`-Repo-Root-Suche.
   - `reposcope.nvim` (`lua/reposcope/utils/repo_status.lua`, `repo_actions.lua`) — eigene `git status --porcelain=v2`/`push`/`pull`/`fetch`-Aufrufe für Dutzende Repo-Pfade parallel (hier teils gerechtfertigt, da `lib.nvim.git` aktuell kein Multi-Repo kann — aber genau das wäre der Fix).
   - `open.nvim` (`lua/open/context.lua`) — eigene `resolve_git_root()`.
   - `ui.nvim` (`lua/ui/statusline/modules/git_clickable/init.lua`) — dupliziert `gitsuite.features.branch.switch()`/`status.repo()` fast 1:1 per eigenem `vim.fn.systemlist`, obwohl der gitsuite-Code laut eigenem Docstring genau aus diesem Modul herausgezogen wurde. Das Original wurde nie stillgelegt.
   - `insights.nvim` (`lua/insights/conflicts/init.lua`) — eigene `in_git_repo()` + `git diff --diff-filter=U`-Shellout, obwohl `gitsuite.features.conflict.list()` genau dieses Modul bereits als Abhängigkeit nutzt.
   - `github_stats.nvim` (`lua/github_stats/statusline.lua:resolve_slug`) — eigene Remote-URL-Regex statt `gitsuite.features.browse.url.parse_remote`/`host_kind`.
   - `hover.nvim` (`lua/hover/preview/git.lua`) — eigener `vim.system({"git","show",...})`-Aufruf statt über `lib.nvim.git`.
   - `filetree.nvim` (`lua/filetree/features/git/git_status/init.lua`) — eigener Porcelain-Parser statt `lib.nvim.git.status_porcelain()`.

   **Empfehlung:** `opts.dir` auf `status_porcelain`/`ahead_behind`/`current_branch` nachrüsten (kleiner, rückwärtskompatibler Patch in `lib.nvim.git`) — das ist der Single Point of Leverage für mindestens 6 der oben genannten Duplikate, unabhängig von jeder gitsuite-Anbindung.
3. **`gitsuite.features.ui.lazygit.M.open()` kann keinen beliebigen Repo-Pfad annehmen** — `repo_dir` ist hart auf `git.repo_root() or vim.fn.getcwd()` verdrahtet. Blockiert: `reposcope.nvim`s Idee, aus der Multi-Repo-Übersicht heraus direkt lazygit für eine bestimmte Zeile zu öffnen; `sandbox.nvim`s Idee, lazygit im gemounteten Devcontainer-Workspace statt im cwd zu öffnen. Ein optionaler `M.open(repo_dir?)`-Parameter behebt beides.
4. **`gitsuite.features.blame` ist hart an den aktuellen Buffer/Cursor gebunden** (`file_location(bufnr)`), es gibt keine Variante, die für einen beliebigen Pfad blamed. Blockiert: `insights.nvim`s Idee, TODO-Treffer mit Autor/Datum zu annotieren; `casedesk.nvim`s Idee, nie lokal geöffnete Cases nach letztem Blame-Zeitstempel zu sortieren. Ein `blame.for_location(dir, path, lnum)`-Export würde beides freischalten.
5. **gitsuite hat kein eigenes `lua/gitsuite/statusline.lua` und kein `integrations/menu.lua`**, obwohl `ui.nvim`s Statusline-Modul-Konvention (`sandbox.statusline`, `sessions.git`, `runtime_analysis_ampel`) und die `ui.contextmenu`-Konvention (`sandbox`, `spotlight`) beide bereits etabliert sind und gitsuite mit `conflict.has_conflicts(bufnr)` (fertiges Boolean, kein Gap) sofort andocken könnte.

---

## Priorisierte Kurzliste

Diese vier Punkte haben den höchsten Wert/Aufwand-Hebel, weil sie entweder mehrere Ideen gleichzeitig freischalten oder eine bereits dokumentierte echte Schwäche (Duplikation, verlorene Sicherheit) beheben:

1. `lib.nvim.git`: `opts.dir` auf `status_porcelain`/`ahead_behind`/`current_branch` nachrüsten (§ Querschnittsbefund 2).
2. `gitsuite.features.ui.lazygit.M.open(repo_dir?)` — optionaler Pfad-Parameter (§ Querschnittsbefund 3).
3. `gitsuite.features.branch.switch()` auf `pickers.nvim`s `git_branches`-Builtin umstellen, wenn verfügbar (fuzzy statt `vim.ui.select`) — kleiner Patch, sofort spürbarer UX-Gewinn.
4. `ui.nvim`s `git_clickable`-Statusline-Modul auf `gitsuite.features.branch`/`status` umstellen statt eigenem Shellout — konkrete, bereits im Code kommentierte Altlast (das Modul, aus dem gitsuite ursprünglich extrahiert wurde).

Alles andere unten ist Ideenmaterial für spätere Phasen, keine Zusage.

---

## ai.nvim

**gitsuite → ai.nvim**
- `conflict.choose("ai")` (neuer 6. Modus neben ours/theirs/both/base/none): baut aus `parser.parse`s bereits gesammelten `ours_first/last`/`theirs_first/last`-Bereichen einen Prompt, ruft `require("ai").ask(...)` und schreibt den Vorschlag mit demselben `nvim_buf_set_lines`-Pfad zurück, den `choose()` schon nutzt.
- `:Git blame explain` — Commit-Summary aus `blame/init.lua`s `format_entry` als Prompt-Kontext an `ai.ask`, um "warum wurde diese Zeile so geschrieben" zu beantworten.

**ai.nvim → gitsuite**
- `ai/context/init.lua`s `M.assemble` hat bereits ein Scope-Plugin-Muster (`opts.buffer`, `opts.structured_data` via `data.nvim`, pcall-gated). Ein neuer `opts.conflict`-Scope könnte `gitsuite.features.conflict.scan(bufnr)` aufrufen und beide Konfliktseiten labeled in den Kontext einfügen — `:'<,'>Ai ask "welche Seite ist richtig?"` bräuchte dann keine manuelle Selektion über die Marker hinweg mehr.
- Ein `opts.remote_link`-Scope könnte die pure `gitsuite.features.browse.url.build(...)` nutzen, um einen zitierfähigen Permalink in den KI-Kontext einzubetten.

## buffer-ctx.nvim

**gitsuite → buffer-ctx.nvim**
- `browse/init.lua`s `M.selection()` liest `'<`/`'>`-Marks manuell — könnte stattdessen `buffer_ctx.ops.location.get_range(mode, line1, line2)` nutzen, das denselben Fallback ("keine explizite Range → letzte Visual-Selection") bereits testet.

**buffer-ctx.nvim → gitsuite**
- `buffer_ctx/ops/git.lua`s `M.get(mode)` (hash/short/branch/tag) dupliziert exakt, was `gitsuite.features.branch.current()` (über `lib.nvim.git`) schon liefert, inklusive desselben Detached-HEAD-Sonderfalls — Routing über `lib.nvim.git` würde eine von zwei parallelen Git-Primitiv-Schichten eliminieren.
- Ein neuer Modus `:Copy location remote` könnte `gitsuite.features.browse.url.build(...)` nutzen, um statt eines lokalen `path:L10-L20`-Strings einen pastefähigen GitHub/GitLab-Permalink zu erzeugen.

## cascade.nvim

**gitsuite → cascade.nvim**
- Nach `conflict.choose(keep)` in einer Markdown-Checkliste könnte gitsuite `require("cascade").renumber()` aufrufen, um die durch den Merge verfälschte Nummerierung sofort zu korrigieren.

**cascade.nvim → gitsuite**
- Ein neuer Handler in cascades Dispatch-Kette (`lua/cascade/dispatch/init.lua`) könnte Konfliktmarker erkennen und auf `gitsuite.features.conflict.next()/prev()/choose(...)` delegieren — dieselbe "durch Zustände zyklen"-Form, die `lists/checkbox.lua` für `[ ]`→`[x]`→`[-]` schon hat.

## casedesk.nvim

**casedesk.nvim → gitsuite**
- `usage.lua`s `M.complete()`-Ranking ist blind für Cases, die nur per `git pull` (identischer Mtime-Stempel) ankamen. Fallback auf den letzten `git.blame_porcelain`-Eintrag (dieselbe Primitive, die `gitsuite/features/blame/init.lua` nutzt) für nie lokal geöffnete Cases würde eine echte statt alphabetische Ordnung liefern.
- Vor Batch-Umbenennungen in `casedesk/apply.lua` (genau die Operationsklasse, die laut `doctor.lua` schon einmal eine echte `Summary.md` überschrieben hat) könnte `gitsuite.features.status.quickfix()` als Sicherheitsnetz laufen, damit sichtbar wird, was gerade uncommitted im Case-Tree liegt.

Keine echte **gitsuite → casedesk**-Richtung gefunden — casedesk hat keinen natürlichen Konsumenten für Git-Orchestrierung.

## cmdlog.nvim

**gitsuite → cmdlog.nvim**
- `branch.switch()` könnte vor dem `git checkout` `cmdlog.core.risky.matching(...)` gegen den zusammengesetzten Argv-String prüfen und bei Treffer eine zusätzliche Warnzeile im `vim.ui.select`-Confirm zeigen.
- `ui/lazygit/init.lua`s Float könnte `cmdlog.core.project_history.get_project_history()` (bereits nach demselben Git-Root geschlüsselt) als Quick-Pick vor/neben dem Float anzeigen.

**cmdlog.nvim → gitsuite**
- `cmdlog/ui/project_picker.lua`s Picker könnte eine Mapping bekommen, die `gitsuite.features.ui.lazygit.M.open()` für das aktuell gewählte Projekt-Root direkt aus der History-Picker-Ansicht öffnet.

## color_my_ascii.nvim

**gitsuite → color_my_ascii.nvim**
- `conflict.scan(bufnr)` behandelt aktuell jeden markerförmigen Bereich als echten Konflikt — auch innerhalb eines Markdown-Fenced-Codeblocks, der Konfliktmarker nur als Doku-Beispiel zeigt. Filterung über `color_my_ascii.api.fences.list_blocks(bufnr)`/`.block_at(bufnr, row)` (dieselbe stabile API, die markdown.nvim konsumiert) würde das vermeiden.

Keine echte **color_my_ascii → gitsuite**-Richtung — reine Fenced-Block-Syntax-Einfärbung hat keinen natürlichen Git-Konsumenten.

## data.nvim

**gitsuite → data.nvim**
- `features/diff/init.lua` könnte für JSON/YAML-Dateien den `git:HEAD`-Blob und den Arbeits-Buffer erst durch `data.format.json.decode/render("pretty")` schicken, bevor `data/preview.lua`s bestehendes Diff-Vorschau-Flow (Apply/Discard) läuft — macht kompakt committete Configs lesbar, statt eine unleserliche Einzeilen-Diff zu zeigen. **Voraussetzung:** Punkt 1 im Querschnittsbefund (`git show`-Wrapper fehlt).

**data.nvim → gitsuite**
- Nach einem erfolgreichen `--inplace`-Write (`data/scope/sink.lua:write_inplace`) könnte data.nvim `gitsuite.features.hunk.stage()` aufrufen, um die entstandene Änderung sofort zu stagen — ein Motion statt zwei.

## dap.nvim

**gitsuite → dap.nvim**
- Vor `continue()` könnte gitsuite über `conflict.has_conflicts(bufnr)` prüfen und den Debug-Start blocken, wenn die Datei noch Konfliktmarker enthält (würde ohnehin nicht kompilieren/parsen).

**dap.nvim → gitsuite**: kein echter Fit — dap.nvim hat keinerlei Git-Bewusstsein, kein Hook-Punkt vorhanden.

## debugging.nvim

**gitsuite → debugging.nvim**
- Bei einem hängenden/nicht beendenden lazygit-Spawn (reales Windows-Risiko laut eigenen Notizen zu detached-Prozessen) könnte gitsuite `debugging.tools.proc_trace.watch(...)` gegen die PID des Jobs aufrufen, um den Kindprozessbaum zu diagnostizieren.

**debugging.nvim → gitsuite**
- `debugging/actions/reports.lua`s Buffer-Report könnte `conflict.has_conflicts(bufnr)` mit aufnehmen — erklärt seltsames Verhalten (falsches Syntax-Highlighting, LSP-Fehler) durch unbemerkt verbliebene Konfliktmarker.

## diff.nvim

*(`:Git diff *` ist bereits ein dünner Alias — hier nur NEUE Synergien darüber hinaus.)*

**gitsuite → diff.nvim**
- `:Git conflict diff` — Drei-Wege-Diff via `diff.run("base=git:HEAD target=git:MERGE_HEAD view=vsplit ...")` als Ergänzung (nicht Ersatz) zu gitsuites eigenem Inline-Marker-Picker.
- `:Git branch diff` — zwei Branches per `vim.ui.select` wählen, dann `diff.run("target=git:<a>..<b>")` über diff.nvims bislang ungenutzte `git:<rev1>..<rev2>`-Syntax.
- `status.quickfix()`s Quickfix-Liste könnte eine Mapping bekommen, die `diff.diff_history(path)` für die Datei unter dem Cursor öffnet — aktuell nur für den aktuellen Buffer verdrahtet.

**diff.nvim → gitsuite**
- `lua/diff/features/gitsigns_peek.lua` bindet `gh` direkt an `gitsigns.preview_hunk_inline` und dupliziert damit, was `gitsuite.features.hunk.preview()` (mit Adapter-Verfügbarkeitscheck + Fallback) bereits zentralisiert — sollte stattdessen dorthin delegieren.

## documentation.nvim

**gitsuite → documentation.nvim**
- Vor `hunk.stage()`/`stage_buffer()` könnte gitsuite den Hunk-Diff-Text durch `documentation.core.history.parse_diff(text)` schicken und bei geänderten Public-Function-Signaturen warnen, wenn die zugehörige Doku seit dem letzten `:DocMap`-Lauf nicht aktualisiert wurde.

**documentation.nvim → gitsuite**
- `standalone/docmap.lua` verlangt aktuell manuelle `--repo-url=`/`--branch=`-Flags für Source-Links. Könnte stattdessen die pure `gitsuite.features.browse.url.parse_remote/host_kind/build` nutzen, um die Blob-URLs automatisch aus dem echten Git-Remote abzuleiten.

## emojis.nvim

**gitsuite → emojis.nvim** (schmal, aber real)
- `status.quickfix()` könnte pro Statuscode (A/M/D/R…) ein Shortcode emittieren und die Zeilen durch `emojis.core.ops.replace(lines, names)` schicken, bevor `setqflist` läuft — echte Glyphen statt Buchstaben in der Changed-Files-Liste.

**emojis.nvim → gitsuite**: kein echter Fit — Picker/Overlay sind Fire-and-Forget ohne Callback, gitsuite hat auch kein eigenes Commit-Message-Compose-Feld (das liegt bei lazygit/neogit).

## fileops.nvim

**Duplikations-Fund:** `fileops/features/conflict_marks.lua` ist eine schwächere Parallel-Implementierung von `gitsuite.features.conflict` — nur regex-basiertes `matchadd`/`matchdelete`, kein diff3/zdiff3-Parsing, keine Resolution.

**fileops.nvim → gitsuite**
- `conflict_marks.lua`s `BufWinEnter`-Autocmd könnte zuerst `gitsuite.features.conflict.refresh(bufnr)` versuchen (pcall, soft) und nur bei fehlendem gitsuite auf die eigene `matchadd`-Logik zurückfallen.
- `on_hold.lua`s Blame-Fallback-Kette (bevorzugt bereits `gitsigns.preview_hunk_inline`) könnte `gitsuite.features.blame.line()` als zweiten bevorzugten Backend-Schritt einfügen, statt auf die eigene rohe Porcelain-Parsing-Kette zurückzufallen.
- `fileops/ops/bulk.lua`s `M.plan()` könnte eine Quickfix-Quelle bekommen, die über `gitsuite.features.status.quickfix()`s Liste statt über ein Verzeichnis iteriert — Bulk-Rename gezielt auf die geänderten Dateien vor einem PR.

**gitsuite → fileops.nvim**
- `branch.switch()` könnte nach erfolgreichem Checkout `fileops.ops.file.notify_change("branch_switch", cwd)` aufrufen, damit neo-tree/nvim-tree sofort aktualisieren statt auf ein unabhängiges Event zu warten.
- Bei fehlgeschlagenem Checkout (Windows-Sharing-Violation, z. B. OneDrive) könnte `branch.switch()` `fileops.diagnose_lock(cb, path)` aufrufen, um die blockierende PID zu melden, statt rohen Git-stderr zu zeigen.

## filetree.nvim

**Duplikations-Fund:** `filetree/features/git/git_status/init.lua` parst `git status --porcelain` per Hand statt `lib.nvim.git.status_porcelain()` zu nutzen — obwohl gitsuites eigener Adapter-Registry-Code laut Docstring explizit nach filetrees `adapter/init.lua`-Vorbild gebaut ist. Kein Overlap dagegen mit `filetree/util/conflict.lua` — das ist ein reiner Dateikollisions-Helfer für fileops, nichts mit Git-Konfliktmarkern zu tun.

**gitsuite → filetree.nvim**
- Nach `branch.switch()` könnte der Adapter `open_reveal(path, ...)` aufrufen, um den Baum auf den neuen Branch-Zustand zu resynchronisieren.
- Nach `blame.full()` könnte `open_reveal(path, line)` den Baum auf die geblamte Datei springen lassen.
- Nach der letzten aufgelösten Konfliktregion (`conflict.scan` leer) könnte `:Filetree git refresh` getriggert werden, damit das `✗`-Konfliktsymbol sofort verschwindet statt auf den nächsten Debounce zu warten.

**filetree.nvim → gitsuite**
- Ein Kontextmenü-Eintrag könnte den Node zuerst per `adapter.open_file(path)` öffnen und dann `gitsuite.features.browse.file()`/`diff.head()`/`hunk.stage_buffer()` aufrufen.
- Auf einem `✗`-markierten (konfliktbehafteten) Node könnte eine Mapping die Datei öffnen und direkt `conflict.refresh(bufnr)` aufrufen.

## github_stats.nvim

**Duplikations-Fund:** `github_stats/statusline.lua:resolve_slug` parst Remote-URLs per eigener Regex (`github%.com[:/]...`) statt über `gitsuite.features.browse.url.parse_remote`/`host_kind` zu gehen — genau die generische, mehrere Hosts abdeckende Logik, die gitsuite schon hat. Der Docstring des Moduls erwähnt sogar einen früheren, ähnlichen Cross-Feature-Fund gegen `ui.nvim` — diesen hier hat er nicht erwischt.

**gitsuite → github_stats.nvim**
- `status.repo()` könnte bei geladenem github_stats eine Traffic-Kennzahl (`github_stats.analytics.query_metric`) an die Statuszeile anhängen, sofern das Repo in `config.get_repos()` gelistet ist — über eine neue `"stats"`-Adapter-Registrierung, nicht per direktem `pcall(require, ...)`.

**github_stats.nvim → gitsuite**
- Ein Kontextmenü-Eintrag "Open on GitHub" im Dashboard könnte `gitsuite.features.browse.repo()` nutzen — allerdings nur sinnvoll, wenn die ausgewählte Dashboard-Zeile mit dem aktuellen Buffer/cwd übereinstimmt (github_stats hat keine Slug→lokaler-Pfad-Zuordnung).

## gopath.nvim

**gitsuite → gopath.nvim**
- Ein neuer `:Git browse define`-Befehl könnte `gopath.resolve()` (liefert `path`+`line` unter dem Cursor) nutzen, um für die Zieldefinition (nicht den aktuellen Buffer) einen Web-Permalink zu bauen und zu öffnen.

**gopath.nvim → gitsuite**
- `gopath/alternate/frecency.lua`s Ranking könnte Kandidaten, die laut `lib.nvim.git.status_porcelain()` aktuell geändert/staged sind, leicht bevorzugen — dieselbe Art Bonus, die für manuelle Picks bereits existiert.

## hover.nvim

**Duplikations-Fund:** `hover/preview/git.lua` spawnt `git show`/`cat-file` direkt per `vim.system`, ohne über `lib.nvim.git` zu gehen.

**gitsuite → hover.nvim**
- `conflict.scan(bufnr)` könnte als hover-Positions-Contribution registriert werden (`hover.registry.register`), damit der Cursor auf einer Konfliktzeile eine Kurzvorschau ("ours: Zeile 12-14, theirs: 16-18 — `:Git conflict choose ...`") zeigt.
- `blame.line()`s Logik könnte als `on_request=true`-Position registriert werden (hovers eigener Kostenschalter für teure Git-Spawns) für ein Blame-on-demand ohne Toggle.

**hover.nvim → gitsuite**
- `hover/preview/git.lua`s SHA-Vorschau könnte per `gitsuite.features.browse.url.build(...)` einen Commit-Web-Link anhängen — behebt auch, dass `hover.open()` für `target.type=="git"` aktuell explizit nichts tut (`gf` auf einer SHA würde dann den Commit online öffnen).

## images.nvim

**gitsuite → images.nvim**
- `status.quickfix()`s Pfadliste könnte, gefiltert auf Bilddateien, an `images.gallery(paths)` übergeben werden — visuelle statt textuelle Review geänderter Icons/Assets.
- Bei einem laut `conflict.list()` unmerged Bild (kein Marker-basiertes Resolving möglich, Binärdatei) könnte `images.show(path)` zumindest die visuelle Inspektion ermöglichen.

**images.nvim → gitsuite**
- `images/orphans.lua`s `M.delete()` könnte vor dem `fs_unlink` `lib.nvim.git.is_tracked(path)` prüfen und bei getrackten Dateien warnen statt sie kommentarlos zu löschen.

*Bestätigte Lücke:* Binäre Merge-Konflikte (Bilder) können durch gitsuites reinen Text-Marker-Parser grundsätzlich nicht aufgelöst werden — Git fügt in Binärdateien nie Textmarker ein.

## insights.nvim

*(`conflict.list()` delegiert bereits an `insights.conflicts` — hier nur neue Synergien.)*

**gitsuite → insights.nvim**
- `:Git status todos` könnte `insights.todos.scan({cwd=...})` auf die Dateiliste aus `status_porcelain()` scopen — neue TODO/FIX-Marker im aktuellen Diff vor dem Commit sichtbar machen.

**insights.nvim → gitsuite**
- `insights.fileinfo.show()` könnte eine Blame-Zeile ergänzen (braucht den unter Querschnittsbefund 4 genannten `blame.for_location()`-Export).
- `insights.todos.scan()`-Treffer könnten mit Autor/Datum via derselben Helper-Funktion annotiert werden.

**Duplikations-Fund (wiederholt bestätigt):** `insights/conflicts/init.lua` rollt eigenes `in_git_repo()` + `git diff --diff-filter=U` statt `lib.nvim.git` zu nutzen — relevant, weil gitsuites eigenes `conflict.list()` genau von diesem Modul abhängt.

## language.nvim

**gitsuite → language.nvim**
- `:Git status spell` könnte `language.spellcheck(nil, "path="..file)` für jede geänderte Markdown/Text-Datei aus `status_porcelain()` aufrufen — Rechtschreibfehler vor dem Commit fangen.

**language.nvim → gitsuite**: kein echter Fit — `gitcommit`-Buffer werden laut `config/DEFAULTS.lua` bereits automatisch spellgecheckt, kein zusätzlicher Hook nötig.

## lsp.nvim

**gitsuite → lsp.nvim**
- `:Git status lint` — für jede Datei aus `status_porcelain()` Diagnostics via `lsp.diagnostics.quickfix.to_qf({severity="error"})` prüfen, als Pre-Commit-Gate nur für die zu committenden Dateien statt den ganzen Workspace.

**lsp.nvim → gitsuite**: kein konkreter Fit, nur ein architektonisches Vorbild (`lsp.integrations.menu` als `ui.contextmenu`-Konvention, die gitsuite noch nicht hat — siehe Querschnittsbefund 5).

## markdown.nvim

**Stärkster Fund dieses Batches.** `lib.nvim.git.status_porcelain()` schlüsselt Rename-Einträge bereits nach neuem Pfad mit `orig_path` daneben. `markdown.find_references_async`/`markdown.retarget` existieren fertig für genau "verschobenes Linkziel reparieren", werden aber aktuell von keinem `:Markdown`-Befehl genutzt.

**gitsuite → markdown.nvim**
- `:Git status relink` (oder `:Git mv <src> <dst>`) könnte `R`-codierte `status_porcelain()`-Einträge nehmen und für jede Markdown-Datei, die die alte Datei verlinkt, `find_references_async` + `retarget` aufrufen — automatische Link-Reparatur nach einem getrackten Rename.

**markdown.nvim → gitsuite**
- markdown.nvims Cursor-Action-Dispatcher könnte eine "Online öffnen"-Alternative bekommen, die `gitsuite.features.browse.url.build(...)` auf das *Linkziel* statt den aktuellen Buffer anwendet — ein verlinktes Doc online öffnen, ohne erst dorthin zu navigieren.

## media.nvim

**gitsuite → media.nvim**
- `status.quickfix()` könnte für Bild-/Video-Pfade `media.probed(path)` (cache-only, nie blockierend) anhängen — Dauer/Auflösung direkt in der Changed-Files-Liste.
- `:Git diff media` (Vorher/Nachher-Poster-Frame-Vergleich) — blockiert auf den fehlenden `git show`-Wrapper (Querschnittsbefund 1).

**media.nvim → gitsuite**: kein echter Fit — media.nvims Hub/Dashboard ist bewusst prozessfrei und git-unabhängig.

## mdview.nvim

**gitsuite → mdview.nvim**
- `:Git diff history` könnte eine "diese Revision live rendern"-Aktion bekommen, die den historischen Blob-Inhalt via `mdview.open()` im Live-Preview zeigt — blockiert ebenfalls auf den fehlenden `git show`-Wrapper.

**mdview.nvim → gitsuite**: kein echter Fit — mdview hat laut Quelltext keinerlei Git-Bewusstsein.

## open.nvim

*(bereits Soft-Dependency für `browse` — hier nur neue Richtungen.)*

**gitsuite → open.nvim**
- `status.quickfix()`/`conflict.list()` könnten eine "im Dateimanager zeigen"-Aktion bekommen über `open.registry.dispatch("filemanager", {text=path, is_path=true})`, statt gitsuite eine eigene plattformspezifische Reveal-Logik bauen zu lassen.

**open.nvim → gitsuite**
- `open.context.resolve_git_root()`s `"git"`-Scope-Token führt aktuell zu einer `file://`-URL des `.git`-Ordners — nicht das, was man meist will. Ein neuer `git_web`-Handler könnte bei geladenem gitsuite auf `gitsuite.features.browse.repo()` delegieren, für ein sinnvolles `:Open git_web`.

## pdfport.nvim

**gitsuite → pdfport.nvim** (schmal, aber konkret)
- `blame.full()`s formatierte Zeilenliste könnte 1:1 an `pdfport.create({text=...})` übergeben werden — ein druckbarer Blame-Snapshot außerhalb von Git, ohne Adapter, nur ein `pcall(require, "pdfport")`.

**pdfport.nvim → gitsuite**: kein echter Fit — PDF-Extraktion/-Erstellung hat nichts, worauf gitsuites Git-Baum aufsetzen könnte.

## pickers.nvim

**Stärkster Fund dieses Batches.**

**pickers.nvim → gitsuite**
- `branch.switch()` rollt aktuell ein eigenes `vim.ui.select` über `git.refs()`. Sollte bei installiertem pickers.nvim `pickers.builtins.run("git_branches")` bevorzugen — fuzzy-filterbar mit Preview statt flacher Liste (Punkt 3 der Kurzliste).
- `status.quickfix()`/`conflict.list()` könnten `pickers.builtins.run("quickfix")` als Alternative zum reinen `:copen` anbieten — durchsuchbar statt statisch.

**gitsuite → pickers.nvim**
- `pickers.sources.repos` kennt bereits alle geklonten Repos unter `REPOS_DIR`. Ein `:Git status repo <name>` könnte darüber den Zielpfad auflösen — setzt aber Querschnittsbefund 2 (`dir`-Parameter) voraus.

## recommender.nvim

**recommender.nvim → gitsuite**
- Ein neuer `"changed"`-Scope (neben `buffer|path|cwd|cfile|line`) könnte seine Dateiliste aus `status_porcelain()` statt aus einer vollen Verzeichnis-Traversierung beziehen — Aliasing-Analyse nur auf die zu committenden Dateien.

**gitsuite → recommender.nvim**: kein zusätzlicher Fit über die obige Richtung hinaus.

## replacer.nvim

**Duplikations-Fund (stärkster dieses Batches):** `replacer/gitfiles.lua` shellt für `--changed[=modified,staged,untracked]` **drei sequenzielle Git-Prozesse** plus eine eigene `toplevel()`-Repo-Root-Suche — während `lib.nvim.git.status_porcelain()` alle drei Zustände in **einem** Aufruf über den XY-Porcelain-Code liefert. Lohnt sich unabhängig von jeder gitsuite-Anbindung (siehe Querschnittsbefund 2).

**Cross-Feature-Fit:** keiner stark genug, weil `replacer.M.run()` nur einen Scope-Token statt einer injizierbaren Dateiliste annimmt — gitsuite kann ihm aktuell keine Konflikt-/Status-Dateiliste übergeben, ohne dass replacer selbst einen neuen Einstiegspunkt bekommt.

## reposcope.nvim

*(Kein Datei→Web-URL-Mapping vorhanden — bereits bestätigt, hier andere Synergien.)*

**reposcope.nvim → gitsuite**
- Die Bulk-Status-Übersicht (`ui/actions/status_view.lua`) hat Zeilen-Aktionen für push/pull/fetch/README, aber keine für eine tiefe Einzel-Repo-Git-UI. Eine neue Mapping könnte `gitsuite.features.ui.lazygit.open()` für die gewählte Zeile aufrufen — setzt Querschnittsbefund 3 (`repo_dir`-Parameter) voraus.

**Duplikations-Fund:** `reposcope/utils/repo_status.lua`/`repo_actions.lua` shellen eigene `git status --porcelain=v2`/`push`/`pull`/`fetch`-Aufrufe für viele Repo-Pfade parallel — hier teils gerechtfertigt (Multi-Repo, was `lib.nvim.git` aktuell nicht kann), aber genau der Use-Case, den Querschnittsbefund 2 lösen würde.

## runtime-analysis.nvim

**gitsuite → runtime-analysis.nvim**
- Selbstinstrumentierung via `runtime-analysis.telemetry.auto({namespace="gitsuite.nvim", ...})` würde beantworten, welche der ~30 `:Git <scope> <action>`-Routen nie aufgerufen werden — eine echte Coverage-Prüfung für einen Command-Tree dieser Größe.

**runtime-analysis.nvim → gitsuite**: kein echter Fit — HTTP-Runner/Benchmark-Domäne passt nicht zu gitsuites (meist notify-only) Feature-Funktionen.

## sandbox.nvim

**sandbox.nvim → gitsuite**
- Vor `devcontainer.build` (mountet `workspace_dir` ungeprüft) könnte `conflict.list()` als Preflight-Check laufen, um zu verhindern, dass ein Mid-Merge-Arbeitsbaum unbemerkt in ein Image gebacken wird.

**gitsuite → sandbox.nvim**
- Der lazygit-Float-Titel könnte `sandbox.statusline.status()` (reiner gecachter String) anhängen, damit sichtbar ist, ob der Devcontainer für dieses Repo läuft.
- Lazygit direkt im gemounteten Devcontainer-Workspace statt im cwd öffnen — setzt Querschnittsbefund 3 voraus.

## sessions.nvim

*(`sessions.git` wrapt bereits `lib.nvim.git` — hier nur neue Synergien.)*

**gitsuite → sessions.nvim**
- Nach erfolgreichem `branch.switch()` könnte gitsuite `sessions.core.save(nil)` dann `.load(nil)` aufrufen — Checkout eines Branches würde automatisch die Fenster-/Tab-Anordnung des Ziel-Branches laden statt die des alten stehen zu lassen.

**sessions.nvim → gitsuite**
- `cfg.hooks.on_load` könnte `gitsuite.features.status.quickfix()` aufrufen — beim Laden einer Branch-Session sofort sehen, was auf diesem Branch offen/geändert ist ("was habe ich hier gemacht").

## spotlight.nvim

**gitsuite → spotlight.nvim**
- Eine Mapping in `blame.full()`s Split könnte `spotlight.add(sha)` aufrufen — alle Zeilen desselben Commits leuchten synchron in Blame-Split und Quellbuffer auf. Ein "welche Zeilen gehören zu diesem Commit"-Feature, das keines der beiden Plugins allein hat.

**spotlight.nvim → gitsuite**: kein echter Fit — reiner Text-Highlighter ohne Git-Bewusstsein.

## ui.nvim

**Duplikations-Fund (real, mit Docstring-Beleg):** `ui/statusline/modules/git_clickable/init.lua` ist das Modul, aus dem gitsuites `features/branch`-Code laut eigenem Kommentar extrahiert wurde — das Original wurde aber nie stillgelegt und dupliziert `branch.switch()`/`status.repo()` fast Zeile für Zeile über eigene `vim.fn.systemlist`-Aufrufe (Punkt 4 der Kurzliste).

**gitsuite → ui.nvim**
- Ein neues `lua/gitsuite/statusline.lua` (nach dem etablierten `sandbox.statusline`-Muster) auf Basis von `conflict.has_conflicts(bufnr)` würde ui.nvim einen vierten Statuszeilen-Baustein für einen Live-"mitten im Merge"-Indikator ermöglichen.
- Ein `lua/gitsuite/integrations/menu.lua` (nach dem `sandbox`/`spotlight`-`ui.contextmenu`-Muster) auf Basis von `conflict.choose(...)`/`.next()/.prev()` würde Rechtsklick-Konfliktauflösung passend zur bestehenden Ökosystem-Konvention geben.

## docmap-desktop

Eine eigenständige Tauri/Rust-App (`src-tauri/src/*.rs`), kein Lua, kein Neovim-Prozess, keine RPC-Brücke zu gitsuite.nvim. Macht ihre eigene, unabhängige Git-Arbeit in Rust (`filetree.rs::git_states`, eigener `git status --porcelain --ignored`-Shellout) — dieselbe Aufgabe wie `lib.nvim.git`, aber zweimal in unterschiedlichen Sprachen implementiert, ohne gemeinsamen Codepfad. Keine erzwungene Idee — der einzige bestehende Bridge-Punkt ("open file:line im eigenen Editor") ist generisch und nicht git-spezifisch.

---

## Nicht verfolgte Richtungen

Explizit als "kein echter Fit" verworfen (nicht vergessen, sondern geprüft und abgelehnt): color_my_ascii→gitsuite, casedesk-Gegenrichtung, cmdlog bereits abgedeckt, dap.nvim→gitsuite, language.nvim→gitsuite, lsp.nvim→gitsuite (nur architektonisches Vorbild), media.nvim→gitsuite, mdview.nvim→gitsuite, pdfport.nvim→gitsuite, recommender-Gegenrichtung, runtime-analysis→gitsuite, spotlight→gitsuite. Jeweils mit Begründung im jeweiligen Abschnitt.
