# emojis.nvim

## Zweck
`emojis.nvim` stellt einen einzigen `:Emojis [action] [scope]`-Befehl bereit, um
Emoji-Grapheme im Buffer oder projektweit zu entfernen, zu zählen, aufzulisten,
durch `:shortcode:`-Platzhalter zu ersetzen (und zurück), einzufügen oder als
"Checkbox"-Glyphen (`🔲` -> `✅`) zeilenweise durchzuschalten. Zusätzlich gibt es
einen Quick-Insert-Overlay (Grid mit Frecency-Sortierung) und einen
Such-Picker (telescope/fzf-lua/vim.ui.select). Emoji-Erkennung läuft über einen
selbstgeschriebenen, reinen UTF-8-Byte-Pattern-Tokenizer (`core/patterns.lua`),
keine externe Lib. Harte Abhängigkeit: `lib.nvim` (Command-Layer über
`lib.nvim.usercmd.composer`).

## Nicht-standard Patterns / Algorithmen

1. **Frecency-Scoring mit exponentiellem Recency-Decay** — `lua/emojis/overlay/frecency.lua:150-162` (`score()`).
   Score = `count * 0.5^(age_days / HALF_LIFE_DAYS)` mit `HALF_LIFE_DAYS = 30`
   (Zeile 26). Ein zweimal heute genutztes Glyph schlägt eines, das dreimal vor
   einem Monat genutzt wurde, aber ein Langzeit-Favorit wird nicht durch einen
   einzelnen Zufallstreffer verdrängt. Tie-Break fällt auf die kuratierte
   Ausgangsreihenfolge zurück (`M.sort`, Zeile 168-189, stabiler Sort über
   `idx`), damit das Grid nicht unter dem Cursor "springt". Wichtig: das
   Overlay reordnet nur eine vom User kuratierte Liste (`overlay.picks`), fügt
   nie neue Einträge hinzu und entfernt nie welche — bewusste Trennung von
   "was ist wählbar" (Config) und "in welcher Reihenfolge" (Nutzung).

2. **Defensive Persistenz, die nie den Kernpfad brechen darf** —
   `frecency.lua:46-114` (`read_file`/`load`/`save`). Jede Lese-/Schreiboperation
   ist mit `pcall`/Nil-Checks abgesichert; eine fehlende, unlesbare oder
   korrupte JSON-Datei degradiert still zu "keine Nutzung aufgezeichnet"
   statt zu werfen. Beim Laden werden zusätzlich einzelne Einträge validiert
   (`type(entry.count) == "number"`, Zeile 84), damit eine handbearbeitete
   Datei nicht NaN/nil in die Score-Arithmetik einschleust. Begründung im
   Moduldoc (Zeile 16-19): "losing a usage histogram must never break emoji
   insertion" — ein reines Nice-to-have-Feature darf niemals die
   Kernfunktion (Emoji einfügen) zum Absturz bringen.

3. **Table-driven UTF-8-Codepoint-Ranges statt handgeschriebener Byte-Patterns** —
   `lua/emojis/core/patterns.lua:63-99`. `RANGES` listet inklusive Codepoint-
   Bereiche, `range_pattern()` kompiliert daraus zur Ladezeit Lua-Byte-Class-
   Patterns (`encode()`, Zeile 27-46, reine Arithmetik ohne Bitoperatoren —
   explizit für Lua 5.1/LuoJIT-Kompatibilität, Zeile 18). Ein neuer
   Unicode-Bereich ist damit eine Ein-Zeilen-Datenänderung statt manuell
   berechneter Byte-Sequenzen.

4. **Vollständige Grapheme-Erkennung statt Codepoint-für-Codepoint** —
   `patterns.lua:132-201` (`match_unit`/`match_at`). Ein "Emoji" ist hier
   nicht ein einzelner Codepoint, sondern eine ganze Grapheme-Sequenz: Basis
   + optionaler Fitzpatrick-Hautton-Modifikator + optionales VS16 + entweder
   ein zweites Regional-Indicator-Symbol (Flaggen-Paar wie 🇩🇪) oder eine
   ZWJ-Kette (Familien-/Berufs-/Regenbogenflagge-Sequenzen wie 👨‍👩‍👧). Naive
   Ansätze zählen VS16-dekorierte Emoji wie ⚠️ doppelt oder zerreißen
   ZWJ-Sequenzen; das Modul dokumentiert genau diesen früheren Bug (siehe
   `docs/commands.md:125-127`: "previously they were counted twice").

5. **Space-Collapse beim Entfernen von Emoji-Runs** — `lua/emojis/core/ops.lua:16-74`
   (`_clear_line`). Wenn ein entferntes Emoji (oder ein zusammenhängender Lauf
   mehrerer Emoji) auf beiden Seiten genau ein Leerzeichen hatte, bleibt nach
   dem Entfernen genau eines übrig statt zwei (`" 🚀 " -> " "`, nicht `"  "`).
   Explizit als Fix eines alten Bugs dokumentiert (`docs/commands.md:113-131`).
   Die Implementierung erweitert einen Match über direkt angrenzende weitere
   Emoji/verirrte VS16-Bytes (Zeile 37-48), damit ein ganzer Lauf als eine
   Einheit für die Space-Collapse-Entscheidung zählt.

6. **Zeichenspezifischer Column-Offset für Cell-Spans im Overlay-Grid** —
   `lua/emojis/overlay/init.lua:110-140` (`render()`). Byte-Spans jeder Grid-
   Zelle werden während des Renderns mitgeschrieben statt nachträglich aus der
   Spaltenposition zurückgerechnet — Kommentar erklärt: Emoji sind
   Mehrbyte-Zeichen und (meist) doppelbreit dargestellt; eine Rückrechnung
   Spalte->Byte-Offset müsste dieselben Breiten-Annahmen ein zweites Mal
   treffen und würde bei jedem Glyph, der doch einfachbreit rendert, leise
   auseinanderdriften.

7. **Word-Scope als reiner Cursor-Substring-Scan statt Regex/Treesitter** —
   `lua/emojis/core/scope.lua:41-77`. "Wort" ist hier bewusst simpel definiert:
   zusammenhängende, whitespace-freie Zeichen um den Cursor, per manuellem
   Zeichen-für-Zeichen-Scan (kein `\k`, kein `iskeyword`). Robust und
   dependency-frei, aber grobkörniger als Vims `iw`.

8. **Ambiguitäts-Auflösung über konfigurierbare Set-Reihenfolge statt
   Tabellen-Iterationsreihenfolge** — `lua/emojis/core/checkbox.lua:28-47`
   (`locate()`) + `lua/emojis/config/init.lua:92-137` (`checkbox_sets()`).
   Da Lua-Tabellen keine garantierte Iterationsreihenfolge haben, würde ein
   Glyph, das in mehreren Sets vorkommt, sonst nicht-deterministisch
   aufgelöst. Die Lösung: `checkbox.order` legt die Suchreihenfolge fest;
   Sets, die dort fehlen, werden alphabetisch angehängt (nie "silently
   unreachable", `config/init.lua:121-127`).

9. **Deep-merge-Falle bei Listen bewusst umgangen** — `lua/emojis/config/init.lua:44-63`.
   `vim.tbl_deep_extend` merged Listen indexweise, sodass eine kürzere
   User-Liste den Default-"Schwanz" behalten würde. Für kuratierte Listen
   (`overlay.picks`, jedes `checkbox.sets[name]`) ist das falsch — "diese fünf
   Glyphen" muss exakt fünf bedeuten. Nach dem generischen Merge werden diese
   Felder deshalb explizit mit `vim.deepcopy(user_opts...)` überschrieben statt
   gemischt.

## Abgeleitete Guidelines

1. **Pure Core / Impure Shell strikt trennen.** `core/*.lua` (patterns, ops,
   scope, checkbox) machen keine einzige `vim.api`/`vim.fn`-Aufrufe und geben
   `(result, err)` oder `(result, count)` zurück statt zu werfen oder zu
   notifien. Alles Buffer-/UI-Anfassende lebt in `actions.lua`/`overlay/`/
   `picker.lua`. Das macht den Kern headless testbar (siehe `docs/TESTS/`) und
   erzwingt, dass Fehlerbehandlung an einer Stelle (der Caller) passiert statt
   verstreut.

2. **Fehler als Rückgabewerte im Core, `notify` nur in der UI-Schicht.**
   `scope.resolve()` gibt `(target|nil, err|nil)` zurück (`core/scope.lua:17`);
   die aufrufende Ebene (`init.lua`, `commands.lua`) entscheidet, ob/wie sie
   notifiziert. `util/notify.lua` bündelt das an einer Stelle, mit Präfix.

3. **Bindings-Verzeichnis strukturell einheitlich halten, auch wenn leer.**
   `bindings/autocmds.lua` existiert nur für strukturelle Symmetrie mit
   usrcmds/keymaps, obwohl es keine Autocmds gibt (`bindings/autocmds.lua:1-15`).
   Das hält die Modulstruktur über mehrere Plugins konsistent vorhersagbar.

4. **Soft-Deps immer über einen zentralen `pcall`-Wrapper mit Fallback
   führen, nie verstreut.** `util/lib.lua` ist der einzige Ort, der
   `lib.nvim.notify`/`lib.nvim.map`/`lib.lua.tables`/`lib.lua.strings.utf8`
   probiert und bei Fehlen auf native Neovim-APIs zurückfällt. Andere Module
   rufen nur `util/lib.lua` bzw. `util/notify.lua` auf, nie direkt
   `pcall(require, "lib...")`.

5. **Harte vs. weiche Abhängigkeit explizit dokumentieren und im
   `:checkhealth` unterscheidlich behandeln.** `lib.nvim.usercmd.composer` ist
   hart (kein Fallback, `vim.health.error` bei Fehlen, `health.lua:19-23`);
   `lib.nvim.ui.kit` ist weich für eine Einzelfunktion (Overlay), degradiert zu
   `vim.health.warn` (`health.lua:28-32`); `which-key`/`cascade.nvim` sind rein
   informativ (`vim.health.info`). Drei Härtegrade, drei Health-Level.

6. **Config-Merge: kuratierte Listen/Maps explizit als "replace", nicht
   "merge" behandeln.** Wo eine Liste eine geschlossene, sinntragende Menge
   ist (Overlay-Picks, Checkbox-Sets), nach `tbl_deep_extend` gezielt mit
   `vim.deepcopy(user_value)` überschreiben. Sonst produziert
   `vim.tbl_deep_extend("force", ...)` bei Listen index-weise Merges mit
   Default-Resten — ein subtiler, schwer zu findender Bug.

7. **Ein Katalog, mehrere Ableitungen, nie doppelt pflegen.**
   `config/DEFAULTS.lua:16-129`: `CATALOG` (Glyph+Label) ist die einzige
   Quelle; `picks` und `names` (Codepoint -> Shortcode) werden daraus
   generiert, der Codepoint wird aus dem Glyph selbst dekodiert
   (`patterns.codepoint(glyph)`) statt hart einprogrammiert — ein Tippfehler
   im Hex-Wert kann so nicht mehr vom Glyph abweichen.

8. **Command-Dispatch: Validierung/Routing zentral in einer `execute()`-
   Funktion halten, auch wenn ein Composer-Layer davorgeschaltet wird.**
   `commands.lua:56-131` bleibt die "unveränderte" Dispatch-Engine; die
   Composer-Routen (`action_route`, `forward`) rekonstruieren nur das alte
   `{fargs, range, line1, line2}`-Shape und delegieren weiter. Vermeidet,
   Validierungslogik beim Wechsel auf eine neue Command-Registrierungs-API
   zweimal auszudrücken (siehe Kommentar `commands.lua:7-15`).

9. **Bei destruktiven, projektweiten Aktionen: Dry-Run-Pfad anbieten und
   Bestätigung erzwingen.** `search.lua:48-60` fragt vor
   `clear`/`replace` über `cwd` per `confirm_fn` nach, Default ist "Nein"
   (`choice ~= 1` bricht ab); ungesicherte, geänderte Buffer werden
   übersprungen statt überschrieben (`search.lua:70-72`). `docs/commands.md`
   empfiehlt explizit `:Emojis list cwd` als Preview davor.

10. **Reine Funktionen aus der UI-Schicht explizit für Skripting exponieren.**
    `init.lua:151-155` (`M.ops()`) reicht `core.ops` unverändert nach außen
    durch, extra für Tests/Scripting — kein Duplikat, keine Re-Implementierung.

11. **Geteilte Schreibpfade (Picker + Overlay) in ein gemeinsames Modul
    ziehen, nicht pro Call-Site duplizieren.** `core/insert.lua` existiert
    einzig, damit Picker und Overlay dieselbe Einfüge- UND
    Frecency-Aufzeichnungslogik teilen (Moduldoc Zeile 4-8) — sonst würde
    Frecency nur einen der beiden Eintrittspunkte sehen.

## Keybindings-Audit

Preset-Keymaps (`lua/emojis/bindings/keymaps.lua`, nur aktiv bei
`keymaps.preset = true`, Default `false`):

| lhs | mode | Aktion | count-Unterstützung | Completion | Anmerkung |
|---|---|---|---|---|---|
| `<C-e>` | n, i | `emojis.insert()` (Picker) | nicht anwendbar — öffnet nur den Picker, kein Wiederholungssinn | n/a (kein Ex-Command-Input hier) | — |
| `<leader>ee` | n | `emojis.overlay()` | nicht anwendbar — Overlay ist ein Ein-Glyph-Insert pro Öffnung | n/a | — |
| `<leader>et` | n, x | `emojis.toggle()` (Checkbox) | **Ja, aber ungewöhnlich implementiert**: in Normal-Mode mit `v.count1 > 1` wird der Scope auf die nächsten `count` Zeilen ab Cursor erweitert (`init.lua:70-84`, `checkbox_target()`), toggelt also `count` Zeilen statt das Toggle `count`-mal zu wiederholen. Sinnvoll für "checke die nächsten 3 Zeilen", aber semantisch anders als z. B. `3dd`. Nicht dokumentiert in `docs/keymaps.md`/`BINDINGS.md` — nur im Code-Kommentar. | n/a | Lücke: Verhalten bei count sollte in `docs/BINDINGS.md` stehen, nicht nur im Quellcode. |
| `<leader>ec` | n | `emojis.count()` | nein — Aktion ist buffer-weit, ein count ergibt keinen Sinn | n/a | — |
| `<leader>el` | n | `actions.list()` -> quickfix | nein, aus demselben Grund | n/a | — |

`:Emojis`-Command (`commands.lua`, immer registriert, via
`lib.nvim.usercmd.composer`):

- **Autocompletion**: vollständig vorhanden und mehrstufig — erstes Argument
  vervollständigt alle Actions, zweites je nach Action entweder Scopes
  (`word line visual % cwd`), Overlay-Modi (`grid grid_keys list`) oder die zur
  Laufzeit konfigurierten Checkbox-Set-Namen (`commands.lua:172-181`,
  `config.checkbox_set_names()` wird bei Registrierung gelesen). Das ist
  vorbildlich: Completion-Werte kommen aus der aktiven Config, nicht aus einer
  hartkodierten Liste, sodass ein user-definiertes Set genauso vervollständigt
  wie ein eingebautes.
- **count**: Der `:Emojis`-Range-Mechanismus (`:'<,'>Emojis`, `:10,20Emojis`)
  deckt den ex-typischen "N-fach"-Anwendungsfall ab; ein numerisches Prefix
  vor `:Emojis` selbst wird nicht ausgewertet (auch nicht sinnvoll für die
  meisten Aktionen außer evtl. `next`, wo N-maliges Springen fehlt — siehe
  unten).
- **Fehlende Flags/Ideen beim Lesen aufgefallen**:
  - `:Emojis next` hat keinen Count-Support (`nav.lua:72-79` springt immer nur
    einen Schritt); ein `[count]Emojis next` das N Emoji weiterspringt wäre
    naheliegend und billig zu ergänzen (Schleife um `goto_emoji`).
  - `overlay`-Grid: kein direktes "Suchen/Filtern" per Tippen (nur `list`-Modus
    hat das über den kit-Chooser). Ein Tipp-zu-Filter-Modus im Grid wäre
    konsistent mit dem `insert`-Picker.
  - `checkbox.toggle` mit `dir = -1` (rückwärts) ist in `core/checkbox.lua`
    und `actions.checkbox` vorhanden, aber weder über `:Emojis toggle` noch
    über eine Preset-Keymap erreichbar — nur über die Lua-API
    (`require("emojis").toggle(set, -1)`). Lücke: kein Ex-Command-Flag/keine
    Keymap für Rückwärts-Toggle.
  - `search.no_ignore`/extra Globs sind nur über `:Emojis <action> cwd
    <glob>...` erreichbar, keine `--no-ignore`-artige Ad-hoc-Flag im Command
    selbst (nur über Config) — nachvollziehbar, aber ein `!`-Bang-Suffix
    (`:Emojis! clear cwd`) für "diesmal mit no_ignore" wäre ein verbreitetes
    Vim-Idiom, das hier fehlt.

which-key-Label (`bindings/which_key.lua`): registriert nur die Gruppe
`<leader>e`, keine eigenen Keys — korrekt als reine Beschriftung.

## Ideen für andere Plugins

1. **Generisches Frecency-Modul als eigenständiges `lib.nvim`-Utility.** Das
   Scoring-Muster (`count * 0.5^(age/half_life)`, JSON-Persistenz unter
   `stdpath("data")`, "nie werfen, nur reordern") ist plugin-agnostisch nutzbar
   überall dort, wo eine kuratierte Liste nach Nutzungshäufigkeit sortiert
   werden soll (z. B. Snippet-Picker, Symbol-Picker, MRU-Dateilisten,
   `pickers.nvim`-Quellen). Sollte aus `emojis.nvim` heraus nach `lib.nvim`
   extrahiert werden (Parameter: Half-Life, Storage-Key, Item-Identity-Fn),
   statt in jedem neuen Plugin neu erfunden zu werden — passt zum bereits in
   Memory festgehaltenen "lib.nvim ist eine bewusste Dependency"-Muster.

2. **Reiner UTF-8-Grapheme-Tokenizer als eigenständiges `lib.lua`-Modul.** Der
   Ansatz in `core/patterns.lua` (Codepoint-Ranges -> Byte-Class-Pattern,
   ZWJ-/VS16-/Regional-Indicator-Handling) ist nicht emoji-spezifisch, sondern
   generisches Unicode-Grapheme-Matching auf reinen Lua-Strings. Nützlich für
   jedes Plugin, das UTF-8-korrekt zählen/schneiden muss (z. B. Statuszeilen-
   Truncation, Textwidth-Berechnung mit Emoji, Suchhervorhebung).

3. **"Checkbox-Cycle" als generisches Konzept lässt sich von Emoji lösen.**
   `core/checkbox.lua` kennt eigentlich nur "finde eines von N Token-Sets auf
   der Zeile und rotiere". Das ließe sich zu einem generischen
   Status-Zyklus-Plugin verallgemeinern (TODO-Status-Wörter, Prioritäts-Tags
   `[P0]`/`[P1]`/`[P2]`, Ampel-Symbole) — die cascade.nvim-Bridge zeigt
   bereits, wie zwei Plugins sich einen Vokabular-Datensatz teilen können,
   ohne dass eines vom anderen hart abhängt (`cascade_groups()` ist reine
   Daten-Funktion, kein `require("cascade")`).

4. **Async-cwd-Suche mit Confirm-Gate + Skip-bei-unsaved-Buffer als
   wiederverwendbares Pattern für "projektweite Mutation via ripgrep".**
   `search.lua` zeigt ein sauberes Muster für jedes Plugin, das
   Buffer-übergreifend im Projekt sucht und ändert (z. B. ein
   "TODO-Migrator" oder "Import-Pfad-Umschreiber"): async rg-Aufruf,
   Dry-Run-Voransicht über `list`, Bestätigungsdialog vor der Mutation,
   offene ungespeicherte Buffer überspringen statt überschreiben.

5. **Drei-Modi-Overlay (Grid / Grid mit Hotkeys / Liste) über einem
   gemeinsamen Datensatz** ist ein wiederverwendbares UI-Muster für jeden
   "kleine kuratierte Auswahl schnell einfügen"-Anwendungsfall (Snippets,
   Farbschemata, Symbol-Sets) — nicht emoji-spezifisch.
