# diff.nvim

## Zweck

`diff.nvim` stellt einen einzigen flexiblen `:Diff`-Befehl bereit, der zwei
(oder mit `base=` drei) beliebige "Seiten" — aktueller Buffer, Datei,
Buffernummer, Clipboard, `git:<rev>`, `http(s)://…`, Bilddatei — gegeneinander
vergleicht und das Ergebnis auf mehrere Arten ausliefert (Split/Tab,
Inline-Unified-Diff, Float, Message-Prompt, Datei, Clipboard, reine
Statistik). Zusätzlich gibt es `:DiffOrig` (Buffer vs. Disk), `:DiffBuffers`
(Buffer-Picker) und `:DiffExit`. Alles Diffing läuft über `vim.diff`
(libvim) — keine Shell-Aufrufe; einzige Pflicht-Abhängigkeit ist `lib.nvim`
(README.md:27-29, docs/architecture.md).

## Nicht-standard Patterns / Algorithmen

1. **Manuelles Byte-Level Word-Diff via `vim.diff` auf explodiertem String**
   `lua/diff/core/render.lua:262-294` (`word_diff_ranges`) und
   `:309-362` (`apply_word_diff`). Für Wort-/Zeichen-Highlighting innerhalb
   einer geänderten Zeile wird jede Zeile in einzelne Bytes "explodiert"
   (jedes Byte wird eine eigene Zeile eines synthetischen Dokuments,
   `explode()` in render.lua:267-273) und dann nochmal durch `vim.diff` mit
   `result_type="indices"` gejagt. Warum: `vim.diff` bietet nativ nur
   zeilenweise Granularität; statt eine eigene Char-Diff-Implementierung zu
   schreiben, wird der vorhandene (in C implementierte, schnelle) Myers/
   Histogram-Algorithmus zweckentfremdet. Bewusster Kompromiss: Byte- statt
   UTF-8-codepoint-genau (Kommentar Zeile 253-256) — ein mehrbyteiges
   Codepoint kann an einer Highlight-Grenze auseinandergerissen werden, wird
   aber explizit als akzeptierter Sonderfall dokumentiert statt stillschweigend
   in Kauf genommen.

2. **Statistik-Klassifikation durch Positions- statt Content-Match**
   `render.lua:55-59` (Kommentar) und `compute_stats` (`render.lua:49-73`):
   Beim Zählen von `+`/`-`-Zeilen im unified diff wird bewusst NICHT nach
   Inhalt gefiltert (z. B. Header-Zeilen `+++`/`---` ausschließen), weil eine
   entfernte/hinzugefügte Codezeile selbst mit `--` beginnen kann (Lua-
   Kommentar). Stattdessen liefert `vim.diff` mit `result_type="unified"` gar
   keine Header-Zeilen — die Klassifikation ist also allein durch die
   Faktenlage möglich, dass die rohe `vim.diff`-Ausgabe direkt bei `@@`
   beginnt. `apply_word_diff` löst dasselbe Problem in render.lua:310
   („lines[1]/[2] sind immer der Header") durch Skip-by-Position statt
   Skip-by-Prefix.

3. **`git show <rev>:<relpath>` statt Shell/Plugin-Wrapper**
   `lua/diff/core/git.lua:70-73`. Nutzt `vim.system({...}):wait()` (Windows-
   und Unix-tauglich, kein Shell-String) statt z. B. `fugitive` oder
   `vim.fn.system("git show ...")`. Repo-Root-Suche läuft manuell über
   `vim.fs.find(".git", {upward=true})` (git.lua:26-32) und behandelt sowohl
   `.git`-Verzeichnis als auch `.git`-Datei (Submodule/Worktrees) — ein Detail,
   das ein naiver `isdirectory(".git")`-Check übersehen hätte.

4. **URL-Fetch mit doppeltem Timeout-Mechanismus**
   `lua/diff/core/url.lua:35-111`. `curl --fail --location` läuft asynchron
   über `vim.system`, zusätzlich wird ein eigener `vim.uv.new_timer()`
   gesetzt (url.lua:50, 101-110), der den Prozess hart killt (`sigkill`),
   falls `curl`s eigenes `--max-time` bei gehängtem TLS-Handshake versagt
   (Kommentar url.lua:5-9). Ein `done`-Flag (url.lua:49, 55-59) verhindert
   doppeltes Callback-Feuern zwischen Timer und Prozess-Exit — klassische
   Race-Condition-Absicherung bei zwei konkurrierenden Async-Quellen für
   denselben Abschluss.

5. **Bild-Dateien werden vom Text-Diff-Pfad abgefangen, bevor sinnloser Diff
   entsteht** `lua/diff/features/image_compare.lua` (ganzes Modul) und
   Aufrufstelle in `core/init.lua:144`. Da `resolve.lua` jede Nicht-Buffer-/
   Nicht-Clipboard-Spezifikation blind per `vim.fn.readfile()` als Text liest
   (core/resolve.lua:56-60), würde eine PNG-Datei stillschweigend als Garbage-
   Text gelesen und "gedifft" — kein Fehler, aber bedeutungsloses Ergebnis.
   `image_compare.lua` erkennt das per Extension-Whitelist (Zeile 28,
   bewusst ohne `.svg`, da das Text ist) VOR dem eigentlichen Resolve und
   biegt auf `images.nvim`'s Gallery um, mit explizitem Warn-Notify statt
   stillem Fallback, wenn `images.nvim` fehlt (Zeilen 90-100).

6. **Idempotentes `setup()` per Modul-lokalem Flag statt `vim.g`**
   `lua/diff/init.lua:20-30` (`_setup_done`). Verhindert doppelte
   Command-/Autocmd-Registrierung bei mehrfachem `require("diff").setup()`
   (z. B. durch versehentliches Re-Sourcing der Config). `vim.g.loaded_diff`
   wird zusätzlich gesetzt, aber nur als Health-Check-Signal — der eigentliche
   Guard ist die lokale Closure-Variable.

7. **Kontext wird eager gesnapshotted, nicht lazy referenziert**
   `lua/diff/core/init.lua:56-59` (`DiffNvim.Context`-Kommentar) und
   `core/init.lua:437-442`: Bufnr, Fenster und Range werden beim Aufruf von
   `:Diff` sofort in eine Context-Tabelle kopiert, weil ein asynchroner
   Picker oder URL-Fetch dazwischen liegen kann und der "aktuelle" Buffer/
   das "aktuelle" Fenster bis zum tatsächlichen `execute()` sonst
   weggewandert sein könnte ("async pickers cannot let these values drift").

8. **Kein eigenes Wort für "abgebrochen" bei pickers.nvim**
   `lua/diff/core/pickers_bridge.lua:16-20` (Moduldoc) und `health.lua:59-63`:
   Das Modul dokumentiert explizit eine bekannte API-Lücke bei der fremden
   Picker-Library (kein zuverlässiges Cancel-Signal über alle Engines
   hinweg) und wälzt die Verantwortung dafür sauber auf die Caller ab, statt
   sie zu verschleiern.

## Abgeleitete Guidelines

1. **Pure Resolution-Layer strikt von der UI-Layer trennen.** `core/resolve.lua`,
   `core/git.lua`, `core/url.lua` geben ausschließlich `(value, err)` zurück
   und rufen niemals `notify` auf (Moduldoc jeweils oben in der Datei); nur
   `core/render.lua` und `core/init.lua` (die "UI-facing layer") dürfen
   Notifications feuern. Diese Trennung macht die Resolver trivial testbar
   und wiederverwendbar.

2. **Jeder öffentliche State lebt modul-lokal, nicht in `vim.g`.**
   `config/init.lua` (`_active`), `core/scratch.lua` (`_bufs`),
   `features/exit.lua` (`_cfg`) — alles lokale Upvalues mit Get/Set-Funktionen.
   `vim.g.*` wird nur für plugin-übergreifend sichtbare Signale genutzt
   (Load-Guard für `:checkhealth`).

3. **Ressourcen-Lifecycle über eine zentrale Registry kapseln.**
   `core/scratch.lua` ist die einzige Stelle, die Scratch-Buffer erzeugt
   (`M.create`) oder fremde Buffer zur Cleanup-Liste hinzufügt (`M.track`).
   `cleanup_all()` und `wipe_on_exit()` sind die einzigen Wege, sie wieder
   loszuwerden — verhindert verstreute `nvim_buf_delete`-Aufrufe und
   garantiert, dass `:DiffClear`/`VimLeavePre` wirklich alles erwischen.

4. **Defensive `pcall` an jeder Stelle, wo Neovim-APIs auf ungültigem State
   werfen können.** Beispiele: `nvim_buf_set_name` bei Namenskollision
   (`scratch.lua:27`), `nvim_buf_delete` beim Cleanup (`scratch.lua:78,100`),
   `nvim_buf_set_extmark` beim Word-Diff (`render.lua:335,345`),
   `timer:stop()/close()` (`url.lua:61-67`). Kombiniert mit expliziten
   `validate.buf_valid`/`validate.win_valid`-Checks VOR API-Zugriffen
   (`lib.nvim.normalize`-Delegation, `util/validate.lua`).

5. **Soft-Dependencies immer über `pcall(require, ...)` + Feature-Test,
   niemals über bloßes `require`.** `pickers_bridge.lua:28-36` prüft
   Modulexistenz UND die erwartete Funktions-Shape (`type(engine.pick_item)
   == "function"`), bevor sie genutzt wird. `image_compare.lua:91-100` macht
   dasselbe für `images.nvim`. Wenn die Soft-Dependency fehlt, gibt es eine
   klare, informative Fallback-Meldung statt eines stillen No-Ops oder
   Absturzes.

6. **`vim.system` statt Shell-Strings für alles, was einen externen Prozess
   braucht.** Sowohl `git.lua:72` als auch `url.lua:76-93` nutzen argv-Arrays
   (`{"git", "-C", root, "show", object}` bzw. `{"curl", ...}`) — nie
   String-Interpolation in einen Shell-Aufruf. Verhindert Command-Injection
   und Windows/Unix-Quoting-Divergenzen strukturell, nicht durch Escaping.

7. **Async-Fetches brauchen einen eigenen Timeout, unabhängig vom Tool-
   internen Timeout.** `url.lua`s Doppel-Timeout-Pattern (siehe Punkt 4 oben)
   ist eine wiederverwendbare Regel: Bei jedem externen, potenziell hängenden
   Prozessaufruf zusätzlich zur eigenen Timer-basierten Absicherung greifen,
   nicht nur auf `--max-time`/CLI-eigene Flags vertrauen.

8. **Config-Merge ist immer `vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS),
   user_opts)`**, niemals die DEFAULTS-Tabelle selbst mutieren
   (`config/init.lua:25`). DEFAULTS bleibt so über die gesamte Session hinweg
   ein unveränderliches Referenzobjekt.

9. **Drei-Wege-/Mehrwege-Feature-Kombinationen früh und mit klarer
   Fehlermeldung validieren, bevor irgendetwas geöffnet wird.**
   `core/init.lua:452-472` prüft `base=` gegen `output`/`view` VOR jedem
   Fenster-Öffnen und bricht mit präziser Fehlermeldung ab statt halbwegs
   offene Fenster wieder aufräumen zu müssen.

10. **Commands über einen gemeinsamen Composer registrieren, aber die
    ursprüngliche `key=value`-Parsing-Logik nicht duplizieren.**
    `bindings/usrcmds.lua:9-18` (Moduldoc) erklärt bewusst, dass die per
    `lib.nvim.usercmd.composer` deklarierten KV-Schemas NUR für
    Tab-Completion existieren; das eigentliche Parsing bleibt in
    `core/resolve.lua`. Vermeidet zwei parallele, potenziell divergierende
    Parser für dieselbe Grammatik.

11. **Health-Check deckt jede weiche Abhängigkeit einzeln ab**, inklusive
    Neovim-Versionsgates (`vim.system` erst ab 0.10) und externer Programme
    (`git`, `curl`) — `health.lua` prüft jede Fähigkeit separat und nennt die
    genau betroffenen Features, statt nur "geht/geht nicht".

12. **Jede Config-Option, die vom naiven Standard abweicht, bekommt einen
    Kommentar direkt am Default-Wert, der das "Warum" erklärt** (nicht nur
    das "Was"). Siehe `config/DEFAULTS.lua:40-44` (`native_diffthis`,
    Default `false` mit Begründung) oder `:30-35` (`image_compare`). Das
    verhindert, dass zukünftige Refactorings die Absicht hinter einem
    unauffälligen `false`/`true` verlieren.

## Keybindings-Audit

diff.nvim definiert genau **ein** eigenes Keymap (plus ein Float-lokales
Hilfsmapping); alle Befehle laufen primär über Ex-Commands.

| Mapping | Modus | Scope | Zweck |
|---|---|---|---|
| `<Esc><Esc>` | n | `buffer` (default) / `global` / aus (`false`) | Diff-Modus verlassen (`docs/BINDINGS.md:18`, `lua/diff/bindings/keymaps.lua`) |
| `q` / `<Esc>` | n | Buffer-lokal, nur `view=float`-Fenster | Float schließen (`render.lua:243-245`, via `lib.nvim.window.nice_quit`) |

- **Count-Unterstützung (`2<leader>xy` etc.):** Nicht anwendbar. `<Esc><Esc>`
  ist ein reiner Toggle/Exit-Befehl ohne sinnvolle Wiederholungssemantik —
  ein Count vor "verlasse Diff-Modus" hat keine Bedeutung. Ebenso bei `q`/`<Esc>`
  im Float. Richtig so, keine Lücke.
- **Autocompletion für Ex-Commands:** Vollständig vorhanden und vorbildlich.
  `bindings/usrcmds.lua` registriert für `:Diff`/`:DiffBuffers` `key=value`-
  Completion über `lib.nvim.usercmd.composer` (Route.kv), inklusive
  kontextsensitiver Vervollständigung nach `view=`, `output=`, `source=`,
  `target=`, `base=` (siehe `docs/commands.md:141-152`). Die Value-Listen sind
  bewusst als "soft hints" (`KvSpec.values`, nicht `KvSpec.enum`) implementiert,
  damit z. B. ein echter Dateipfad als `target=` weiterhin funktioniert
  (usrcmds.lua:14-18) — eine durchdachte Abwägung zwischen Discoverability
  und Flexibilität.
- **Fehlende Flags/Optionen (Ideen beim Lesen aufgefallen):**
  - Kein eigenes Keymap für "diff gegen letzten Commit" (`:Diff target=git:HEAD`)
    oder für den populären Merge-Conflict-Fall (`base=git:HEAD target=git:MERGE_HEAD`)
    — beides nur über ausgeschriebene Ex-Commands erreichbar. Ein optionales,
    deaktivierbares Default-Mapping dafür könnte den Alltag beschleunigen,
    ist aber laut Config-Philosophie des Plugins (keine aufgedrängten Leader-
    Mappings) bewusst weggelassen.
  - Kein Keymap-Äquivalent für `:DiffBuffers`/`:DiffOrig`/`:DiffClear` — auch
    hier konsequent Command-only, was zur "kein aufgedrängtes Leader-Mapping"-
    Linie passt (`docs/BINDINGS.md:48-52`), aber für ein häufig genutztes
    Feature wie `:DiffOrig` (Vergleich mit Disk-Version) evtl. eine
    optionale, deaktivierbare Empfehlung wert wäre.
  - Kein `<C-c>`/Doppel-Escape-Alternativmapping für `scope="global"`, das
    einen bewussten Bail-out aus einem versehentlich global gesetzten Mapping
    böte, falls `<Esc><Esc>` mit anderen Plugins kollidiert.

## Ideen für andere Plugins

- **Generisches "Soft-Dependency-Bridge"-Pattern extrahieren:** Sowohl
  `pickers_bridge.lua` als auch `image_compare.lua` folgen demselben Muster
  (pcall-require → Shape-Check → Adapter-Funktion → Fallback). Das könnte als
  wiederverwendbarer Helper in `lib.nvim` wandern (z. B.
  `lib.nvim.softdep.resolve(modname, shape_check, adapter)`), damit künftige
  *.nvim-Plugins dieses Pattern nicht jedes Mal neu schreiben.

- **Ein eigenständiges "byte-level word-diff"-Utility in `lib.nvim`:** Das
  `word_diff_ranges`/`apply_word_diff`-Pattern (vim.diff auf explodierten
  Strings) ist generisch genug (jede Plugin-Diff-Ansicht, jeder Merge-Viewer)
  um als `lib.nvim.diff.word_ranges(a, b, algorithm)` zentral bereitgestellt
  zu werden, statt in jedem *.nvim, das Diffs zeigt, neu implementiert zu
  werden.

- **"URL als Content-Quelle" als generisches lib.nvim-Utility:** Der
  Async-Fetch-mit-Doppel-Timeout aus `url.lua` (curl via vim.system + libuv-
  Timer-Fallback) ist unabhängig von Diffing nützlich — z. B. für ein
  Snippet-Viewer-Plugin, das Gists lädt, oder ein Doku-Plugin, das Remote-
  READMEs zieht. Als `lib.nvim.net.fetch_text(url, opts, callback)` central
  bereitstellen.

- **Ein eigenständiges "3-way / N-way native diffmode orchestrator"-Modul:**
  `render.lua`'s `three_way()` zeigt, dass Neovims eingebautes Diffmode für
  3+ Fenster "einfach funktioniert", sobald man die Fenster richtig öffnet
  und `'diff'` setzt. Ein generisches `lib.nvim.diffmode.open_n_way({bufs},
  view)`-Helper würde diesen Layout-Code (vsplit/split/tab-Varianten,
  aktuell dreimal fast identisch dupliziert zwischen `side_by_side` und
  `three_way` in render.lua) einmal zentral lösen und für andere Merge-
  /Review-Plugins wiederverwendbar machen.

- **Ein "Vendored-Code-Drift-Checker"-Plugin:** Aus `docs/url-sources.md`s
  Beispielen (Vendored-Code vs. Upstream, API-Schema-Drift, Skript-
  Verifikation vor Ausführung) ergibt sich die Idee für ein eigenständiges,
  kleines Plugin, das periodisch/on-demand eine Liste konfigurierter
  lokaler-Datei-zu-URL-Paare prüft und bei Drift benachrichtigt (baut direkt
  auf `diff.nvim`s URL-Diff-Fähigkeit auf, aber als eigenes,
  Automatisierungs-fokussiertes Tool statt manuellem `:Diff`-Aufruf).

- **Statusline-Component-Konvention:** `diff.status()` (init.lua:83-98) ist
  ein sehr kleines, sauberes Pattern (aktive Ressourcen zählen, kurzer
  String, konfigurierbares Prefix, leerer String wenn inaktiv) — als
  Konvention für alle *.nvim-Plugins mit einem "aktiven Zustand" (z. B.
  language.nvim, project-insight.nvim) übernehmenswert, damit lualine-
  Integration überall gleich aussieht.
