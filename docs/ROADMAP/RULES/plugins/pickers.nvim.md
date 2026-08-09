# pickers.nvim

## Zweck
`pickers.nvim` konsolidiert sieben vormals separate Picker-Module (find_config,
find_in_folder, dir_picker, repo_pickers, grep, search_all_drives, system_find)
zu einem einzigen `:Pickers`-Befehl (`lua/pickers/command/init.lua`). Es
abstrahiert dabei über drei Backend-Engines — telescope.nvim, fzf-lua,
snacks.nvim (`lua/pickers/engines/`) — und bietet zusätzlich eine `smart`-Aktion,
die grep- und find-Ergebnisse zu einer nach Relevanz sortierten Liste mischt
(`lua/pickers/smart/`). Andere Plugins/Configs hängen sich über
`pickers.command.handle({ fargs = {...} })`, `pickers.mappings` oder
`pickers.builtins.run(name)` ein (siehe z.B. `lua/pickers/bindings/keymaps.lua`)
— das ist die stabile API, über die z.B. undo-history-Bindings in der
nvim-Config geroutet werden.

## Nicht-standard Patterns / Algorithmen

1. **Selected-Index-Overlay: korrekte Index-Formel statt naivem `row+1`**
   `lua/pickers/selected_index/init.lua:87-110`. Der alte Fallback
   (`compute_index_from_picker`, jetzt nur noch Legacy-Pfad in
   `lua/pickers/selected_index/compute.lua`) benutzte `row + 1`, was nur unter
   Telescopes nicht-default `sorting_strategy = "ascending"` stimmt. Unter dem
   Default `"descending"` sitzt Index 1 bei `row == max_results - 1`. Fix:
   `picker:get_index(row)` — Telescopes eigene autoritative Row↔Index-Abbildung
   — wird bevorzugt verwendet. Der Kommentar im Code dokumentiert explizit,
   warum der Bug *jedes* Mal auftrat, nicht nur intermittierend, und warum die
   alten Fallback-Pfade (`picker.results`/`.manager.results`/`._results`) auf
   modernen Telescope-Versionen gar nicht mehr existieren (Ergebnisse liegen in
   einer Linked List, nicht in einem flachen Array).

2. **Weak-keyed Cache mit inkrementellem Zählen** `lua/pickers/selected_index/cache.lua:1-95`.
   `count_upto` zählt Nicht-nil-Einträge einer Ergebnisliste bis zu einem Index,
   cached den Fortschritt aber inkrementell pro Ergebnistabelle (`__mode = "k"`,
   automatisches GC wenn die Results-Tabelle verworfen wird). Bei wachsender
   `results_len` (Live-Grep-Streaming) wird ab dem letzten `cached_upto`
   weitergezählt statt neu; schrumpft die Länge unter `cached_upto`, wird der
   Cache invalidiert. Zusätzlich eine harte Obergrenze `MAX_CACHE_ENTRIES = 100`
   mit periodischem Ausdünnen (`cleanup_if_needed`), damit der Cache bei vielen
   parallel offenen/geschlossenen Pickern nicht unbegrenzt wächst — klassischer
   Performance-Kompromiss gegen O(n)-Neuzählung bei jedem Cursor-Move.

3. **Debounce + zwei Autocmd-Quellen für den Overlay** `lua/pickers/selected_index/init.lua:180-203`.
   Der Overlay reagiert nicht nur auf `CursorMoved` im Results-Buffer, sondern
   auch auf `TextChangedI`/`TextChanged` im Prompt-Buffer, weil ein Tipp-Event
   die Sortierung ändert (Rang des selektierten Eintrags verschiebt sich ohne
   Cursor-Bewegung). Beide Quellen laufen über denselben 30ms-Debounce
   (`lua/pickers/selected_index/debounce.lua`, dünner Wrapper um
   `lib.nvim.debounce` mit explizitem `cancel`-Handle), damit Telescopes
   asynchrones Re-Sort sich erst setzen kann, bevor neu gerendert wird.

4. **Bewusst rohe `nvim_create_autocmd`-Calls statt `lib.nvim.autocmd.create`**
   `lua/pickers/selected_index/init.lua:184-193` (Kommentar im Code). Für
   Buffer-lokale Autocmds (`buffer = results_bufnr`) wird bewusst NICHT die
   eigene lib.nvim-Abstraktion benutzt, weil deren `opts` nur
   group/pattern/desc/once/nested durchreicht, aber kein `buffer` — würde man
   sie trotzdem verwenden, würden Picker-lokale Hooks stillschweigend zu
   globalen (jeder-Buffer-)Listenern. Der Code verweist explizit auf dieselbe
   Lücke in `github_stats.nvim`, `color_my_ascii.nvim` und `markdown.nvim` —
   ein wiederkehrendes, dokumentiertes lib.nvim-Gap.

5. **Smart-Action: ein gemeinsamer, engine-unabhängiger Scoring-Kern**
   `lua/pickers/smart/score.lua:1-195`. Datei- und Grep-Treffer werden auf
   EINER Skala bewertet (`M.match`: Substring-Score mit Boni für frühe
   Position/Wortgrenze/Präfix/Exaktheit + schwacher Subsequence-Fallback für
   fuzzy-artiges Tippen), damit sie in einer einzigen sortierten Liste
   interleaven statt in zwei Blöcken zu erscheinen. Ein Treffer, der SOWOHL im
   Dateinamen als auch im Inhalt matcht, bekommt einen festen Bonus
   (`weights.both`, Default 25) — bewusst simpel/transparent statt eines vollen
   Fuzzy-Frameworks, weil die Engines selbst das In-Picker-Feeling übernehmen
   und der Score hier nur eine sinnvolle *relative* Ordnung liefern muss
   (`score.lua:10-14`).

6. **Smart-Action ist absichtlich synchron via `vim.system():wait()`**
   `lua/pickers/smart/search.lua:1-9`. Statt drei unterschiedliche
   Async-Result-Streaming-Integrationen für snacks/telescope/fzf-lua zu bauen,
   läuft `fd`+`rg` blockierend innerhalb des jeweiligen
   Per-Keystroke-Callbacks jeder Engine — die Engines debouncen die Eingabe
   ohnehin, `fd`/`rg` sind schnell genug, das hält den gemeinsamen Kern trivial
   portabel. Bewusster Trade-off gegen "richtiges" Async, mit `timeout`
   (Default 3000ms) als Sicherheitsnetz gegen Hänger.

7. **Frecency: log-gedämpfte Häufigkeit statt linearer Zählung**
   `lua/pickers/smart/frecency.lua:109-122`. `M.score` kombiniert
   `math.log(count+1)` (verhindert, dass eine Datei mit hunderten Visits
   permanent dominiert) mit einem gebucketten Recency-Gewicht
   (`recency_weight`: <1h=100, <1d=80, <1w=60, <30d=40, sonst 20) — dieselbe
   Heuristik-Form wie telescope-frecency/Browser-"Frecency"-Scores, aber neu
   und minimal implementiert (kein sqlite, reines JSON unter
   `stdpath("data")/pickers.nvim/frecency.json`), lazy geladen, nur bei
   `VimLeavePre`/explizitem `M.flush()` persistiert (kein Disk-I/O pro
   Buffer-Visit).

8. **Engine-spezifische History-Modelle statt eines gemeinsamen Abstraktionszwangs**
   `lua/pickers/history/init.lua:1-97`. Statt History über alle drei Engines
   hinweg künstlich zu vereinheitlichen, dokumentiert und respektiert der Code
   explizit die unterschiedlichen Architekturgrenzen: Telescope hat ein
   Prozess-weites Singleton-History-Objekt (keine Per-Call-Isolation möglich,
   `fzf_scope` greift dort nicht), fzf-lua kann pro Provider-Call eine eigene
   History-Datei bekommen (`fzf_scope = "plugin"|"global"|"patch"`), snacks.nvim
   hat gar keinen Hook-Punkt (fixer Pfad, kein `enabled`/`dir`/`limit`-Feld) —
   dafür wird nichts gepatcht. `M.patch` verzögert das Patchen von
   `telescope.setup()`/`fzf-lua.setup()` bewusst via `vim.schedule`, damit es
   NACH allen lazy.nvim-`config()`-Aufrufen läuft und nicht durch einen
   späteren User-`setup()`-Call überschrieben wird (Kommentar
   `history/init.lua:69-79`, insbesondere zu fzf-lua's destruktivem
   `setup()`-Reset-Verhalten ohne `do_not_reset_defaults=true`).

9. **Result-Count: Polling statt Event-Hook** (dokumentiert in
   `doc/pickers.txt:709-712`, nicht direkt gelesen im Detail, aber explizit im
   Code/Doc benannt): Der Live-Ergebniszähler pollt den Entry-Manager alle
   150ms statt auf ein Event zu hören, weil es für asynchron eintrudelnde
   `live_grep`-Treffer kein passendes `CursorMoved`/`TextChanged`-Äquivalent
   gibt.

10. **`plugin_spec()` explizit NICHT aus `setup()` aufrufbar** —
    `lua/pickers/init.lua:24-29`, ausführlich in `doc/pickers.txt:127-148`.
    Weil lazy.nvim `dependencies` VOR `config()` auflöst, muss die
    Engine-Wahl für optionales Auto-Install/Configure bereits beim
    Spec-Bau feststehen, nicht erst wenn `setup()` läuft — ein subtiler,
    dokumentierter Lazy.nvim-Lifecycle-Constraint, der die API-Form
    (separate Top-Level-Funktion statt `setup()`-Option) erzwingt.

Insgesamt: keine Security-relevanten Anpassungen gefunden (reine
Editor-Tooling-Domäne, keine Netzwerk-/Secrets-Berührung), aber mehrere echte
Performance-/Correctness-Patterns (Punkte 1-4) und bewusste
Architektur-Kompromisse (Punkte 5-10), die über naive Standardlösungen
hinausgehen.

## Abgeleitete Guidelines

1. **Engine-/Backend-Abstraktion über ein schmales Funktions-Interface, nicht
   über Vererbung.** `pickers.engines.load()` gibt ein Modul zurück, das exakt
   `pick_files/pick_item/live_grep/pick_dir` implementiert
   (`lua/pickers/engines/init.lua:6-8`); jeder Adapter (`telescope.lua`,
   `fzf.lua`, `snacks.lua`) erfüllt dieses Interface unabhängig. Für künftige
   Plugins mit mehreren austauschbaren Backends: ein minimales, explizit
   dokumentiertes Funktions-Set pro Adapter, kein gemeinsames Basisobjekt.

2. **`auto`-Detection mit klarer Prioritätsreihenfolge + Fallback-Warnung.**
   `pickers.engines.load` probiert bei explizitem, aber nicht verfügbarem
   Engine-Wunsch erst den Wunsch, warnt dann (`notify.warn`) und fällt auf die
   Auto-Reihenfolge zurück, statt hart zu fehlern (`engines/init.lua:34-47`).
   Übertragbar: Nutzerwunsch > Fallback-Kette > expliziter Fehler nur wenn
   wirklich nichts verfügbar ist, mit sichtbarer Warnung bei jedem Downgrade.

3. **Getrennte Skalen für "Kern-Logik testen" vs. "Engine-Feeling".** Der
   Scoring-Algorithmus (`smart/score.lua`) ist pure/seiteneffektfrei und direkt
   unit-testbar (`docs/TESTS/pickers_spec.lua`), obwohl er letztlich in drei
   verschiedene Picker-UIs gerendert wird. Kernlogik, die von der Engine
   getrennt werden kann, sollte auch als eigenes, ungebundenes Modul existieren
   — das macht sie testbar ohne Neovim-UI-Mock.

4. **Strukturierte Fehler mit `kind` statt bloßer String-Fehler.**
   `lua/pickers/error.lua`: ein `Pickers.Error{kind, message}` +
   `safe_call(kind, fn, ...)`-Wrapper um `pcall`. Bewusst klein gehalten ("thin
   dispatcher, kein volles Error-Framework") — für ein Dispatch-Plugin reicht
   ein getaggtes Ergebnis-Objekt, kein Exception-Hierarchie-Overkill.

5. **Config-Normalisierung: jedes Sub-Objekt hat seine eigene
   `normalise_*`-Funktion mit Whitelist + `notify.warn` bei ungültigem Wert,
   nie stillem Verwerfen und nie hartem Error.** Siehe
   `lua/pickers/config/init.lua` (`normalise_collection`, `normalise_history`,
   `normalise_selected_index`, `normalise_keys`) — ungültige Werte behalten den
   vorherigen/Default-Wert und melden sich per Warnung. Migrations-Pfade
   (altes `opts.selected_index` → `experimental.selected_index`) werden mit
   expliziter Warnung UND Doku-Verweis abgefangen, nicht kommentarlos ignoriert.

6. **`vim.tbl_deep_extend("force", defaults, user)` als Standard-Merge-Muster
   für Optionsobjekte, aber mit bewusster Ausnahme dort, wo "merge" keinen Sinn
   ergibt** (z.B. `cfg.mappings` wird ersetzt statt gemerged, weil es keinen
   sinnvollen Default gibt, gegen den man mergen könnte —
   `config/init.lua:236-239`). Regel: nicht blind überall denselben Merge
   anwenden, sondern pro Feld explizit entscheiden und kommentieren, warum.

7. **Ein einziger Dispatch-Choke-Point für alles, was einen Picker öffnet.**
   `pickers.command.handle`/`dispatch_action` ist die einzige Stelle, die
   tatsächlich einen Picker startet — Keymaps, Compat-Commands,
   Collection-Commands rufen alle `handle({fargs=...})` auf statt eigene
   Öffnen-Logik zu duplizieren (`bindings/keymaps.lua` ruft durchgehend
   `require("pickers.command").handle(...)`). Das macht Session-State wie
   `pickers.last` (für `:PickersRepeat`) trivial an einer Stelle zu pflegen.

8. **Deferred/`vim.schedule`-Patches für fremde Plugin-`setup()`-Aufrufe, wenn
   Merge-Semantik und Aufrufreihenfolge sonst unklar wären.**
   `pickers.history.patch` schiebt das eigene Patchen von
   `telescope.setup()`/`fzf-lua.setup()` explizit nach hinten, damit es nach
   der eigenen `config()`-Phase des Users landet, nicht davor
   (`history/init.lua:81-95`). Immer wenn ein Plugin fremden Plugins in deren
   `setup()` hineinpatcht: Reihenfolge relativ zu lazy.nvim `config()` explizit
   bedenken und dokumentieren, nicht implizit auf Deklarationsreihenfolge
   vertrauen.

9. **Buffer-lokale Autocmds: eigene lib.nvim-Wrapper NICHT blind einsetzen,
   wenn sie kein `buffer`-Feld durchreichen** — lieber roh `nvim_create_autocmd`
   mit explizitem Kommentar, warum (siehe Pattern 4 oben). Bekanntes,
   wiederkehrendes lib.nvim-Gap über mehrere Plugins hinweg — sollte perspektivisch
   in lib.nvim selbst gefixt werden (Cross-Plugin-Item, kein Pickers-spezifisches).

10. **Feature-Flags für experimentelle Funktionalität in einen eigenen
    `experimental`-Namespace stecken, statt sie top-level zu platzieren.**
    `experimental.selected_index` erlaubt Shape-Änderungen ohne
    Compat-Versprechen auf den Rest von `setup()` (`config/init.lua:258-262`,
    dokumentiert in `doc/pickers.txt:628-630`).

11. **Engine-Fähigkeitslücken explizit dokumentieren und als No-Op behandeln,
    statt sie zu verstecken oder künstlich nachzubauen.** `result_count` und
    `selected_index` sind bewusst "telescope-only", weil fzf-lua/snacks das
    nativ schon anbieten (`doc/pickers.txt:634-636`, `701-702`) — kein
    Nachbau einer Funktion, die eine andere Engine schon besser kann.

## Keybindings-Audit

Das Plugin selbst setzt Normal-Mode-Keymaps in `lua/pickers/bindings/keymaps.lua`
(registriert wenn `keymaps.enable = true`, Default an):

| Keymap | Default | Aktion |
|---|---|---|
| `<leader>dp` | an | `:Pickers dir` — Dir-Navigation |
| `<leader>fb` | an | `:Pickers folder files` |
| `<leader>fc` | an | `:Pickers config files` |
| `<leader>gc` | an | `:Pickers config grep` |
| `<leader>li` | an | `:Pickers cwd grep` |
| `<leader>.` | an | Explorer (aktive Engine) |
| `cwd_files`, `repos_files`, `repos_grep`, `system_files`, `cwd_smart`, `config_smart`, `folder_smart`, `cwd_find_all` | aus (nil) | opt-in, gleiches Registrierungsmuster |

Zusätzlich: `keys.*` (In-Picker-Bindings: Preview-Scroll, History-Navigation,
`create_file`, `open_background`, `preview_toggle`, `split`/`vsplit`/`tab`,
siehe `doc/pickers.txt:556-580`) und Collection-eigene `keys.files`/`keys.grep`/
`keys.smart` (`bindings/collections.lua`, nicht im Detail gelesen, aber laut
Doku analog zu `keymaps.*` registriert).

- **Count-Unterstützung (`2<leader>xy`, `N<leader>xy`):** Keine der Keymaps
  interpretiert einen vorangestellten Count. `map()` in
  `lua/pickers/bindings/util.lua:10-18` bindet immer eine parameterlose
  Callback-Funktion; `vim.v.count`/`vim.v.count1` wird nirgends im
  gesamten `lua/pickers/`-Baum referenziert (keine Treffer bei Durchsicht der
  bindings/command/actions-Module). Das ist nachvollziehbar — die Keymaps
  öffnen alle interaktive Picker-Sessions (kein "N-mal wiederholen"-Konzept
  wie bei einem Textobjekt/Motion), ein Count wäre hier semantisch nicht
  sinnvoll zuzuordnen, außer man würde ihn z.B. für "gehe N Verzeichnisse
  hoch" bei `dir_pick` nutzen. Genau das existiert bereits, aber NICHT über
  `vim.v.count`, sondern über ein separates Ex-Command-Argument:
  `:Pickers dir <number>` (`doc/pickers.txt:238-247`). Für zukünftige Plugins
  mit ähnlichem "N Ebenen hoch"-Konzept wäre `vim.v.count1` an der Keymap
  direkt eine naheliegende Ergänzung (aktuell muss man dafür den Ex-Command
  bemühen, das Keymap `<leader>dp` selbst geht immer interaktiv über den
  Nav-Picker).

- **Autocompletion für Ex-Commands:** Ja, vorhanden und mehrstufig.
  `:Pickers` unterstützt vollständige Tab-Completion für Scope/Action/Nav
  (`lua/pickers/command/composer.lua`, `complete = function(arg_lead) ...`,
  Zeilen 43 und 62), aufgebaut über einen "Route Tree", der Dispatch,
  Completion UND die Dokumentation aus einer Quelle speist
  (`doc/pickers.txt:198-201`). Compat-Commands wie `:RepoFiles [repo]`
  completen ebenfalls aus `REPOS_DIR` (`doc/pickers.txt:443-444`). Für
  Ex-Commands mit Enum-artigen Argumenten (Scope/Action/Nav-Listen) ist
  vollständige `complete=`-Unterstützung hier klar Pflicht, und wird auch
  konsequent eingehalten — als Vorbild für künftige Plugins übernehmenswert.

- **Fehlende Flags/Optionen (Ideen beim Lesen aufgefallen):**
  - Kein `vim.v.count`-Hook für `dir_pick`, obwohl das Konzept ("N Ebenen
    hoch") in `:Pickers dir <number>` bereits existiert — ein direktes
    `2<leader>dp` → "2 Ebenen hoch, Action-Picker" wäre eine natürliche
    Ergänzung ohne architektonischen Bruch.
  - `keymaps.explorer` (`<leader>.`) ist im Doku-Kommentar
    (`bindings/keymaps.lua:9`) gelistet, aber in der Konfigurationsreferenz
    `doc/pickers.txt` (Abschnitt 9, Keymaps) nicht explizit als eigenständiges
    `keymaps.explorer`-Feld dokumentiert — ggf. Doku-Lücke, nicht im Detail
    verifiziert.
  - Keine Möglichkeit, den `find`-Override der "find all"-Eskalation
    (`hidden+no_ignore+follow`) selektiv zu kombinieren (z.B. nur `no_ignore`
    ohne `hidden`) — es ist ein All-or-nothing-Flag `files all`.

## Ideen für andere Plugins

- **Generischer "Route-Tree"-Command-Composer als eigenständiges lib.nvim-Modul.**
  `pickers.command.composer` treibt Dispatch + Tab-Completion + Doku-Generierung
  aus einer einzigen Baumstruktur. Das Muster (eine Datenstruktur, drei
  Konsumenten: Ausführung, Completion, Doku) ist generisch genug, um als
  wiederverwendbares `lib.nvim.usercmd.composer`-Feature für jedes Plugin mit
  verschachtelten Ex-Command-Argumenten zu dienen (aktuell laut Doku bereits
  in lib.nvim, aber offenbar noch nicht von allen eigenen Plugins genutzt —
  Kandidat für Vereinheitlichung).

- **Ein `lib.nvim`-weiter "Buffer-lokale Autocmds mit vollem Options-Durchreich"-Fix.**
  Das wiederkehrende Gap (Pattern 4 oben, in mind. 4 Plugins dokumentiert:
  pickers.nvim, github_stats.nvim, color_my_ascii.nvim, markdown.nvim) ist ein
  starker Kandidat für einen einmaligen Fix in `lib.nvim.autocmd.create`
  (`buffer`-Feld durchreichen), statt in jedem Plugin erneut roh auf die
  Neovim-API auszuweichen.

- **Eigenständiges "Frecency-as-a-Service"-Modul in lib.nvim.** Das
  Recency/Frequency-Scoring aus `pickers.smart.frecency` (log-gedämpfte
  Häufigkeit + gebuckete Recency, JSON-Persistenz unter
  `stdpath("data")/<plugin>/frecency.json`) ist generisch genug, um von
  mehreren Plugins (z.B. einem MRU-Filetree, einem Buffer-Switcher) geteilt zu
  werden, statt in jedem Plugin einzeln neu implementiert zu werden — passt zum
  bereits dokumentierten Muster "lib.nvim ist eine bewusste Dependency" aus dem
  Memory-Index.

- **"Smart merge + rank" als generisches Muster für andere Kombinationen.**
  Die Idee "zwei heterogene Ergebnisquellen auf eine gemeinsame Skala normieren
  und interleaven" (hier: Dateiname- vs. Inhalts-Treffer) ließe sich auf andere
  Domänen übertragen, z.B. ein Picker, der LSP-Symbole UND Text-Grep-Treffer
  gemeinsam rankt, oder ein Notiz-Plugin, das Tag-Treffer und Volltext-Treffer
  mischt.
