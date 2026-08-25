# Merged Roadmap -- Erledigt

Aus `MERGED.md` herausgenommene Tasks, sobald sie abgeschlossen sind.
Neueste zuerst. Gilt fuer alle `*.nvim`-Repos unter `C:/repos` plus diese
nvim-Config.

---

## 2026-08-25

### Git & Repo-Hygiene

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
