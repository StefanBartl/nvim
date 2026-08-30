# Neotree-Source-Report — Auswertung aller `NEOTREE_FEATURES.md`

**Stand:** 2026-08-28
**Quelle:** die 9 Dateien `docs/ROADMAP/NEOTREE_FEATURES.md` aus `C:\repos\*.nvim`.
Diese Dateien wurden nach Erstellung dieses Reports **ersatzlos aus den Plugin-Repos
entfernt**; dieser Report ist ab jetzt die einzige Überlieferung ihres Inhalts.

**Leitfrage** (der eigentliche Zweck der Übung): *Eignet sich ein Plugin als
**Source** für Neo-tree* — also als eigener Reiter in der Source-Leiste, so wie
`filesystem`, `buffers`, `git_status`, `document_symbols`? Alles andere
(Aktionen, Patterns, Utilities) wird nachrangig als Beifang mitgeführt.

---

## 1. Wann ist ein Plugin eine Source — und wann nicht

Eine Neo-tree-Source beantwortet genau eine Frage: *„Welche Einträge stehen in
diesem Baum?"* Daraus folgen fünf harte Kriterien. Ein Kandidat muss **alle
fünf** erfüllen, sonst ist er ein Picker, ein Float oder eine Aktion — aber
keine Source.

| # | Kriterium | Warum es Kandidaten zerlegt |
|---|---|---|
| K1 | **Hierarchische Daten.** Die Items haben eine echte Eltern-Kind-Beziehung. | Eine flache Liste in einem Baum-Pane ist ein Baum der Tiefe 1 — verschenkter Platz. Das ist das häufigste K.o.-Kriterium. |
| K2 | **Stabile Item-IDs.** Ein Item bleibt über Refreshes hinweg identifizierbar. | Ohne stabile ID gehen Expand-State, Cursor-Position und Marks bei jedem Refresh verloren. |
| K3 | **Dauerhafte Sichtbarkeit lohnt.** Man will die Liste *während* der Arbeit sehen, nicht einmalig abfragen. | Das ist der einzige echte Vorteil gegenüber einem Picker. Fällt er weg, ist der Picker überlegen: schneller, fuzzy, kein Fensterplatz. |
| K4 | **Moderate Kardinalität und moderater Churn.** Etwa 5–500 Items, nicht 20 000; nicht bei jedem Tastendruck neu. | Neo-tree rendert synchron in einen Buffer. Sehr lange oder stark flatternde Listen sind in fzf/telescope besser aufgehoben. |
| K5 | **Node-Aktionen sind sinnvoll.** open / reveal / delete / mark auf einem Item. | Ohne Aktionen ist es eine Anzeige, kein Baum — dann reicht ein Float oder die Statusline. |

**Zusatzkosten jeder Source** (fließt unten in „Aufwand" ein): Neo-tree-Sources
sind **nicht** manager-agnostisch. Eine Source ist per Definition Neo-tree-API
(`components`, `renderer`, `commands`, `setup`) — sie widerspricht dem
`filetree.nvim`-Grundsatz „adapter-agnostisch" und ist in nvim-tree, netrw oder
oil schlicht nicht portierbar. Jede Source ist damit ein bewusst eingegangener
Neo-tree-Lock-in.

---

## 2. Ergebnis in einem Satz

Von den neun auditierten Plugins ist **keines** ein überzeugender
Neo-tree-Source-Kandidat. Der Ertrag der ganzen Audit-Runde liegt woanders: in
Node-**Aktionen** (insights, pdfport, cmdlog), in **Infrastruktur** (lib.nvim)
und in einer sehr guten **Lückenliste** für `filetree.nvim` (Sibling-Navigation,
Collapse all, Sort-Cycling). Die drei ernsthaften Source-Kandidaten des
Gesamtökosystems — `sessions.nvim`, `sandbox.nvim`, `documentation.nvim` —
hatten nie eine `NEOTREE_FEATURES.md` und tauchen deshalb erst in Abschnitt 5
auf.

---

## 3. Die neun auditierten Plugins

| Plugin | Source-Eignung | Nutzwert | Aufwand | Kernaussage |
|---|---|---|---|---|
| `filetree.nvim` | entfällt (Konsument) | sehr hoch | — | Zielplugin, nicht Kandidat. Enthält die beste Lückenliste. |
| `lib.nvim` | nein | hoch | — | Infrastruktur unter allem; keine eigenen Items. |
| `pickers.nvim` | nein (Anti-Kandidat) | hoch | — | Die Konkurrenz zur Source-Idee; verletzt K3 systematisch. |
| `insights.nvim` | nein | mittel-hoch | S–M | Liefert Node-**Aktionen**, keine Item-Menge. |
| `cmdlog.nvim` | Grenzfall (nur Favorites) | mittel | M | History verletzt K1/K4; die Favorites-Teilmenge wäre denkbar. |
| `spotlight.nvim` | nein (explizit begründet) | mittel | — | Verletzt K1 und K3; liefert dafür fünf starke Mechanismen. |
| `pdfport.nvim` | nein | mittel | S | Integrationspunkt plus Konventionen. |
| `open.nvim` | nein | sehr gering | — | Vollständig durch die Adapter-Schicht abgelöst. |
| `migrate.nvim` | nein | null | — | Audit ergab nichts. Abgeschlossen. |

Aufwand: S = bis 1 Tag · M = 2–5 Tage · L = mehr als 1 Woche.

---

### 3.1 `filetree.nvim` — das Zielplugin (253 Zeilen, mit Abstand das wertvollste Dokument)

Kein Source-Kandidat, sondern der Adressat aller anderen Audits. Das Dokument
bestand aus drei Durchgängen.

**Pass 1 — alte Neo-tree-Config (`nvim/lua/config/neotree/`) gegen filetree.nvim.**
Kategorienweiser Abgleich (nav / ui / fileops / search / paths / git / lsp /
compare / org / infra). Ergebnis: Der Großteil war zum Auditzeitpunkt bereits
portiert (56 Features in der Registry, Stand 2026-08-25). Offen blieben vier
Punkte:

1. **Markdown-Link-Bridge** — erledigt. Gelandet als `paths.markdown_links`
   (`ML`/`MR`/`MM`); schreibt `[name](relative/path)` selbst, statt in
   markdown.nvim zu rufen, hat also keine zu schützende Abhängigkeit.
2. **pdfport-Integration** — erledigt. Gelandet als `system.pdf_open` plus
   `system.pdf_create` (Nodes *zu* PDF, vom Audit nicht antizipiert). pdfport
   ist Soft-Dependency; ohne sie geht der Node an den OS-Viewer. Beides läuft
   über den Adapter, ist also tree-agnostisch.
3. **Buffers-Source (`dd` = buffer_delete)** — *offen*. filetree.nvim kennt kein
   „Buffers-Source"-Konzept. **Das ist exakt der Punkt, den die Leitfrage
   adressiert** („wie Tabliste im Filebrowser"). Die `noop`-Guards der alten
   Config, die filesystem-only-Tasten auf dieser Source unterdrücken, sind
   Neo-tree-spezifisch und nicht portierbar.
4. **Neotest-Source** — geparkt. Keymaps für eine Neo-tree-*tests*-Source
   (run/debug/watch/stop unter dem Cursor). In der Config annotiert als
   „AUDIT: Wird nicht verwendet derzeit!". Als Idee vormerken
   (`integration.neotest`), nicht portieren, solange keine Tests-Source aktiv ist.

**Pass 2 — `github_stats.nvim` als Muster-Steinbruch.** Keine Port-Targets,
sondern Architektur- und UI-Patterns:

- Cross-platform Command-Detection (`Get-Command` auf Windows, `command -v` auf
  Unix, Direct-Exec als Fallback).
- **Atomischer Schreibvorgang**: nach `<path>.tmp` schreiben, dann
  `vim.loop.fs_rename`, Temp bei Fehler löschen. Für jeden persistierten
  Zustand (Marks, Bookmarks, Watcher-Quarantäne) statt eines nackten `writefile`.
- Dual Config Source mit klarer Priorität: `setup(opts)` > `config.json` auf
  Platte > automatisch angelegtes Default-`config.json`. Interessant, falls je
  Zustand über Maschinen hinweg via Dotfiles synchronisiert werden soll.
- Dreistufiges `notification_level` (all / errors / silent) vor einem
  `notify`-Wrapper — relevant für alles, was im Hintergrund häufig meldet.
- `bindings/{usrcmds,keymaps,autocmds}`-Split; ein `usrcmds/init.lua`
  registriert *alle* User-Commands; Keymaps getrennt in **konfigurierbar**
  (leerer String deaktiviert) und **fix**.
- which-key-Registrierung vollständig unter `pcall(require, "which-key")`.
- **Debounced Re-Render**: ein Single-Shot-`vim.loop.new_timer()` bündelt
  schnelle State-Änderungen zu einem Render, mit `force`-Bypass für
  nutzerausgelöste Aktionen. Direkt relevant für fs-watcher-Ticks und
  CursorMoved.
- Native Cursorbewegung in reinen Anzeige-Buffern per `<Nop>` blockieren
  (`h`/`l`/Pfeile/PageUp/PageDown/Home/End), damit App-State und Cursor nicht
  divergieren.
- **Sort-Cycling mit Identitätswiederherstellung**: Identität des selektierten
  Items vor dem Sortieren merken, danach über den Namen wiederfinden — der
  Cursor springt beim Umschalten des Sortierkriteriums nicht. Genau die Form,
  die „Sortierung wechseln, ohne die Stelle zu verlieren" braucht.
- `vim.system(args, ...)` immer mit Argument-**Tabelle**, nie mit interpoliertem
  Shell-String.
- `@types/`-Split: eine Datei pro Domäne, jede gibt `{}` zurück und existiert
  nur für `---@class`/`---@field`.

**Pass 3 — nvim-tree und netrw als Feature-*Quellen*** statt nur als
Adapter-Ziele gelesen, und zwar gegen die reale Action-Fläche
(`lua/nvim-tree/actions/*/`) und netrws dokumentierten Kommandosatz, nicht aus
dem Gedächtnis. Der Großteil ist abgedeckt. **Drei echte Lücken:**

| Lücke | Quelle | Bewertung |
|---|---|---|
| **Sibling-Navigation** — nächster/voriger Eintrag auf *gleicher* Tiefe, ohne abzusteigen | nvim-tree `actions/moves/sibling` | `nav/tree_traverse` hat nur `up()`/`down()`, die den *Root* wechseln. `grep -ri sibling lua/filetree/features/` war leer. Billig und in breiten Verzeichnissen wirklich nützlich. **Beste Aufwand/Nutzen-Relation im gesamten Dokumentenbestand.** |
| **Collapse all** — alle offenen Verzeichnisse auf den Root zurückfalten | nvim-tree `actions/tree/collapse` | Die `collapse`-Treffer im Baum sind alle beiläufig (auto_reveal, cwd_sync, marks), keiner ist eine nutzerseitige Aktion. Jeder Adapter kann das nativ — also eher eine dünne Adapter-Methode als ein eigenes Feature. |
| **Sort-Cycling** (name / size / mtime, plus reverse) | netrw `s` und `r` | Es gibt gar keine nutzerseitige Sortiersteuerung; alle `sort`-Treffer sind intern. Erst pro Adapter prüfen: Neo-tree hat `sort_function`, nvim-tree hat `sort.sorter`. Wenn alle ansteuerbar sind, ist auch das eine Adapter-Methode. Zu kombinieren mit dem Identity-Restore-Pattern aus Pass 2. |

Bewusst **keine** Lücken: Hidden-Files-Toggle (absichtlich an den Adapter
delegiert, `H` in beiden Managern — eine eigene Implementierung ergäbe zwei
Schalter für ein Verhalten), Remote-Editing über scp/ftp (out of scope: netrw
ist Browser *plus* Transport, filetree.nvim ist ein Manager über lokale Bäume),
netrw-Listing-Styles (Rendering des Adapters).

Grundregel aus dem Dokument: Alles landet **hinter** der Adapter-Schicht
(`lua/filetree/adapter/{neotree,nvimtree,netrw,oil,mini_files}.lua`) — ein
Feature liest „Node unter dem Cursor / markierte Nodes / aktuelles Verzeichnis"
vom Adapter, nie direkt aus einem Neo-tree-State-Objekt. Und alles, was
shelled, geht über `util/platform.lua`, nicht über inline
`xdg-open`/`start`/`open`-Zweige.

---

### 3.2 `lib.nvim` — Infrastruktur, keine Source

Spiegelbild des filetree-Audits: Was hat lib.nvim, das filetree.nvim
konsumieren kann?

Bereits konsumiert: Neo-tree-Node-Auflösung (`lib.nvim.neotree.node` mit
`get_current`, `get_path`, `collect_nodes`, `extract_paths`, `get_line_number`),
`ui.hover_select` (hinter `util.select`), die Wrapper
`bindings.keymap`/`usercmd`/`autocmd`.

Kandidaten, die jeweils ein lokales `util.*` überlappen:

- **Fenster:** `make_scratch`, `nice_quit`, `center`, `close_on_focus_lost`,
  `set_title`, `attach`. `window.find_by_filetype(ft)` wurde von der früheren
  Neo-tree-Hartverdrahtung (`get_neotree_window()`) zu einem generischen
  Filetype-Lookup verallgemeinert — filetree.nvim kann es jetzt mit dem
  Filetype des jeweils aktiven Adapters aufrufen.
- **Buffer/Window/Tab:** `normal_buffer` (Specials überspringen, normales
  Fenster finden), `safe_adjacent_buffer`, `capture` (session-artiger
  Zustandsschnappschuss), `move_buffer_to_tab`, `resize_guarded` (relevant für
  das geplante Auto-Resize).
- **Pfade und FS:** `fs.path` (join/ensure-dir), `path_shorten` (für
  Node-Labels und Statusline), `is_dir` / `is_readable_file` / `is_subpath` /
  `relpath`, `find_upward_dir`, `polymorphic_rootresolver` (mehrstrategischer
  Projekt-Root, stärkere Variante), `normalize.*`
  (`normalize_path`, `path_kind`, `to_path`, `to_argv`) — und vor allem
  **`fs.collect_recursive`** (sync und async, files/dirs), das die Lücke des
  handgeschriebenen iterativen Walkers in `util.fs` schließt.
- **Cross-platform:** `cross.platform.is_windows/linux/macos/wsl`, `cross.run`
  und `run_argv` (relevant für „open in system app", Trash, Launcher),
  `copy_to_clipboard` (überlappt `paths.path_copy`), `cross.fs.separators`.
  `lib.nvim.system` ist neuer und breiter als `cross` — vor einer
  Konsolidierung vergleichen.
- **Git:** Repo-Root, aktueller Branch, dirty, ahead/behind, upstream,
  HEAD-Hash, `clear_line_diff`.

Migrationsregel aus dem Dokument: über lib.nvim routen, aber mit lokalem
Fallback, damit filetree.nvim standalone lauffähig bleibt — genau wie bereits
bei `map`/`usercmd`/`autocmd`/`hover_select` praktiziert.

---

### 3.3 `pickers.nvim` — enthielt in Wahrheit den Config-Audit

Die Datei in `pickers.nvim` inventarisierte nicht pickers.nvim, sondern die
**alte Neo-tree-Config** (`lua/config/neotree/`), mit einer eigenen
Portabilitäts-Ampel (grün = bereits cross-platform und manager-agnostisch, gelb
= teilweise gekoppelt, rot = eng an Neo-tree-State/API). Inhaltlich überlappt
sie stark mit Pass 1 aus 3.1, hat aber zwei Dinge, die dort fehlen.

**Die Safety-Schicht**, im Original als starker, weitgehend manager-unabhängiger
Migrationskandidat markiert: aggregierte Fassade (`safety/`), automatisches
Backup vor destruktiven Operationen, Dry-Run-Modus, File-Operation-Wrapper mit
Quarantäne, sequentielle Operation-Queue, automatische Recovery/Rollback,
Input-Validierung. Nebenbemerkung aus dem Original: Der Ordnername
`safety/file_operatiuon_wrapper` enthält einen Tippfehler, der bei der
Extraktion zu korrigieren war.

**Die Drei-Tier-Migrationsleitlinie:**

- *Tier 1 — nahezu unverändert übernehmbar (manager-agnostisch, cross-platform):*
  `open/system_app`, `open/filemanager`, `trash/platform`, `safety/*`,
  `actions/path/to_require` und `rel_path_to_require`, `actions/copy/*`,
  `actions/project_root`, `actions/grep_picker`, `commands/diff_files`.
- *Tier 2 — braucht eine dünne Node/State-Abstraktion*
  (`FiletreeNode { path, type, bufnr? }` plus `reveal`/`select`/`refresh`, damit
  die Logik den Neo-tree-State nicht mehr anfasst): `traverse`, `info/node`,
  `save/*`, `node_replace_buf`, `mark`, `clipboard`, `cwd_sync`,
  `refresh_adapter`, `layout_guard`, `watcher_quarantine`, Reveal.
- *Tier 3 — Neo-tree-spezifisch, pro Manager neu zu bauen:* `components/`,
  `event_handlers/`, `autocmds/`, `sources/` samt Source-Keymaps.

Ebenfalls dort vermerkt: Auch die Trash-Schicht (Orchestrator,
plattformspezifisches Backend, Bestätigungsdialoge, Batch-Ausführung ohne
Rückfrage, Undo mit History) und die `checkhealth/`-Struktur (core, actions,
features, utils) waren als übernehmenswerte Muster markiert. netrw und nvim-tree
waren in der Config nicht angepasst, boten also nichts zu migrieren — die
Feature-Ernte aus diesen beiden erfolgte erst später in Pass 3 des
filetree-Dokuments (siehe 3.1).

**Zur Leitfrage:** pickers.nvim ist der **systematische Gegenspieler** der
Source-Idee. Es konsolidiert sieben Picker-Module hinter einem einzigen
`:Pickers`-Kommando über telescope, fzf-lua oder snacks. Jede flache, punktuell
abgefragte Liste ist dort besser aufgehoben als in einem Baum-Pane — das ist
K3. Praktische Konsequenz: **Bevor irgendeine Source gebaut wird, ist zu prüfen,
ob dieselbe Liste nicht einfach ein `:Pickers`-Scope sein sollte.** In fast
allen hier betrachteten Fällen ist das die Antwort. Zusätzlicher Vermerk aus dem
Original: `actions/grep_picker` überlappt mit pickers.nvim — teilen statt
duplizieren.

---

### 3.4 `insights.nvim` — Aktionen ja, Source nein

Vier Features waren als filetree-relevant markiert:

| Feature | Wo es hingehört | Bewertung |
|---|---|---|
| Async Projekt-Dateibaum nach Datei oder Clipboard (`vim.system`; PowerShell auf Windows, `find`+`sed` auf Unix; konfigurierbare Exclude-Patterns) | „Export tree"-Aktion auf dem Root-Node | Nutzwert hoch, Aufwand S. Klarster Kandidat des Dokuments. |
| Verzeichnis-Kompression (`tar`/`zip`/`Compress-Archive`, Engine plattformabhängig; schreibt Archiv plus `file-list.txt` in ein `compressed/`-Unterverzeichnis; `.git/` automatisch ausgeschlossen) | „Compress" im Kontextmenü eines Ordner-Nodes | Nutzwert mittel, Aufwand S–M. |
| Datei-Info-Float über `fs.stat` (Größe, mtime, Rechte, Typ) | „File info" auf dem Node unter dem Cursor | Muss vom *aktuellen Buffer* auf den *Node unter dem Cursor* umgestellt werden. Überlappt `ui.node_info`. |
| Datei- und Verzeichniszähler unter einem Pfad (gleiche Exclude-Patterns wie der Export) | Footer/Statusline für Root oder markierten Subtree | Nutzwert gering, Aufwand S. |

Als ausdrücklich *nicht* relevant markiert: `symbols` (ripgrep/Tree-sitter
Symbol-Index), `metrics` (Lua-Codestatistik), `imports` (require-Analyse) —
allesamt Code-Navigation oder Code-Qualität, keine Filetree-Belange.

**Source-Bewertung:** Nein. Alle vier sind Operationen *auf* einem Node und
liefern keine eigene Item-Menge; K1 fehlt, K5 ist invertiert. Zusatzbefund
außerhalb des Originals: Der `symbols`-Index wäre das einzig Baumförmige an
insights.nvim — er kollidiert aber frontal mit Neo-trees eingebauter
`document_symbols`-Source und mit `lsp.outline`. Nicht bauen.

---

### 3.5 `cmdlog.nvim` — der einzige Grenzfall

Inhalt des Audits:

- **Favorites-System**, persistent und JSON-basiert (`core/favorites.lua`:
  `M.load`:161, `M.save`:194, `M.toggle`:255, `M.is_favorite`:279).
  Bemerkenswert ist die Verteidigungskette gegen Windows-Pfad- und
  mkdir-Eigenheiten: erst `vim.fn.mkdir`, dann ein manueller libuv-Walk, dann
  `plenary.Path` als letzter Fallback. Direkt wiederverwendbar für jedes
  Feature, das JSON nach `stdpath("data")` schreibt.
- **Notizen pro Eintrag** (Buffer mit Autosave auf
  `TextChanged`/`TextChangedI`/`BufWritePost`). *Aus cmdlog entfernt*, weil die
  Seitenfenster-Logik nicht mit Telescope koexistieren konnte: Das Verlassen
  des Prompt-Fensters schließt den Picker. Aus der Git-History zu holen:
  `lua/cmdlog/core/notes.lua`, `lua/cmdlog/ui/telescope/notes_picker.lua` und
  `open_notes_window` in `lua/cmdlog/ui/picker_utils.lua`, jeweils Stand Commit
  `1ecd416`. Lehre für eine Portierung: die Notiz in einem *eigenen*, normalen
  Fenster öffnen, nicht als Split aus einem fokussierten Picker heraus. Das
  Namensschema `note_key` sanitisiert einen beliebigen String zu einem
  dateisystemsicheren Namen — dieselbe Technik für „absoluter Pfad zu
  Notizdateiname".
- **Unique/Dedup-Ansichten** (`ui/history_unique_picker.lua`,
  `all_unique_picker.lua`: jüngstes Vorkommen behalten, ältere Duplikate
  verwerfen) — Vorlage für einen „zuletzt benutzte Dateien/Verzeichnisse"-Picker
  mit Dedup nach Pfad.
- **Cross-platform Pfad- und Env-Expansion** (`core/shell.lua:58`,
  `expand_path_template`): behandelt `~`, POSIX `$VAR` und Windows `%VAR%` in
  einer Funktion und normalisiert danach die Slashes. Jede Config-Option, die
  einen Pfad annimmt (Custom-Root, Ignore-Datei, Exportziel), sollte das
  benutzen statt sich auf `vim.fn.expand` allein zu verlassen.
- Config-Layout `config/DEFAULTS.lua` plus `config/init.lua` plus typisiertes
  `@types/` — als Angleichungsziel über alle `StefanBartl/*.nvim` hinweg notiert.
- `health.lua`: Neovim-Version, je nach Config die benötigte Dependency
  (plenary/telescope/fzf-lua) und ein feature-spezifischer Runtime-Check. Für
  filetree.nvim heißt das: prüfen, ob das konfigurierte Backend überhaupt
  installiert ist.
- Opt-in-Keymaps, standardmäßig deaktiviert. Generelles Prinzip: nie
  ungefragt eine Leader-Taste beanspruchen, und immer `desc` setzen, damit
  which-key v3 die Bindung ohne expliziten `wk.register()`-Aufruf findet.

**Source-Bewertung:** Die Command-History selbst ist **keine** Source — sie ist
flach (K1), hat tausende Einträge (K4), extremen Churn (K4), und man will sie
punktuell abfragen statt dauerhaft sehen (K3). Der *Favorites*-Teil erfüllt
K2 bis K5, scheitert aber weiterhin an K1. Denkbar wäre allenfalls eine
kombinierte Source „Favoriten plus zuletzt besuchte Verzeichnisse", zweistufig
nach Kategorie gruppiert — eine künstliche Hierarchie, um K1 formal zu
erfüllen. Nutzwert mittel, Aufwand M, Neo-tree-Lock-in inklusive.
**Empfehlung: als `:Pickers`-Scope bauen, nicht als Source.**

---

### 3.6 `spotlight.nvim` — die sauberste Absage, mit dem größten Beifang

Das Dokument stellt die Leitfrage wörtlich und beantwortet sie mit **„Nein, und
sollte es auch nicht"**: Spotlight besitzt eine flache, sessionweite Liste von
etwa ein bis acht Tokens. Das ist eine Liste, keine Hierarchie (K1), und
`lib.nvim.ui.kit.select` rendert sie *besser* als ein Baum-Pane, weil der
Farb-Chip pro Zeile der eigentliche Informationsträger ist — und eine
Tree-Source gibt genau die Per-Row-Highlight-Spans auf.

Stattdessen zwei benachbarte, sinnvolle Dinge, von denen keines eine Source ist:

1. Ein `filetree.nvim`-Kommando „aus dem Baum heraus spotlighten": Cursor auf
   einem Datei-Eintrag, eine Taste, der Basename wird Spotlight-Token — danach
   sieht man, welche der offenen Logs ihn erwähnen. Rund zehn Zeilen
   `require("spotlight").add(name)` in der Keymap-Schicht.
2. Spotlight-Treffer *im* Tree-Fenster: funktioniert bereits, weil das Ledger
   jedes nicht-floatende Fenster als eligible behandelt — ein Token, das in
   einem Dateinamen vorkommt, leuchtet im Baum in derselben Farbe wie im Log.
   Nichts zu bauen; offen ist nur, ob es ein Opt-out braucht, falls es stört.

**Fünf übertragbare Mechanismen** (der eigentliche Wert des Dokuments):

- **Window-local-State-Ledger** (`core/match.lua`: Ledger-Tabelle :29,
  `eligible()` :41 mit Float-Skip, `apply_window()` :94, `remove()` :116,
  `forget_window()` :160; getrieben von den Autocmds
  `WinNew`/`BufWinEnter`/`TabNewEntered` in `bindings/autocmds.lua:52` und
  `WinClosed` :74). Ein `Fenster -> { logische ID -> vim-seitiges Handle }`-Ledger,
  das fensterlokalen Zustand auf jedes Fenster neu anwendet, sich merkt was es
  wohin gesetzt hat, und ein logisches Item aus allen je erreichten Fenstern
  wieder entfernen kann. Das ist der stärkste Transfer: Neo-tree- und
  NvimTree-Fenster werden permanent geschlossen und neu erzeugt (Toggle, `:e`
  im Baum, Tabwechsel), und alles Fensterlokale —
  `matchadd()`-Hervorhebung git-dirty oder gefilterter Einträge,
  `winhighlight`-Overrides, eine eigene `statuscolumn` — geht dabei verloren.
  Ein Ledger plus drei Autocmds löst das einmal für alle Manager statt einmal
  pro Manager. Anzupassen: Das `WinNew`-Deferral (`vim.schedule`) existiert,
  weil das neue Fenster noch nicht current ist; und der Key muss `(win, root)`
  sein statt nur `win`, weil ein Tree-Fenster für verschiedene Roots
  wiederverwendet wird.
- **Projekt-relative Pfad-Keys, cross-platform** (`util/path.lua`:
  `is_windows()` :21, `slashes()` :35, `root()` :45, `buffer_key()` :62):
  Forward-Slash-Normalisierung, Abschneiden des Projekt-Root-Präfixes,
  case-insensitiver Vergleich unter Windows, und definierte Antworten für
  Dateien außerhalb des Projekts sowie Buffer ohne Datei. Das Original nennt
  das „die Bug-Fabrik jedes Filetree-Plugins, das Zustand persistiert":
  `C:\Repos\x` und `c:\repos\x` sind dasselbe Verzeichnis und ergeben zwei
  verschiedene Keys, und ein Key mit eingebettetem absolutem Pfad bricht in dem
  Moment, in dem der Checkout umzieht. Rund 25 Zeilen für beides. Zu ergänzen:
  ein `dir_key()`-Geschwister (ein Baum persistiert *Verzeichnisse*, und ein
  Trailing-Slash-Mismatch spaltet den Key genauso wie ein Case-Mismatch) sowie
  ein herausgelöster „liegt dieser Pfad unter jenem Root"-Test, den ein Baum
  ohnehin fürs Filtern braucht.
- **Zwei-Achsen-Override-Modell** — globaler Default plus Ausnahme pro Pfad,
  aufgelöst von einer Funktion, wobei der Override unabhängig von der Sache
  persistiert wird, die er steuert (`persist.lua`: `persists()` :74,
  `has_override()` :84, `set_exception()` :192, und die Entscheidung „die
  Ausnahmeliste immer persistieren" :113). Gemünzt auf „follow current file",
  „show hidden", „show gitignored", „auto-expand" — jeweils global mit Ausnahme
  pro Verzeichnis (`node_modules` in einem Projekt sichtbar, sonst nirgends).
  Der leicht falsch zu bauende Teil ist die Drei-Zustands-Auflösung
  `on`/`off`/`default`, bei der `default` den Override *löscht*, statt ihn auf
  den aktuellen Wert des Defaults zu setzen. Für einen Baum zusätzlich:
  Vererbung nach unten (eine Ausnahme auf `a/` gilt für `a/b/`), also
  Longest-Prefix- statt Exact-Key-Lookup.
- **Chooser-Zeilen mit Farb-Chip pro Zeile** (`ui/list.lua`: `row()` :34 baut
  die Form `{ value, lines, highlights }` für `lib.nvim.ui.kit.select`,
  `open()` :55), samt der bewussten Entscheidung, `respect_override` *nicht* zu
  setzen: Ein fremdes `vim.ui.select`-Backend kann keine Per-Span-Farben
  rendern. Die übertragbare Einsicht: das Picker-Backend des Nutzers
  respektieren bei einfachen Listen, den kit-Chooser behalten, wenn die Farben
  *die* Information sind. Relevant für Root-Switcher, Bookmark-Liste,
  Git-Status-Liste, „zuletzt benutzte Verzeichnisse".
- **Config-Validierung, die degradiert statt zu werfen** (`config/init.lua`:
  `M.issues` :24, `normalize_palette()` :63, `normalize_cursor_patterns()` :95,
  `normalize_numbers()` :116; berichtet über `health.lua`). Ungültige Werte
  fallen auf den Default zurück, sammeln eine menschenlesbare Begründung und
  erscheinen in `:checkhealth` — eine kaputte Zeile verhindert nie das Laden.
  Für eine Filetree-Config noch wertvoller als hier, weil sie größer ist
  (Sektionen pro Manager, Icon-Tabellen, Keymap-Tabellen) und ein Tippfehler in
  einer verschachtelten Tabelle wahrscheinlicher. Besonders
  `pcall(string.find, "", p)` zur Validierung nutzergelieferter Lua-Patterns:
  Ein ungültiges Filter-Pattern würde sonst mitten im Verzeichnis-Scan werfen,
  weit weg von der verursachenden Config-Zeile.

Explizit **nicht** übertragbar, damit es später niemand doch versucht:

- Die Entscheidung `matchadd()` statt Extmarks. Sie ist in spotlight richtig,
  weil die Hervorhebung musterförmig und die Datei groß ist. Die Dekorationen
  eines Filetrees sind positionsförmig und sein Buffer ist winzig — dort sind
  Extmarks richtig, und die Begründung mitzukopieren wäre eine Pessimierung.
- Der Token-Resolver (`cursor.lua`) — reine Log-Zeilen-Inhaltslogik.
- On-demand-Counting (`core/count.lua`) — der Size-Guard, dessentwegen es
  existiert, gilt für einen Tree-Buffer nicht.
- Die Palette (`core/palette.lua`) — acht gegeneinander unterscheidbare
  Hintergrundfarben sind eine Markierungspalette; ein Filetree will semantische,
  an das Colorscheme gebundene Farben (Git-Status, Dateityp), also das
  Gegenteil. Die `ColorScheme`/`OptionSet background`-Reapply-*Mechanik* ist
  dagegen übernehmenswert, die Farben nicht.

---

### 3.7 `pdfport.nvim` — Integrationspunkt und Konventionen

Kein Filetree-Plugin, daher Muster statt Port-Targets:

- **Idempotenter FileType-plus-augroup-Helper**
  `M.on_filetype(pattern, augroup_name, callback)`
  (`bindings/autocmds.lua:15-21`): legt eine benannte Gruppe mit `clear = true`
  an und bindet einen Callback; ein erneutes `setup()` räumt und erzeugt neu,
  statt Autocmds und Keymaps zu akkumulieren. Direkt anwendbar, weil
  filetree.nvim rund 40 per-Feature-`FileType`-Autocmds hat und einen zentralen
  Dispatcher genau deshalb aufgeschoben hat. pdfport hat die minimale Version
  davon bereits gebaut — als Fix für einen realen Bug: nvim-tree registrierte
  seine Autocmd ohne augroup und duplizierte bei wiederholtem `setup()` still
  die Keymaps. Vor einem Eigenbau anschauen.
- which-key-Registrierung vollständig unter `pcall(require, "which-key")`, Spec
  nur für tatsächlich aktive Keymaps aufbauen, dann ein einziges
  `pcall(wk.add, spec)` (`bindings/keymaps.lua:47-58`). Dritte unabhängige
  Implementierung derselben Form — Bestätigung, dass das Muster trägt, keine
  neue Erkenntnis.
- **`false`-deaktiviert-Konvention**: Jede Keymap-Aktion läuft über
  `M.resolve(opts)` (`bindings/keymaps.lua:35-43`), wobei explizites `false` die
  Bindung unterdrückt und `nil` auf den Default zurückfällt — einmal beim Setup
  geprüft statt verstreuter `if opts.x ~= false`-Checks. Offener Punkt:
  github_stats verwendet stattdessen den leeren String als Sentinel. Falls die
  Keymap-Auflösung je über die Plugins hinweg vereinheitlicht wird, ist eine der
  beiden Konventionen zu wählen.
- **Cross-platform Interpreter-Auflösung** (`platform/init.lua:62-84`):
  `M.python()` probiert `python3`, dann `python`, dann `py` und cached den
  ersten Treffer; `has_python_module()` ruft
  `vim.fn.system({python, "-c", "import "..module})` in Tabellenform, ohne
  Shell-String, und liest `vim.v.shell_error`. Ersetzte einen Bug, bei dem
  `os.execute("python3 -c '...' 2>/dev/null")` unter `cmd.exe` brach
  (Single-Quotes, `/dev/null`). Gleiche Form wie github_stats' `command_exists`.
  Prinzip: „den funktionierenden Kommandonamen auflösen und cachen, nie einen
  Shell-String mit OS-spezifischem Quoting bauen" — gilt für alles, was
  filetree.nvim aufruft (Trash, Git, externe Opener).
- **Der konkrete Integrationspunkt**, kein bloßes Pattern: `util/picker.lua`
  besitzt als einziges Modul die Tabelle der Öffnungsmodi und den
  `hover_select`-oder-`vim.ui.select`-Fallback; alle vier Tree-Adapter
  (neo-tree, nvim-tree, netrw, oil) rufen dasselbe `pick_and_open(path)` auf,
  statt je eine eigene Kopie zu tragen (vier nahezu identische Kopien wurden zu
  einer dedupliziert). Wenn filetree.nvims Preview einen PDF-Node dispatcht,
  soll sie `require("pdfport").open({ path = ..., mode = ... })` oder
  `.extract({ path = ..., __callback = ... })` aufrufen — beides stabile, in
  `doc/pdfport.txt` §6 dokumentierte öffentliche Einstiegspunkte — statt einen
  eigenen Modus-Picker gegen pdfport-Interna zu bauen.
- `config/DEFAULTS.lua` gibt eine **Funktion** zurück
  (`return function() return {...} end`), die von `config/init.lua`
  (`M.setup()`/`M.get()`, :14-19) jedes Mal frisch aufgerufen wird, sodass
  niemand eine mutable Default-Tabelle per Referenz teilt. Klein, aber leicht
  falsch zu machen: Eine schlichte `M.DEFAULTS = {...}`-Tabelle kann von einem
  `vim.tbl_deep_extend("force", M.DEFAULTS, opts)` in-place mutiert werden, wenn
  der Aufruf je direkt auf sie zielt statt auf eine Kopie. Die
  Konstruktor-Funktion umgeht die ganze Fehlerklasse.

Nicht anwendbar: pdfports domänenspezifische Module
(PDF-Extraktions-Backends, Text-/Markdown-Rendering, Claude- und
Ollama-API-Clients).

**Source-Bewertung:** Nein. PDFs sind Dateien im normalen Filesystem-Baum; eine
eigene Source dafür wäre ein Filter, kein Baum.

---

### 3.8 `open.nvim` — vollständig abgelöst

Der Audit stellt den Ertrag gleich zu Beginn als gering fest. Die
Tree-Buffer-Logik in `lua/open/context.lua` existiert nur, um für genau drei
Backends eine einzige enge Frage zu beantworten: „welcher Pfad steht gerade
unter dem Cursor, für `:Open`". filetree.nvims formales
`FiletreeAdapter`-Interface beantwortet für fünf Backends einen deutlich
reicheren Fragenkatalog (aktueller Node, sichtbare Nodes, expand/collapse,
Highlight, Reveal). Alle vier Techniken sind dort allgemeiner abgedeckt:

- Dispatch nach `filetype` (neo-tree / NvimTree / netrw) → das
  `filetypes`-Feld jedes Adapters, das zusätzlich oil.nvim und mini.files
  abdeckt.
- Neo-tree-Node-Auflösung mit Fallback auf `state.tree:get_node()` →
  `adapter/neotree.lua` `node_path`, über `lib.nvim.neotree.node` mit lokalem
  Fallback. Dieselbe Fallback-*Form* wurde auf beiden Seiten unabhängig
  gefunden, was das Muster bestätigt.
- nvim-tree über `api.tree.get_node_under_cursor()` → die Adapter-Variante
  erfasst zusätzlich Typ, Tiefe und Expanded-State.
- netrw-Pfadauflösung (`netrw_curdir` plus aktuelle Zeile, per
  String-Konkatenation) → filetree.nvims `parse_netrw_line` plus
  `get_current_node` ist strikt korrekter.
- Die `PATH_TARGETS`-Scope-Heuristik (will dieser Handler-Key einen validierten
  Pfad oder cword/Visual-Text?) ist ein anderes Paradigma und nicht portierbar.

**Keine Lücken gefunden.** Ein Nebenbefund, der open.nvim selbst betrifft und im
Original bewusst *nicht* als Action Item geführt wurde, weil praktisch folgenlos:
`resolve_netrw_path()` (`context.lua:115`) überspringt netrws Banner- und
Header-Zeilen nicht (die `"..`-Kommentarzeile, die `--..`-Sortier- und
Filtermarker), anders als filetree.nvims `parse_netrw_line`. Da der Cursor beim
`:Open`-Aufruf selten auf der Bannerzeile steht, ist die Auswirkung gering.
**Damit dieser Befund mit dem Löschen der Datei nicht verlorengeht, steht er
hier.**

---

### 3.9 `migrate.nvim` — Nullergebnis, abgeschlossen

Code-Migrations-Plugin (deprecated Option-API, `vim.notify`). **Keinerlei**
Filetree-Integration, per Vollsuche über `lua/`, `doc/` und `docs/` verifiziert
(`grep -riE "neotree|nvim-tree|nvimtree|netrw|filetree"` ohne Treffer). Die
einzige Dateisystem-Interaktion ist das Lesen und Schreiben der migrierten
Dateien selbst sowie das Auflisten von `*.lua` unter cwd (per `globpath` oder
`rg --vimgrep`). Nichts davon rendert einen Baum, inspiziert einen
Explorer-Buffer oder überschneidet sich mit dem Funktionsumfang eines
Filetree-Managers. Der Audit war bereits im Original als abgeschlossen
markiert.

---

## 4. Bewertung: Sinnhaftigkeit, Nutzwert und Aufwand der Gesamtübung

**Was die Übung geleistet hat.** Sie hat zwei zuvor vermischte Fragen sauber
getrennt beantwortet. Erstens: *Welche Features fehlen filetree.nvim?* Antwort:
sehr wenige — drei konkrete Lücken aus Pass 3, und die zwei größten Kandidaten
aus Pass 1 sind seither geliefert. Zweitens: *Wer taugt als Source?* Antwort:
von den neun niemand. Beides sind belastbare Negativergebnisse, und ein
Negativergebnis, das das Bauen einer falschen Sache verhindert, ist hier mehr
wert als eine weitere Feature-Liste.

**Wo der Aufwand nicht rentiert hat.** `migrate.nvim` und `open.nvim` haben je
ein Dokument gekostet und nichts erbracht — vorhersehbar, weil beide keine
baumförmigen Daten besitzen. Vier der neun Dokumente (`pdfport`, `open`,
`migrate`, teilweise `cmdlog`) sind im Kern Konventions-Quervergleiche zwischen
Plugins desselben Autors und bestätigen überwiegend bereits getroffene
Entscheidungen. Das ist nicht wertlos — ein dreifach unabhängig erreichtes
Muster ist ein starkes Signal —, beantwortet aber nicht die gestellte Frage.
Ein Filter vorab („hat das Plugin überhaupt hierarchische Daten?") hätte etwa
die Hälfte der Arbeit eingespart.

**Konkrete Empfehlung, nach Aufwand/Nutzen sortiert:**

| Prio | Maßnahme | Aufwand | Nutzwert |
|---|---|---|---|
| 1 | **Sibling-Navigation** in `nav/tree_traverse` | S | hoch — echte, billige Lücke |
| 2 | **Collapse all** und **Sort-Cycling** als Adapter-Methoden, letzteres mit dem Identity-Restore-Pattern aus Pass 2 | S–M | hoch |
| 3 | **Buffers-/Tab-Liste** — die Leitfrage selbst, siehe Abschnitt 6 | M | mittel-hoch |
| 4 | Spotlights **Pfad-Key-Modul** (`buffer_key` plus `dir_key`) übernehmen, **bevor** irgendetwas Zustand persistiert | S | hoch — verhindert eine ganze Bugklasse |
| 5 | Spotlights **Window-State-Ledger** für Tree-Fenster, Key `(win, root)` | M | mittel-hoch |
| 6 | insights: **Export tree** und **Compress** als Node-Aktionen | S–M | mittel |
| 7 | Atomisches Schreiben (`.tmp` plus `fs_rename`) überall dort, wo persistiert wird | S | mittel |
| 8 | cmdlog **Favorites/Recent dirs** — aber als `:Pickers`-Scope, nicht als Source | M | mittel |
| — | **Nicht bauen:** Spotlight-Source, PDF-Source, insights-`symbols`-Source, Neotest-Source (dormant) | — | — |

---

## 5. Die übrigen 23 Plugins — Source-Eignung im Schnelldurchlauf

Diese Plugins hatten **keine** `NEOTREE_FEATURES.md`. Die Bewertung erfolgt
anhand von README und Plugin-Zweck gegen K1 bis K5 — also **eine Einschätzung,
kein Audit**.

| Plugin | Baumförmige Daten? | Source-Eignung | Nutzwert | Aufwand | Begründung |
|---|---|---|---|---|---|
| `sessions.nvim` | ja (Projekt → Branch → Session) | **ja, bester Kandidat** | hoch | M | Echte Zweistufigkeit, stabile IDs, moderate Anzahl, sinnvolle Aktionen (restore, delete, rename). Man will die Liste beim Projektwechsel sehen, nicht nur abfragen. |
| `sandbox.nvim` | ja (Sandbox → Dateien) | **ja** | mittel-hoch | M | Sandboxen sind Container mit Inhalt, also genuin baumförmig. Dauerhafte Sichtbarkeit plausibel. Hängt bereits an lib.nvim. |
| `documentation.nvim` | ja (Doku-Hierarchie) | **ja** | mittel-hoch | M–L | Ein Doku-Baum neben dem Code-Baum ist ein klassisches Source-Muster. Aufwand hängt daran, wie stabil die Doku-Struktur modelliert ist. |
| `reposcope.nvim` | teils (Owner → Repo) | Grenzfall | mittel | M | Zweistufig, aber ausgesprochen picker-artig genutzt: suchen, springen, fertig. K3 wackelt. Erst als `:Pickers`-Scope. |
| `dap.nvim` | ja (Stack → Frames → Scopes) | Grenzfall | mittel | L | Baumförmig, aber `nvim-dap-ui` besetzt das Feld vollständig. Doppelarbeit. |
| `debugging.nvim` | teils | Grenzfall | mittel | M | Nur sinnvoll, wenn es Breakpoints und Sessions als eigene Hierarchie hält. |
| `markdown.nvim` | ja (TOC-/Heading-Hierarchie) | Grenzfall | mittel | M | Echter Baum, kollidiert aber mit Neo-trees `document_symbols` und mit `lsp.outline`. Nur bauen, falls Markdown dort schlecht abgedeckt ist. |
| `lsp.nvim` | ja | nein (redundant) | — | — | `document_symbols` und `diagnostics` sind bereits Neo-tree-Sources. |
| `github_stats.nvim` | nein (flach, metrisch) | nein | — | — | Zahlen pro Repo: ein Dashboard, kein Baum. Sein Wert lag als Pattern-Quelle vor (siehe 3.1, Pass 2). |
| `fileops.nvim` | nein (Aktionen) | nein | mittel | S | Node-Aktionen auf dem Filesystem-Baum, keine eigene Item-Menge. Gehört unter `fileops.*`. |
| `gopath.nvim` | nein (Sprungziele) | nein | — | — | Das Ergebnis ist ein Sprung, kein persistenter Baum. |
| `buffer-ctx.nvim` | nein (Referenz-String) | nein | gering | S | Erzeugt `require(...)`- und `path:line`-Referenzen; überlappt `paths.lua_require_copy`. Höchstens Node-Aktion. |
| `diff.nvim` | nein (Paarvergleich) | nein | mittel | S | Deckt sich mit `compare.diff` auf zwei markierten Nodes. |
| `replacer.nvim` | nein | nein | gering | S | `:Replace` auf einem Node oder Subtree wäre eine Aktion. |
| `recommender.nvim` | nein (Vorschlagsliste) | nein | — | — | Buffer-Analyse, flach, einmalig abgefragt. |
| `cascade.nvim` | nein (Listen im Buffer) | nein | — | — | Arbeitet im Buffer-Inhalt, nicht auf Dateien. |
| `emojis.nvim` | nein | nein | — | — | Glyph-Auswahl, reiner Picker-Fall. |
| `color_my_ascii.nvim` | nein | nein | — | — | Rendering im Buffer. |
| `images.nvim` | nein | nein | mittel | S | Bild-Preview für einen Node ist eine **Preview-Aktion** — passt zur geplanten granularen Preview-Konfiguration, analog zu pdfport. |
| `mdview.nvim` | nein | nein | gering | S | Live-Mirror eines Buffers; als Preview-Backend denkbar, sonst nichts. |
| `language.nvim` | nein | nein | — | — | Sprach- und Toolchain-Konfiguration. |
| `runtime-analysis.nvim` | teils (Call-/Kostenbaum) | nein | gering | L | Baumförmig, aber ohne Dateikontext; ein eigener Report-Buffer ist passender. |
| `insights.nvim` | siehe 3.4 | nein | mittel-hoch | S–M | Aktionen statt Source. |

---

## 6. Antwort auf die Leitfrage

**Als Neo-tree-Source lohnt sich von den auditierten neun Plugins keines.** Der
Grund ist fast überall derselbe und lässt sich auf einen Satz verkürzen: *Sie
besitzen Listen, keine Bäume — und Listen gehören in `pickers.nvim`.* Die
einzigen drei Plugins mit echter Hierarchie (`sessions.nvim`, `sandbox.nvim`,
`documentation.nvim`) wurden nie auditiert, weil sie nie eine
`NEOTREE_FEATURES.md` bekommen haben. **Wenn die Source-Frage weiterverfolgt
wird, dann dort — nicht bei den neun.**

Der genannte Vergleich („wie Tabliste im Filebrowser") hat trotzdem einen
konkreten Anknüpfungspunkt, und zwar den einzigen, der aus den Dokumenten selbst
kommt: **Lücke 3 aus 3.1** — Neo-trees `buffers`-Source mit `dd` = buffer_delete,
für die filetree.nvim bislang kein Konzept hat. Das ist wörtlich die Tabliste.
Vor dem Bau sind zwei Dinge zu klären:

1. **Adapter-Reichweite.** Eine Buffers-Source ist Neo-tree-API und damit
   Lock-in. Ist das akzeptabel, oder soll es eine adapter-agnostische
   Buffer-Liste in `nav/` werden, die Neo-tree lediglich *auch* rendert?
2. **Abgrenzung zu `:Pickers`.** Eine Buffer-Liste erfüllt K3 tatsächlich — man
   will offene Buffer dauerhaft sehen. Sie ist damit der einzige Fall in diesem
   ganzen Report, in dem der Baum dem Picker überlegen ist. Genau deshalb ist
   sie auch die einzige Source, deren Bau sich lohnt.

### 6.1 Die andere Hälfte der Frage: Sources nicht *bauen*, sondern *schalten*

Aufgenommen aus `filetree.nvim/docs/ROADMAP/IDEAS/Neotree_Sources.md`
(2026-08-29 hierher integriert und dort gelöscht). Der Punkt gehört inhaltlich
hierher, weil er dieselbe Frage von der anderen Seite stellt: nicht „welches
Plugin wird eine Source", sondern „was macht filetree.nvim mit den Sources, die
Neo-tree ohnehin hat".

**Ursprünglicher Wunsch:** Neo-trees `sources`-Feature nachbauen — eine lazy
Source-Registry, drei Icon-Familien (nerd / codicons / common), responsive
Sizing. Eingestuft als Phase 4, niedrige Priorität.

**Befund aus der Verifikation:** `lua/config/neotree/sources/registry.lua` ist
derzeit ein simpler Lazy-Loader (`register` / `load` / `is_loaded` / `list`),
kein Template-System. Der Wunsch existiert im Code also noch gar nicht.

**Empfehlung statt Template-Engine:** eine kleine Sammlung von Rezepten
beziehungsweise Copy-Paste-Konfigurationen (zwei bis drei gängige
Source-Setups) im README oder unter `docs/`. Das trifft den tatsächlichen
Schmerzpunkt („das Aufsetzen war mühsam") deutlich billiger als ein neues
System.

**Der eigentlich wertvolle Punkt** stand im Original als Nachsatz und ist die
beste Idee im ganzen Dokument: Wer filetree.nvim mit Neo-tree als Engine
benutzt, sollte die Sources schlicht **aus der filetree.nvim-User-Config heraus
ein- und ausschalten** können (deklarativ in der Spec). Das passt exakt zum
Ergebnis dieses Reports: Der Ertrag liegt nicht darin, eigene Sources zu
schreiben — von den auditierten neun taugt keine —, sondern darin, die bereits
vorhandenen Neo-tree-Sources (`filesystem`, `buffers`, `git_status`,
`document_symbols`) über die einheitliche, adapter-agnostische Config
erreichbar zu machen. Aufwand S–M, Nutzwert hoch, und es erzeugt keinen
zusätzlichen Neo-tree-Lock-in, weil es nur konfiguriert, was der Adapter
ohnehin kann. Zusammen mit der Buffers-/Tabliste aus Abschnitt 6 ist das die
vollständige Antwort auf die Leitfrage.

---

## Anhang — Verbleib der Originale

| Repo | Datei | Zeilen | Status |
|---|---|---|---|
| `cmdlog.nvim` | `docs/ROADMAP/NEOTREE_FEATURES.md` | 77 | gelöscht, Inhalt in 3.5 |
| `filetree.nvim` | `docs/ROADMAP/NEOTREE_FEATURES.md` | 253 | gelöscht, Inhalt in 3.1 |
| `insights.nvim` | `docs/ROADMAP/NEOTREE_FEATURES.md` | 21 | gelöscht, Inhalt in 3.4 |
| `lib.nvim` | `docs/ROADMAP/NEOTREE_FEATURES.md` | 104 | gelöscht, Inhalt in 3.2 |
| `migrate.nvim` | `docs/ROADMAP/NEOTREE_FEATURES.md` | 31 | gelöscht, Inhalt in 3.9 |
| `open.nvim` | `docs/ROADMAP/NEOTREE_FEATURES.md` | 46 | gelöscht, Inhalt in 3.8 |
| `pdfport.nvim` | `docs/ROADMAP/NEOTREE_FEATURES.md` | 26 | gelöscht, Inhalt in 3.7 |
| `pickers.nvim` | `docs/ROADMAP/NEOTREE_FEATURES.md` | 132 | gelöscht, Inhalt in 3.3 |
| `spotlight.nvim` | `docs/ROADMAP/NEOTREE_FEATURES.md` | 116 | gelöscht, Inhalt in 3.6 |
| `filetree.nvim` | `docs/ROADMAP/IDEAS/Neotree_Sources.md` | 7 | gelöscht 2026-08-29, Inhalt in 6.1 |

Die Originale bleiben über die Git-History der jeweiligen Repos erreichbar —
Commit unmittelbar vor dem jeweiligen Löschcommit.

Verweise auf die entfernten Dateien wurden am 2026-08-29 aus den Repos
`filetree`, `insights`, `markdown`, `migrate`, `open`, `pdfport` und `pickers`
entfernt, ebenso der zugehörige Migrationsblock in
`WKDBooks/Development/wkdbook-Lua/Checklists/gates/RELEASE.md`, dessen Aufgabe
mit diesem Report erledigt ist.
