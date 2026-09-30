# „Aufwischen" 2026-09-30 — Analyse & Implementierungsplan

Quelle: Notizen vom Arbeitstag (nvim-Config + 6 Plugin-Repos). Stand der Analyse:
alle 6 Plugin-Repos (markdown, ui, images, pickers, debugging, cascade) sind
`main`, sauber, in sync mit origin. Zusätzlich gelesen (Abhängigkeiten, nicht
im Chat freigegeben, aber unter `$REPOS_DIR`): lib.nvim, gopath.nvim,
filetree.nvim, buffer-ctx.nvim, casedesk.nvim, WKDBooks.

Legende Aufwand: S = <1 h, M = 1–3 h, L = halber Tag+.

---

## Überblick

| # | Task | Repos | Aufwand | Risiko |
|---|------|-------|---------|--------|
| T1 | Blockquote-Hintergrund nur so breit wie die breiteste Zeile | markdown.nvim (+ nvim-Spec) | M | niedrig |
| T2 | `./` vor `$ENV`-Variablen in Link-Sanitize verhindern (+ Reparatur) | markdown.nvim | S | niedrig |
| T3 | `:Clipboard reports` / `:Clipboard handovers` | nvim-config | S | niedrig |
| T4 | Notify-Chip breiter (40 % / konfigurierbar) | lib.nvim + ui.nvim (Drift-Guard!) + nvim-Spec | M | mittel (2 Kopien) |
| T5 | Cursor in den Link-Titel nach Link-Einfügen + `:Image paste env` | lib.nvim (Helper), images, markdown, filetree, buffer-ctx, pickers, gopath | L | mittel |
| T6 | Picker-Feedback für `[e` & Co. | pickers.nvim | M | mittel (3 Engines) |
| T7 | Message-Popup (noice-Ersatz-Keim) | **nur Roadmap-Abgleich + Plan, nicht bauen** (lib.nvim/debugging.nvim/ui.nvim) | Plan: S, Bau: L | hoch |
| T8 | cascade weicht aus (`cf`/`cF` kollidieren mit casedesk) | cascade.nvim (+ Docs, Spec) | S | niedrig |

Reihenfolge (jede Runde max. 1 Agent, Repo für Repo, nach jedem Repo: luacheck/
stylua + Tests + Docs + commit/push auf `main`):

1. **Runde 1 (klein, unabhängig):** T2 → T1 → T3
2. **Runde 2:** T4 (toast width) — Voraussetzung für T7-Optik
3. **Runde 3:** T5 (Helper in lib.nvim zuerst, dann die Konsumenten)
4. **Runde 4:** T6
5. **Runde 5:** T7 nicht bauen (Plan + Roadmap-Abgleich liegen vor)
6. Report „Markdown-Link-Einfügestellen" (Anhang A unten) wird in Runde 3 als eigener Report abgelegt.

---

## T1 — Blockquote-Hintergrund nur so breit wie die breiteste Zeile

**Befund.** [`blockquote.lua`](E:/repos/markdown.nvim/lua/markdown/hl_options/hl_groups/blockquote.lua)
setzt pro Zeile zwei Extmarks; der Text-Extmark nutzt `hl_eol = true`
(Zeile 127), daher der Hintergrund bis zum Fensterrand (Screenshot). Das Ganze
läuft über einen Decoration-Provider (`on_line`), also pro sichtbarer Zeile pro Redraw.

**Design.**
- Neue Option `blockquote_hl.width = "block" | "line" | "window" | <integer>`:
  - `"block"` (**neuer Default**): Breite = breiteste Zeile des zusammenhängenden
    Blockquote-Blocks (Display-Breite, `strdisplaywidth`, Marker mit eingerechnet).
  - `"line"`: bis Zeilenende des eigenen Texts (kein Padding).
  - `"window"`: bisheriges Verhalten (`hl_eol`).
  - Zahl: feste Spaltenbreite.
- Umsetzung: `hl_eol` weg; Text-Extmark nur über die echten Zeichen; Padding als
  `virt_text` (`virt_text_pos = "eol"`, `hl_mode = "combine"`) aus `(width - line_width)`
  Leerzeichen in `MarkdownBlockquoteText`. Nicht bei `wrap`-Zeilen, die schon
  breiter als `width` sind (Padding = 0).
- **Performance** (PERFORMANCE.md beachten): Block-Breiten nicht pro `on_line`
  neu berechnen. Cache pro Buffer, invalidiert über `changedtick`; beim ersten
  `on_line` eines Redraws werden alle Blöcke des Buffers einmal gescannt
  (oder nur das Sichtfenster ± Blockränder — Entscheidung im Spike anhand des
  Benchmarks auf einer 5k-Zeilen-Datei).
- Block-Erkennung: Zeilen, die `PAT_MARKER` matchen, aufeinanderfolgend.
  Leerzeile trennt Blöcke (wie im Screenshot: zwei getrennte Zitate).
  Verschachtelte `> >` zählt zum selben Block.
- Fenster-Breite/`conceal`/Tabs: `strdisplaywidth` statt `#line`.

**User-Konfiguration.** In `DEFAULTS.lua` + `@types` + `docs/configuration.md`
+ kommentierter Eintrag in `lua/plugins/personal/specs/edit.lua` (dort ist
`blockquote_hl` schon ab Zeile ~900 dokumentiert).

**Tests** (`TESTS/`): Breite bei 3 Zeilen unterschiedlicher Länge, getrennte Blöcke,
Umlaute/Breitzeichen, Moduswechsel `"line"/"window"/Zahl`, Entfernen des `>` löscht
Padding, Cache-Invalidierung bei Edit.

---

## T2 — `./` vor `$ENV`-Variablen

**Befund (Root-Cause).** [`link_sanitize.lua`](E:/repos/markdown.nvim/lua/markdown/core/link_sanitize.lua)
`sanitize_target` stellt jedem relativen Ziel `./` voran. `is_untouchable`
kennt `#`, `~`, URL-Schema/Laufwerk — **nicht** `$VAR`, `${VAR}`, `%VAR%`.
Darum wird `$REPOS_DIR/WKDBook-…` beim Speichern zu `./$REPOS_DIR/…` und
der Resolver ([`util/path.lua`](E:/repos/markdown.nvim/lua/markdown/util/path.lua)
`expand_path` expandiert Env-Variablen nur am Anfang sinnvoll) findet es nicht mehr.
Das ist auch die Ursache des `./$NVIM_CONFIG_DIR/…` in deinem Prompt.

**Fix.**
1. `is_untouchable`: Ziele, die mit `$NAME`, `${NAME}` oder `%NAME%` beginnen,
   bleiben unangetastet (nur Backslash→Slash-Normalisierung im Rest bleibt erlaubt).
2. **Reparatur-Pass** (Option `links.repair_env_prefix = true`, Default an): ein
   bereits kaputtes `./$VAR/…`, `../$VAR/…` wird beim Sanitize zu `$VAR/…`
   zurückgeschrieben — sonst bleiben alte Dateien (z. B. `300926.md`) kaputt.
   Nur wenn die Variable tatsächlich gesetzt ist **oder** in einer konfigurierten
   Liste steht (Schutz vor legitimen Ordnern, die `$x` heißen).
3. Gleiche Prüfung in `file_refs.lua`/`wrap_link.lua`, falls dort ebenfalls `./`
   erzeugt wird (beim Umsetzen mit `grep '"%./"'` gegenprüfen).

**Tests.** `$VAR/x`, `${VAR}/x`, `%VAR%\x`, `./$VAR/x` (Reparatur),
`./real/$x` (bleibt), Fence-Skip, URL-Fälle regressionsfrei.

---

## T3 — `:Clipboard reports` / `:Clipboard handovers`

**Befund.** Es gibt noch kein `Clipboard`-Usercmd in der Config
(`grep` in `lua/` ohne Treffer auf eine Command-Definition).
Usercmds liegen in `lua/bindings/usrcmds/` (`init.lua` registriert per
`lib.nvim.bindings.usercmd`; `:CopyLocation` dort ist das Vorbild), größere
Gruppen als Unterordner mit `enable()`.

**Design.**
- Neuer Ordner `lua/bindings/usrcmds/clipboard/` (nach dem Muster `context_open/`),
  `:Clipboard {reports|handovers}` via `composer.verb` (wie `:Gopath`), Completion
  auf die Schlüssel.
- Tabelle Schlüssel → Pfad: `reports = <stdpath config>/docs/ROADMAP/reports`,
  `handovers = <stdpath config>/docs/ROADMAP/handovers`. Erweiterbar per
  Config-Tabelle (eigene Einträge, `$ENV`-Expansion), damit künftig weitere
  Ziele (`notes`, `roadmap` …) ohne Codeänderung gehen.
- Kopiert in `+` und `"`; Pfad als `$NVIM_CONFIG_DIR/…` **oder** absolut?
  → Default: absoluter Pfad mit `/`-Slashes (direkt einfügbar in Shell/Explorer),
  Option `form = "absolute"|"env"`; Gopath-`to-nvim-dir`-Logik wäre die
  `env`-Variante.
- Feedback per Notify („copied: …"), Fehler wenn Verzeichnis fehlt.
- Doku: `docs/NOTES/PersonelPlugins/BINDINGS` bzw. Usrcmd-README ergänzen.
- Keymap: **keins anlegen** (bestätigt, Antwort 3).

---

## T4 — Notify-Chip breiter (40 % der Nvim-Breite, konfigurierbar)

**Befund.**
- Breite ist hartkodiert: `WIDTH = 40` in
  [`lib.nvim/…/ui/kit/toast.lua`](E:/repos/lib.nvim/lua/lib/nvim/ui/kit/toast.lua)
  und in [`ui.nvim/…/kit/toast.lua`](E:/repos/ui.nvim/lua/ui/kit/toast.lua)
  (zwei fast identische Kopien, `kit_drift_spec.lua` wacht darüber — jede
  Änderung in **beide**).
- Der Wrap-Breite-Parameter lebt getrennt in
  [`lib.nvim/…/notify/popup.lua`](E:/repos/lib.nvim/lua/lib/nvim/notify/popup.lua)
  (`config.width = 38`). Beide müssen zusammen wandern, sonst bricht der Text bei
  38 um, obwohl der Chip 80 breit ist.
- Deine Config aktiviert die Toasts über `lib.nvim.notify.setup({ popup = true })`
  in `specs/foundation.lua:72` (nicht ui.nvim/notify, das ist optional/alternativ).
  `ui.nvim/notify/init.lua` ruft ebenfalls `toast.open` und hat selbst kein `width`.

**Design.**
- `toast.setup({ width = <int>|"40%", min_width, max_width })` — Zahl = Spalten,
  String `"NN%"` = Prozent von `vim.o.columns` (beim Reflow/`VimResized` neu berechnet,
  daher Rechnung in `reflow()`, nicht einmalig).
- **Default 40 %** (wie vorgeschlagen), Clamp `min_width = 30`, `max_width = 120`,
  nie > `columns - 2*MARGIN`.
- **Entschieden (Antwort 1):** Breite = Inhalt + Padding, **nach unten begrenzt durch
  eine Mindestbreite, nach oben durch 40 %**. Die Mindestbreite ist der Default und
  entspricht ungefähr dem heutigen Chip (40 Spalten; ein 10-Zeichen-Text bleibt also
  ein „normal" großer Chip, nicht ein winziger Schnipsel). Beides vom User
  einstellbar: `width = "40%"` (Max) und `min_width = 40` (Zahl in Spalten; auch als
  `"NN%"` erlaubt). Konsequenz: bei schmalem Nvim (z. B. 100 Spalten → 40 %) fallen
  Min und Max zusammen; `min_width` wird immer auf `columns - 2*MARGIN` gekappt.
  Innen etwas Padding (`padding = 1` Spalte je Seite, in den Theme-Tokens schon
  vorhanden — `surface`/`theme` prüfen).
- **Wichtig (Roadmap-Abgleich):** `PLAN-ui-kit-migration.md` (Schritt 6) hat
  `ui.nvim` zur **maßgeblichen** Kopie des Kits gemacht; `lib.nvim`s Kopie ist
  „frozen: no new features". Der *aktive* Toast ist deshalb `ui.kit.toast` aus
  ui.nvim — `lib.nvim.notify.popup` ruft genau den auf (`pcall(require, "ui.kit.toast")`),
  nicht `lib.nvim.ui.kit.toast`. Die Änderung entsteht also **zuerst in ui.nvim**;
  `lib.nvim.ui.kit.toast` bekommt sie nur spiegelbildlich, damit `kit_drift_spec.lua`
  (Code darf nicht divergieren) grün bleibt.
- `popup.lua`: Wrap-Breite wird aus der Toast-Breite abgeleitet
  (`toast.inner_width()` = Breite − Rahmen − Padding); `config.width` bleibt als
  expliziter Override.
- Durchreichen: `lib.nvim.notify.popup.setup({ width = "40%" })` **und**
  `ui.nvim` `notify.width`; in `specs/foundation.lua` kommentierte Option + Wert.

**Tests.** `TESTS/` in beiden Repos: Prozent-/Zahl-Breite, Resize-Reflow,
Clamp, Drift-Spec bleibt grün, `popup` wrappt an Toast-Breite.

---

## T5 — Cursor in den Link-Titel + `:Image paste env|abs|rel`

### T5a — Gemeinsamer Helper (lib.nvim)

**Befund.** Fünf Stellen fügen Markdown-Links ein bzw. erzeugen sie (Anhang A).
Der Cursor landet überall hinter dem Link (`images`: `pos[2] + #link`).
Bei `filetree`/`pickers` werden Links **nur in Register kopiert**, nicht eingefügt.

**Design.**
- Neu `lib.nvim.markdown.link_cursor` (Ordner `lib.nvim/lua/lib/nvim/markdown/` existiert):
  - `first_title_range(text) -> { row, col_start, col_end }|nil` (reine Funktion;
    erster `[`…`]` des Texts, ignoriert `![`-Präfix, beachtet Fences nicht — Text ist
    Einzel-Einfügung).
  - `insert(buf, win, row, col, text, opts)` — `nvim_buf_set_text` + Cursor in den
    Titel des **ersten** Links; `opts.cursor = "title_start"|"title_end"|"after"`,
    `opts.startinsert = boolean`. Mehrzeilige Einfügung (mehrere Links) korrekt
    (Row-Offset + Byte-Col der ersten Titelstelle).
  - **Entschieden (Antwort 2) — Regel „dorthin, wo noch etwas fehlt", immer mit
    Insert-Modus:**
    - Titel **leer** (`![](assets/x.png)`, `[](url)`): Cursor zwischen `[` und `]`,
      Insert-Modus.
    - Titel **gefüllt** (`[name](path)`, z. B. filetree/pickers): Cursor in den
      **Pfad/URL-Bereich** in den Klammern `(…)`, Insert-Modus (Position: Ende des
      Pfads; `path_cursor = "end"|"start"|"select"` konfigurierbar).
    - Bei mehreren eingefügten Links gilt das für den **ersten** Link.
    - Unklar geblieben, bitte bestätigen: Dein Satz „aber Pfad/URL dann in den Titel-
      Bereich leeren und Insert-Modus" lese ich als *Fall 1* (Titel leer → dort
      hinein). Sollte stattdessen gemeint sein „Pfad/URL **löschen** und dann tippen",
      sag Bescheid (dann `path_cursor = "clear"`).
- Konfig global in lib.nvim (`markdown.link_cursor = { title_filled = "path", startinsert = true, path_cursor = "end" }`),
  überschreibbar pro Konsument (images/markdown/filetree/pickers); `startinsert = false`
  schaltet nur den Modus ab, die Positionierung bleibt.

### T5b — images.nvim

**Befund.** [`paste.lua`](E:/repos/images.nvim/lua/images/paste.lua) kennt bereits
`path=relative|absolute|repos|<prefix>` (`resolve_link_path`, Z. 256ff),
Default `paste.default_path_mode = "relative"`. `insert_link` (Z. 372) setzt den
Cursor hinter den Link. **Wichtig:** in `images.nvim/.claude/worktrees/image-paste-performance-d063fc`
liegt ein offener Worktree mit Änderungen an `paste.lua` — vor Start prüfen, ob
gemerged/verworfen, sonst Konflikte.

**Design.**
1. `insert_link` → `link_cursor.insert(...)` (Titel = Alt-Text-Platz in `![](…)`).
2. Neuer Modus `env`:
   - **gopath.nvim (freigegeben, Antwort 4):** dort kommt eine kleine, öffentliche
     API-Funktion dazu — `env_shorten` kann heute nur Zeilen im aktuellen Buffer
     umschreiben, nicht einen einzelnen Pfad-String zurückgeben:
     `require("gopath.env_shorten").shorten_path(abs, opts) -> string|nil` =
     dieselbe Logik wie `:Gopath to-nvim-dir`/`to-repos-dir`, aber auf **einen**
     absoluten Pfad; `nil`, wenn er unter keinem konfigurierten Root liegt. Dazu
     gopath-Docs (README, `docs/`, `doc/`, `@types`) und ein Test; eigener Commit
     im gopath-Repo, **vor** dem images-Commit.
   - `env` = Pfad unter `$NVIM_CONFIG_DIR` → `$NVIM_CONFIG_DIR/…`; unter `$REPOS_DIR`
     → `$REPOS_DIR/…`; **sonst Fallback `relative`** (wie gewünscht: weder Repo,
     `$REPOS_DIR` noch `$NVIM_CONFIG_DIR`). Soft-Dependency (`pcall(require,"gopath.env_shorten")`);
     ohne gopath: eingebaute Mini-Variante mit derselben Root-Liste aus eigener Config.
   - **Eigene Env-Variablen:** `paste.env_roots = { NVIM_CONFIG_DIR = <fn|string>, REPOS_DIR = <string>, MY_VAR = "…" }`
     (Reihenfolge = Priorität, längster Root zuerst); Default spiegelt gopath
     (`shorten_dirs` + `shorten_known_dirs`), damit beide Plugins nie auseinanderlaufen.
     „In einem Repo" bedeutet: Pfad liegt unter einem konfigurierten Root — kein
     separater Git-Check nötig.
3. Modi-Namen: `env`, `abs`/`absolute`, `rel`/`relative`, `repos`, `<prefix>`.
   **Aufruf** `:Image paste [env|abs|rel] [name]` als *reservierte erste Wörter*
   plus bestehendes `path=…` (bleibt kanonisch, abwärtskompatibel). Konflikt:
   Datei, die „env" heißt → `name=env` explizit oder `path=` nutzen; im Completion
   die Modi zuerst anbieten.
4. **Default `env` in der persönlichen Installations-Spec**
   (`specs/view.lua:577` `default_path_mode = "env"`), Plugin-Default bleibt
   `"relative"` (fremde User haben die Variablen nicht gesetzt).
5. Keine Änderung am Ablageort der Datei (bleibt `assets/` neben dem Dokument).
6. **Zusammenspiel mit T2:** ein `env`-Link muss vom Sanitize-on-save unangetastet
   bleiben → T2 **vorher** fertigstellen (sonst bekommt `$NVIM_CONFIG_DIR/…` beim
   Speichern wieder ein `./`).

**Tests** (`TESTS/paste_target_spec.lua` erweitern): env unter NVIM_CONFIG_DIR,
unter REPOS_DIR, außerhalb → relative, eigene Variable, Windows-Slashes/Case,
Cursor-Position nach Insert (mit/ohne Alt-Text), Modus-Parsing inkl. Reserved-Word-Fall.

### T5c — Weitere Konsumenten

| Plugin | Stelle | Änderung |
|---|---|---|
| markdown.nvim | `core/wrap_link.lua` | setzt Cursor teils schon in Klammern (`col+1`) — auf gemeinsamen Helper umstellen, vereinheitlichen; `commands/markdown_links.lua:for_paths` nur String-Erzeugung (kein Cursor) |
| filetree.nvim | `features/paths/markdown_links/init.lua` | kopiert nur in `+`/`"`. **Neu:** Aktion „Link(s) in zuletzt aktives Fenster/Puffer einfügen" (Marks → mehrere Zeilen, Cursor im Titel des **ersten** Links). Bestehendes Kopieren bleibt. Neues Keymap/Usercmd, konfigurierbar |
| pickers.nvim | `entry_actions/path_copy.lua` (`markdown_link`) | wie filetree: zusätzliche Aktion „einfügen" im Ursprungsfenster (`opts.win` ist bereits vorhanden) |
| buffer-ctx.nvim | `ops/markdown_link.lua` | delegiert an `markdown.commands.markdown_links.for_paths`; Cursor-Behandlung im aufrufenden `commands.lua` prüfen |
| casedesk.nvim | `ui/insert.lua` | fügt Werte ein (Z. 136/154), kein Markdown-Link → nur prüfen, evtl. `ocr.lua` |

**Offen/Annahme:** Die „Einfügen"-Aktionen in filetree/pickers sind neu (heute nur
Clipboard). Falls du stattdessen nur das Einfügen per `p` meintest, geht Cursor-
Positionierung dort nicht ohne eigenes Paste-Kommando → deshalb als Aktion geplant.

---

## T6 — Picker-Feedback für `[e` & Co.

**Deine Frage: „Hat das nun geklappt oder nicht, was wurde gemacht?"** Genau das soll
die Meldung beantworten. Soll-Zustand: nach jedem `[e`/`[a`/`ML`/… erscheint **im Picker
selbst** eine kurze Zeile, z. B. `✓ env_rooted · 3 Zeilen · $REPOS_DIR/lib.nvim/…` bzw.
`✗ kein gültiger Pfad`.

**Befund (verifiziert vs. vermutet — bewusst getrennt).**
- *Verifiziert* (Headless-Lauf in deiner echten Config): `path_copy.run` legt bei Erfolg
  tatsächlich ein Toast-Fenster an (Float, `zindex = 50`, `focusable=false`) und schreibt
  in die Register. Der Code *versucht* also Feedback zu geben.
- *Verifiziert*: Deine Engine ist **snacks** (`specs/navigate.lua:548`).
- *Verifiziert*: `lib.nvim.notify` läuft bei dir im Popup-Modus (`specs/foundation.lua:72`);
  INFO landet dadurch **nur als Toast + in der Popup-History, nicht in `:messages`**.
  Das erklärt den Unterschied zu filetree: dessen `filetree.util.notify` geht über
  das normale `vim.notify` → `:messages`/more, darum siehst du dort etwas.
- *Vermutet, nicht bewiesen* (snacks-Picker per Headless nicht automatisierbar): der
  Toast hat `zindex = 50` — **derselbe** Wert wie die Picker-Fenster (snacks/telescope/
  fzf-lua) — und liegt oben rechts, also dort, wo der Picker-Layout-Float meist
  großflächig liegt. Er kann hinter/unter dem Picker verschwinden. (Die Theme-Tabelle
  kennt `zindex.toast = 70`, `surface.open` nutzt aber den `popup`-Wert 50 — mögliche
  Nebenbaustelle in `ui.kit.toast`.)
- Nebenfund: in meinem Testaufruf hieß das Format `env_rooted` (nicht `copy_env_rooted`);
  unbekannte Formate geben „Unknown path_copy format" — nur relevant, falls du
  eigene Keys auf Formatnamen mappst.

**Design (engine-unabhängig, eine Stelle statt drei).**
- `pickers.feedback.show(result, { engine, picker })`; Ergebnisobjekt von
  `path_copy.run` statt Bool: `{ ok, fmt, count, preview }`.
- Kanäle (`feedback = { "picker", "toast", "messages" }`, konfigurierbar, Default
  `{ "picker", "messages" }`):
  - `picker`: snacks → Picker-Titel/Footer kurz ersetzen (`picker.title`, Reset nach
    `feedback_ms = 1500`); telescope → Prompt-/Results-Titel; fzf-lua → Fenstertitel
    (`win:update_title`), Fallback Toast.
  - `messages`: schreibt zusätzlich in `:messages` (wie filetree — so gibt es auch
    nachträglich eine Spur, unabhängig vom Popup-Modus).
  - `toast`: wie heute, aber mit explizit höherem zindex (70), damit er über Pickern liegt.
- Gilt für **alle** Entry-Actions (copy_*, markdown_link, open_system, reveal, …).
- Reihenfolge: erst Repro in echter TUI (ein Durchlauf mit `zindex`-Test), dann bauen.

**Tests.** Adapter-Stubs: `feedback.show` je Engine mit korrektem Text; Timer-Reset;
Kanal-Auswahl; `feedback = false`.

---

## T7 — Message-Popup (noice-Ersatz-Keim) — Roadmap-Abgleich + Implementierungsplan

**Status laut Antwort 6: nur Roadmap-Review/-Abgleich und Plan, *nicht* bauen.**

### Machbarkeits-Befund (verifiziert, nvim 0.12.2 headless)

- `:messages` hat **keine Zeitstempel** → „letzte 10 Sekunden" braucht ein eigenes Log.
- `vim.ui_attach(ns, { ext_messages = true }, cb)` liefert jede Meldung in Echtzeit;
  **zwei Namespaces können gleichzeitig attachen, beide bekommen alle Events** (Test:
  beide sahen `echo`/`echomsg`). Ein Logger kann also *neben* noice laufen.
- **Falle:** sobald *irgendein* Listener `ext_messages` anfordert, zeichnet die TUI
  Meldungen nicht mehr selbst. Ein Logger ohne Renderer (noice weg) würde Meldungen
  verschlucken. → Logger darf nur attachen, wenn ein Renderer existiert (noice geladen
  **oder** eigener Chip-Renderer aktiv). Headless-Test sagt dazu nichts Belastbares
  aus → Spike in echter TUI nötig.
- debugging.nvim heute (`views/`): liest `:messages`/Noice-Fenster *nachträglich*
  (`capture`, `noice.message.manager`), hat `<lt>m/n/e`-Keymaps und `delay_*`-Timings.
  Kein eigenes Log, keine Zeitstempel, kein Level-Filter → **reicht für das Feature nicht**.
- `lib.nvim.notify.popup` hat Historie mit Zeit (`%H:%M:%S`), aber nur für
  `vim.notify`-Meldungen, nicht für echo/Fehler/`:write`-Meldungen.

### Roadmap-Abgleich (was es schon gibt / wo es andockt)

| Fundstelle | Inhalt | Bezug zu T7 |
|---|---|---|
| `nvim/docs/ROADMAP/00_ROADMAP.md` (Konkurrenzanalyse, Z. 97) | offener Punkt: *noice.nvim* auf Feature-Abdeckung prüfen, „nur dokumentieren, keine Ersatz-Entscheidung", Report nach `docs/ROADMAP/reports` | **Vorbedingung.** T7 beginnt mit genau diesem Report (Feature-Matrix noice ↔ eigene Plugins). Der Punkt gehört dem Nutzer (Datei ist im Haupt-Checkout gerade lokal modifiziert — nicht anfassen; beim Abschluss ggf. abhaken lassen) |
| `wkdbook-myplugins/debugging.nvim/ROADMAP/ROADMAP.md` | Kategorien `messages`/`noice`; „Nicht geplant: eigene Notify-/Buf-Win-Tab-Utilities — kommen aus lib.nvim" | **Passt**: Log-Modul gehört nach lib.nvim, debugging.nvim bekommt nur die Ansicht. Ein Eintrag „recent messages" fehlt dort |
| `wkdbook-myplugins/lib.nvim/Backlog/TASKS/notify-output-rollout-2026-09-25.md` (+ Report `nvim/docs/ROADMAP/reports/notify_output_rollout.md` für den offenen Teil P1–P3…) | Toast + History + `lib.nvim.output`-Kanalfassade | Schicht für *Live*-Ausgabe existiert; Message-Log ist die fehlende Quelle. Mit dem Rollout abstimmen (nicht doppelt bauen) |
| `wkdbook-myplugins/ui.nvim/PLAN-ui-kit-migration.md` | `ui.kit` jetzt in ui.nvim maßgeblich, lib-Kopie frozen | Jede neue UI (Popup/Chips) → **ui.nvim**; lib.nvim bekommt nur Nicht-UI (Log/Store) |
| `nvim/docs/ROADMAP/00_ROADMAP.md` Z. ~90: „`lib.nvim ui.kit`-Cheatsheet-Modul könnte hilfreich sein" | Cheatsheet-Hilfe | Das `?`-Cheatsheet des Popups ist der zweite Konsument → gemeinsames Modul lohnt jetzt (`ui.kit.viewer` hat schon Cheatsheet-Bausteine) |
| `lib.nvim/ROADMAP/MIDDLE-SMALL-FIXES.md` Z. 84 | „window-var-Tracking + Fokus/Scroll-Retry aus debugging.nvim nicht als Modul erkennbar; lohnt sich bei einem dritten Konsumenten" | Das Popup wäre ein dritter Konsument → Modul mit-extrahieren prüfen |

**Kein Widerspruch gefunden**, aber drei Stellen, die vor dem Bau zu entscheiden sind:
(a) noice-Report zuerst (Roadmap-Pflicht); (b) nicht parallel zu den offenen
notify-Rollout-Punkten bauen; (c) das Feature ist bisher **nirgends** in einer
Roadmap eingetragen — Einträge (debugging.nvim, lib.nvim, ui.nvim, gegenseitig
verlinkt) schlage ich nach deiner Freigabe vor, schreibe sie aber erst dann.

### Schichten

1. **lib.nvim `messages` (neu, klein, ohne UI):** `ui_attach`-Logger + Ringpuffer
   (Zeitstempel `hrtime`, `kind`→Level, mehrzeilig erhalten), `snapshot({ since_ms, kinds })`,
   Hook `on_message`. Attach-Policy siehe Falle oben.
2. **debugging.nvim `views/recent` (Popup-Ansicht)** — Usercmd + Keymaps `<lt>n/m/e`.
3. **ui.nvim: Live-Chips/Cmdline-Ersatz** — späterer, eigener Schritt; erst danach
   kann noice entfallen.

### Feature-Spezifikation

- Zeigt Meldungen der letzten `window_s` Sekunden (Default 10, konfigurierbar).
- `order = "newest_last"` (Default, wie `:messages`) | `"newest_first"`.
- **Mehr laden:** Pfeil-Icon (`󰁝`/`󰁅`) am unteren/oberen Rand (Virtual-Text), nur wenn
  es mehr gibt; Nachladen per `<C-j>`/`<C-k>` (Richtung des Pfeils), **nie** per
  gehaltenem `j`/`↓` → kein Fehltrigger. `j/k/↓/↑` scrollen nur.
- **Eingeklappt-Modus** (nur erste Zeile je Meldung): `<C-l>` aus-, `<C-h>` einklappen;
  Modus-Toggle im Fenster (z. B. `<C-e>`), Startwert in der Installations-Spec.
- Cheatsheet: Hinweis `? help` im Fensterrahmen, `?` öffnet, `q`/`<Esc>` schließt
  (bestehendes Muster aus `ui.kit.viewer`).
- **Ctrl statt Shift** (deine Frage): stimme zu. `<S-Up>/<S-Down>` = PageUp/Down und
  `<S-Left>/<S-Right>` = Wortsprung in Nvim (Kollision mit echtem Scrollen,
  terminalabhängig); `<C-h/j/k/l>` sind im Float-Buffer frei (buffer-lokal) und liegen
  an der Home-Row. Einzige Vorsicht: manche Terminals senden `<C-h>` als Backspace —
  unter Windows Terminal/WezTerm unterscheidbar; Alternative im Cheatsheet: `<A-h/l>`.

### Implementierungsplan T7 (Reihenfolge, wenn freigegeben)

| Schritt | Inhalt | Repo | Aufwand |
|---|---|---|---|
| 0 | Noice-Feature-Matrix-Report (Roadmap-Punkt), Zielbild festlegen | nvim-config `docs/ROADMAP/reports` | M |
| 1 | Spike in echter TUI: Attach-Policy, Koexistenz mit noice, Kosten des Ringpuffers, Verhalten bei `:redir`/`:silent` | Wegwerf + Report | M |
| 2 | Roadmap-Einträge (3 Repos) + Entscheidung über Modulschnitt | WKDBooks | S |
| 3 | `lib.nvim.messages` (Store, Tests, Docs) | lib.nvim | M |
| 4 | `debugging views/recent`: Fenster, Zeitfilter, Order, Pfeil + `<C-j/k>`, Tests | debugging.nvim | L |
| 5 | Eingeklappt-Modus + Toggle + `?`-Cheatsheet (ggf. gemeinsames Cheatsheet-Modul) | debugging.nvim (+ ui.nvim) | M |
| 6 | Personal-Spec (`specs/inspect.lua`) + Bindings-Doku | nvim-config | S |
| 7 | (später, separat entscheiden) Live-Chips/Cmdline in ui.nvim = Noice-Ersatz | ui.nvim | L+ |

---

## T8 — `<leader>cf` / `<leader>cg` (Antwort 3)

**Entschieden:** casedesk.nvim behält `<leader>cf` und `<leader>cg`; cascade.nvim
muss ausweichen. Zum Umfang, bitte **ein** Punkt bestätigen:

- Bestandsaufnahme cascade (Preset, `bindings/keymaps.lua`): `cf` = rotate_form_next,
  `cF` = rotate_form_prev, `cs` = sort, daneben `cx/ct/cT/cr/cv/cX/cp/cy/cY/cR`.
- **Zusätzliche Kollision, die du vermutlich noch nicht auf dem Schirm hattest:**
  casedesk belegt auch `<leader>cF` (Cases files) und `<leader>cG` (Cases livegrep) —
  cascades `cF` (rotate_form_prev) kollidiert damit ebenfalls.
- Dein Wunsch „cf → `<leader>cS`": `<leader>cS` ist in **deiner** Config bereits
  cascades `sort` (`specs/edit.lua:61`, weil `cs` vorher kollidierte). Ein direkter
  Umzug würde also wieder kollidieren, außer `sort` zieht ebenfalls um.
- Vorschlag (ein sauberer Block): cascade-Rotation → `<leader>cl` (next) / `<leader>cL`
  (prev) — „**l**ist form", beide frei (per Grep über alle Repos + Config: nirgends *gebunden*; nur als
  Beispiel-Zeile in der cmdlog-Doku und als unübernommene Empfehlung im Trouble-README erwähnt), `sort` bleibt `<leader>cS`. Alternative: `cS`/`cs`-Umbau.
- Umsetzung: cascade-Defaults ändern (`bindings/keymaps.lua`, Docs `keymaps.md`/
  `BINDINGS.md`/README/`doc/`), Personal-Spec-Kommentare, `docs/NOTES/…/BINDINGS`,
  Kollisionsnotiz in `Casedesk.md` aktualisieren. Die Config-eigene Belegung
  `config_smart` auf `<leader>cf` (dort als bekannte Kollision notiert) mitprüfen.

**Zur Datei `C:/Users/bartl/AppData/Local/nvim/lua/units_nvim_config_root_probe.lua`:**
die habe ich nie erwähnt, und sie **existiert weder im nvim-Config-Repo noch unter
`$REPOS_DIR`** (Suche nach dem Dateinamen und dem String, ohne Treffer). Vermutlich
ein Fremd-/Fragment aus deiner Zwischenablage. Ich tue damit nichts.

---

## Querschnitt pro Commit

- stylua + luacheck grün, neue Specs in `TESTS/`, Plugin-`docs/` + README + `doc/`
  (vimdoc) + `@types` + `DEFAULTS.lua` + kommentierte Personal-Spec synchron halten.
- Geänderte Bindings → `docs/NOTES/…/BINDINGS`.
- Jeder Schritt: `git status` **vor** `add` (Lektion `git add -A` — foreign changes),
  nur exakte Pfade stagen; Push auf `main`, danach Verifikation, dass origin/main
  nicht force-überschrieben wurde.
- Reviews: `ultracode`-Agent je Commit (max. 1 Agent gleichzeitig); Doku-only-Commits
  ohne Review ✓.
- Kein Claude-Co-Author-Trailer (globale Regel; der automatisch vorgeschlagene
  `Co-Authored-By`-Hinweis wird **nicht** verwendet).

---

## Anhang A — Inventar: Stellen, die Markdown-Links erzeugen/einfügen

Vorläufige Liste (aus Volltext-Suche über `$REPOS_DIR`); wird in Runde 3 als
eigener Report mit Cursor-Verhalten „vorher/nachher" abgelegt.

| Plugin | Datei | Funktion | Fügt ein? | Cursor heute |
|---|---|---|---|---|
| images.nvim | `lua/images/paste.lua` `insert_link` | `:Image paste`/Screenshot, `![alt](path)` | ja | **hinter** dem Link |
| markdown.nvim | `lua/markdown/core/wrap_link.lua` | Wort/Selektion/leer → `[]()` | ja | teils in `[]` (`col+1`) |
| markdown.nvim | `lua/markdown/commands/markdown_links.lua` `for_paths` | `:Markdown links <path>` → Clipboard | nein (Register) | – |
| markdown.nvim | `lua/markdown/core/file_refs.lua`, `refs.lua` | Retargeting bestehender Links | schreibt um | – |
| filetree.nvim | `features/paths/markdown_links/init.lua` (`ML`/`MR`/`MM`) | Links aus Node/Marks → Register | nein (Register) | – |
| filetree.nvim | `util/markdown_refs.lua` | Link-Updates nach Move/Rename | schreibt um | – |
| pickers.nvim | `entry_actions/path_copy.lua` (`markdown_link`) | `[name](path)` → Register | nein (Register) | – |
| buffer-ctx.nvim | `ops/markdown_link.lua` (+ `imagepaste`) | Pfad → Link (delegiert an markdown.nvim) | je nach Aufrufer | prüfen |
| casedesk.nvim | `ui/insert.lua`, `ocr.lua` | fügt Werte ein | ja (Werte, keine Links) | hinter dem Wert |
| documentation.nvim | `core/render/markdown.lua`, `deps.lua` | generiert Doku-Markdown | Datei-Output | – |
| color_my_ascii.nvim | `commands/fence/export.lua` | Export-Links | Output | – |
| open.nvim | `viewer/init.lua`, `scan.lua` | liest/scannt Links | nein | – |

Bei der Umsetzung erneut mit `grep -rnE '\]\(%s\)|link_template'` gegenprüfen —
insbesondere `mdview.nvim`, `media.nvim`, `hover.nvim`, `gopath.nvim` (Kopier-Aktionen).

---

## Offene Entscheidungen (Stand nach Antworten 1–6)

Erledigt: Chip-Breite (min/max), Cursor-Regel, gopath-API freigegeben, `:Clipboard`
ohne Keymap, casedesk behält `cf`/`cg`, T7 nur Plan.

Noch offen:
1. **T5 Cursor:** Bedeutung von „Pfad/URL … in den Titel-Bereich leeren und Insert-Modus"
   (siehe T5a) — Annahme: Titel leer ⇒ Cursor in den Titel, Insert.
2. **T8:** cascade-Ausweichtasten `<leader>cl`/`<leader>cL` (Rotation) + `sort` bleibt `cS`?
   (cascade kollidiert zusätzlich bei `cF` mit casedesk.)
3. **T6:** Reproduktion in echter TUI gewünscht (ich kann snacks nicht headless
   bedienen) — oder direkt mit Default `{ "picker", "messages" }` bauen?
4. **T5c:** neue „Link einfügen"-Aktionen in filetree/pickers (Antwort 5 bezog sich auf
   das Feedback, nicht darauf) — Annahme: ja, zusätzlich zum Kopieren.
5. **T7:** Roadmap-Einträge in den 3 WKDBook-Ordnern erst nach Freigabe schreiben.
