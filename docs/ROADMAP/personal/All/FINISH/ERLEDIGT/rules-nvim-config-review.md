# `rules.nvim` gegen die nvim-config — Durchgang 2026-09-17

> Schwesterdokument zu [`rules-nvim-review.md`](./rules-nvim-review.md) und
> [`rules-nvim-review-full.md`](./rules-nvim-review-full.md), die beide
> `ai.nvim` prüfen. Dieser Durchgang richtet denselben Katalog auf **die
> Konfiguration selbst**. Lebendes Dokument: bei einem Re-Run vor Ort
> aktualisieren.

**Stand:** 2026-09-17. **Geprüft gegen:** dieses Repo, Worktree
`nvim-plugins-quality-review-30b806`, Basis `38c40a1`. **Katalog:** 421
Regeln in 14 Familien aus
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists` — 32 davon
mechanisch prüfbar, 389 `manual`.

**Vorgehen:** die Engine headless gefahren (`rules.check_family_json` über
jede geladene Familie), danach die kritischen `manual`-Regeln einzeln gegen
den Quelltext geprüft. Jeder Fund unten wurde **in einem laufenden Neovim
reproduziert**, bevor er gefixt wurde — kein Fund steht hier auf reiner
Quelltext-Lektüre. Die Gegenprobe steht jeweils in der Commit-Message.

**Status-Legende:** ✅ erfüllt · ➖ nicht anwendbar · 🔶 Fund (gefixt) ·
❓ offene Entscheidung

---

## Durchgangs-Status

| Ebene | Regeln (anwendbar) | Stand |
| ----- | ------------------ | ----- |
| automatisch | 32 | vollständig, 2026-09-17 |
| `critical` (manuell) | ~76 | vollständig, 2026-09-17 |
| `recommended` (manuell) | 180 | vollständig, 2026-09-17 |
| `nice-to-have` (manuell) | 71 | vollständig, 2026-09-17 |

NEW-/REL-Regeln zählen hier nicht mit: das sind Gates für ein
veröffentlichtes Plugin (s. `.rules-waivers.json` unten).

---

## Zusammenfassung Durchgang 1 — kritisch: 8 Funde, 8 gefixt, 2 Entscheidungen offen

| # | Regel | Schwere | Fund | Commit |
| - | ----- | ------- | ---- | ------ |
| 1 | `ERR-60` | 🔴 kritisch | `case/doctor.lua`s „Ziel existiert schon"-Guard war an **sieben** Stellen als `exists(to) and nil or to` geschrieben — ein Ausdruck, der *immer* `to` liefert. `normalize.lua` handelt auf jedem `to ~= nil`, `mutate.rename_file` ist ein nacktes `uv.fs_rename`, und das **überschreibt sein Ziel stillschweigend** (auf dieser Windows-Maschine verifiziert). Mit einer Alias-Datei neben einer echten `Notes.md` hätte `:Case normalize` die Notizen gelöscht. Derselbe Verlust ist diesem Modul laut eigenem Header **schon einmal passiert**. | `c560cfb` |
| 2 | `SEC-03` | 🔴 kritisch | `custom_menu`s „Terminal hier öffnen" baute `cd <dir> ; $SHELL` als Shell-String. `<dir>` kommt aus dem Buffernamen; ein Pfad darf Shell-Metazeichen enthalten. Reproduziert: ein `;` im Namen führt den Rest aus — das `cd` muss dafür nicht einmal gelingen. | `b157786` |
| 3 | `SEC-34` | 🔴 kritisch | Vier `vim.fn.expand()`-Aufrufe auf nicht-statischen Strings. Der in `context_open/providers.lua` bekommt `<cfile>`, also beliebigen Text aus einem fremden Buffer: unter `expand()` ist ein Backtick-Span eine Kommandosubstitution über `&shell`, und `%`/`#` lösen still zu anderen Pfaden auf (verifiziert: `expand("%")` gibt den aktuellen Dateinamen). Alle vier gehen jetzt über `lib.nvim.cross.fs.expand_path`. | `b157786` |
| 4 | `ERR-31` | 🔴 kritisch | Harpoons `is_first_run()`/`mark_initialized()` waren Check-dann-Erzeugen, mit ungewöhnlich weitem Fenster: geprüft in `setup()`, markiert erst nach `VimEnter` + `vim.schedule`. Zwei gleichzeitig gestartete Neovims hätten beide geseedet. Jetzt ein `fs_open(..., "wx")` (`O_CREAT`\|`O_EXCL`), das beansprucht *und* markiert. | `9494c08` |
| 5 | `LUA-16` | 🔴 kritisch | `bindings_explorer/source.lua` fällt mit `node.module or node.id` zurück. Ein JSON-`null` dekodiert zu `vim.NIL` — Userdata und damit **truthy**, der Fallback greift nie, und die erste Verkettung wirft. `documentation.nvim` schreibt diese Form nachweislich (192 von 414 Knoten). Latent, nicht aktiv: nur ein Knoten trägt derzeit `bindings`, und der hat beide Felder gesetzt. | `d0a9493` |
| 6 | `XP-05` | 🔴 kritisch | Die `bat`-Probe steckte in fzf-luas `preview`-Callback, den fzf pro angezeigtem Eintrag aufruft. `vim.fn.executable` cacht nicht. Gemessen: ~13,6 ms pro Probe bei gefundenem Tool, ~48 ms bei nicht gefundenem. 50 Previews kosteten 633 ms reines PATH-Stat'en, jetzt 12,3 ms. | `43225b4` |
| 7 | `XP-01` | 🔴 kritisch | `:NeotestDebugFramework` listete das CWD per `vim.fn.glob(cwd .. "/*")`. glob liest sein ganzes Argument als Pattern, `cwd` eingeschlossen — verifiziert: ein `proj[1]`-Ordner mit einer Datei globt zu 0 Einträgen, `vim.fs.dir` findet sie. Ein Debug-Kommando, das still „nichts" antwortet, ist der schlechtestmögliche Ausfall. | `5f7e8fb` |
| 8 | `NEW-03`/`NEW-36` | 🟡 empfohlen | `.luarc.json` hatte zwei Trailing Commas und war damit **kein gültiges JSON**. LuaLS' eigener Parser toleriert das, weshalb es unbemerkt blieb; nichts anderes, was die Datei liest, tut das. Im selben Durchgang: `stylua --check` war auf drei committeten Dateien rot, das Format-Gate der CI also bereits rot. | `20e3e83` |

### Zusätzlich gehärtet (kein aktiver Bug)

- **`SEC-35`** (`be55563`): Der WhichKey-Prompt wurde in einen Ex-String
  konkateniert, wo `|` ein zweites Kommando beginnt. which-key deklariert
  sein Usercommand mit `nargs="*"` **ohne** `-bar`, schluckt den `|` also
  heute — an einer Live-Deklaration verifiziert, nicht angenommen. Das ist
  aber ein Fremdplugin-Detail, das diese Config nicht kontrolliert, und die
  Argumentform liefert ein byte-identisches `cmd.args`.
- **`ERR-60`** in `case/solution.lua` (`c560cfb`): dasselbe Idiom, dort
  **inert**, weil `flush()` zuerst `current_key` prüft. Trotzdem auf ein
  explizites `if` umgestellt, damit die Falle nicht stehen bleibt.

---

## Zusammenfassung Durchgang 2 — `recommended` und `nice-to-have`

| # | Regel | Schwere | Fund | Commit |
| - | ----- | ------- | ---- | ------ |
| 9 | `undefined-field` ×15 | 🟡 | **Die gesamte neotest-Anbindung rief fünf APIs an, die es nicht gibt.** Gegen ein laufendes Neovim gemessen: `neotest.state` hat genau `adapter_ids`/`positions`/`status_counts`, und `neotest.config` ist immer `nil` (leere Tabelle mit `__index`). Folgen: `show_output_on_fail` warf bei jedem Testlauf, `:NeotestClearAll` brach vor `summary.close()` ab, `auto_discovery`s `pcall(neotest.state.clear)` war `pcall(nil)`, und `:NeotestValidateConsumer` konnte **nie** bestehen. | `0a08469` |
| 10 | `LLS-08`-Kaskade | 🟡 | Der Validator-Fix legte zwei weitere Fehler frei, die vorher unerreichbar waren: Schritt 2 verlangte eine Funktion, der Consumer ist eine *aufrufbare Tabelle*; Schritt 6 rief `neo-tree.sources.manager.get_source_names()`, das es in v3 nicht gibt. Beide mitgefixt statt als neuen ersten Fehler stehen zu lassen — genau der Punkt von LLS-08. `:NeotestValidateConsumer` besteht jetzt. | `0a08469` |
| 11 | `undefined-field` (Rest) | 🟡 | `:NeotestDebugState` übergab den Buffer**namen** als Adapter-ID (immer „Found: NO"), las `tree.name` statt `tree:data().name` (immer „Root: ?"); `:NeotestDebugFile` iterierte ein Array mit `pairs` und indizierte die Zahl (Wurf); der Test-Zähler las `node.children` als Feld statt Methode — `ipairs` auf eine Funktion, also kein „0 gefunden", sondern ein Wurf im `defer_fn`. An einem konstruierten `neotest.Tree` verifiziert: neu 2 von 2. | `e0f2b2f` |
| 12 | `PRIN-51` | 🟡 | 137 von 445 öffentlichen Funktionen ohne `@return`, bei 308 mit — Drift im etablierten Hausstil, nicht dessen Abwesenheit. `@param` war lückenlos. Klassifikation per Tokenizer statt Regex (ein erster Regex-Lauf schrieb `return` aus inneren Callbacks der äußeren Funktion zu). 136× `---@return nil`, einmal `boolean` von Hand. | `1062ee8` |
| 13 | `LUA-11`/`LUA-13` | 🟡 | `:Case reply check` fängt den Buffer ein, wartet einen Netzwerk-Linkcheck ab, und `c` räumt danach Emojis — auf dem alten Handle. Ein zwischenzeitlich gelöschter Buffer wirft `Invalid buffer id` aus einem Keymap-Callback. Die anderen 31 ungeschützten Handle-Zugriffe holen ihr Handle synchron unmittelbar davor. | `3c5c242` |
| 14 | `UI-02` | 🟡 | Previews über 1,5 MB wurden stumm auf 4000 Zeilen gekappt. Jetzt Markerzeile im Buffer. Der Grenzfall „groß in Bytes, aber wirklich nur 10 Zeilen" wird korrekt nicht als gekappt gemeldet (an drei Fixtures geprüft). | `3a9842e` |
| 15 | `UI-03` | 🟡 | Ohne fzf-lua wechselte das Harpoon-Menü wortlos auf Harpoons Quick-Menu; fehlte auch das, passierte gar nichts — stumm. Jetzt einmalige Warnung bzw. Fehlermeldung. | `3a9842e` |
| 16 | `PERF-64` | 🟡 | `auto-center-fexplorer` rollte einen Timer pro Buffer selbst, inklusive eigener `BufDelete`-Aufräumung. `lib.nvim.debounce.buffer` ist genau diese Form. Der alte Code war nicht kaputt (PERF-62/PERF-80 erfüllt) — entfernt wurde eine korrekte Reimplementierung. | `e105e97` |
| 17 | `PERF-82` | 🟡 | Der SLA-Poll hatte ein idempotentes `setup()`, aber kein `stop()`-Gegenstück; einmal gestartet lief er die Sitzung durch. | `e105e97` |
| 18 | `LUA-96` | 🟡 | Vier Autocmds ohne `group` (3× `FileType` in treesitter, `VimEnter` in neotest). `Autocmd.create` vergibt keine Default-Gruppe, also stapelt ein Config-Reload Duplikate. `once = true` schützt davor nicht. Mechanismus isoliert belegt: mit geleerter Gruppe bleibt es bei 3, ohne kommen 2 dazu. | `3184c97` |
| 19 | `ERR-62` | 🟡 | `pcall(vim.cmd, "Inspect")` — `vim.cmd` ist eine aufrufbare *Tabelle*, die Regel nennt genau diesen Fall. Einzige solche Stelle. | `48f2e14` |
| 20 | `CMT-05` | 🟡 | `persist_paths` verwies auf „die zwei Kommandos **unten**", die längst nach `config.harpoon.usrcmds` umgezogen sind. | `e105e97` |
| 21 | `LUA-53` | 🟡 | Drei deutschsprachige Code-Kommentare (`records.lua` ×2, `status.lua`). Die deutschen *Ausgabe*-Strings bleiben — die Regel zielt auf Namen und Kommentare. | `e105e97` |
| 22 | `LUA-71` | 🟢 | 59 `---@field … # …` auf die vom Katalog bevorzugte Form ohne `#` umgestellt, nachdem an einem Fixture geprüft war, dass das `#` bei `fun(...)`-Typen nicht doch als Trenner trägt. | `c70ef9f` |

**Gesamtverifikation:** ein voller `lua-language-server`-Lauf über die Config
(`scripts/luals-scan`, before/after) geht von **28 auf 12 Diagnosen**, in
keiner Kategorie schlechter. Von den 12 verbleibenden ist keine ein echter
Codefehler:

| Rest | Anzahl | Warum er stehen bleibt |
| ---- | ------ | ---------------------- |
| `duplicate-doc-alias`/`-field` | 5 | Worktree-Artefakt, unten belegt (im Haupt-Checkout 0) |
| `param-type-mismatch` | 3 | `opts`-Tabellen gegen Fremdplugin-Typen; zwei davon am echten Server 0 |
| `undefined-field` (`ui_statusline`) | 2 | eigenes Zusatzfeld in einem lazy-Spec, das `LazyPlugin` nicht deklariert |
| `missing-parameter` | 1 | `navigate(state)` ist korrekt (`path or state.path`); die Annotation des Fremdplugins ist unvollständig |
| `cast-local-type` | 1 | Wrapper-Rückgabe gegen den Consumer-Typ des Fremdplugins |

> **Korrektur (2026-09-17, gleiche Sitzung):** hier stand zuerst „auf 0". Die
> Zahl war aus einem noch **laufenden** Scan gelesen — das Ergebnisfile war
> schlicht noch nicht geschrieben. Also exakt der `LLS-07`-Fehlermodus, der
> zwei Absätze weiter unten beschrieben ist, einmal selbst begangen. Lehre für
> den nächsten Durchgang: `compare.py` erst aufrufen, wenn der Scan-Prozess
> wirklich beendet ist — ein leeres `out/<pass>/` ist von „keine Befunde"
> nicht zu unterscheiden. Die Zwischenmessung nach Abschluss ergab 14, der
> endgültige Lauf nach dem Fix unten 12.

Zwei der zunächst 14 waren **neu und selbst verursacht**: der Validator-Fix
führte `neotest.neotree` ein, ein Feld, das LuaLS nicht kennen kann, weil ein
Fremdplugin den Consumer erst zur Laufzeit per `__index` nachreicht. Nach
`LLS-08` (kein Fix, der eine Warnung nur verschiebt) im selben Durchgang mit
`---@diagnostic disable-next-line` plus Begründung geschlossen statt stehen
gelassen — am laufenden Server gegengeprüft (Datei: 0 Diagnosen).

### Was sich als Messfehler herausstellte (und warum das hier steht)

- **Alle `duplicate-doc-alias`/`duplicate-doc-field`** sind ein Artefakt des
  Arbeitens **im Worktree**: der LSP-`root_dir` ist der Haupt-Checkout, der
  Worktree liegt darin, also sieht LuaLS jeden `@alias` zweimal.
  `lua/@types/aliases.lua` meldet im Worktree 37, dieselbe Datei aus dem
  Haupt-Checkout geöffnet **0**. Genau der Fall, für den `LLS-04` sagt:
  erst den Messaufbau verdächtigen.
- **Zeitfenster:** Diagnosen brauchen ~18 s zum Einschwingen. Bei 11 s meldete
  eine Datei 0, die bei 18 s reproduzierbar 13 meldet — `LLS-07` („nochmal
  messen") hat das abgefangen, bevor daraus ein falscher Schluss wurde.
- **Scan-Tool ≠ Server:** `context_open/scan.lua` und `plugins/ui.lua` waren
  Treffer des Scan-Tools und 0 am echten Server (`LLS-44`).
- **Ein erster Regex-Scan** meldete 12 gruppenlose Autocmds; real waren es 4.

### Bewusst nicht umgesetzt

- **`ERR-05`/`ERR-06`/`PRIN-21`/`PRIN-22`** (`safe_api.safe_call`,
  `lib.lua.error`): 0 Nutzungen bei 293 `pcall`-Stellen. Davon sind aber 167
  `pcall(require, …)`-Soft-Dependency-Proben und 21 Inline-Guards — Formen,
  für die `safe_call` nicht gedacht ist. Der eigentliche Wert von `safe_api`
  sind seine handle-validierenden Accessor, und das ist `LUA-11`/`LUA-12`,
  das hier separat geprüft wurde. Ein Rundumtausch von ~105 Aufrufen wäre
  Churn ohne Gegenwert; strukturierte Fehlertypen adressieren einen
  Plugin-API-Vertrag, den eine Config nicht hat.
- **`LUA-54`** (keine Emojis, keine fetten Pseudo-Überschriften): 755
  Emoji-Zeilen und 321 fette Überschriften in `docs/`. Die Regel gilt der
  „Dokumentation dieses Ökosystems" — `docs/` ist hier ein persönlicher
  Arbeits-Notizbaum, und die Review-Dokumente nutzen ✅/➖/🔶 funktional als
  Statuslegende. Über 1000 Edits an eigenen Notizen stünden in keinem
  Verhältnis.
- **`LUA-70`** braucht nichts: 426 von 442 beschriebenen `@return` nutzen die
  vom Regeltext ausdrücklich erlaubte Alternative „hinter dem Typ".

---

## Offene Entscheidungen (keine Mängel, sondern deine Wahl)

| Regel | Sachverhalt |
| ----- | ----------- |
| `NEW-06` / `REL-28` | Kein `LICENSE` im Repo. Der Katalog legt seit 2026-09-06 MIT (Copyright Stefan Bartl) als Hausentscheidung fest — das ist dort allerdings für *Plugins* begründet. Dieses Repo ist öffentlich (`github.com/StefanBartl/nvim`), also hat die Frage eine echte Außenwirkung: ohne Lizenzdatei gilt „alle Rechte vorbehalten". |
| `NEW-11` / `REL-01` | Kein `README.md`. Für eine persönliche Config kein Mangel im Sinne der Regel (die zielt auf installierbare Plugins), aber das Repo ist die erste Seite, die jemand sieht. |

Beide sind bewusst **nicht** in `.rules-waivers.json` eingetragen: ein
Waiver hält fest, dass ein Fund gesehen und akzeptiert wurde — hier ist noch
nichts entschieden.

---

## `.rules-waivers.json` — was bewusst nicht gilt

Die Engine lädt alle 14 Familien, auch die beiden Plugin-Gates. Deren
Formregeln beschreiben ein `*.nvim`-Repo (`lua/<plugin>/health.lua`,
`config/DEFAULTS.lua`, `doc/<name>.txt`, `bindings/{keymaps,usrcmds,autocmds}.lua`).
Diese Config hat keinen `lua/<name>/`-Namensraum, in dem irgendetwas davon
leben könnte — sie hält dieselben Trennungen eine Ebene höher unter
`lua/bindings/`.

Waived mit Begründung: `LUA-80`, `NEW-07`, `NEW-08`, `NEW-10`, `NEW-13`,
`NEW-27`, `UI-62`, `REL-05`, `REL-16` (Plugin-Form) · `NEW-45`
(`.stylua.toml` ist da, nur dot-präfixiert — der `file_exists`-Check kennt
nur die undotted Schreibweise) · `NEW-49` (kein Testsuite in diesem Repo,
also keine busted-Globals für luacheck) · `DEP-01` (beide Treffer sind
Kommentarprosa, die Harpoon2s *eigenes* `settings.key()` zitiert; jede
Aufrufstelle im Repo nutzt längst `vim.uv or vim.loop`).

Ein Waiver ist ausdrücklich nicht dasselbe wie die Familie aus dem Gate zu
nehmen: der Fund bleibt sichtbar, mit Grund.

---

## Geprüft und sauber (Auswahl, mit Beleg)

Damit ein Re-Run nicht dieselben Wege noch einmal geht — das sind die
Stellen, an denen eine Regel *hätte* greifen können und nachweislich nicht
greift:

- **`SEC-46`** (Escape-Zeichen zuerst escapen): `case/attachments.lua`s
  `ps_quote()` verdoppelt `'`, genau PowerShells Regel für
  Single-Quote-Literale — und dort ist `\` kein Escape, die beschriebene
  Falle existiert also nicht. Der eingebettete Wert ist ohnehin das
  Downloads-Verzeichnis.
- **`SEC-15`** (Keys nie selbst verwalten): `gp_config/config.lua` liest
  ausschließlich `os.getenv(...)`, kein Key-Store, keine Persistenz.
- **`SEC-30`** (Nutzereingabe literal escapen): die Pattern-Baustellen
  nutzen durchweg `vim.pesc` oder eine handgeschriebene, vollständige
  Metazeichen-Klasse. Zwei Stellen ohne Escape (`case/render.lua`s
  `snow_prefix`, `case/ui.lua`s `label`) bekommen dokumentierte, aktuell
  alphanumerische Konstanten — kein Nutzereingabe-Pfad.
- **`SEC-20`/`21`/`23`** (Downloads): die Config lädt keine Binaries. Der
  einzige Netzwerkpfad ist `case/linkcheck.lua`s `HEAD`-Anfrage über
  `lib.nvim.net.curl`, mit `timeout_ms`.
- **`ERR-33`/`LUA-13`** (Handles in verzögerten Callbacks): ein Scan über
  alle `vim.schedule`/`vim.defer_fn`-Blöcke fand zwei Kandidaten
  (`explorer-singleton.lua`, `custom_menu/init.lua`); beide lesen ihre
  Handles **frisch im Callback** statt sie einzufangen.
- **`ERR-62`** (`pcall(f(args))` fängt nichts): kein einziger Treffer, alle
  Stellen sind `pcall(function() … end)` oder `pcall(fn, args)`.
- **`XP-06`** (Modulpfad-Schreibweise): 321 verschiedene `require`-Ziele
  gegen 251 Module auf Platte geprüft — **0** Abweichungen. Der Linux-CI-
  Runner kann daran nicht scheitern.
- **`PERF-92`** (keine Layout-Geometrie auf Modulebene): alle zwölf
  `vim.o.columns`/`vim.o.lines`-Lesungen liegen in Funktionskörpern, werden
  also pro Öffnen berechnet.
- **`PERF-93`** (heißes Event nie ungeschützt): alle vier Handler auf
  `CursorMoved`/`TextChanged`/`WinScrolled` sind **buffer-lokal**
  registriert, laufen im normalen Editier-Buffer also gar nicht erst an.
  `CursorHold` verlässt den häufigen Fall über einen `buftype`-Vergleich.
- **`LUA-17`** (`vim.g` ist kein Transportweg): die vier `vim.g.*`-
  Zuweisungen sind reine Datentabellen für Vimscript-Plugins (matchup,
  mkdp, VM) — keine Funktionen, keine Metatables.
- **`UI-55`** (sichtbare Fenster vor dem Löschen umleiten): an einem echten
  Split nachgestellt — solange ein anderer gelisteter Buffer existiert,
  setzt Neovim die Fenster selbst darauf. Bleibt keiner übrig, ist ein
  Scratch-Buffer die einzig mögliche Antwort.

---

### Durchgang 2 zusätzlich geprüft und sauber

- **`LUA-60`** (Datei-Tags): 0 von 224 Dateien ohne `@module`/`@class`/`@brief`.
- **`PRIN-50`** (jede Datei erklärt sich): 0 ohne Kopf.
- **`LUA-50`/`PRIN-05`** (nur intern Genutztes bleibt privat): 0 öffentliche
  `M.*`-Funktionen, die nirgends aufgerufen werden.
- **`LUA-95`** (Usercmd-Kollisionen): alle 46 selbst vergebenen Namen sind
  präfixiert oder spezifisch; keiner wird von einem installierten Plugin
  ebenfalls definiert.
- **`CMT-03`** (`require`-Pfade in Doku sind echt): 10 nicht auflösbare
  Treffer, alle legitim — Platzhalter (`require("x")`), auskommentierte Specs
  nicht installierter Plugins, und historische Migrationsnotizen
  (`nvchad.mason`, `menu`), die ausdrücklich „war mal" sagen.
- **`CMT-05`** (Migrationsreste in user-facing Strings): kein einziges
  `notify`/`desc` zeigt auf ein totes Kommando — gegen die Kommandoliste einer
  wirklich geladenen Config geprüft.
- **`ERR-34`** (Symlinks beim Walk): alle rekursiven Walks delegieren an
  `lib.nvim.fs.collect_recursive`, das die Regel explizit umsetzt und beim
  Namen nennt — zugleich `LUA-02` erfüllt.
- **`ERR-64`** (Klammern kappen Mehrwertigkeit): 26 Treffer, alle das bewusste
  `(x:gsub(...))`-Idiom oder eine dokumentierte `boolean`-Rückgabe.
- **`ERR-62`**: außer `vim.cmd` kein einziger `pcall(f(args))`.
- **`XP-06`** (Modulpfad-Schreibweise): 0 Abweichungen über 321 `require`-Ziele.
- **`SEC-02`** (`cwd` explizit): Git läuft über `git -C <dir>`, pandoc über
  absolute Temp-Pfade.
- **`SEC-41`** (Fremdconfig strikt prüfen): `machine.lua` ist mustergültig —
  Typprüfung, Normalisierung, Whitelist, Warnung, Fallback auf Default (damit
  zugleich `ERR-22`).
- **`SEC-44`**: `linkcheck`s Klassifikation ist sicher, weil `fetch_raw` bei
  `ok = true` einen geparsten `status` garantiert (in lib.nvim nachgelesen).
- **`TS-01`/`TS-02`/`TS-05`**: die sechs eigenen Query-Dateien enthalten
  zusammen 47 Zeilen reine Captures, kein einziges Predicate oder Directive.
  `TS-03` (`;; extends`) haben alle sechs.
- **`DEP-05`**: kein `sign_define` im Repo.
- **`UI-56`** (springende Previews): kein Fall — die Config rendert nie in ein
  Fenster nach, in dem gescrollt wurde; ihre Report-Flächen entstehen einmal
  in einem frischen Scratch-Buffer.
- **`PERF-92`**: alle zwölf `vim.o.columns`/`lines`-Lesungen liegen in
  Funktionskörpern.
- **`PERF-93`**: alle vier Handler auf heißen Events sind buffer-lokal
  registriert, laufen im normalen Editier-Buffer also gar nicht erst an.
- **`PERF-71`**: drei `table.remove(x, 1)`, keines in einer Queue-Schleife.
- **`SEC-14`**: keine secret-artige Datei getrackt.

---

## Methodik-Notiz

`run_all.lua`/`rules_init.lua` (headless-Bootstrap plus Schleife über alle
Familien) waren bewusst Wegwerf-Skripte im Scratchpad, nicht committetes
Werkzeug — nach `TOOLS/TOOL-PLACEMENT.md` § 1: die Frage war einmalig zu
beantworten, das Ergebnis ist dieses Dokument, und `:Rules check` ist für
den Wiederholungsfall schon da. Dasselbe gilt für die Scanner dieses
Durchgangs (Return-Contract-Tokenizer, Autocmd-Gruppen-Zähler,
Require-Pfad-Prüfer). Für die LuaLS-Seite gibt es dagegen mit
`scripts/luals-scan` bereits ein echtes Werkzeug im Repo — das wurde benutzt,
nicht nachgebaut.

**Worktree-Warnung für den nächsten Durchgang:** `nvim -u init.lua` aus einem
Worktree lädt `require`-Module trotzdem aus dem Haupt-Checkout
(`stdpath('config')`), und `vim.loader` cacht, sodass ein nachträgliches
`runtimepath`-Prepend nichts ändert. Ein früher Validator-Lauf hat dadurch
stillschweigend die *alte* Datei getestet. Wer eine geänderte Datei wirklich
ausführen will: `loadfile("<worktree>/lua/.../x.lua")()` mit Windows-Pfad.
Derselbe Effekt erzeugt die oben beschriebenen Phantom-Duplikate.
