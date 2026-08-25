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

### Security, Tests & CI/CD

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
