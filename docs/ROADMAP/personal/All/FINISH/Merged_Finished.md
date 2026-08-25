# Merged Roadmap -- Erledigt

Aus `MERGED.md` herausgenommene Tasks, sobald sie abgeschlossen sind.
Neueste zuerst. Gilt fuer alle `*.nvim`-Repos unter `C:/repos` plus diese
nvim-Config.

---

## 2026-08-25

### Git & Repo-Hygiene

- [x] **Claude-Branches aufräumen — 26 von 28** (Rest: die zwei jüngeren als
      3 Tage, siehe MERGED.md).

      18 waren vollständig in `main` — ersatzlos gelöscht, lokal wie remote,
      plus vier verwaiste `.claude/worktrees/`-Checkouts.

      Die 8 älteren mit unveröffentlichten Commits wurden nicht weggeworfen,
      sondern eingebaut. `main` war überall 24–52 Commits weiter, also war kein
      einziger ein glatter Cherry-Pick:

      - `replacer.nvim` — vier `*tag*`-Definitionen statt `|tag|`-Referenzen in
        `doc/replacer.txt`. Doppelte Tag-Definitionen brechen `:helptags` und
        damit `:Lazy sync`.
      - `buffer-ctx.nvim` — `:Insert/:Copy date` bekommt dieselbe
        `[format] [--utc]`-Grammatik wie `timestamp`, plus 5 neue Formate.
      - `filetree.nvim` — zwei Commits: `no_name_guard` aus sechs
        Test-Setups heraus (es löschte die Scratch-Buffer, bevor der Test ihre
        Keymaps lesen konnte), und `lua_require_copy` auf
        `lib.nvim.lua_ls.get_module_path` konsolidiert. Die zweite Hälfte des
        ersten Commits wurde verworfen: `main` hatte denselben Bug inzwischen
        präziser gefixt.
      - `markdown.nvim` — zwei Features: `:Markdown links sanitize` +
        Sanitize-on-save, und der Heading-Gap-Checker (`:Markdown gaps`,
        `check_heading_gaps`, `--check-gaps`). Beide Branches hatten ältere
        Fassungen von Config-Block, Subcommand-Tabelle und vimdoc-Kapitel-
        nummerierung, die durch die aktuellen ersetzt wurden.
      - `pickers.nvim` — von 9 Commits war genau einer noch nicht auf `main`:
        die Systemscope suchte unter Windows in `"/"`, also im Root des
        *aktuellen* Laufwerks statt überall, und `pick_dir` in den
        telescope-/snacks-Engines kannte `fdfind` nicht (Debian/Ubuntu). Gegen
        `main`s inzwischen asynchrone `drives.lua` neu implementiert.
      - `mdview.nvim` — vollständig überholt: `main` hat `:MDView blanklines`
        eigenständig gelöst, client-seitig in TypeScript statt in Rust/WASM.
        Übrig blieb eine echte Doku-Lücke: `doc/mdview.txt` kannte das Feature
        als einziges nicht.

      Aufgefallen und mitgenommen: `docs/NOTES/PersonelPlugins/BINDINGS`
      beschrieb drei dieser Features bereits, aber mit Verweis auf Branches, die
      es jetzt nicht mehr gibt — auf "seit 2026-08-25 auf `main`" umgestellt.

- [x] **`gh repo edit` (Description, Topics) pro Repo.**
      Description und Topics waren in allen 31 Repos schon gesetzt; offen war
      die Konsistenz. Basis-Set `neovim` / `neovim-plugin` / `lua` -- die drei
      Topics, über die auf GitHub tatsächlich gesucht wird -- fehlte in sechs
      Repos: `color_my_ascii.nvim`, `dap.nvim`, `language.nvim`,
      `replacer.nvim`, `sessions.nvim` (jeweils `nvim-plugin` statt
      `neovim-plugin`) und `mdview.nvim`. `mdview.nvim` stand bereits auf dem
      GitHub-Maximum von 20 Topics, deshalb ist `local` (als Topic
      bedeutungslos) für `lua` gewichen.

      Nebenbei die Homepage-URLs: `lib.nvim` hat eine Pages-Site
      (stefanbartl.github.io/lib.nvim), war aber nicht verlinkt -- jetzt schon.
      `fileops.nvim` und `spotlight.nvim` zeigten als "Homepage" auf ihre
      eigene GitHub-Seite, was GitHub ohnehin schon tut -- geleert.


- [x] **Branch auf `main` umstellen, wo noch nicht geschehen.**
      Einziges Repo abseits von `main` war `lsp.nvim`
      (`feat/diag-severity-completion-and-autocmd-groups`, ein unveroeffentlichter
      Commit). Fast-forward nach `main` gemergt, gepusht, Feature-Branch geloescht.
      Alle 31 Plugin-Repos stehen jetzt auf `main`.

### Dokumentation & Cheatsheets

- [x] **`.luarc.json` pro Plugin-Root anlegen.**
      War in allen 31 Repos bereits vorhanden. Bei der Pruefung fiel auf, dass
      `sandbox.nvim/.luarc.json` durch zwei nachgestellte Kommata kein gueltiges
      JSON war (LuaLS' eigener Parser toleriert das, jeder andere Consumer nicht) --
      korrigiert. Alle 31 Dateien parsen jetzt als striktes JSON.

### Dokumentation & Cheatsheets

- [x] **Verweise auf die Quell-Checklisten korrigiert** (die offene Frage aus
      dem Roadmap-Task, von dir beantwortet: die Checklisten sind in den Regeln
      unter `WKDBooks/Development/wkdbook-Lua/Checklists/` aufgegangen).

      19 Verweise in 7 Repos zeigten auf `Notes/MyNotes/Checklists/Lua/`, die
      meisten noch mit dem alten `E:`-Laufwerk. Umgehängt nach der Zuordnung,
      die das `archiv/README.md` der Regelsammlung selbst festhält:
      `Arch&Coding-Regeln.md` → `regeln/PRINCIPLES.md` (+ `regeln/LUA_NVIM.md`),
      `Zentrale-Prinzipien.md` → `regeln/PRINCIPLES.md`, `Checklist.md` →
      `regeln/` + `gates/`.

      Der Linktext nannte jeweils noch die stillgelegte Datei, obwohl er aufs
      neue Ziel zeigte — jetzt benennt er das Ziel, plus eine Zeile, dass die
      Quellen aufgegangen und nicht verloren sind.

      `gopath.nvim` ist der Sonderfall: dort liegt eine 776-Zeilen-Kopie der
      *alten* Checkliste statt eines gopath-Audits. Sie sagt jetzt selbst, dass
      sie nicht die kanonischen Regeln ist und wo die stehen. Ob sie ganz weg
      soll, ist deine Entscheidung — die Regelsammlung sagt „Kopien an anderen
      Orten verweisen hierher und enthalten selbst keine Regeln".

      Damit sind die Roadmap-Dokumente aller 31 Repos frei von toten Links
      (vorher 38).

- [x] **`docs/ROADMAP.md` pro Plugin anlegen bzw. durchgehen.**
      Jedes Repo hatte etwas, aber in drei verschiedenen Formen: mal
      `docs/ROADMAP.md`, mal nur ein `docs/ROADMAP/`-Ordner, mal beides ohne
      Verbindung.

      *Angelegt:* `filetree.nvim` war das einzige Repo mit Ordner und ohne
      Einstiegspunkt — vier Dokumente, keine Aussage darüber, welche noch offen
      sind. Der README verwies auf den Ordner und zählte geplante Arbeit auf,
      die davon abgewichen war.

      *Durchgegangen:* neun Repos hatten `docs/ROADMAP.md` **und**
      `docs/ROADMAP/` nebeneinander, und die Datei erwähnte den Ordner nie —
      die Audits und Konzeptpapiere darin waren nur zu finden, wenn man das
      Verzeichnis bemerkte. Jede dieser Dateien indexiert ihren Ordner jetzt und
      sagt, dass nichts davon offene Arbeit ist, sofern es nicht dasteht. Wo die
      Roadmap nur aus Überschrift und Trennlinie bestand, steht jetzt, dass
      nichts offen ist, statt den Leser raten zu lassen.

      *Dabei gefunden:*
      - `filetree.nvim`s Neotree-Audit führte zwei der vier Lücken noch als
        „konkrete Arbeitspakete", obwohl beide gebaut sind
        (`paths.markdown_links`, `system.pdf_open`/`pdf_create`). Auch die
        Feature-Zahl war veraltet (62 → 56).
      - **38 tote Links** in den Roadmap-Dokumenten, jetzt 14 — und die
        verbleibenden sind alle dieselbe offene Frage (s. MERGED.md). Darunter
        drei, die `gen_map` in `images.nvim` bei *jedem* Lauf gemeldet hat, und
        neun in `filetree.nvim`s `Refs_Engine.md`, die als repo-root-relativ
        geschrieben waren, obwohl das Dokument drei Ebenen tief liegt.
      - `filetree.nvim` schloss Fixtures unter `TESTS/smart_rename_refs/` aus —
        in `.luacheckrc` **und** in der `.styluaignore`. Die Suite ist längst
        `TESTS/refs/`; beide Ausschlüsse liefen also ins Leere und die Fixtures
        wurden wie Plugin-Quellcode gelintet.
      - `gopath.nvim`s `Checklist.md` ist eine wörtliche Kopie der geteilten
        Checkliste, kein gopath-Audit wie in allen Geschwister-Repos — inklusive
        elf Querverweise auf Dateien des Quell-Repos.

- [x] **README.md pro Plugin an Spec anpassen.**
      Punkt für Punkt gegen alle 31 READMEs geprüft. Das meiste war schon da:

      | Spec-Punkt | Stand |
      | --- | --- |
      | Badges / ASCII-Art | 31/31 ✅ |
      | Auf Englisch | 31/31 ✅ (kein deutscher README-Text gefunden) |
      | Lizenzverweise löschen | 31/31 ✅ — kein README hat einen Lizenz-Abschnitt |
      | `dir = vim.env…` entfernen | 31/31 ✅ — kein lazy-`dir`-Feld irgendwo (der eine Treffer war `repos_dir = vim.env.REPOS_DIR`, eine echte Plugin-Option) |
      | `lazy=false`/`VeryLazy` explizit | 31/31 ✅ — die vier Treffer ohne Trigger waren `mini.deps`/`vim.pack`-Snippets, die keinen kennen |
      | Cross-Link zu verwandtem Plugin | war 30/31 |
      | Installation für mehrere Package-Manager | war 27/31 |

      Geschlossen wurden also zwei Lücken:

      - **`sandbox.nvim`** war das einzige README, dessen Kopf auf kein
        Schwester-Plugin zeigte. `reposcope.nvim` ist die ehrliche Paarung:
        reposcope klont ein Repo in ein Verzeichnis, und sandbox liest die
        `compose.yml` / `.devcontainer/`, die dieses Repo mitbringt, aus dem cwd
        oder einem Vorfahren — die beiden treffen sich, ohne dass eines von
        beiden einen Pfad konfiguriert bekommt.
      - **`images.nvim`, `language.nvim`, `sandbox.nvim`** zeigten nur ein
        lazy-Snippet. Alle drei haben jetzt `docs/installation.md` im Format der
        übrigen Repos (Prerequisites getrennt nach „required" und „schaltet
        genau eine Sache frei", dazu packer.nvim und vim-plug). Dabei kam jeweils
        etwas heraus, das im README nirgends stand: images braucht ein Terminal
        mit OSC 1337 (und warum die Spec `cmd` **und** `ft` trägt), sandbox
        braucht überhaupt eine Container-Engine auf dem `PATH`.

      Anmerkung: die bestehenden Cross-Link-Absätze beginnen mit einem
      Emoji (`> 💡 Pairs well with …`). Der neue in `sandbox.nvim` nicht — nach
      deiner stehenden Regel „keine Emojis in generiertem Inhalt". Sag Bescheid,
      wenn er der Optik zuliebe doch eines bekommen soll.

### Healthchecks, Config & Defaults

- [x] **`:checkhealth`-Unterstützung pro Plugin implementieren.**
      War in 30 von 31 Repos vorhanden. Headless über alle 31 verifiziert:
      `:checkhealth <name>` findet überall ein Modul und wirft keine Exception.

      Die eine Lücke war `documentation.nvim`: nach dem core/editor-Split lag
      der Healthcheck unter `documentation.editor.health`. Neovim löst
      `:checkhealth documentation` aber ausschließlich nach
      `lua/documentation/health.lua` auf und durchsucht keine
      Unter-Namespaces -- der Aufruf, den README, vimdoc und drei weitere Docs
      nennen, lief also ins Leere. Weiterleitungs-Modul angelegt.

      Aufgefallen dabei: der Name, den `:checkhealth` erwartet, ist der
      Lua-Modulname, nicht der Repo-Name -- und bei `dap.nvim` (intern
      `wkddap`, damit es nicht mit `nvim-dap` kollidiert) ist der nicht zu
      erraten. Die vollständige Zuordnung steht jetzt in
      `docs/NOTES/PersonelPlugins/Misc.md`.

- [x] **`/bindings`-Ordner (usrcmds/keymaps/autocmds) anlegen.**
      29 von 31 Repos hatten ihn. Die beiden Lücken sind geschlossen, und beide
      haben beim Aufräumen je einen echten Fehler hergegeben:

      - `replacer.nvim`: die Usercmds wurden von einer handgepflegten
        `pcall`-Leiter in `plugin/replacer.lua` registriert, die neun Module
        nannte und keines der Kommandos, die sie anlegen; der eine Autocmd und
        die zwei Panel-Keymaps standen inline in `regex.lua`.
        `lua/replacer/bindings/` hält jetzt alle drei. Der Autocmd bekam dabei
        eine benannte Gruppe (`ReplacerTestPanel`) — stapeln konnte er nicht,
        aber ein namenloser Autocmd ist für jeden unsichtbar, der prüfen will,
        was ein Plugin installiert.
      - `lib.nvim`: die ganze Bindings-Fläche lag in einer 168-Zeilen-
        `init.lua`. Aufgeteilt in `actions`/`usrcmds`/`autocmds` (kein
        Keymaps-Modul — eine Library, von der andere Plugins abhängen, hat
        keine Taste zu belegen). **Dabei gefunden:** der Helptags-Autocmd hatte
        keine Augroup, und `setup()` läuft bei jedem Config-Reload erneut. Nach
        zwei Reloads lief `helptags ALL` bei einem `:Lazy sync` also dreimal —
        ~229 ms pro Lauf bei 116 Plugins, und nicht inkrementell. Jetzt
        idempotent.

### Healthchecks, Config & Defaults

- [x] **Sinnvolle Features default aktivieren, Init-Spec so schlank wie möglich
      halten.**
      Zielbild war eine Spec, die nur noch aus Repo, Lazy-Trigger und `opts`
      besteht. **746 Spec-Zeilen → 639**, und danach ist in `opts` nichts mehr
      übrig, was nicht bewusst gesetzt ist.

      Zwei Sorten Ballast, beide mechanisch gefunden:

      *Optionen, die den Default des Plugins bloß wiederholten.* Jede
      `opts`-Tabelle gegen die `config/DEFAULTS.lua` des Plugins verglichen —
      sieben Specs erzählten dem Plugin seine eigenen Defaults zurück. `cascade`
      listete alle sechzehn Feature-Schalter (nur `keymaps.preset` weicht ab),
      `fileops` dreizehn (nur `cycle.open_target`), dazu buffer-ctx komplett,
      `diff.features.*`, `emojis.default_scope`, `debugging.features.neotree`,
      `images.display.draw_inset`, `cmdlog.picker`, `replacer.default_scope`.
      Eine wiederholte Default-Zeile ist schlechter als gar keine: sie sieht aus
      wie eine Entscheidung und hört still auf, dem Plugin zu folgen, wenn sich
      der Default bewegt.

      *`config`-Blöcke, die taten, was `opts` von selbst tut.*
      `config = function(_, opts) require(X).setup(opts) end` ist exakt
      lazy.nvims eigenes Verhalten für eine Spec mit `opts`. Von 16 solchen
      Blöcken sind 5 übrig — die, die wirklich etwas berechnen (pickers'
      collections, filetrees Feature-Tabelle, documentations
      bindings/generate_all-Builder).

      Verifiziert, nicht angenommen: jedes umgestellte Plugin headless geladen
      und geprüft, dass sein Modul auflöst und sein Command registriert ist.

      **Zur ersten Hälfte des Tasks:** die Defaults *sind* schon sinnvoll. Der
      Beweis ist genau das obige Ergebnis — nachdem alles Redundante raus ist,
      bleiben über 31 Plugins sechs echte Einstellungen übrig (Engine-Wahl,
      `progress_style = "statusline"`, cascades Keymap-Preset, fileops'
      `open_target`, images' gemessenes `cell_aspect`, pickers' collections).
      Kein Feature gefunden, das per Default an sein sollte und es nicht ist.

      **READMEs nachgezogen** (16 Repos), weil User die Spec von dort kopieren.
      Dabei drei echte Fehler in den Install-Anleitungen:
      - `cmdlog.nvim` bot drei Lazy-Load-Rezepte gleichrangig an; **zwei davon
        leeren genau die History, die das Plugin zeigen soll** — der
        `CmdlineLeave`-Tracker startet dann erst beim ersten `:Cmdlog`. Steht
        jetzt als Warnung unter beiden.
      - `replacer.nvim`s Snippets sagten `StefanBartl/replacer` mit
        `name`/`as`-Override daneben. Das Repo heißt `replacer.nvim`; die
        Kurzform funktioniert nur über GitHubs Redirect vom alten Namen, und der
        Override existierte nur, um das zu kaschieren.
      - `color_my_ascii.nvim` zeigte unter der Spec noch ein separates
        `require(...).setup()` — las sich wie ein zweiter Pflichtschritt.

- [x] **`config/init.lua` + `config/DEFAULTS.lua` pro Plugin anlegen,
      pluginseitige Defaults dorthin.**
      Die Struktur stand bereits in **allen 31 Repos**. Geprüft wurde deshalb
      die zweite Hälfte: liegen die Defaults auch wirklich dort?

      Gesucht nach Default-Tabellen außerhalb von `config/DEFAULTS.lua` — 6
      Repos, 10 Stellen. Nach Durchsicht sind acht davon korrekt am Platz:
      Funktionsargument-Defaults (`sessions.nvim`s Statusline-Komponente),
      interne Transport-Konstanten (`mdview.nvim`s Websocket-Backoff),
      Highlight-Konstanten (`lsp.nvim`) und drei filetree-Features, deren
      Defaults laut der dokumentierten Architektur beim Feature bleiben
      („Per-feature defaults that are not listed here live in the feature
      module itself").

      Zwei waren echte Befunde:

      - **`filetree.nvim`, `cwd_mode`:** `config/DEFAULTS.lua` führte eine
        von Hand gepflegte **Teilkopie** der Feature-Tabelle — und war schon
        abgedriftet. Der ganze `nearest`-Block (zehn Package-Marker, die
        komplette Konfigurationsfläche eines der sechs Modi) stand nur im
        Feature; wer die zentralen Defaults las, konnte nicht erkennen, dass es
        überhaupt konfigurierbar ist. Dasselbe bei `indicator.labels` und
        `align`. Nach `features/nav/cwd_mode/DEFAULTS.lua` ausgelagert und von
        beiden Seiten `require`d — genau die Anordnung, die
        `filetree.refs.DEFAULTS` in derselben Datei schon benutzt. Gemerged
        wurde vorher wie nachher gleich (die kopierten Keys stimmten zufällig
        überein, und der Merge ist tief); es geht um den nächsten Edit, nicht
        um diesen.
      - **`runtime-analysis.nvim`:** `setup()` akzeptiert vier Optionen —
        `KNOWN_OPTS` validiert genau dagegen — aber `DEFAULTS.lua` beschrieb
        drei. `telemetry` existierte nur in der `@param`-Annotation. Steht
        jetzt dort, bewusst **ohne Default-Wert**: Auto-Instrumentierung ist
        opt-in, und gerade die *Abwesenheit* des Keys bedeutet „nicht
        instrumentieren" — eine Default-Tabelle hätte sie für alle
        eingeschaltet, die nie danach gefragt haben.

- [x] **Prüfen: sind wirklich alle Plugins lazy geladen?**
      Nein — und das ist überwiegend richtig so. Von 31 Specs in
      `lua/plugins/personal/init.lua` laden 7 eager (`lazy = false`):

      | Plugin | Eager, weil | War begründet? |
      | --- | --- | --- |
      | `lib.nvim` | Library + registriert `:Lib`/`:CwdHere` beim Start (Priority 1000) | ja |
      | `lsp.nvim` | Capabilities müssen global stehen, bevor der erste Client attached (Priority 900) | ja |
      | `runtime-analysis.nvim` | Telemetrie muss die anderen Plugins umschließen, bevor die laden | ja |
      | `insights.nvim` | conflicts/unimported/devserver sind Autocmds aus `setup()` | ja |
      | `sessions.nvim` | `VimEnter`-Autoload und `VimLeavePre`-Autosave | **nein, jetzt** |
      | `pickers.nvim` | `setup()` leitet ~20 Keymaps aus der `collections`-Tabelle ab | **nein, jetzt** |
      | `cmdlog.nvim` | `setup()` startet den `CmdlineLeave`-Tracker | **nein, jetzt** |

      `learn-cli.nvim` steht ebenfalls auf `lazy = false`, ist in `source.lua`
      aber `"disabled"` — lädt also ohnehin nie.

      **Der eine echte Fund:** `cmdlog.nvim` hatte `lazy = false` **und**
      `cmd = { "Cmdlog" }`. lazy.nvim ignoriert das `cmd` dann, aber die Zeile
      las sich, als wäre das Plugin kommando-lazy — und wer sie „aufräumt",
      indem er `lazy = false` entfernt, bricht das Plugin auf eine Art, die
      niemand als Fehler sieht: der Tracker startete dann erst in dem Moment,
      in dem man die History zum ersten Mal öffnet, die also immer leer wäre.
      Das tote `cmd` ist weg, der Grund steht jetzt dort.

      Die drei unbegründeten Fälle haben jetzt ihre Begründung im Spec. Kein
      Plugin wurde umgestellt: bei allen sieben ist eager nach Prüfung die
      richtige Antwort.

### Security, Tests & CI/CD

- [x] **Testdateien unter `TESTS/**` schreiben** — die zweite Hälfte des
      Test-Tasks. **Alle 31 Repos haben jetzt eine Suite und einen Test-Job in
      CI**, vorher waren es 25.

      Fünf Repos hatten überhaupt keine Tests. Jedes hat jetzt vier bis sechs
      Specs im Haus-Stil (`TESTS/run.lua` + `harness.lua`, headless, keine
      Netzwerk-/UI-Abhängigkeit), ein `TESTS/README.md` und einen dritten
      CI-Job mit lib.nvim als Sibling-Checkout.

      Was dabei zutage kam — in allen fünf Fällen habe ich das **tatsächliche**
      Verhalten festgeschrieben und den Kommentar dazugeschrieben, statt zu
      „reparieren", was eine Entscheidung von dir wäre:

      - **`reposcope.nvim`**: `setup()` merged in die *aktuelle* Optionstabelle
        (`vim.tbl_deep_extend("force", M.options, opts)`), nicht in eine Kopie
        von DEFAULTS wie in allen Geschwister-Plugins. Es akkumuliert also:
        ein zweites `setup({})` setzt nichts zurück, und eine einmal gesetzte
        Option lässt sich später nicht mehr abwählen. Für den normalen
        Einmal-`setup()`-Pfad egal, für Runtime-Rekonfiguration überraschend.
      - **`insights.nvim`**: `require("a." .. kind)` wird als Modul `a.`
        gemeldet — der Scanner sieht nur das Literal vor der Konkatenation. Das
        ist genau die False-Positive-Klasse, die die `:DocMap`-Notizen der
        nvim-Config beschreiben. Zu unterdrücken bräuchte eine Entscheidung,
        was ein dynamisches require beitragen soll: nichts, oder das Präfix als
        Hinweis.
      - **`recommender.nvim`**: eine Dreiteil-Kette liefert bei Threshold 1
        *zwei* Vorschläge, weil auch ihr Zweiteil-Präfix ein Kandidat ist —
        genau deshalb ist der Default über 1. Und die Blacklist matcht
        Strings, nicht Segmente: `vim.a` blockt `vim.api`.
      - **`sessions.nvim`**: die sicherheitsrelevante Stelle ist
        `git.sanitize` — ein Session-Name wird zu einem Dateipfad, und die
        Namen kommen aus Branch und Verzeichnis. `feature/login`, `..`, ein
        Backslash und eine ANSI-Farbsequenz müssen alle zu etwas werden, das
        das Sessions-Verzeichnis nicht verlassen kann.
      - **`language.nvim`**: `is_compound` darf nie „nein" sagen, wo `split`
        Arbeit gehabt hätte — dieser Vorab-Check ist das Einzige, was still
        einen echten Fund kosten kann.

      **Und ein sechstes Repo:** `color_my_ascii.nvim` *hatte* eine Suite mit
      16 Spec-Dateien — CI hat sie nie aufgerufen, der Workflow hieß „Lint" und
      tat genau das. Jetzt läuft sie. Beim ersten Lauf über `TESTS/` kam
      heraus, dass das Verzeichnis noch nie geprüft worden war (falscher
      Quote-Stil, eine tote Zuweisung).

- [x] **Bestehende Tests nach `TESTS/**` verschieben (Root statt `docs`)** —
      die Verschiebe-Hälfte des Test-Tasks. Vorher lagen sie an vier
      verschiedenen Orten, jetzt an einem: **25 von 31 Repos haben `TESTS/` im
      Root**, keines mehr `docs/TESTS/`, `tests/` oder `test/`.

      - 12 Repos: `docs/TESTS/` → `TESTS/`.
      - 5 Repos: `tests/` → `TESTS/` (als zwei git-moves, weil eine reine
        Groß-/Kleinschreibungs-Umbenennung auf einem case-insensitiven
        Dateisystem ein No-op ist).
      - `filetree.nvim` hatte beides: `test/` mit den vier Headless-Suites und
        `TESTS/` mit den Fixture-Tests. Zusammengelegt; `test/README.md` war
        keine Dublette, sondern eine manuelle Integrations-Checkliste — liegt
        jetzt als `TESTS/MANUAL.md` daneben.
      - `github_stats.nvim` hatte seine Specs unter `lua/github_stats/tests/`,
        also **im Runtime-Tree** — sie wurden mit ausgeliefert und lagen auf dem
        runtimepath. Jetzt im Root.

      **Der teure Fund dabei:** luacheck bringt eingebaute busted-Defaults mit,
      die auf `**/spec/**`, `**/test/**` und `**/tests/**` matchen — alles
      klein. Solange die Suite in `tests/` lag, bekam sie den busted-std
      geschenkt; `TESTS/` matcht keines davon, und `assert.has_no.errors` &
      Co. wurden zu 465 Warnungen in `lsp.nvim`, von denen keine einzige den
      Code betraf. Jetzt explizit deklariert — was ohnehin besser ist, weil
      vorher nirgends stand, woher die busted-Globals kamen.

      Zwei weitere Fallen, die nur auf Linux sichtbar wurden:
      - `sandbox.nvim` hatte drei `require("tests.sandbox.helpers.…")` —
        Modulpfade, keine Dateipfade, also für eine `tests/`-Suche unsichtbar.
        Unter Windows löste das weiter auf (case-insensitiv), auf CI nicht: jede
        Spec meldete Erfolg und der Prozess ging trotzdem mit 1 raus.
      - `runtime-analysis.nvim`s `parse_spec.lua` lud `ftdetect/` über
        `TESTS/../../` — zwei Ebenen hoch, weil die Suite unter `docs/` lag.


- [x] **`ci`/`stylua`/Tests über alle Plugins grün ziehen.**
      Ausgangslage: 21 Repos rot, 4 ohne jeden Workflow, 7 grün.
      Endstand: **alle 31 Repos grün, in jedem Workflow** -- und ohne
      `continue-on-error` irgendwo, das Grün also echt.

      Was rot war, nach Ursache:

      *stylua* (16 Repos) -- Dateien, die älter als die `stylua.toml` waren
      oder daran vorbeigedriftet sind. Formatierung, keine Verhaltensänderung.

      *luacheck* (10 Repos). Zwei davon waren echte Bugs, nicht nur Lint:
      - `emojis.nvim`: `open_grid` wurde im `/`-Filter mehrere hundert Zeilen
        vor seiner `local function`-Definition aufgerufen, war dort also gar
        kein Upvalue, sondern ein nil-Global -- Filtern im Grid ist
        geknallt statt neu zu rendern. Jetzt forward-deklariert.
      - `reposcope.nvim`: `metrics.lua` baute einen Authorization-Header und
        übergab ihn nicht, `/rate_limit` lief unauthentifiziert und meldete die
        anonyme Quote (60/h) statt der des Tokens (5000/h).
      Der Rest waren tote Zuweisungen, ungenutzte Argumente/Shims, ein leerer
      `if`-Zweig, ein Shadowing von `pcall`s `ok`-Flag, plus drei Config-Fixes
      (`bit` als LuaJIT-Global in `images.nvim`; `max_line_length` an stylua
      abgegeben, wo es nur Stringliterale und LuaCATS-Kommentare traf;
      `.luarocks/` aus dem Prüfpfad von `github_stats.nvim`).

      *Tests / Job-Setup* -- Gates, die strukturell nie grün werden konnten:
      - `diff.nvim`: `git_spec` rief das längst callback-basierte
        `core.git.resolve` positionell auf und las einen Rückgabewert. `cb` war
        damit nil, die Guard-Clauses sind mit "attempt to call upvalue 'cb'"
        auf dem Main-Loop hochgegangen -- mitten in `url_spec`, das dadurch die
        ganze Suite mitgerissen hat.
      - `documentation.nvim`: der `<Tab>`-Completion-Abschnitt war von Hand in
        das **generierte** `docs/BINDINGS.md` geschrieben. Jeder `:DocMap`-Lauf
        hat ihn gelöscht, und weil die Modul-Map BINDINGS.md einbettet, war
        auch sie danach "stale" -- rotes Gate ohne irgendetwas im Working Tree,
        das es erklärt hätte. Der Abschnitt liegt jetzt im Renderer, wo der
        Kommentar direkt darunter das auch vorschreibt.
      - `images.nvim`: das map-Gate lief `gen_map.lua --check`, das gegen eine
        *committete* Map vergleicht -- `docs/map/` steht dort aber in der
        `.gitignore`. Auf einem frischen Checkout gab es nichts zu vergleichen,
        das Gate konnte nie grün werden.
      - `github_stats.nvim`: `scripts/test.sh` war ohne Executable-Bit
        committet, der Runner hat es mit exit 126 abgelehnt.
      - `replacer.nvim`: CI checkt lib.nvim *in* den Workspace aus, der
        Resolver sucht ein *Geschwister*-Verzeichnis. Alle drei Suites brachen
        vor dem ersten Check ab.
      - `open.nvim`: `features_spec` behauptete, `filemanager.reveal=true/false`
        bauten immer verschiedene Kommandos. Ohne select-fähigen Dateimanager
        (also auf jedem Runner) degradiert `reveal=true` per Design zum
        Öffnen des Elternverzeichnisses -- der Test hat geprüft, ob der Runner
        einen Desktop hat.

      *Advisory-Gates abgeschafft* -- `filetree.nvim` (105 Dateien
      nachformatiert; die vier Headless-Suites melden davor und danach exakt
      dieselben Pass/Fail-Zahlen), `fileops.nvim`, `markdown.nvim`. Bei
      `fileops.nvim` kam dabei heraus, dass der stylua-Schritt nie gelaufen
      war: ohne `token` bricht die Action ab, was durch `continue-on-error`
      niemand gesehen hat.

- [x] **GitHub Actions einrichten (z. B. `luacheck`).**
      Vier Repos hatten ueberhaupt keinen Workflow: `insights.nvim`,
      `language.nvim`, `reposcope.nvim`, `sessions.nvim`. Alle vier haben jetzt
      `.github/workflows/ci.yml` mit `stylua --check` (auf 2.5.2 gepinnt) und
      `luacheck`, im Stil der Geschwister-Repos.

      Was dabei mitkam:
      - `sessions.nvim` hatte weder `stylua.toml` noch `.luacheckrc` -- beide
        angelegt (Haus-Stil); die 139 luacheck-Findings waren nur der Default-`std`,
        der `vim` nicht kennt.
      - `insights.nvim/stylua.toml` stand auf `line_endings = "Windows"`, waehrend
        `.gitattributes` `eol=lf` erzwingt. Jeder Linux-Runner haette damit
        *jede* Datei als unformatiert gemeldet. Auf `Unix` umgestellt.
      - `reposcope.nvim`: luachecks einziges Finding war ein echter Bug --
        `metrics.lua` baute einen Authorization-Header und uebergab ihn nicht,
        `/rate_limit` lief also unauthentifiziert und meldete die anonyme
        Quote (60/h) statt der des Tokens (5000/h).
